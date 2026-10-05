---
tags: django, insights, coolify
summary: Heroku just announced it's entering "sustaining engineering mode". No more new features. After years of security breaches, outages, and price hikes, it's time to leave.
---

# It's time to leave Heroku

Remember when Heroku felt like magic? You pushed to `main`, and it built and deployed your site automatically. For me personally this was a huge improvement over hosting Python projects myself, and the free tier was generous enough that most side projects never ended up paying a cent. Literally every Python developer I knew recommended it.

Sadly, that era is over.

## The slow decline

As far as I can tell, the problems started in 2022. In April, hackers [stole OAuth tokens](https://blog.heroku.com/april-2022-incident-review) used for GitHub integration, gaining access to customer repositories. Then we found out that hashed and salted customer passwords were also [exfiltrated from an internal database](https://www.bleepingcomputer.com/news/security/heroku-admits-that-customer-credentials-were-stolen-in-cyberattack/) and Heroku [forced password resets](https://thehackernews.com/2022/05/heroku-forces-user-password-resets.html) for all users. They revoked all GitHub integration tokens without warning, which broke deploys for everyone, causing [Heroku to face serious backlash](https://therecord.media/heroku-breach-salesforce-oauth-github) about how they handled this incident.

Then in August 2022, Heroku [announced they would eliminate all free plans](https://techcrunch.com/2022/08/25/heroku-announces-plans-to-eliminate-free-plans-blaming-fraud-and-abuse/), blaming "fraud and abuse." By November, the free dynos and Postgres databases were indeed gone. I understand this wasn't sustainable for the company, but was there really no better solution? Going from free to a minimum of $5-7/month for a dyno plus $5/month for a database adds up quickly when you have a few side projects! And these developers are same ones who would recommend Heroku at work.

The platform became famously unstable. On June 10, 2025, Heroku suffered a [massive outage lasting over 15 hours](https://www.bleepingcomputer.com/news/technology/massive-heroku-outage-impacts-web-platforms-worldwide/). Eight days later, [another outage](https://www.qovery.com/blog/heroku-outages) lasted 8.5 hours. Multiple smaller incidents followed throughout the rest of 2025.

As if the outages weren't bad enough, Heroku also stopped evolving. Yefim Natis of Gartner [described it well](https://www.infoworld.com/article/2264177/the-decline-of-heroku.html): "I think they got frozen in time." Jason Warner, who led engineering at Heroku from 2014 to 2017, was [even more blunt](https://www.infoworld.com/article/2336521/if-heroku-is-so-special-why-is-it-dying.html): "It started to calcify under Salesforce."

Surprising absolutely nobody, competitors quickly sprung up to fill the void: [Fly.io](https://fly.io/), [Railway](https://railway.com/), [Render](https://render.com/), [DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform), and self-hosted solutions like [Coolify](https://coolify.io/) and [Dokku](https://dokku.com/). Developers were leaving in droves.

Yesterday, Heroku published a post titled [An Update on Heroku](https://www.heroku.com/blog/an-update-on-heroku/), announcing they are transitioning to a "sustaining engineering model", "with an emphasis on maintaining quality and operational excellence rather than introducing new features." They also stopped offering enterprise contracts to new customers. 

The reason? Salesforce (who acquired Heroku back in 2010) is "focusing its product and engineering investments on areas where it can deliver the greatest long-term customer value, including helping organizations build and deploy enterprise-grade AI." Translation: Heroku doesn't make enough money, and Salesforce would rather invest in AI hype.

You don't have to be a genius to see the writing on the wall.

## What leaving Heroku looks like

In 2023 I started working with [Sound Radix](https://www.soundradix.com/), who had a SvelteKit app with a Django backend running on Heroku. They were paying $500 per month for a pretty simple site. Five hundred dollars! On top of that the performance was terrible with slow builds and bad response times.

As one of my first tasks, I set up a Debian server on [Hetzner](https://www.hetzner.com/) and moved everything over. A single dedicated instance could easily run the full stack for a mere $75 per month. Setting up backups and auto-deploys took some more work, but we everything got significantly faster, and we were paying 85% less. Seemed like a good trade to us.

In 2025 we moved to [Coolify](https://coolify.io/), a self-hosted PaaS that gives you much of Heroku's developer experience without the costs. We now run two Hetzner servers: a small $5/month instance for Coolify itself, and a $99/month server for the actual application (the $75/month instance was sadly no longer offered by Hetzner). Setting up Coolify and getting a Django project running on it is quite easy - I've written about it in detail: [Running Django on Coolify](/articles/2025/coolify-django/) and [Django static and media files on Coolify](/articles/2025/coolify-django-static-media/).

If you're still on Heroku, it's time to leave before its inevitable closure is announced. What a sad end to an era.