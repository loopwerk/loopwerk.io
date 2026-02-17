---
tags: review, analytics
summary: After leaving Plausible I moved to Umami. Here's what's better, how I set up proxying to bypass adblockers, and the one problem neither tool can solve.
---

# Umami vs Plausible: why I switched

In my [previous article](/articles/2026/plausible/) I wrote about my frustrations with Plausible: the price hike, analytics getting overrun by bot traffic, and the features they lock away from the open source version. I've now moved all my sites to [Umami](https://umami.is), and I'm happy with the switch.

## What Umami does better

The biggest difference is that Umami's self-hosted version is the full product. There's no feature split between a free and paid tier. If you want managed hosting you can pay for it, but the self-hosted version doesn't hold anything back (although releases are created some time after the cloud version already got new features and fixes). Compare that to Plausible's Community Edition, which locks away "premium" features like funnels, revenue tracking, and of course advanced bot tracking.

Umami also offers some unique features:

- **Specific screen sizes.** Umami shows you actual resolutions like 1920x1080 or 390x844. Plausible only shows device categories (desktop, mobile, tablet), which is far less useful when you're trying to make design decisions.
- **[Individual session details.](https://umami.is/docs/sessions)** You can view exactly which pages a visitor viewed and which events they triggered, in order. Plausible shows aggregate stats but gives you no way to inspect individual visits.
- **Visitor journeys.** Umami visualizes the paths visitors take through your site, showing how people actually navigate from page to page.
- **Retention reports.** Track how many visitors come back over time, segmented by device, country, or traffic source. Plausible has no equivalent.
- **[Cohorts.](https://umami.is/docs/cohorts)** Group users based on specific actions (like visiting a URL or triggering an event) within a date range, then track that group's behavior over time. Plausible has [audience segmentation](https://plausible.io/audience-segmentation) through filters, but no way to define and follow a fixed cohort.

On the infrastructure side, Umami uses PostgreSQL. This makes backups straightforward and works perfectly with [Coolify](https://coolify.io)'s built-in backup features for offsite storage. Plausible uses ClickHouse, which is significantly harder to manage and back up; it's definitely not possible from within Coolify's interface.

If you do want managed hosting, Umami's pricing is reasonable: free up to 100k events per month, or $20/month for a million events. Plausible charges $19/month and $69/month for those same two tiers, respectively.

## What Plausible does better

To be fair, Plausible certainly has its strengths.

The dashboard is cleaner and more modern, and it really nails the "glance at it and know what's going on" experience. Umami's interface is functional but doesn't feel as polished. Especially on mobile I greatly prefer Plausible's UI:

<div class="images">
<img src="/articles/images/umami-vs-plausible-1.webp"/><img src="/articles/images/umami-vs-plausible-2.webp"/>
</div>

*I really do not like Umami's sidebar-based navigation. It takes 4 clicks to change between sites!*

Plausible integrates with Google Search Console, so you can see which search terms people use to find your site. Umami has no equivalent, and there's been an [open feature request](https://github.com/umami-software/umami/discussions/645) for it since 2021. You can always check Search Console directly, but having everything in one dashboard is convenient.

Plausible also tracks scroll depth per page, which is useful for long-form content. Umami doesn't offer this.

On the practical side, Plausible supports data import from Google Analytics and via CSV files. Umami has no import at all; if you're switching, you start with a blank slate.

And if you're willing to pay for Plausible's cloud offering, their bot filtering is genuinely good. Nothing in the open source self-hosted analytics space comes close to that.

## Why I switched to Umami

I'll be honest: I do not really like Umami's UI, and it caused me to think long and hard before I switched over. Missing features such as the Google Search Console integration and scroll depth tracking didn't help either.

But there are two big things that drew me in:

1. I can easily back up all the data myself.
2. I feel more aligned with Umami's true open source principles.

Even after I switched all my sites over to Umami I kept wondering if it was the right call, especially when I tried to view the analytics on my mobile phone. But to me principles are more important than convenience and a nice UI.

## Setting up Umami

I'm running Umami as an application in Coolify. This is extremely simple: just add a new resource to a project, and choose Umami from the list. Start the container, and you can login using `admin` / `umami` (change this immediately!)

### Proxying to bypass adblockers

I proxy Umami's tracking script through each site's own domain. This way, every site loads `/script.js` from its own domain rather than from the Umami server, which means adblockers don't block it.

The Nginx config is simple:

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

The `/api/send` location needs the extra headers because both my sites and Umami sit behind Cloudflare and then Traefik on Coolify. Without forwarding the real client IP, every visitor would show up as coming from the same Cloudflare address, and geolocation would be completely wrong.

On the Umami side, two environment variables make this work:

```
CLIENT_IP_HEADER=x-client-real-ip
SKIP_LOCATION_HEADERS=1
```

`CLIENT_IP_HEADER` tells Umami to read the real IP from the custom header instead of the connection's source IP. `SKIP_LOCATION_HEADERS` prevents Umami from using Cloudflare's location headers (which at that point reflect the proxy server's location, not the visitor's).

### The bot problem

Here's the one thing that didn't improve. After switching [critical-notes.com](https://www.critical-notes.com) to Umami, I saw similarly inflated visitor numbers as I did with self-hosted Plausible. Umami uses the [isbot](https://github.com/omrilotan/isbot) library for bot detection, which filters based on user-agent strings. It catches the obvious crawlers, but anything pretending to be a regular browser sails right through.

This isn't really Umami's fault. **No client-side analytics tool handles bots well without server-side infrastructure like data center IP blocking and behavioral analysis.**

One thing I'm experimenting with is a Cloudflare WAF rule that blocks known bots, empty user-agents, and known datacenter IP addresses from hitting the analytics endpoints:

```
(
  http.request.uri.path eq "/script.js"
  or http.request.uri.path eq "/api/send"
)
and
(
  cf.client.bot
  or http.user_agent eq ""
  or http.user_agent contains "Googlebot"
  or http.user_agent contains "ChatGPT-User"
  or http.user_agent contains "GPTBot"
  or http.user_agent contains "ClaudeBot"
  or http.user_agent contains "PerplexityBot"
  or http.user_agent contains "Amazonbot"
  or http.user_agent contains "Bytespider"
  or (ip.src.asnum in {16509 14618 15169 396982 8075 14061 24940 16276 20473 63949 31898 12876 51167 45102 60781 9009 132203})
)
```

> [!SIDENOTE]
> The numbers in the `ip.src.asnum` line are ASNs (Autonomous System Numbers) that identify major cloud providers like AWS, Google Cloud, Azure, DigitalOcean, Hetzner, Tencent Cloud, and Vultr. Real visitors don't browse from data centers, so any traffic from these networks is almost certainly a bot.
> 
> Cloudflare's `cf.bot_management.score` rule would allow for more granular bot detection, but it requires an extremely expensive Cloudflare Enterprise plan.

This adds a layer of bot filtering before the traffic even reaches Umami. It's too early to say how much of a difference it makes, but the idea is simple: if Cloudflare already knows it's a bot or coming from a data center, don't let it pollute the analytics.

I'll update this article once the Cloudflare WAF rule has had time to prove itself.