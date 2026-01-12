---
tags: deployment, python, django, sveltekit, howto
summary: I recently had to set up a brand new server for a website running on SvelteKit and its API running on Django. I am a software developer and setting up servers and hosting isn't something I normally do, so I followed a bunch of different tutorials. In this article I want to combine all these tutorials, mostly for future me, but hopefully you'll find it useful as well.
---

# Setting up a Debian 11 server for SvelteKit and Django

I recently had to set up a brand new server for a website running on SvelteKit and its API running on Django. I used a virtual server from [Hetzner](https://www.hetzner.com/cloud) running Debian 11. A CCX22 instance to be exact: 4 dedicated vCPUs, 16 GB of RAM and 160 GB of disk space, with 20 TB of traffic included, all for €45 per month - although you can also get a server for as little as €3.79 per month! And if you use my [referral link](https://hetzner.cloud/?ref=WZ6oJ9LrNtzM) when signing up for a cloud server, you'll get €20 in credits.

> [!SIDENOTE]
> I've moved on from manually setting up a server as described in this article, to Coolify. Please check my article [Hosting your Django sites with Coolify](/articles/2025/coolify-django/).

I am a software developer and setting up servers and hosting isn't something I normally do, so I followed a bunch of different tutorials. In this article I want to combine all this information, mostly for future me, but hopefully you'll find it useful as well. Most of the info came from the following tutorials, so check them out if you want more in-depth explanations of the commands:

- https://www.digitalocean.com/community/tutorials/initial-server-setup-with-debian-11
- https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-debian-11
- https://linuxize.com/post/how-to-set-up-ssh-keys-on-debian-10
- https://computingforgeeks.com/how-to-install-node-js-on-ubuntu-debian/
- https://www.howtogeek.com/675010/how-to-secure-your-linux-computer-with-fail2ban/
- https://linuxiac.com/how-to-set-up-automatic-updates-on-debian/

In this article many commands have placeholders like `<var>$SERVER_IP_ADDRESS</var>` which you need to replace with the actual value.

- `<var>$SERVER_IP_ADDRESS</var>`: the IP address of your server. You got this from Hetzner.
- `<var>$PROJECT_USER</var>`: the user that will be running your project. This can be your name, or for a server that is used for one project, the name of your project. Examples: `kevin` or `criticalnotes` or `loopwerk`.
- `<var>$BACKEND_DOMAIN</var>`: domain that's used for your backend, like `api.example.com` (without `http://` or `https://`)
- `<var>$FRONTEND_DOMAIN</var>`: domain that's used for your frontend, like `www.example.com` (again without `http://` or `https://`)
- `<var>$NAKED_DOMAIN</var>`: the "naked" domain that's used for your frontend, without the `www` like `example.com` (you guessed it, without `http://` or `https://`)

# Table of contents

%TOC%

# Chapter 1 - Setting up the basics

## 1.1 - Setting up the accounts

First we're going to login as root, create a new user, and then allow the new user to run commands as root with `sudo`.

```shell-session
$ ssh root@<var>$SERVER_IP_ADDRESS</var>
# adduser <var>$PROJECT_USER</var>
# usermod -aG sudo <var>$PROJECT_USER</var>
```

Open a new terminal (keep the one where you're logged in as root open), and test if you can indeed login as the new user, and run commands as sudo:

```shell-session
$ ssh <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
$ sudo echo "I am root!"
```

You're asked to enter your password (not the root password!), and then you should see "I am root!". With all that done, you can close the second terminal and go back to the session where you are logged in as root.

## 1.2 - Firewall

While you can create a firewall within Hetzner's web UI and select it when creating a new server, I prefer to simply run it on the server itself. The Uncomplicated Firewall, or UFW for short, is indeed not complicated at all, but with all the power of iptables under the hood.

While still logged in as root, enter the following commands:

```shell-session
# apt update
# apt install ufw
# ufw allow OpenSSH
# ufw enable
# ufw status
```

The output should be like this:

```text
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
```

Done!

## 1.3 - Logging in with SSH keys

When setting up the server with Hetzner you had the opportunity to select an SSH key for logging in. If you didn't do that than you received the root password in your email, and you used that in step 1.1 to login to the server.

Instead of having to type in a password when we log into the server, it is much nicer and safer to instead login using private keys, so let's set that up now.

If you don't have SSH keys on your own computer yet, create them with the following command **on your own computer, not on the server**:

```shell-session
$ ssh-keygen -t ed25519 -C "your_email@domain.com"
```

You don't have to enter a passphrase when creating a key, just press enter for no passphrase - although adding a passphrase is of course more secure.

Now we're going to copy the public key to your server with the following command:

```shell-session
$ ssh-copy-id <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
```

Now, try logging into the server again. Open a new terminal and enter the following. This time you should not be asked for your password:

```shell-session
$ ssh <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
```

If that worked, you can close the second terminal and go back to the one where you're logged in as root.

## 1.4 - Securing the SSH server

At the moment you can still SSH into your server using a password, and you can connect as the root user. Let's disable both these things so that the root user can never connect via SSH, and the normal user can only connect using SSH keys.

**Before making the following changes, make absolutely sure you can login to your server without a password, and that the user has sudo privileges. See steps 1.1 and 1.3.**

As root, enter the command

```shell-session
# pico /etc/ssh/sshd_config
```

Search for the following variables and change them as such:

```ini
PermitRootLogin no
PasswordAuthentication no
```

Uncomment these lines if they were previously commented out. Save the file and restart the SSH server:

```shell-session
# service ssh restart
```

Open a new terminal and test logging in as root:

```shell-session
$ ssh root@<var>$SERVER_IP_ADDRESS</var>
```

This should fail with the message `Permission denied (publickey)`. Now make sure logging in as the normal user still works:

```shell-session
$ ssh <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
```

You can now close the other SSH sessions, including the one where you are still logged in as root.

**From now all everything will be done as the normal user, using `sudo` where necessary**.

## 1.5 - Further securing your server with fail2ban

Inevitably, hackers will try to log into your server, trying a bunch of common passwords. Let's automatically block anyone who fails to connect using fail2ban.

```shell-session
$ sudo apt install fail2ban
$ cd /etc/fail2ban
$ sudo cp jail.conf jail.local
$ sudo pico jail.local
```

You'll want to add or change the following variables in the `[DEFAULT]` section:

```ini
bantime = 2h
maxretry = 3
banaction = ufw
```

And in the `‌[sshd]` section you'll want to add these variables:

```ini
enabled = true
maxretry = 1
```

Now enable end start fail2ban:

```shell-session
$ sudo systemctl enable fail2ban
$ sudo service fail2ban start
```

You can see its status with the following command:

```shell-session
$ fail2ban-client status sshd
```

## 1.6 - Automatic security updates

It would be great if important security updates automatically get installed on the server, and that's exactly what the `unattended-upgrades` package is for. Let's install it:

```shell-session
$ sudo apt install unattended-upgrades
$ sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Check if the service is started:

```shell-session
$ sudo service unattended-upgrades status
```

# Chapter 2 - PostgreSQL

## 2.1 - Setup

Install PostgreSQL:

```shell-session
$ sudo apt install postgresql
```

And then log into an interactive PostgreSQL session:

```shell-session
$ sudo -u postgres psql
```

Run the following commands to create a new database user, set some parameters on the user as [recommended by Django](https://docs.djangoproject.com/en/4.2/ref/databases/#optimizing-postgresql-s-configuration), and then finally we create a new database for the new user:

```sql
postgres=# CREATE USER <var>$PROJECT_USER</var> WITH PASSWORD 'password';
postgres=# ALTER ROLE <var>$PROJECT_USER</var> SET client_encoding TO 'utf8';
postgres=# ALTER ROLE <var>$PROJECT_USER</var> SET default_transaction_isolation TO 'read committed';
postgres=# ALTER ROLE <var>$PROJECT_USER</var> SET timezone TO 'UTC';
postgres=# CREATE DATABASE my_database_name OWNER <var>$PROJECT_USER</var>;
```

Press command+d to exit the PostgreSQL session.

## 2.2 - Backups

Let's make sure we make daily backups of our database.

```shell-session
$ mkdir ~/backups
$ pico ~/backup.sh
```

Enter the following contents:

```bash
#!/usr/bin/bash

set -x

# Location to place backups
backup_dir="/home/<var>$PROJECT_USER</var>/backups/"

# String to append to the name of the backup files
backup_date=`date +%Y-%m-%d`

# Number of days you want to keep copy of your databases
number_of_days=30

databases=`psql -X -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d'`

for i in $databases; do
  if [ "$i" != "template0" ] && [ "$i" != "template1" ]; then
    echo Dumping $i to $backup_dir$i\_$backup_date
    pg_dump -Ox $i | gzip > $backup_dir$i\_$backup_date.sql.gz
  fi
done

# Remove old backups
find $backup_dir -type f -prune -mtime +$number_of_days -exec rm -f {} \;
```

Now we need to make sure the script is automatically run, using the cron.

```shell-session
$ chmod +x ~/backup.sh
$ crontab -e
```

Enter the following contents:

```text
# m h dom mon dow command
0 6 * * * /home/<var>$PROJECT_USER</var>/backup.sh
```

This will run the script every day at 6:00.

## 2.3 - Store the backups off-site

The backups are now stored on the same server as the PostgreSQL database itself. It's much better than not having backups at all, but even better would be to store them off-site. I use [rsync.net](https://www.rsync.net) for this purpose. It's like a cloud server that you can run commands on via SSH, and you can send folders with files to it via rsync, sftp and scp. It's really great. After you signed up, just add this to the end of the backup script:

```bash
# Immediately store off-site
rsync -avH ~/backups <var>your_rsync_username</var>@<var>your_rsync_instance</var>.rsync.net:
```

But to enable this to run without having to enter a password, let's enable SSH key authentication.

On your server, logged in as `<var>$PROJECT_USER</var>`, create a new SSH key:

```shell-session
$ ssh-keygen -t rsa -b 4096
```

Accept the defaults and do **NOT** enter a passphrase. Then upload it to the rsync.net server:

```shell-session
$ scp ~/.ssh/id_rsa.pub <var>your_rsync_username</var>@<var>your_rsync_instance</var>.rsync.net:.ssh/authorized_keys
```

Test that your key works by ssh'ing to your rsync.net filesystem:

```shell-session
$ ssh <var>your_rsync_username</var>@<var>your_rsync_instance</var>.rsync.net ls
```

You should not be asked for a password.

# Chapter 3 - the Django backend

Debian doesn't come with the latest and greatest version of Python pre-installed, but that doesn't matter since we should be using [uv](https://docs.astral.sh/uv/) as our dependency- and virtual-environment manager of choice. You can then specify the specific Python version to use inside of each Python project, and uv will install it automatically.

## 3.1 - uv

Install uv:

```shell-session
$ curl -LsSf https://astral.sh/uv/install.sh | sh
```

For the actual usage of uv in your project I'll refer to the official docs on https://docs.astral.sh/uv/. I use uv with two [dependency groups](https://docs.astral.sh/uv/concepts/dependencies/#dependency-groups): `dev` and `prod`, which I make optional with the following two lines added to `pyproject.toml`:

```toml
[tool.uv]
default-groups = []
```

## 3.3 - Checking out the backend project

First we're going to clone the git project, and open the directory:

```shell-session
$ cd ~
$ git clone your_backend_git_repo_address <var>$BACKEND_DOMAIN</var>
$ cd <var>$BACKEND_DOMAIN</var>
```

Then we'll instruct uv install the dependencies, including the ones from the `prod` group:

```shell-session
$ uv sync --group prod
```

This will also install the Python version as specific in your project's `.python-version` file.

Make sure the Django project's settings are using your server's PostgreSQL database (for example using an `.env` file - I use [django-environ](https://django-environ.readthedocs.io/en/latest/) for that) and let's run the Django migrations:

```shell-session
$ uv run ./manage.py migrate
```

## 3.4 - systemd config

We now need to make sure that the Django server is automatically started when the server is started. For this we'll use systemd.

Create a new service config:

```shell-session
$ sudo pico /etc/systemd/system/<var>$BACKEND_DOMAIN</var>.service
```

With the following contents:

```ini
[Unit]
Description=<var>$BACKEND_DOMAIN</var>

[Service]
User=<var>$PROJECT_USER</var>
Group=<var>$PROJECT_USER</var>
Restart=on-failure
WorkingDirectory=/home/<var>$PROJECT_USER</var>/<var>$BACKEND_DOMAIN</var>
ExecStart=/home/<var>$PROJECT_USER</var>/.local/bin/uv run gunicorn \
          --access-logfile - \
          --workers 2 \
          --bind=127.0.0.1:8000 --bind=[::1]:8000 \
          <var>your_project_name</var>.wsgi:application

[Install]
WantedBy=multi-user.target
```

To make sure the service automatically starts when the server starts, run the following command:

```shell-session
$ systemctl enable <var>$BACKEND_DOMAIN</var>
```

And finally, start the server using:

```shell-session
$ service <var>$BACKEND_DOMAIN</var> start
```

Check if it is indeed running:

```shell-session
$ service <var>$BACKEND_DOMAIN</var> status
```

## 3.5 - Nginx

While the Django server is now running, is isn't actually accessible yet. For that we'll install Nginx, and use it to proxy request to the gunicorn proces.

Install Nginx and then create a site config file:

```shell-session
$ sudo apt install nginx
$ sudo pico /etc/nginx/sites-available/<var>$BACKEND_DOMAIN</var>
```

With the following contents:

```nginx
server {
    server_name <var>$BACKEND_DOMAIN</var>;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location /static/ {
        alias /home/<var>$PROJECT_USER</var>/<var>$BACKEND_DOMAIN</var>/static_root/;
    }

    location /media/ {
        alias /home/<var>$PROJECT_USER</var>/<var>$BACKEND_DOMAIN</var>/media_root/;
    }

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_redirect off;
        proxy_buffering off;
        proxy_pass http://localhost:8000;
    }

    listen 80;
    listen [::]:80
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
```

Then to enable the site:

```shell-session
$ cd /etc/nginx/sites-enabled/
$ sudo ln -s ../sites-available/<var>$BACKEND_DOMAIN</var>
```

Run `sudo nginx -t` to check if the config has no errors, and then reload Nginx with `service nginx reload`.

Finally, we need to configure the firewall to open up the ports for the Nginx:

```shell-session
$ sudo ufw allow "Nginx Full"
```

Your backend should now be reachable on `http://<var>$BACKEND_DOMAIN</var>/` if you already changed the domain's DNS settings, otherwise it's reachable via `http://<var>$SERVER_IP_ADDRESS/</var>`.

Let's make it run on HTTPS though. For this the DNS settings of the domain should be in order, so an `A` record pointing your (sub)domain to the server's IP address should be in place.

Install Certbot using Snap:

```shell-session
$ sudo apt install snapd
$ sudo snap install core
$ sudo snap install --classic certbot
$ sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

With all that done, simply run Certbot:

```shell-session
$ sudo certbot
```

Answer the questions and select your domain for which you want to active HTTPS. Certbot then does the rest and you should be able to visit `https://<var>$BACKEND_DOMAIN</var>/`. Hooray!

## 3.6 - Deploying changes

I use a really simple deploy script in my backend project:

```bash
git pull
uv sync --group prod
uv run ./manage.py migrate
sudo /usr/sbin/service <var>$BACKEND_DOMAIN</var> restart
```

So whenever I want to deploy changes I simply run these three commands:

```shell-session
$ ssh <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
$ cd <var>$BACKEND_DOMAIN</var>
$ ./deploy.sh
```

This will ask for your password because of the `sudo` command to restart the service. This gets kind of annoying, so to solve that, create the following file:

```shell-session
$ sudo pico /etc/sudoers.d/user_restart
```

With the following contents:

```text
<var>$PROJECT_USER</var> ALL=NOPASSWD: /usr/sbin/service <var>$BACKEND_DOMAIN</var> restart
<var>$PROJECT_USER</var> ALL=NOPASSWD: /usr/sbin/service <var>$FRONTEND_DOMAIN</var> restart
```

This will allow the user to restart the backend and the future frontend services without having to type a password.

# Chapter 4 - The SvelteKit frontend

## 4.1 - Installing Node.js

```shell-session
$ curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
$ sudo apt install nodejs
```

## 4.2 - Checking out the code and creating a build

```shell-session
$ cd ~
$ git clone your_frontend_git_repo_address <var>$FRONTEND_DOMAIN</var>
$ cd <var>$FRONTEND_DOMAIN</var>
$ npm install
$ npm run build
$ mv build deploy
```

## 4.3 - systemd

Create a new service config:

```shell-session
$ sudo pico /etc/systemd/system/<var>$FRONTEND_DOMAIN</var>.service
```

With the following contents:

```ini
[Unit]
Description=<var>$FRONTEND_DOMAIN</var>

[Service]
User=<var>$PROJECT_USER</var>
Group=<var>$PROJECT_USER</var>
WorkingDirectory=/home/<var>$PROJECT_USER</var>/<var>$FRONTEND_DOMAIN</var>
Environment="HOST=127.0.0.1"
Environment="PORT=3000"
ExecStart=node deploy/index.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

To make sure the service automatically starts when the server starts, run the following command:

```shell-session
$ systemctl enable <var>$FRONTEND_DOMAIN</var>
```

And finally, start the server using:

```shell-session
$ service <var>$FRONTEND_DOMAIN</var> start
```

Check if it is indeed running:

```shell-session
$ service <var>$FRONTEND_DOMAIN</var> status
```

## 4.4 - Nginx

Create a site config file:

```shell-session
$ sudo pico /etc/nginx/sites-available/<var>$FRONTEND_DOMAIN</var>
```

With the following contents:

```nginx
server {
    server_name <var>$FRONTEND_DOMAIN</var>;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffer_size 16k;
        proxy_buffers 4 16k;
        proxy_busy_buffers_size 16k;
        client_max_body_size 20m;
    }

    listen 80;
    listen [::]:80
}

server {
    server_name <var>$NAKED_DOMAIN</var>;
    return 301 http://<var>$FRONTEND_DOMAIN</var>$request_uri;
    listen 80;
    listen [::]:80
}
```

Then to enable the site:

```shell-session
$ cd /etc/nginx/sites-enabled/
$ sudo ln -s ../sites-available/<var>$FRONTEND_DOMAIN</var>
```

Run `sudo nginx -t` to check if the config has no errors, and then reload Nginx with `service nginx reload`.

Now we can run Certbot again - after making sure the DNS has an entry for `<var>$FRONTEND_DOMAIN</var>` and `<var>$NAKED_DOMAIN</var>`:

```shell-session
$ sudo certbot
```

This time choosing the newly added domains. You should be able to visit `https://<var>$FRONTEND_DOMAIN</var>/`.

## 4.5 - Deploying changes

I include the following deploy script in my SvelteKit project:

```bash
git pull
nice -15 npm install
nice -15 npm run build
rm -rf deploy
mv build deploy
sudo /usr/sbin/service <var>$FRONTEND_DOMAIN</var> restart
```

So whenever I want to deploy changes I simply run these three commands:

```shell-session
$ ssh <var>$PROJECT_USER</var>@<var>$SERVER_IP_ADDRESS</var>
$ cd <var>$FRONTEND_DOMAIN</var>
$ ./deploy.sh
```
