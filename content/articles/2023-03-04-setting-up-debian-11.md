---
tags: django, sveltekit
summary: I recently had to set up a brand new server for a website running on SvelteKit and its API running on Django. I am a software developer and setting up servers and hosting isn't something I normally do, so I followed a bunch of different tutorials. In this article I want to combine all these tutorials, mostly for future me, but hopefully you'll find it useful as well.
---

# Setting up a Debian 11 server for SvelteKit and Django

I recently had to set up a brand new server for a website running on SvelteKit and its API running on Django. I used a virtual server from [Hetzner](https://www.hetzner.com/cloud) running Debian 11. A CCX22 instance to be exact: 4 dedicated vCPUs, 16 GB of RAM and 160 GB of disk space, with 20 TB of traffic included, all for €45 per month - although you can also get a server for as little as €3.79 per month! And if you use my [referral link](https://hetzner.cloud/?ref=WZ6oJ9LrNtzM) when signing up for a cloud server, you'll get €20 in credits.

I am a software developer and setting up servers and hosting isn't something I normally do, so I followed a bunch of different tutorials. In this article I want to combine all this information, mostly for future me, but hopefully you'll find it useful as well. Most of the info came from the following tutorials, so check them out if you want more in-depth explanations of the commands:

- https://www.digitalocean.com/community/tutorials/initial-server-setup-with-debian-11
- https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-debian-11
- https://linuxize.com/post/how-to-set-up-ssh-keys-on-debian-10
- https://computingforgeeks.com/how-to-install-node-js-on-ubuntu-debian/
- https://www.howtogeek.com/675010/how-to-secure-your-linux-computer-with-fail2ban/
- https://linuxiac.com/how-to-set-up-automatic-updates-on-debian/

In this article many command have placeholders like `/*TMS*/$SERVER_IP_ADDRESS/*TME*/` which you need to replace with the actual value.

- `/*TMS*/$SERVER_IP_ADDRESS/*TME*/`: the IP address of your server. You got this from Hetzner.
- `/*TMS*/$PROJECT_USER/*TME*/`: the user that will be running your project. This can be your name, or for a server that is used for one project, the name of your project. Examples: `kevin` or `criticalnotes` or `loopwerk`.
- `/*TMS*/$BACKEND_DOMAIN/*TME*/`: domain that's used for your backend, like `api.example.com` (without `http://` or `https://`)
- `/*TMS*/$FRONTEND_DOMAIN/*TME*/`: domain that's used for your frontend, like `www.example.com` (again without `http://` or `https://`)
- `/*TMS*/$NAKED_DOMAIN/*TME*/`: the "naked" domain that's used for your frontend, without the `www` like `example.com` (you guessed it, without `http://` or `https://`)

# Table of contents

%TOC%

# Chapter 1 - Setting up the basics

## 1.1 - Setting up the accounts

First we're going to login as root, create a new user, and then allow the new user to run commands as root with `sudo`.

```
ssh root@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
adduser /*TMS*/$PROJECT_USER/*TME*/
usermod -aG sudo /*TMS*/$PROJECT_USER/*TME*/
```

Open a new terminal (keep the one where you're logged in as root open), and test if you can indeed login as the new user, and run commands as sudo:

```
ssh /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
sudo echo "I am root!"
```

You're asked to enter your password (not the root password!), and then you should see "I am root!". With all that done, you can close the second terminal and go back to the session where you are logged in as root.

## 1.2 - Firewall

While you can create a firewall within Hetzner's web UI and select it when creating a new server, I prefer to simply run it on the server itself. The Uncomplicated Firewall, or UFW for short, is indeed not complicated at all, but with all the power of iptables under the hood.

While still logged in as root, enter the following commands:

```
apt update
apt install ufw
ufw allow OpenSSH
ufw enable
ufw status
```

The output should be like this:

```
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

```
ssh-keygen -t ed25519 -C "your_email@domain.com"
```

You don't have to enter a passphrase when creating a key, just press enter for no passphrase - although adding a passphrase is of course more secure.

Now we're going to copy the public key to your server with the following command:

```
ssh-copy-id /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
```

Now, try logging into the server again. Open a new terminal and enter the following. This time you should not be asked for your password:

```
ssh /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
```

If that worked, you can close the second terminal and go back to the one where you're logged in as root.

## 1.4 - Securing the SSH server

At the moment you can still SSH into your server using a password, and you can connect as the root user. Let's disable both these things so that the root user can never connect via SSH, and the normal user can only connect using SSH keys.

**Before making the following changes, make absolutely sure you can login to your server without a password, and that the user has sudo privileges. See steps 1.1 and 1.3.**

As root, enter the command

```
pico /etc/ssh/sshd_config
```

Search for the following variables and change them as such:

```
PermitRootLogin no
PasswordAuthentication no
```

Uncomment these lines if they were previously commented out. Save the file and restart the SSH server:

```
service ssh restart
```

Open a new terminal and test logging in as root:

```
ssh root@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
```

This should fail with the message `Permission denied (publickey)`. Now make sure logging in as the normal user still works:

```
ssh /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
```

You can now close the other SSH sessions, including the one where you are still logged in as root.

**From now all everything will be done as the normal user, using `sudo` where necessary**.

## 1.5 - Further securing your server with fail2ban

Inevitably, hackers will try to log into your server, trying a bunch of common passwords. Let's automatically block anyone who fails to connect using fail2ban.

```
sudo apt install fail2ban
sudo pico /etc/fail2ban/jail.local
```

Enter the following contents:

```
[DEFAULT]
bantime = 2h

[sshd]
enabled = true
maxretry = 1
```

Now enable end start fail2ban:

```
sudo systemctl enable fail2ban
sudo service fail2ban start
```

You can see its status with the following command:

```
fail2ban-client status sshd
```

## 1.6 - Automatic security updates

It would be great if important security updates automatically get installed on the server, and that's exactly what the `unattended-upgrades` package is for. Let's install it:

```
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Check if the service is started:

```
sudo service unattended-upgrades status
```

# Chapter 2 - PostgreSQL

## 2.1 - Setup

Install PostgreSQL:

```
sudo apt install postgresql
```

And then log into an interactive PostgreSQL session:

```
sudo -u postgres psql
```

Run the following commands to create a new database user, set some parameters on the user as [recommended by Django](https://docs.djangoproject.com/en/4.2/ref/databases/#optimizing-postgresql-s-configuration), and then finally we create a new database for the new user:

```
postgres=# CREATE USER /*TMS*/$PROJECT_USER/*TME*/ WITH PASSWORD 'password';
postgres=# ALTER ROLE /*TMS*/$PROJECT_USER/*TME*/ SET client_encoding TO 'utf8';
postgres=# ALTER ROLE /*TMS*/$PROJECT_USER/*TME*/ SET default_transaction_isolation TO 'read committed';
postgres=# ALTER ROLE /*TMS*/$PROJECT_USER/*TME*/ SET timezone TO 'UTC';
postgres=# CREATE DATABASE my_database_name OWNER /*TMS*/$PROJECT_USER/*TME*/;
```

Press command+d to exit the PostgreSQL session.

## 2.2 - Backups

Let's make sure we make daily backups of our database.

```
mkdir ~/backups
pico ~/backup.sh
```

Enter the following contents:

```
#!/usr/bin/bash

set -x

# Location to place backups
backup_dir="/home//*TMS*/$PROJECT_USER/*TME*//backups/"

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

```
chmod +x ~/backup.sh
crontab -e
```

Enter the following contents:

```
# m h dom mon dow command
0 6 * * * /home//*TMS*/$PROJECT_USER/*TME*//backup.sh
```

This will run the script every day at 6:00.

## 2.3 - Store the backups off-site

The backups are now stored on the same server as the PostgreSQL database itself. It's much better than not having backups at all, but even better would be to store them off-site. I use [rsync.net](https://www.rsync.net) for this purpose. It's like a cloud server that you can run commands on via SSH, and you can send folders with files to it via rsync, sftp and scp. It's really great. After you signed up, just add this to the end of the backup script:

```
# Immediately store off-site
rsync -avH ~/backups /*TMS*/your_rsync_username/*TME*/@/*TMS*/your_rsync_instance/*TME*/.rsync.net:
```

But to enable this to run without having to enter a password, let's enable SSH key authentication.

On your server, logged in as `/*TMS*/$PROJECT_USER/*TME*/`, create a new SSH key:

```
ssh-keygen -t rsa -b 4096
```

Accept the defaults and do **NOT** enter a passphrase. Then upload it to the rsync.net server:

```
scp ~/.ssh/id_rsa.pub /*TMS*/your_rsync_username/*TME*/@/*TMS*/your_rsync_instance/*TME*/.rsync.net:.ssh/authorized_keys
```

Test that your key works by ssh'ing to your rsync.net filesystem:

```
ssh /*TMS*/your_rsync_username/*TME*/@/*TMS*/your_rsync_instance/*TME*/.rsync.net ls
```

You should not be asked for a password.

# Chapter 3 - the Django backend

Debian doesn't come with the latest and greatest version of Python pre-installed, so we're going to install a new version using [pyenv](https://github.com/pyenv/pyenv). I'm also using [Poetry](https://python-poetry.org/) as my Python dependency- and virtual-environment manager of choice, rather than pip and virtualenv.

## 3.1 - pyenv

Install pyenv:

```
curl https://pyenv.run | bash
```

After that you can install a new version of Python, and set it as the globally used version:

```
pyenv install 3.10
pyenv global 3.10
```

## 3.2 - Poetry

For the actual usage of Poetry in your project I'll refer to the official docs on https://python-poetry.org/docs/basic-usage/. I use Poetry with two [optional groups](https://python-poetry.org/docs/managing-dependencies/#optional-groups): `dev` and `prod`.

On the server, install Poetry with this oneliner:

```
curl -sSL https://install.python-poetry.org | python3 -
```

## 3.3 - Checking out the backend project

First we're going to clone the git project, and open the directory:

```
cd ~
git clone your_backend_git_repo_address /*TMS*/$BACKEND_DOMAIN/*TME*/
cd /*TMS*/$BACKEND_DOMAIN/*TME*/
```

Then we'll instruct Poetry to use Python 3.10, and we install the dependencies, including the ones from the `prod` group:

```
poetry env use 3.10
poetry install --with prod
```

Make sure the Django project's settings are using your server's PostgreSQL database (for example using an `.env` file - I use [django-environ](https://django-environ.readthedocs.io/en/latest/) for that) and let's run the Django migrations:

```
poetry run ./manage.py migrate
```

## 3.4 - systemd config

We now need to make sure that the Django server is automatically started when the server is started. For this we'll use systemd.

Create a new service config:

```
sudo pico /etc/systemd/system//*TMS*/$BACKEND_DOMAIN/*TME*/.service
```

With the following contents:

```
[Unit]
Description=/*TMS*/$BACKEND_DOMAIN/*TME*/

[Service]
User=/*TMS*/$PROJECT_USER/*TME*/
Group=/*TMS*/$PROJECT_USER/*TME*/
Restart=on-failure
WorkingDirectory=/home//*TMS*/$PROJECT_USER/*TME*///*TMS*/$BACKEND_DOMAIN/*TME*/
ExecStart=/home//*TMS*/$PROJECT_USER/*TME*//.local/bin/poetry run gunicorn \
          --access-logfile - \
          --workers 2 \
          --bind=127.0.0.1:8000 --bind=[::1]:8000 \
          /*TMS*/your_project_name/*TME*/.wsgi:application

[Install]
WantedBy=multi-user.target
```

To make sure the service automatically starts when the server starts, run the following command:

```
systemctl enable /*TMS*/$BACKEND_DOMAIN/*TME*/
```

And finally, start the server using:

```
service /*TMS*/$BACKEND_DOMAIN/*TME*/ start
```

Check if it is indeed running:

```
service /*TMS*/$BACKEND_DOMAIN/*TME*/ status
```

## 3.5 - Nginx

While the Django server is now running, is isn't actually accessible yet. For that we'll install Nginx, and use it to proxy request to the gunicorn proces.

Install Nginx and then create a site config file:

```
sudo apt install nginx
sudo pico /etc/nginx/sites-available//*TMS*/$BACKEND_DOMAIN/*TME*/
```

With the following contents:

```
server {
    server_name /*TMS*/$BACKEND_DOMAIN/*TME*/;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location /static/ {
        alias /home//*TMS*/$PROJECT_USER/*TME*///*TMS*/$BACKEND_DOMAIN/*TME*//static_root/;
    }

    location /media/ {
        alias /home//*TMS*/$PROJECT_USER/*TME*///*TMS*/$BACKEND_DOMAIN/*TME*//media_root/;
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

```
cd /etc/nginx/sites-enabled/
sudo ln -s ../sites-available//*TMS*/$BACKEND_DOMAIN/*TME*/
```

Run `sudo nginx -t` to check if the config has no errors, and then reload Nginx with `service nginx reload`.

Finally, we need to configure the firewall to open up the ports for the Nginx:

```
sudo ufw allow "Nginx Full"
```

Your backend should now be reachable on `http:///*TMS*/$BACKEND_DOMAIN/*TME*//` if you already changed the domain's DNS settings, otherwise it's reachable via `http:///*TMS*/$SERVER_IP_ADDRESS//*TME*/`.

Let's make it run on HTTPS though. For this the DNS settings of the domain should be in order, so an `A` record pointing your (sub)domain to the server's IP address should be in place.

Install Certbot using Snap:

```
sudo apt install snapd
sudo snap install core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

With all that done, simply run Certbot:

```
sudo certbot
```

Answer the questions and select your domain for which you want to active HTTPS. Certbot then does the rest and you should be able to visit `https:///*TMS*/$BACKEND_DOMAIN/*TME*//`. Hooray!

## 3.6 - Deploying changes

I use a really simple deploy script in my backend project:

```
git pull
poetry install --with prod --sync
poetry run ./manage.py migrate
sudo /usr/sbin/service /*TMS*/$BACKEND_DOMAIN/*TME*/ restart
```

So whenever I want to deploy changes I simply run these three commands:

```
ssh /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
cd /*TMS*/$BACKEND_DOMAIN/*TME*/
./deploy.sh
```

This will ask for your password because of the `sudo` command to restart the service. This gets kind of annoying, so to solve that, create the following file:

```
sudo pico /etc/sudoers.d/user_restart
```

With the following contents:

```
/*TMS*/$PROJECT_USER/*TME*/ ALL=NOPASSWD: /usr/sbin/service /*TMS*/$BACKEND_DOMAIN/*TME*/ restart
/*TMS*/$PROJECT_USER/*TME*/ ALL=NOPASSWD: /usr/sbin/service /*TMS*/$FRONTEND_DOMAIN/*TME*/ restart
```

This will allow the user to restart the backend and the future frontend services without having to type a password.

# Chapter 4 - The SvelteKit frontend

## 4.1 - Installing Node.js

```
curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
sudo apt install nodejs
```

## 4.2 - Checking out the code and creating a build

```
cd ~
git clone your_frontend_git_repo_address /*TMS*/$FRONTEND_DOMAIN/*TME*/
cd /*TMS*/$FRONTEND_DOMAIN/*TME*/
npm install
npm run build
mv build deploy
```

## 4.3 - systemd

Create a new service config:

```
sudo pico /etc/systemd/system//*TMS*/$FRONTEND_DOMAIN/*TME*/.service
```

With the following contents:

```
[Unit]
Description=/*TMS*/$FRONTEND_DOMAIN/*TME*/

[Service]
User=/*TMS*/$PROJECT_USER/*TME*/
Group=/*TMS*/$PROJECT_USER/*TME*/
WorkingDirectory=/home//*TMS*/$PROJECT_USER/*TME*///*TMS*/$FRONTEND_DOMAIN/*TME*/
Environment="HOST=127.0.0.1"
Environment="PORT=3000"
ExecStart=node deploy/index.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

To make sure the service automatically starts when the server starts, run the following command:

```
systemctl enable /*TMS*/$FRONTEND_DOMAIN/*TME*/
```

And finally, start the server using:

```
service /*TMS*/$FRONTEND_DOMAIN/*TME*/ start
```

Check if it is indeed running:

```
service /*TMS*/$FRONTEND_DOMAIN/*TME*/ status
```

## 4.4 - Nginx

Create a site config file:

```
sudo pico /etc/nginx/sites-available//*TMS*/$FRONTEND_DOMAIN/*TME*/
```

With the following contents:

```
server {
    server_name /*TMS*/$FRONTEND_DOMAIN/*TME*/;
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
    server_name /*TMS*/$NAKED_DOMAIN/*TME*/;
    return 301 http:///*TMS*/$FRONTEND_DOMAIN/*TME*/$request_uri;
    listen 80;
    listen [::]:80
}
```

Then to enable the site:

```
cd /etc/nginx/sites-enabled/
sudo ln -s ../sites-available//*TMS*/$FRONTEND_DOMAIN/*TME*/
```

Run `sudo nginx -t` to check if the config has no errors, and then reload Nginx with `service nginx reload`.

Now we can run Certbot again - after making sure the DNS has an entry for `/*TMS*/$FRONTEND_DOMAIN/*TME*/` and `/*TMS*/$NAKED_DOMAIN/*TME*/`:

```
sudo certbot
```

This time choosing the newly added domains. You should be able to visit `https:///*TMS*/$FRONTEND_DOMAIN/*TME*//`.

## 4.5 - Deploying changes

I include the following deploy script in my SvelteKit project:

```
git pull
nice -15 npm install
nice -15 npm run build
rm -rf deploy
mv build deploy
sudo /usr/sbin/service /*TMS*/$FRONTEND_DOMAIN/*TME*/ restart
```

So whenever I want to deploy changes I simply run these three commands:

```
ssh /*TMS*/$PROJECT_USER/*TME*/@/*TMS*/$SERVER_IP_ADDRESS/*TME*/
cd /*TMS*/$FRONTEND_DOMAIN/*TME*/
./deploy.sh
```
