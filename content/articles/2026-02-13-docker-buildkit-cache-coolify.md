---
tags: coolify, deployment, howto
summary: If your Coolify deployments are sometimes fast and sometimes mysteriously slow, Docker's BuildKit garbage collection is probably silently deleting your build cache.
---

# Prevent your Coolify deploys from randomly starting without a build cache

I deploy my static site to a Coolify server using a multi-stage Dockerfile. The build uses a `swift:6.0-noble` base image (~800 MB), installs system dependencies, compiles Swift packages, builds the site, and copies the output into an nginx container. When Docker's layer cache is warm, a deploy takes under a minute. The only layers that need to rebuild are the ones that depend on my content files.

Every once in a while though, the deploy takes over four minutes, when nothing about the Dockerfile or dependencies has changed. What's up with that?

## What happened

The same thing happened again yesterday, and this time I dove into the logs to figure this out. 

A normal deploy looks like this:

```
#5  [builder 1/15] FROM swift:6.0-noble@sha256:f91568f7...
#5  DONE 0.0s

#15 [builder 2/15] RUN apt-get update && apt-get install ...
#15 CACHED

#17 [builder 11/15] RUN swift package resolve && swift build ...
#17 CACHED
```

Every heavy layer is cached. Only the content-dependent steps at the end actually run.

The slow deploy looked completely different:

```
#6  [builder 1/15] FROM swift:6.0-noble@sha256:f91568f7...
#6  sha256:744559f7... 0B / 799.09MB 0.2s
...
#6  sha256:744559f7... 799.09MB / 799.09MB 19.7s done
#6  extracting sha256:744559f7... 32.6s done
#6  DONE 52.4s
```

The base image was being re-downloaded and extracted from scratch. Every subsequent layer had to rebuild too: apt-get, npm install, Swift compilation, all of it.

## The cause: BuildKit's default garbage collection

I had already configured Coolify's "Docker Cleanup" settings to only run once a month instead of every night. So why was the cache gone, and everything had to be downloaded and built from scratch again?

The answer is that Docker's BuildKit has its own garbage collection that runs independently of any cleanup you configure in Coolify. Without explicit configuration, the defaults are aggressive: unused cache entries are evicted after roughly 48 hours.

So unless you deploy your site every day or so, you will run into this issue as well. You can verify this on your server. If you run `docker builder du` and see very little cache (only from your most recent build), your older cache has been garbage collected.

It was pretty confusing and unexpected to me that Coolify's own "Docker Cleanup" settings aren't the only thing managing Docker's disk usage. Instead BuildKit's GC operates separately and silently.

## The fix

Luckily the fix is pretty simple. Add a `builder` section to your Docker daemon config at `/etc/docker/daemon.json`:

```json
{
  [...]
  "builder": {
    "gc": {
      "enabled": true,
      "defaultKeepStorage": "10GB"
    }
  }
}
```

Then restart Docker:

```bash
systemctl restart docker
```

This tells BuildKit to keep up to 10 GB of build cache before evicting anything. Adjust the value based on your available disk space (`df -h /var/lib/docker` to check).

After this change, your build cache should survive between deploys, even if you only deploy once a week.
