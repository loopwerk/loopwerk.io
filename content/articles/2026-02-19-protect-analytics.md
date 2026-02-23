---
tags: howto, analytics
summary: How I used Cloudflare's free security rules to filter bot traffic from my self-hosted Umami analytics.
---

# Protect your analytics with Cloudflare

Previously I wrote about how my self-hosted analytics (first [Plausible](/articles/2026/plausible/), then [Umami](/articles/2026/umami-vs-plausible/)) were getting overrun by bots, making the stats borderline useless. After some trial and error I found a pretty good solution: Cloudflare security rules. I went from 2k-5k visitors a day down to about 500, which is a lot more realistic. Before self-hosting, Plausible reported 200-300 visitors a day, but that was without proxying the script, so I was probably missing 25-50% of real visitors.

Here are the rules I enabled in Cloudflare, all available on free accounts. The first two I had enabled for quite a while already, the last two are new additions.

In Security → Security rules:

1. **Block AI scrapers and crawlers**
```
(cf.verified_bot_category eq "AI Crawler") or
(cf.verified_bot_category eq "Search Engine Optimization")
```

This blocks two bot categories: AI and SEO crawlers. They don't get access to my site at all. This rule blocked 2.8k events in the past 24 hours.

2. **AI Crawl Control - Block AI bots by User Agent** 
```
(http.request.uri.path ne "/robots.txt") and 
(
  (http.user_agent contains "Amazonbot") or 
  (http.user_agent contains "Anchor Browser") or 
  (http.user_agent contains "Applebot") or 
  (http.user_agent contains "bingbot") or 
  (http.user_agent contains "Bytespider") or 
  (http.user_agent contains "CCBot") or 
  (http.user_agent contains "ClaudeBot") or 
  (http.user_agent contains "FacebookBot") or 
  (http.user_agent contains "Google-CloudVertexBot") or 
  (http.user_agent contains "GPTBot") or 
  (http.user_agent contains "meta-externalagent") or 
  (http.user_agent contains "Novellum") or 
  (http.user_agent contains "OAI-SearchBot") or 
  (http.user_agent contains "PerplexityBot") or 
  (http.user_agent contains "PetalBot") or 
  (http.user_agent contains "ProRataInc") or 
  (http.user_agent contains "Timpibot")
)
```

This blocks specific bots by user agent. You configure it via AI Crawl Control → Crawlers, where you can see how often each bot visits your site and block them individually. Under the hood it gets stored as a security rule.

This rule blocked 3.1k events in 24 hours.

3. **Challenge likely bot countries**
```
(ip.src.country eq "SG") or (ip.src.country eq "CN") or
(ip.src.country eq "JP") or (ip.src.country eq "HK") or
(ip.src.country eq "VN") or (ip.src.country eq "IN") or
(ip.src.country eq "BR") or (ip.src.country eq "IQ") or
(ip.src.country eq "BD")
```

Unlike the other rules, this one doesn't have the block action, but rather the "managed challenge" action. Visitors from Singapore, China, Japan, and some other countries, need to pass Cloudflare's captcha page before they are allowed to visit the site. The challenge solve rate is 0.9%, so that's proof that almost all visitors from these countries are bots.

Amazingly, this rule blocked close to 10k events in just 24 hours, even though it sits behind the other rules. That means that these bots aren't identifying themselves properly - otherwise they would've been caught in an earlier rule.

4. **Block bots from analytics**
```
(
  http.request.uri.path eq "/script.js" or
  http.request.uri.path eq "/api/send"
)
and
(
  cf.client.bot or
  http.user_agent eq "" or
  http.user_agent contains "Googlebot" or
  http.user_agent contains "ChatGPT-User" or
  http.user_agent contains "GPTBot" or
  http.user_agent contains "ClaudeBot" or
  http.user_agent contains "PerplexityBot" or
  http.user_agent contains "Amazonbot" or
  http.user_agent contains "Bytespider" or
  (ip.src.asnum in {16509 14618 15169 396982 8075 14061 24940 16276 20473 63949 31898 12876 51167 45102 60781 9009 132203})
)
```

Finally, the one from my [previous article](/articles/2026/umami-vs-plausible/). This one specifically blocks bots and visits coming from data centers from accessing the analytics endpoints. They are allowed to crawl the site, but they cannot trigger anything in Umami. 

This blocked almost 3k events, which would otherwise have made it to Umami.

> [!SIDENOTE]
> Plus of course I have my [anti-PHP-scraper rule](/articles/2025/cloudflare-waf-block-php/) active too, which blocks about 1000 events per day on average.

## Proxying your analytics endpoints

Please note that the last rule only works because I'm proxying the Umami script and API through the website's own domain, so the requests pass through Cloudflare. Sadly [Umami's docs](https://umami.is/docs/bypass-ad-blockers) are quite bad, without any examples. Here's how you can proxy in Nginx:

```nginx
location /script.js {
    proxy_pass https://stats.example.com/script.js;
    proxy_set_header Host stats.example.com;
    proxy_ssl_server_name on;
    proxy_buffering on;
}

location /api/send {
    proxy_pass https://stats.example.com/api/send;
    proxy_set_header Host stats.example.com;
    proxy_ssl_server_name on;
    proxy_buffering on;
    proxy_set_header X-Client-Real-IP $http_cf_connecting_ip;
    proxy_set_header X-Forwarded-For $http_cf_connecting_ip;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
}
```

And in Caddy:

```nginx
handle /script.js {
    reverse_proxy https://stats.example.com {
        header_up Host stats.example.com
    }
}

handle /api/send {
    reverse_proxy https://stats.example.com {
        header_up Host stats.example.com
        header_up X-Client-Real-IP {http.request.header.CF-Connecting-IP}
        header_up X-Forwarded-For {http.request.header.CF-Connecting-IP}
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
    }
}
```

On the Umami side, you need these two environment variables make the proxying work:

```
CLIENT_IP_HEADER=x-client-real-ip
SKIP_LOCATION_HEADERS=1
```

If you use Plausible Analytics (either cloud or self-hosted) you can, and should, also proxy the endpoints. Their [docs](https://plausible.io/docs/proxy/introduction) are a lot better, with examples for [Nginx](https://plausible.io/docs/proxy/guides/nginx), [Caddy](https://plausible.io/docs/proxy/guides/caddy), and many more.