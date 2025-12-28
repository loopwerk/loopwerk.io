---
tags: deployment, django, python, workflow, howto
summary: The best feature of Heroku is the ability to just push a branch, and it gets deployed. How do we replicate a workflow like that on our own server?
---

# Automatically deploy your site when you push the main branch

When I [setup my own Debian server back in 2023](/articles/2023/setting-up-debian-11/) I didn't really have a good way to automatically deploy my site. Instead I'd have to SSH into the server, go into the right folder, and execute a script that would pull the changes, run the migrations and restart the service. Something like this, for my Django backend:

```bash title="/home/example/api.example.com/deploy.sh"
git pull
poetry install --with prod --sync
poetry run ./manage.py migrate
sudo /usr/sbin/service api.example.com restart
```

Obviously this isn't ideal, and a far cry from the usability of something like Heroku, where you just push a git branch and it gets deployed. So I wanted to replicate the same kind of workflow, but on my own VPS, without resorting to big complex tools to get the job done.

Turns out that this is pretty simple using GitHub's webhooks. If you have an endpoint that can be POSTed to by GitHub whenever something is pushed to your main branch, then this endpoint can easily run that `deploy.sh` script for you.

Here's my version, using the `express` framework:

```javascript title="/home/example/deploy.example.com/index.js"
import express, { Request, Response } from "express";
import dotenv from "dotenv";
import crypto from "crypto";
import { spawn } from "child_process";

dotenv.config();

const app = express();
const port = process.env.PORT || 3500;
const GITHUB_WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET || "";

app.use(express.json());

function isSignatureOk(secret, req) {
  const incomingSignature = req.header("X-Hub-Signature-256") || "";
  if (!secret || !incomingSignature) {
    return false;
  }

  const expectedSignature =
    "sha256=" +
    crypto
      .createHmac("sha256", secret)
      .update(JSON.stringify(req.body))
      .digest("hex");

  const a = Buffer.from(incomingSignature);
  const b = Buffer.from(expectedSignature);
  return (
    Buffer.byteLength(a) === Buffer.byteLength(b) &&
    crypto.timingSafeEqual(a, b)
  );
}

function deploy(body, res) {
  if (body.head_commit && body.head_commit.message.includes("skipcd")) {
    return res.send({ status: "skipped" });
  }

  const repo = body.repository.name;
  const ref = body.ref;
  let site: string;

  if (repo == "api.example.com" && ref == "refs/heads/main") {
    site = "api.example.com";
  } else if (repo == "www.example.com" && ref == "refs/heads/main") {
    site = "www.example.com";
  } else {
    return res.send({ status: "ignored" });
  }

  console.log(`[DEPLOY] Running deploy.sh in /home/example/${site}`);
  process.chdir(`/home/example/${site}`);
  const s = spawn("./deploy.sh", [], { shell: true });

  s.stdout.on("data", data => {
    console.log(`[DEPLOY] stdout: ${data}`);
  });

  s.stderr.on("data", data => {
    console.error(`[DEPLOY] stderr: ${data}`);
  });

  return res.send({ status: "success" });
}

app.post("/", (req, res) => {
  const signatureOk = isSignatureOk(GITHUB_WEBHOOK_SECRET, req);
  if (!signatureOk) {
    return res.status(403).end();
  }

  const event = req.header("X-Github-Event") || "";
  if (event === "push") {
    return deploy(req.body, res);
  }

  return res.send({ status: "ignored event" });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
```

This script actually works for two sites running on the same server, and sharing the same webhook endpoint. By inspecting the repository name that we get in the POST payload we know which site to deploy.

Also create a `.env` file containing a webhook secret. It can be anything you want, just create something long and random:

```bash title="/home/example/deploy.example.com/.env"
GITHUB_WEBHOOK_SECRET="my_secret_value_here"
```

To get this `express` site up and running I created a `systemd` service file:

```ini title="/etc/systemd/system/deploy.example.com.service"
[Unit]
Description=node daemon for deploy.example.com

[Service]
User=example
Group=www-data
WorkingDirectory=/home/example/deploy.example.com
ExecStart=node index.js
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

And an Nginx site to host it:

```nginx title="/etc/nginx/sites-enabled/deploy.example.com"
server {
    server_name deploy.example.com;
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        proxy_pass http://localhost:3500;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffer_size 16k;
        proxy_buffers 4 16k;
        proxy_busy_buffers_size 16k;
        client_max_body_size 20m;
    }

    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/deploy.example.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/deploy.example.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}
server {
    if ($host = deploy.example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    server_name deploy.example.com;

    listen [::]:80;
    listen 80;
    return 404; # managed by Certbot
}
```

With all of that up and running you can edit the webhook config on GitHub and enter `https://deploy.example.com/` as the payload URL, triggered by push events. Don't forget to fill in your secret value as well.
