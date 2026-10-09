---
tags: django, coolify, howto
summary: Let's solve the challenge of serving media files for your Coolified Django site.
---

# Handling static and media files in your Django app running on Coolify

I recently wrote a detailed how-to of [how to host Django sites with Coolify](/articles/2025/coolify-django/). It covered everything from the Dockerfile and database setup to environment variables and backups. I did leave out one tricky topic though: handling static and media files, as this deserved its own article. Welcome to that article.

If your application only serves static files, the solution is thankfully really simple. Just use [WhiteNoise](https://whitenoise.readthedocs.io/en/latest/) and you're done.

This article is really for people who are also dealing with user-uploaded media. In that case you're faced with two challenges.

The first challenge is that media files uploaded by users will be saved inside the Docker container. And because Coolify creates a fresh container every time you deploy, all user-uploaded files will be gone on every deploy.

One common solution is to store these files on some cloud storage service, like Amazon S3 or Cloudflare R2. The excellent [django-storages](https://django-storages.readthedocs.io/en/latest/) package makes this integration fairly straightforward. You could configure it to handle only your media files, meaning you'd use WhiteNoise to serve your static files. Or you could delegate both static and media files to `django-storages`, whatever you want.

It's a good and simple solution, but I prefer to keep all my project's files on my own server. I didn't want to depend on (and pay for) a storage provider like S3 or R2. This meant I had to find a way to store the media files outside the container.

The second challenge is actually serving the media files, as that's something WhiteNoise refuses to do.

If you're following along with this article, let's assume these settings:

```python title="settings.py"
STATIC_ROOT = BASE_DIR / "static_root"
STATIC_URL = "/static/"
MEDIA_ROOT = BASE_DIR / "media_root"
MEDIA_URL = "/media/"
```

## Coolify Persistent Storage

Thankfully, Coolify has a built-in Persistent Storage feature which solves the storage problem. It allows you to map a directory on your host server to a directory inside your container.

In your Django application's resource view in Coolify, navigate to the Persistent Storage section in the sidebar and click the "Add" button. You'll need to create a new Volume Mount with the following settings:

- Name: a descriptive name, like `media`.
- Source Path: an absolute path to a folder on the host server, for example `/root/my-app-media`.
- Destination Path: the path inside the container where your media files are stored. This should match the `MEDIA_ROOT` from `settings.py`, which in our case is `/app/media_root`.

![](/articles/images/coolify_persistent_storage.png)

With this volume mount in place, the uploaded media files will no longer be nuked on every deploy.

## Serving files with Caddy

While the files are now stored in a safe place, they aren't being served yet. The solution is to add the lightweight web server Caddy to the container that will serve the static and media files, and proxy all other requests to your Django application. We'll also add Supervisor to manage both the Caddy and Gunicorn processes. 

Let's start by updating your `Dockerfile`. We need to install Caddy and Supervisor, copy their configuration files, and run `supervisord` as the main command.

```dockerfile title="Dockerfile"
# Use a slim Debian Trixie image as our base
# (we don't use a Python image because Python will be installed with uv)
FROM ghcr.io/astral-sh/uv:trixie-slim

# Set the working directory inside the container
WORKDIR /app

# Arguments needed at build-time, to be provided by Coolify
ARG DEBUG
ARG SECRET_KEY
ARG DATABASE_URL

# Install system dependencies needed by our app
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    <mark>supervisor \</mark>
    <mark>caddy \</mark>
    && rm -rf /var/lib/apt/lists/*

# Copy only the dependency definitions first to leverage Docker's layer caching
COPY pyproject.toml uv.lock .python-version ./

# Install Python dependencies for production
RUN uv sync --no-group dev --group prod

# Copy the rest of the application code into the container
COPY . .

# Collect the static files
RUN uv run --no-sync ./manage.py collectstatic --noinput

# Migrate the database
RUN uv run --no-sync ./manage.py migrate

<mark>EXPOSE 80</mark>

# Copy configs
<mark>COPY .config/Caddyfile /etc/caddy/Caddyfile</mark>
<mark>COPY .config/supervisord.conf /etc/supervisord.conf</mark>

# Run with supervisord
<mark>CMD ["supervisord", "-c", "/etc/supervisord.conf"]</mark>
```

You'll need to update the "Ports Exposes" setting in the General Configuration tab (under "Network") from `8000` to `80`.

Next up, Caddy's config file:

```apacheconf title=".config/Caddyfile"
:80

handle_path /static/* {
    root * /app/static_root
    file_server {
        precompressed gzip br
    }
    header Cache-Control "public, max-age=31536000, immutable"
}

handle_path /media/* {
    root * /app/media_root
    file_server
    header Cache-Control "public, max-age=86400"
}

handle {
    reverse_proxy 127.0.0.1:8000 {
        header_up Host {host}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-For {remote_host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Host {host}
    }
}
```

This tells Caddy to serve any requests for `/static/*` and `/media/*` from their respective directories on the filesystem. All other requests are proxied to your Django application, which Gunicorn is running on `127.0.0.1:8000`.

And finally, the Supervisor config file, which starts all the services:

```ini title=".config/supervisord.conf"
[supervisord]
nodaemon=true
logfile=/dev/null
logfile_maxbytes=0
logfile_backups=0
loglevel=info

[program:gunicorn]
command=uv run --no-sync gunicorn --bind 127.0.0.1:8000 --workers 3 --access-logfile - --error-logfile - --log-level info config.wsgi:application
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=true
startretries=3

[program:caddy]
command=caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=true
startretries=3
```

An added benefit of Supervisor is that it's super easy to add a long-running process into the mix, for example for [django-tasks](https://github.com/RealOrangeOne/django-tasks):

```ini title=".config/supervisord.conf"
# ...

[program:django-tasks]
command=uv run --no-sync ./manage.py db_worker
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autorestart=true
startretries=3
priority=30
```

And that's it! Both challenges solved.

> [!SIDENOTE]
> You might wonder why we don't use Docker Compose to run Django, Caddy, and the `db_worker` process all in their own containers. We'd get separate logs which would be very nice, containers can be restarted individually, and one crashing container won't bring down the others. Those are all really great benefits, but we'd lose rolling updates, so your app would be down for a short time every time you deploy changes.