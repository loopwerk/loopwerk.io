---
tags: deployment, howto
summary: Webservers get hit by hundreds of thousands of requests to random (non-existing) PHP files. What can we do about this?
---

# Hardening a web server against script kiddies

My webserver is constantly getting hit by requests to random PHP files, even though I don't host any PHP files at all:

```
5.161.49.218 - - [30/May/2024:00:43:02 +0000] "GET /yii/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:03 +0000] "GET /zend/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:03 +0000] "GET /ws/ec/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:03 +0000] "GET /V2/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:04 +0000] "GET /tests/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:05 +0000] "GET /test/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:05 +0000] "GET /testing/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:05 +0000] "GET /api/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:06 +0000] "GET /demo/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:07 +0000] "GET /cms/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:07 +0000] "GET /crm/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:08 +0000] "GET /admin/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:08 +0000] "GET /backup/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:09 +0000] "GET /blog/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:09 +0000] "GET /workspace/drupal/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:10 +0000] "GET /panel/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:10 +0000] "GET /public/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:10 +0000] "GET /apps/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
5.161.49.218 - - [30/May/2024:00:43:11 +0000] "GET /app/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1" 404 153 "-" "Custom-AsyncHttpClient"
```

And when a new PHP vulnerability is discovered it gets even worse, sometimes the server is getting hit hundreds of thousands of times a day. Let's do something about this!

## Step 1: denying the requests

When someone accesses a non-existing PHP file on my server, I don't want my SvelteKit site to render a nice looking 404 page. That's a huge waste of resources and bandwidth. So the first step is to deny requests to these kinds of files on the Nginx level.

For this I created a file `/etc/nginx/deny_rules.conf` with the following contents:

```
location ~ \.php$ {
    deny all;
}
```

And then within my virtual hosts I simply include this file:

```
server {
    server_name www.critical-notes.com;
    include /etc/nginx/deny_rules.conf;
    # The rest of the config
}
```

Make sure the Nginx config is correct (`nginx -t`), and then reload Nginx (`service nginx reload`). Now any request to a URL ending with `.php` simply gets blocked by Nginx itself with a barebones 403 page.

## Step 2: blocking these requests in the firewall

We're now blocking theses requests from reaching our website, but they still hit Nginx, and they generate a bunch of entries in our `error.log`. It would be better to simply block the IP addresses of repeat offenders directly in the firewall.

I am using UFW and fail2ban on my server, which I wrote about in my [Setting up a Debian 11 server for SvelteKit and Django](/articles/2023/setting-up-debian-11/) article last year. So check that article if you don't have a firewall and/or fail2ban running.

### Step 2a: Adding ngx_http_limit_req_module

We can configure Nginx to rate limit certain requests. Rate limited requests will return a 503 error code.

Edit `/etc/nginx/nginx.conf`:

```
http {
    limit_req_zone $binary_remote_addr zone=deny_rules:10m rate=1r/m;
    # The rest of the config
}
```

With this we create a special zone called `deny_rules` (you can name it whatever you want), and we rate limit it to 1 request per minute (per IP address). See [Nginx's documentation](https://nginx.org/en/docs/http/ngx_http_limit_req_module.html) for more details.

Now we edit our `/etc/nginx/deny_rules.conf` file like so:

```
location ~ \.php$ {
    limit_req zone=deny_rules nodelay;
    deny all;
}
```

Here we're saying that we want this location to use the `deny_rules` zone we created, and that we don't want to delay excessive requests.

Reload Nginx, and now when someone tries to repeatedly access a `.php` URL on our server they first get a 403, and from the second request onwards they will get a 503. This by itself isn't very useful yet, after all every request still reaches Nginx - only the error code is different.

### Step 2b: Adding rate limited IP addresses to fail2ban

We can easily configure fail2ban to automatically jail anyone caught by the rate limiter, as this functionality comes built in - we just have to enable it!

Edit your `/etc/fail2ban/jail.local` file, search for the `[nginx-limit-req]` section, and edit it so that it looks like this:

```
[nginx-limit-req]
port    = http,https
logpath = %(nginx_error_log)s
enabled = true
maxretry = 0
```

Restart fail2ban:

```
$ service fail2ban restart
```

Now when someone gets the 503 for accessing a `.php` file twice within one minute, they immediately get added to the firewall by fail2ban.

## If you use CloudFlare

If you proxy your site through CloudFlare then a bit more work is needed, because the IP address hitting your server is CloudFlare's IP address, not the user's IP address. You don't want to add CloudFlare's IP address to the firewall - it would break the site for everyone!

First we need to make sure that Nginx has access to the user's real IP address, by using the `real_ip` module. Edit `/etc/nginx/nginx.conf`:

```
http {
    # Define CloudFlare IP ranges
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/12;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 104.24.0.0/14;

    # Use the header sent by CloudFlare to extract the real client IP
    real_ip_header CF-Connecting-IP;

    limit_req_zone $binary_remote_addr zone=deny_rules:10m rate=1r/m;
    # The rest of the config
}
```

Now `$binary_remote_addr` contains the actual IP address of the visitor, and your access and error logs also contain the real IP addresses.

Reload Nginx, and now the user's real IP address is added to the firewall. But there's a problem: it's not the user's real IP address hitting the server, it's CloudFlare's IP address, so even though the user's IP address is in the firewall, they are not actually blocked at all. To solve this, we need to use CloudFlare's API to add the user's IP address to CloudFlare's firewall. Luckily even this functionality comes with fail2ban!

Edit `/etc/fail2ban/action.d/cloudflare.conf`, and at the bottom fill in the `cftoken` and `cfuser` variables. The value of `cftoken` is your global API key which you can get at https://dash.cloudflare.com/profile/api-tokens, and the value of `cfuser` is your CloudFlare user's email address.

Now edit `/etc/fail2ban/jail.local` and edit the `[nginx-limit-req]` section again so that it looks like this:

```
[nginx-limit-req]
port    = http,https
logpath = %(nginx_error_log)s
enabled = true
maxretry = 0
action = cloudflare
    ufw
```

Now the offending user's IP address is sent to CloudFlare's firewall and to the server's own firewall (to block access to SSH for example). After the ban time is over the IP address is automatically removed from CloudFlare's firewall.

If you want to see the list of blocked IP addresses you can run `fail2ban-client status nginx-limit-req`. You can also view CloudFlare's firewall in Security -> WAF -> Tools.

> [!UPDATED]
> **April 28, 2025**: I wrote [another article](/articles/2025/cloudflare-waf-block-php/) about blocking these sort of requests directly within CloudFlare using their custom WAF rules. This prevents the requests from making it to your server in the first place.
