---
tags: django, python, deployment, coolify
summary: How I moved my Django projects from a manual server setup to Coolify for easier, zero-downtime deployments.
---

# Hosting your Django sites with Coolify

I currently run four Django apps in production, with staging and production environments for each. For years, I've managed this on a single server with a stack that has served me well, but has grown increasingly complex:

- A [Hetzner](https://www.hetzner.com) VPS running Debian 12
- Nginx as a reverse proxy
- Gunicorn processes managed by systemd
- More systemd services for background task runners
- A custom deploy service that listens for GitHub webhooks to pull and restart the right app
- A custom backup script that archives configs and databases and ships them offsite to [rsync.net](https://rsync.net).

I’ve written about this setup in detail, both in [“Setting up a Debian 11 server for SvelteKit and Django”](/articles/2023/setting-up-debian-11/) and more recently in [“Automatically deploy your site when you push the main branch”](/articles/2024/auto-deploying/).

While not rocket science, it’s a non-trivial setup. Each new app requires a checklist of configuration steps, and it's easy to miss one. Worse, my deploy script involves a brief moment of downtime as Gunicorn restarts. It’s only a second or two, but it’s not ideal. I’m more of a developer than an operations person, and building a zero-downtime, rolling deploy script myself feels like a step too far.

On the other end of the spectrum, I have a bunch of static sites hosted with Netlify. Its workflow is a dream: connect a GitHub repo, push changes, and Netlify automatically builds and deploys the site. It handles complex build steps for static site generators, even ones built with Swift like [Saga](https://github.com/loopwerk/Saga). But its magic is limited to static sites; you can't run a backend service like a Django app.

I've been looking for a solution that combines the best of both worlds: the simplicity of Netlify with the power to run my own backend services, all self-hosted, open-source, and on my own hardware.

Enter [Coolify](https://coolify.io/). It promises a Heroku-like experience you can run yourself. It can:

- Deploy static sites from a Git repository, with a build step.
- Run backend services like Node.js and Python via Dockerfiles.
- Manage databases like PostgreSQL and Redis.
- Handle backups, HTTPS certificates, and more.

This looked like exactly what I needed. Here’s how I moved my Django apps to it.

## Step 1: prepare a fresh server

Before installing Coolify, it’s wise to perform some basic server hardening. I spun up a new VPS on Hetzner and logged in as root to get it ready.

First, I disabled password-based SSH login in favor of public key authentication. In `/etc/ssh/sshd_config`, I made these changes:

```ini
PasswordAuthentication no
PubkeyAuthentication yes
```

I supplied my SSH public key to Hetzner during the server creation process, so it was already stored on the server for me. If you didn't do that, you'll need to copy your public key to the server yourself. The easiest way is with the `ssh-copy-id` command from your local machine:

```bash
$ ssh-copy-id root@YOUR_SERVER_IP
```

Next, I set up UFW (Uncomplicated Firewall) to control network traffic:

```
$ apt install ufw
$ ufw default deny incoming
$ ufw default allow outgoing
$ ufw allow ssh
$ ufw allow http
$ ufw allow https
$ ufw enable
```

To protect against brute-force attacks, I installed [Fail2ban](https://github.com/fail2ban/fail2ban).

```
$ apt install fail2ban python3-systemd
$ cd /etc/fail2ban
$ cp jail.conf jail.local
$ nano jail.local
```

I then enabled the SSH jail in `jail.local` and configured it to be quite strict, banning an IP after a single failed attempt. After all, we’re using SSH keys, not passwords.

#### <i class="fa-regular fa-file-code"></i> /etc/fail2ban/jail.local
```ini
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
maxretry = 1
```

You’ll also need to change the value of `banaction` to `ufw`. After saving, I enabled and started the service:

```
$ systemctl enable fail2ban
$ service fail2ban start
```

Finally, I enabled automatic security updates to keep the system patched without manual intervention.

```
$ apt install unattended-upgrades
$ dpkg-reconfigure --priority=low unattended-upgrades
```

With the server secured, it was time for the main event.

## Step 2: install Coolify

This is the easiest part. Coolify provides a simple installation script that handles everything.

```bash
$ curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
```

After a few minutes, Coolify is up and running, accessible via the server's IP address. I created a CNAME DNS entry for my server so that I can easily access it with a memorable domain.

## Step 3: containerize the Django app

Coolify works by building and running your applications in Docker containers. This is a departure from my old setup of running Gunicorn directly on the host. The central piece of this is the `Dockerfile`, a recipe for creating your application's image.

Here is a `Dockerfile` I've put together for a typical Django project. (It uses `uv`, because it’s awesome. I’ve written a [bunch of articles](/articles/tag/uv/) about it.)

#### <i class="fa-regular fa-file-code"></i> Dockerfile
```dockerfile
# Use a slim Debian image as our base
# (we don't use a Python image because Python will be installed with uv)
FROM debian:bookworm-slim

# Set the working directory inside the container
WORKDIR /app

# Arguments needed at build-time, to be provided by Coolify
ARG DEBUG
ARG SECRET_KEY
ARG DATABASE_URL

# Install system dependencies needed by our app
RUN apt-get update && apt-get install -y \
    build-essential \
    curl wget \
    && rm -rf /var/lib/apt/lists/*

# Install uv, the fast Python package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

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

# Expose the port Gunicorn will run on
EXPOSE 8000

# Run with gunicorn
CMD ["uv", "run", "--no-sync", "gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--access-logfile", "-", "--error-logfile", "-", "--log-level", "info", "config.wsgi:application"]
```

(For a non-Python example: the `Dockerfile` for this very website, which is built with Swift, can be found [on GitHub](https://github.com/loopwerk/loopwerk.io/blob/main/Dockerfile).)

This file defines every step needed to run the application. It installs dependencies, builds static assets, and runs database migrations. The final image is a self-contained, runnable artifact. When Coolify deploys this, it's simply a matter of stopping the old container and starting the new one, which is how it achieves zero-downtime deploys.

> Note: I run database migrations as part of the build process. Some some prefer to run migrations at container startup <sup>[citation needed]</sup>, but since we're rebuilding on every Git push anyway, it fits perfectly with this workflow. Feel free to tell me in the comments below if I am wrong.

Within the Coolify UI, I can now create a new application, point it to my GitHub repository, and tell it to use the "Dockerfile" build pack. Coolify automatically detects pushes to my main branch, pulls the code, builds the new image, and deploys it.

I no longer have an `.env` file on the server with the environment variables (like `DATABASE_URL`), instead I use Coolify's Environment Variables within the project settings. The way [I configure my Django projects](/articles/2024/django-settings/) hasn't changed, only the `.env` file part has been replaced with Coolify's UI. However, there is one small gotcha: by default these Coolify environment variables are only available at runtime, but because I use code like `os.getenv("DATABASE_URL")` in my settings.py, these variables also need to be available at build-time when Django commands like `collectstatic` run. This is why we explicitly expose these three variables as build arguments in the Dockerfile with the `ARG` declarations, making them available during the Docker build process.

As a final step when setting up the Django application you’ll want to add a health check. This can easily be done within your app configuration tab. This enables the rolling deployments where the new container is started while the old one is still running. Only when the health check is successful is the old container removed.

Oh, and make sure you include the following two lines in your `settings.py` file, or CSRF verification will fail and you won’t be able to log into the Django Admin:

```python
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
```

For some reason this wasn’t necessary when I ran my Django app behind Nginx, but now it is.

Don’t start the Django app just yet, as we still need to add a database.

> Note: static files and user-uploaded media files need to be handled a bit differently than you might be used to, if you’re coming from a bare-bones deployment strategy, like I was. This is addressed in a [separate article](/articles/2025/coolify-django-static-media/).

## Step 4: Set up the database

With our application containerized, the next piece of the puzzle is the database. Coolify can manage databases like PostgreSQL as first-class services, running them in their own secure containers right alongside your application.

Here’s how to get a PostgreSQL database up and running for your Django project:

1.  **Add a PostgreSQL service:** In your Coolify project, click to add a new resource, but this time select "PostgreSQL" from the list of services. Coolify pre-fills sensible defaults, which will create a `postgres` user with a secure, random password, and an initial `postgres` database. Before you do anything else, find the **“Postgres URL (internal)”** and copy it. You’ll need this in a moment.

2.  **Create a dedicated database:** While you could use the default `postgres` database, it's good practice to create a separate one for each application.
    *   Start the new PostgreSQL service.
    *   Navigate to its "Terminal" tab in the Coolify UI and click "Connect."
    *   This drops you into a shell inside the database container. Run `psql` to access the PostgreSQL prompt.
    *   Create your application's database with a standard SQL command:
        ```sql
        CREATE DATABASE my_app_db;
        ```
    *   You can verify it was created by listing all databases with `\l`. Once confirmed, exit `psql` and the container shell with `exit` or `Ctrl+D`.

3.  **Import existing data:** If you're moving an existing project, you'll need to import your data.
    *   First, create a backup of your old database. The `pg_dump` command with the `-Fc` flag (custom format) is perfect for this. Using `--no-owner` and `--no-privileges` makes the dump more portable.
        ```bash
        $ pg_dump -Fc --no-owner --no-privileges my_app_db > my_app_db.dump
        ```
    *   In Coolify, go to your PostgreSQL service's "Import Backup" tab. Upload the `.dump` file.
    *   **Important:** By default, Coolify's import command restores to the `postgres` database. You must modify the import command to target the database you just created. Use a command like this:
        ```bash
        pg_restore --clean -U $POSTGRES_USER -d my_app_db
        ```

4.  **Connect Django to the database:** Now, let's tell our Django application where to find its database.
    *   Go back to your Django application's settings in Coolify and open the "Environment Variables" tab.
    *   Create a new variable named `DATABASE_URL`.
    *   Paste the internal connection URL you copied in the first step, but **change the database name at the end** from `/postgres` to `/my_app_db`. The final URL should look like this: `postgres://postgres:random_password@container_name:5432/my_app_db`.
    *   Finally, and this is crucial, check the “Is Build Variable” box. This makes the `DATABASE_URL` variable available during the Docker build process (using the `ARG DATABASE_URL` instruction in the `Dockerfile`), and this allows commands like `manage.py migrate` to connect to the database during the image build.

With these steps complete, your Django application is now fully configured to communicate with its PostgreSQL database, all managed neatly within your Coolify project. You can now safely start the Django app.

## Step 5: configure backups

My old [custom backup script](/articles/2023/setting-up-debian-11/#2-2-backups) is no longer needed because Coolify has backups built-in. To enable off-site storage you need to configure a destination, which Coolify calls an "S3 Storage" target.

I'm using [Cloudflare R2](https://www.cloudflare.com/developer-platform/products/r2/) for this, as it offers a generous 10 GB of S3-compatible object storage for free. Here’s how to set it up:

1.  **In Cloudflare:** Navigate to **R2 Object Storage** from your dashboard. Create a new bucket, giving it a unique name (e.g., `coolify-backups-your-name`).
2.  Once the bucket is created, go to the R2 overview page and click **API** dropdown button. Choose **Manage API tokens**.
3.  Click **Create Account API token**. Give it a descriptive name, grant it "Object Read & Write" permissions, and specify the bucket you just created.
4.  After you create the token, Cloudflare will display the **Access Key ID** and **Secret Access Key**. Copy these immediately, as the Secret Key won't be shown again. You will also need your **Account ID** and the S3 endpoint URL.

With these credentials in hand, head back to Coolify:

1.  **In Coolify:** Go to the **Storages** tab in the main navigation.
2.  Click **Add a new S3 Storage**.
3.  Fill in the form with the credentials from Cloudflare. The `region` can be ignored, just leave it as-is.
4.  Save the new storage configuration.

With the S3 storage now configured, we can set up our backups.

- Go to Settings -> Backup, and make sure backups are turned on. Then enable the “S3 Enabled” checkmark. You can choose the local and remote retention; I keep 30 days of backups both locally and remotely.
- Go to your Django project, then to its database, then to the Backups tab. Here you can create a new scheduled backup, which will be stored locally. Enable the “Save to S3” checkmark to also store it remotely.

## Step 6: remaining Coolify config

To make sure you get important alerts, you’ll want to configure the email settings in Settings -> Transactional Email, using an SMTP server. Then go to the Notification menu and enable the “use system wide (transactional) email settings” checkbox. You can choose when to receive notifications, for example when a build fails, a backup fails, or when disk usage gets too high.

## The way forward

Moving to Coolify is a significant simplification of my infrastructure. It replaces my collection of custom scripts with a unified, robust system that provides the modern, git-based workflow I love from Netlify. The shift to containerization was long overdue, and Coolify makes it approachable.

Another major benefit is that all the configuration of how to run an app now lives directly in the project’s repository, in the form of a Dockerfile. It no longer only lives on the server in the form of a bunch of config files and systemd services and crontabs.

Best of all, I get zero-downtime deployments out of the box, all while still running everything on my own server. It's the self-hosted PaaS I've been looking for.