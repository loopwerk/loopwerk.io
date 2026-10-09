---
tags: django, coolify, howto
summary: How I moved my Django projects from a manual server setup to Coolify for easier, zero-downtime deployments.
---

# Hosting your Django sites with Coolify

I currently run four Django apps in production, with staging and production environments for each. For years, I've managed this on a single server with a stack that has served me well, but has grown increasingly complex with a bunch of systemd services and custom scripts for auto-deployments and backups.

I've written about this old setup in detail, both in ["Setting up a Debian 11 server for SvelteKit and Django"](/articles/2023/setting-up-debian-11/) and more recently in ["Automatically deploy your site when you push the main branch"](/articles/2024/auto-deploying/).

While not rocket science, it was also far from trivial. Each new app required a checklist of configuration steps, and it was way too easy to miss one. Worse, my deploy script involved a second or two of downtime as Gunicorn restarted.

I started looking for the simplicity of Heroku, but self-hosted and open-source, on my own server. I quickly found [Coolify](https://coolify.io/), which can:

- Deploy static sites from a Git repository, with a build step.
- Run backend services like Node.js and Python via Dockerfiles.
- Manage databases like PostgreSQL and Redis.
- Handle backups, HTTPS certificates, and more.

I moved all my Django sites, and here's how you can do the same.

## Step 1: prepare a fresh server

Before installing Coolify, it's a good idea to do some basic server hardening. Spin up a new VPS (for example on Hetzner) and log in as root to get it ready.

Personally, I always disable password-based SSH login in favor of public key authentication. In `/etc/ssh/sshd_config`, I made these changes:

```ini
PasswordAuthentication no
PubkeyAuthentication yes
```

I supplied my SSH public key to Hetzner during the server creation process, so it was already stored on the server for me. If you didn't do that, you'll need to copy your public key to the server yourself. The easiest way is with the `ssh-copy-id` command from your local machine:

```shell-session
$ ssh-copy-id root@YOUR_SERVER_IP
```

Next, set up UFW (Uncomplicated Firewall) to control network traffic:

```shell-session
$ apt install ufw
$ ufw default deny incoming
$ ufw default allow outgoing
$ ufw allow ssh
$ ufw allow http
$ ufw allow https
$ ufw enable
```

To protect against brute-force attacks, install [Fail2ban](https://github.com/fail2ban/fail2ban).

```shell-session
$ apt install fail2ban python3-systemd
$ cd /etc/fail2ban
$ cp jail.conf jail.local
$ nano jail.local
```

Then enable the SSH jail in `jail.local` and configure it to be quite strict, banning an IP after a single failed attempt. After all, we're using SSH keys, not passwords.

```ini title="/etc/fail2ban/jail.local"
[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = systemd
maxretry = 1
```

You'll also need to change the value of `banaction` to `ufw`. After saving, enable and start the service:

```shell-session
$ systemctl enable fail2ban
$ service fail2ban start
```

Finally, enable automatic security updates to keep the system patched without manual intervention.

```shell-session
$ apt install unattended-upgrades
$ dpkg-reconfigure --priority=low unattended-upgrades
```

## Step 2: install Coolify

This is the easiest part. Coolify provides a simple installation script that handles everything.

```shell-session
$ curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
```

After a few minutes, Coolify will be up and running, accessible via the server's IP address. You should probably create a CNAME DNS entry for the server so that you can easily access it with a memorable domain.

## Step 3: containerize the Django app

Coolify works by building and running your applications in Docker containers. The central piece of this is the `Dockerfile`, a recipe for creating your application's image. Here's one I've put together for a typical Django project, using uv:

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

# Expose the port Gunicorn will run on
EXPOSE 8000

# Run with gunicorn
CMD ["uv", "run", "--no-sync", "gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--access-logfile", "-", "--error-logfile", "-", "--log-level", "info", "config.wsgi:application"]
```

> [!SIDENOTE]
> I run database migrations as part of the build process. Some people prefer to run migrations at container startup <sup>[citation needed]</sup>, but since we're rebuilding on every Git push anyway, it fits perfectly with this workflow. Feel free to tell me if I am wrong.

Within the Coolify UI, you can now create a new application, point it to your GitHub repo, and tell it to use the "Dockerfile" build pack. Coolify automatically detects pushes to the main branch, pulls the code, builds the new image, and deploys it.

In my old setup I used to have an `.env` file on the server, but this had to be migrated to Coolify's Environment Variables within the project settings. By default these variables are only available at runtime, but because I use code like `os.getenv("DATABASE_URL")` in my settings.py, these variables also need to be available at build-time when Django commands like `collectstatic` run. This is why I explicitly expose these variables as build arguments in the Dockerfile with the `ARG` declaration.

As a final step when setting up the Django application you'll want to add a health check. Go to the Healthchecks tab in the sidebar, and configure a new one. In my case it's just a GET request to `/`. Adding a health check is required to enable the rolling deployments, because Coolify needs to know when the new container is ready before shutting off the old one.

Oh, and make sure you include the following two lines in your `settings.py` file, or CSRF verification will fail and you won't be able to log into the Django Admin:

```python
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
```

Don't start the Django app just yet; you still need to add a database.

> [!SIDENOTE]
> Static files and user-uploaded media files need to be handled a bit differently than you might be used to, if you're coming from a bare-bones deployment strategy, like I was. This is addressed in a [separate article](/articles/2025/coolify-django-static-media/).

## Step 4: set up the database

Your application is containerized, but you probably still need a database. Here's how to get a PostgreSQL database up and running:

1.  **Add a PostgreSQL service:** In your Coolify project, click to add a new resource, but this time select "PostgreSQL" from the list of services. Coolify pre-fills sensible defaults; you don't really need to change anything. Before you do anything else, find the **"Postgres URL (internal)"** and copy it. You'll need this in a moment.

2.  **Create a dedicated database:** While you could use the default `postgres` database, it's good practice to create a separate one for each application.
    - Start the new PostgreSQL service.
    - Navigate to its "Terminal" tab in the Coolify UI and click "Connect."
    - This drops you into a shell inside the database container. Run `psql` to access the PostgreSQL prompt.
    - Create your application's database with a standard SQL command:
      ```sql
      CREATE DATABASE my_app_db;
      ```
    - You can verify it was created by listing all databases with `\l`. Once confirmed, press `Ctrl+D` to exit the shell.

3.  **Import existing data:** If you're moving an existing project, you'll need to import your data.
    - First, create a backup of your old database using the `pg_dump` command with the `-Fc` flag (custom format). Using `--no-owner` and `--no-privileges` makes the dump more portable.
      ```shell-session
      $ pg_dump -Fc --no-owner --no-privileges my_app_db > my_app_db.dump
      ```
    - In Coolify, go to your PostgreSQL service's "Import Backup" tab. Upload the `.dump` file.
    - **Important:** By default, Coolify's import command restores to the `postgres` database. You must modify the import command to target the database you just created. Use a command like this:
      ```shell-session
      $ pg_restore --clean --no-owner --no-privileges -U $POSTGRES_USER -d my_app_db
      ```

4.  **Connect Django to the database:** Now, tell your Django application where to find its database.
    - Go back to your Django application's settings in Coolify and open the "Environment Variables" tab.
    - Create a new variable named `DATABASE_URL`.
    - Paste the internal connection URL you copied in the first step, but **change the database name at the end** from `/postgres` to `/my_app_db`. The final URL should look like this: `postgres://postgres:random_password@container_name:5432/my_app_db`.

Django can now reach its PostgreSQL database, so you can safely start the app.

## Step 5: configure backups

Of course Coolify has backups built-in, no custom janky scripts necessary. To enable off-site storage you need to configure a destination, which Coolify calls an "S3 Storage" target. I'm using [Cloudflare R2](https://www.cloudflare.com/developer-platform/products/r2/) for this, as it offers 10 GB of S3-compatible object storage for free. Here's how to set it up:

1.  **In Cloudflare:** Navigate to **R2 Object Storage** from your dashboard. Create a new bucket, giving it a unique name (e.g., `coolify-backups-your-name`).
2.  Once the bucket is created, go to the R2 overview page and click the **API** dropdown button. Choose **Manage API tokens**.
3.  Click **Create Account API token**. Give it a descriptive name, grant it "Object Read & Write" permissions, and specify the bucket you just created.
4.  After you create the token, Cloudflare will display the **Access Key ID** and **Secret Access Key**. Copy these immediately, as the Secret Key won't be shown again. You will also need your **Account ID** and the S3 endpoint URL.

Head back to Coolify.

1.  Go to the **Storages** tab in the main navigation.
2.  Click **Add a new S3 Storage**.
3.  Fill in the form with the credentials from Cloudflare. The `region` can be ignored; just leave it as-is.
4.  Save the new storage configuration.

With the S3 storage now configured, you can set up the backups.

- Go to Settings -> Backup, and make sure backups are turned on. Then enable the "S3 Enabled" checkmark. You can choose the local and remote retention; I keep 30 days of backups both locally and remotely.
- Go to your Django project, then to its database, then to the Backups tab. Here you can create a new scheduled backup, which will be stored locally. Enable the "Save to S3" checkmark to also store it remotely.

## Step 6: turn on notifications

To make sure you get important alerts, you'll want to configure the email settings in Settings -> Transactional Email, using an SMTP server. Then go to the Notification menu and enable the "use system wide (transactional) email settings" checkbox. You can choose when to receive notifications, for example when a build fails, a backup fails, or when disk usage gets too high.

## The way forward

For me the biggest benefit is that all the configuration of how to run an app now lives directly in the project's repository, in the form of a Dockerfile. It no longer only lives on the server in the form of a bunch of config files and systemd services and crontabs. It's now discoverable and repeatable.

I'm extremely happy with my move to Coolify, and I hope you will be too, and that this article has helped you make the switch.