---
tags: coolify, howto
summary: If your Coolify deployments are sometimes fast and sometimes mysteriously slow, Docker's BuildKit garbage collection is probably silently deleting your build cache.
---

# BuildKit's garbage collection is deleting Coolify's build cache

I deploy my static site to a Coolify server using a multi-stage Dockerfile. When Docker's layer cache is warm, a deploy takes under a minute. Every once in a while though, the deploy takes over four minutes, when nothing about the Dockerfile or dependencies has changed. What's up with that? Why are the build layers no longer retrieved from the cache? I had already configured Coolify's "Docker Cleanup" settings to only run once a month instead of every night, so that can't be the reason.

Turns out that Docker's BuildKit has its own garbage collection that runs independently of any cleanup you configure in Coolify. And its default settings are quite aggressive, causing it to delete cache entries after the cache reaches a certain size.

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

This tells BuildKit to keep up to 10 GB of build cache. Adjust the value based on your available disk space (`df -h /var/lib/docker` to check).

After this change, your build cache should survive between deploys for much longer.