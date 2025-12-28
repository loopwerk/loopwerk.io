---
tags: coolify, deployment
summary: A deep dive into Docker layer caching, BuildKit cache mounts, and how a Coolify bug can sabotage your build times, plus what you can (and can't) do about it.
---

# How Coolify accidentally broke Docker layer caching (and what you can do now)

For two weeks, I watched my Docker builds slow down from a snappy 1 minute to a painful 4.5 minutes. I was using the same code, the same Dockerfile, and the same server. Something had changed, but I had no idea what it was.

This article breaks down the technical cause of the slowdown, explains the difference between Docker's two primary caching mechanisms, and details the partial workaround that helped claw back some time.

## Builds suddenly got slow

Around the start of November 2025, my build times jumped from one minute to nearly five. The logs revealed that every step was running from scratch, even when I only changed a single markdown file.

Dependencies that should have been cached were being reinstalled every time:

- apt-get install: 73 seconds to download and install 152 MB of packages.
- Swift package build: 83 seconds to resolve and compile dependencies.

This made no sense. None of my dependency files had changed, so Docker should have reused the cached layers.

## How builds are supposed to be fast: Docker layer caching

To understand the problem, we first need to look at how Docker is designed for speed. Docker builds images in a series of layers, where each instruction in your Dockerfile creates a new layer, and Docker reuses unchanged layers to skip expensive work.

Consider this simplified Dockerfile:

```dockerfile
FROM swift:6.0-noble AS builder
RUN apt-get update && apt-get install -y nodejs npm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN swift build -c release
```

During a build, Docker checks whether each step is identical to last time:

1. Same base image? → reuse
2. Same `apt-get` commands? → reuse
3. Same `package.json` and `pnpm-lock.yaml`? → reuse
4. Same `pnpm install` command? → reuse
5. Source files changed? → rebuild that layer and everything past it

Critical rule: if anything about a step changes, the cache for that step and all later steps becomes invalid. This includes build arguments, even if your Dockerfile doesn't reference them.

That's important, and it's exactly where things broke.

## The culprit: a Coolify bug that breaks layer caching

My Dockerfile and dependency files were not changing, so layer caching _should_ have been working perfectly. The reason it was failing was hidden deep in the build command itself. [Coolify](https://coolify.io), my deployment platform, was injecting several build arguments automatically:

```bash
docker build \
  --build-arg SOURCE_COMMIT=92dce649815fe776... \
  --build-arg COOLIFY_CONTAINER_NAME=my-container-name... \
  --build-arg COOLIFY_BUILD_SECRETS_HASH=2ba5f84e4552c6bcf...
```

These values change on every build.

And because Docker treats build arguments as part of every layer's cache key, even unused ones, this causes a full cache invalidation.

Effect:

- The first layer becomes new.
- Therefore every following layer becomes new.
- Therefore nothing is cached, ever.

This has been reported in [Coolify issue #7040](https://github.com/coollabsio/coolify/issues/7040). The ticket confirms the problem:

> "Since v432 or so, docker compose builds are no longer utilizing build cache... `COOLIFY_CONTAINER_NAME` changes on every run. Therefore nothing will ever get cached."

Coolify had auto-updated, and my fast builds disappeared overnight.

## A partial solution: using cache mounts

If layer caching is broken, your next-best tool is BuildKit cache mounts.

Cache mounts provide persistent storage that commands can reuse between builds, even when their layers must be re-run. They don't skip commands, but they make the commands faster by avoiding repetitive downloads.

I modified my Dockerfile to use cache mounts for my package managers:

```dockerfile
# syntax=docker/dockerfile:1.4
FROM swift:6.0-noble AS builder

# Configure apt to keep its cache for BuildKit
RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Install system dependencies with cache mounts for apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get --no-install-recommends install -y \
    libgd-dev python3 git nodejs npm

# Install Node dependencies with a cache mount for pnpm
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm config set store-dir /pnpm/store && \
    pnpm install --frozen-lockfile

# Build Swift dependencies with a cache mount for Swift PM
RUN --mount=type=cache,id=swift-pm,target=/root/.cache/org.swift.swiftpm \
    swift package resolve && swift build -c release
```

With these changes, my build times improved from 4.5 minutes to about 3 minutes. The build log for the `apt-get` step confirmed the fix:

```
Need to get 0 B/44.5 MB of archives.
```

The downloads were at least being cached again: a partial victory. Cache mounts fixed the downloading problem, but they did not fix the underlying issue. The commands were still being run every time.

- **What cache mounts fixed**: The time spent downloading packages for apt, npm, and Swift. This saved over a minute.
- **What cache mounts cannot fix**: The time spent installing the apt packages (about 35 seconds) and compiling the Swift code (about 80 seconds).

Only a functioning layer cache can skip these steps entirely. Cache mounts make the repeated steps faster, but they cannot eliminate them.

## Conclusion

The root problem is clear: as long as Coolify injects changing build arguments, Docker's layer cache cannot function. Cache mounts soften the pain, but they can't skip installation or compilation. For that, we need the layer cache back.

If your Coolify builds are slow:

1.  **Implement cache mounts** for your package managers. This will at least prevent re-downloading dependencies on every build.
2.  **Upvote [issue #7040](https://github.com/coollabsio/coolify/issues/7040)** so this can be fixed upstream.

Until Coolify stops injecting ever-changing build arguments, fast Docker builds remain out of reach, but with cache mounts, at least they don't have to be painfully slow.

> **Update December 1, 2025**: I'm happy to report that Coolify has fixed the issue by no longer automatically injecting the changing arguments. Update to v4.0.0-beta.450 or later and enjoy fast builds again.
