---
tags: javascript, sveltekit
summary: I've been running my side project Critical Notes, built with SvelteKit, on my own server for about a year now and it's been pretty much rock solid. Since I saw some questions about how to host a SvelteKit app on your own server, I figured I'd document my setup.
archive: true
---

# Hosting SvelteKit

I've been running my side project [Critical Notes](https://www.critical-notes.com), built with [SvelteKit](https://kit.svelte.dev), on my own server for about a year now and it's been pretty much rock solid. Since I saw some questions about how to host a SvelteKit app on your own server, I figured I'd document my setup.

### **Attention: In 2023 I’ve written [a new article](/articles/2023/setting-up-debian-11/) detailing how to setup a Debian server from scratch for running SvelteKit and Django apps. It’s much more detailed and in-depth, and this article below should no longer be used as a reference.**<br><br>

## Nginx
The first part of the equation is the Nginx configuration for the website. Basically all it does is forward the request to the Node server coming with SvelteKit. It also redirects requests `critical-notes.com` to `www.critical-notes.com`.

#### <i class="fa-regular fa-file-code"></i> /etc/nginx/sites-available/www.critical-notes.com
```
server {
    server_name www.critical-notes.com;
    root /var/www/www.critical-notes.com;

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
}

server {
    server_name critical-notes.com;
    return 301 http://www.critical-notes.com$request_uri;
    listen 80;
}
```

> The folder `/var/www/www.critical-notes.com` that is used in the config file above is an empty folder, the website isn't actually served from there. All that Nginx does, is forward to the request to Node, which serves the site from the real site root, `/opt/www`.

### Get HTTPS working with Certbot
Right now the website is only accessible using HTTP requests on port 80, which is not so good. Luckily getting HTTPS support is as easy and running one simple command:

```
$ certbot --nginx
```

Afterwards your config will looks more like this:

#### <i class="fa-regular fa-file-code"></i> /etc/nginx/sites-available/www.critical-notes.com
```
server {
    server_name www.critical-notes.com;
    root /var/www/www.critical-notes.com;

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

    listen 443 ssl http2; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/api.critical-notes.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/api.critical-notes.com/privkey.pem; # managed by Certbot
    ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = www.critical-notes.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name www.critical-notes.com;
    listen 80;
    return 404; # managed by Certbot
}

server {
    server_name critical-notes.com;
    return 301 https://www.critical-notes.com$request_uri;

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/critical-notes.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/critical-notes.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if ($host = critical-notes.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    server_name critical-notes.com;
    return 404; # managed by Certbot
}
```

Restart Nginx to active the changes: `service nginx reload`.

## SvelteKit server
Within my real site root `/opt/www` I can checkout my Git repo, and run `npm run build`, this creates the compiled build and the Node server. I am using `adapter-node` for this.

To run the Node server, I am using systemd. I created a config file `/etc/systemd/system/www.critical-notes.com.service` with the following content:

#### <i class="fa-regular fa-file-code"></i> /etc/systemd/system/www.critical-notes.com.service
```
[Unit]
Description=www.critical-notes.com

[Service]
User=criticalnotes
Group=criticalnotes
ExecStart=node /opt/www/build/index.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

With that file in place I can run the Node server with the command `service www.critical-notes.com start`.

## Deploying changes
Whenever I make changes to my website, I SSH into the server, `git pull` the latest changes, then run `npm run build && service www.critical-notes.com restart` to build the site and restart the Node server. And presto, the changes are live. Of course you can make this as fancy as you like with build scripts and other automations.