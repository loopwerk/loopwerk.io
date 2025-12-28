---
tags: deployment, howto
summary: Webservers get hit by hundreds of thousands of requests to random (non-existing) PHP files. Previously I dealt with this on the server level, now I'm doing it directly within CloudFlare.
---

# Blocking PHP requests using CloudFlare's WAF rules

A while ago I wrote [an article about hardening your web server](/articles/2024/hardening-web-server/) against script kiddies, who have a tendency to bombard your server with many thousands of requests to (non-existing) PHP files. I used a combination of Nginx rules, a firewall, and fail2ban to not only block these requests but even completely block repeat offenders from accessing anything on the server.

This setup works fine, and is active on all servers I maintain, but there is one downside: my [server monitoring software of choice](https://www.netdata.cloud) sends me warnings whenever the percentage of successful HTTP requests dips below a certain threshold. And when the PHP requests come in and get blocked en masse, that percentage immediately drops and I get a warning email. This usually happens multiple times a day, which is quite annoying.

So now I am blocking these kinds of requests directly within CloudFlare, by using a custom WAF rule with the following expression:

```
(http.request.uri wildcard r"/wp-*") or (http.request.uri wildcard r"/*/wp-*") or
(http.request.uri wildcard r"/wordpress*") or (http.request.uri wildcard r"/*/wordpress*") or
(http.request.uri wildcard r"*.php") or (http.request.uri wildcard r"*.php7")
```

To create such a rule for your domain navigate to Security -> WAF -> Custom rules, and press the "Create rule” button. On this page you can click the "Edit expression” link, and then you can paste in the expression from above. Choose the block action, save the form, and you're done!

I've seen this rule block close to 11,000 requests in 24 hours on one of my domains. That's 11,000 requests that didn't even make it to my server that day 🎉
