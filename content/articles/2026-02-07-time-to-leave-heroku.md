---
tags: deployment, django, python, insights, coolify
summary: Heroku just announced it's entering "sustaining engineering mode". No new features, no enterprise contracts for new customers. After years of security breaches, outages, price hikes, and technological stagnation, it's time to leave.
---

# It's time to leave Heroku

Back in the day Heroku felt like magic for small Django side projects. You pushed to `main`, it built and deployed automatically, and the free tier was generous enough that you could experiment without ever pulling out a credit card. For a long time, Heroku was the easiest way to get something live without worrying about servers, deployment scripts, or infrastructure at all. Every Python developer I knew recommended it.

Sadly, that era is over.

## The slow decline

The problems started piling up in 2022. In April, hackers [stole OAuth tokens](https://blog.heroku.com/april-2022-incident-review) used for GitHub integration, gaining access to customer repositories. It later emerged that hashed and salted customer passwords were also [exfiltrated from an internal database](https://www.bleepingcomputer.com/news/security/heroku-admits-that-customer-credentials-were-stolen-in-cyberattack/). Heroku [forced password resets](https://thehackernews.com/2022/05/heroku-forces-user-password-resets.html) for all users. Their handling of the incident was widely criticized: they revoked all GitHub integration tokens without warning, breaking deploys for everyone, and [communication was slow and vague](https://therecord.media/heroku-breach-salesforce-oauth-github).

Then in August 2022, Heroku [announced they would eliminate all free plans](https://techcrunch.com/2022/08/25/heroku-announces-plans-to-eliminate-free-plans-blaming-fraud-and-abuse/), blaming "fraud and abuse." By November, free dynos, free Postgres databases, and free Redis instances were all gone. Look, I understand this wasn't sustainable for the company. But they lost an entire generation of developers who had grown up with Heroku for their side projects and hobby apps. The same developers who would recommend Heroku at work. Going from free to a minimum of $5-7/month for a dyno plus $5/month for a database doesn't sound like much, but it adds up quickly when you have a few side projects, and it broke the frictionless experience that made Heroku special.

The platform also became unstable. On June 10, 2025, Heroku suffered a [massive outage lasting over 15 hours](https://www.bleepingcomputer.com/news/technology/massive-heroku-outage-impacts-web-platforms-worldwide/). Dashboard, CLI, and many deployed applications were completely inoperable. Even their status page went down. Eight days later, [another outage](https://www.qovery.com/blog/heroku-outages) lasted 8.5 hours. Multiple smaller incidents followed throughout the rest of 2025, affecting SSL, login access, API performance, and logging. As one developer put it on Hacker News: "the last 5 years have been death by a thousand cuts."

And beyond the outages, Heroku simply stopped evolving. Yefim Natis of Gartner [described it well](https://www.infoworld.com/article/2264177/the-decline-of-heroku.html): "I think they got frozen in time." Jason Warner, who led engineering at Heroku from 2014 to 2017, was [even more blunt](https://www.infoworld.com/article/2336521/if-heroku-is-so-special-why-is-it-dying.html): "It started to calcify under Salesforce."

Unsurprisingly, competitors sprung up to fill the void: [Fly.io](https://fly.io/), [Railway](https://railway.com/), [Render](https://render.com/), [DigitalOcean App Platform](https://www.digitalocean.com/products/app-platform), and self-hosted solutions like [Coolify](https://coolify.io/) and [Dokku](https://dokku.com/). Developers were already leaving in droves.

Yesterday, Heroku published a post titled [An Update on Heroku](https://www.heroku.com/blog/an-update-on-heroku/), announcing they are transitioning to a "sustaining engineering model", "with an emphasis on maintaining quality and operational excellence rather than introducing new features." They also stopped offering enterprise contracts to new customers. 

The reason? Salesforce (who acquired Heroku back in 2010) is "focusing its product and engineering investments on areas where it can deliver the greatest long-term customer value, including helping organizations build and deploy enterprise-grade AI." Translation: Heroku doesn't make enough money, and Salesforce would rather invest in AI hype.

This is the classic pattern: stop selling new contracts, honor existing ones, then eventually wind down. If you're still on Heroku, the writing is on the wall.

## What leaving Heroku looks like

I want to share a concrete example. In 2023 I started working with [Sound Radix](https://www.soundradix.com/), who had a SvelteKit app with a Django backend running on Heroku. They were paying $500 per month. Five hundred dollars for what is essentially an e-commerce website. And the performance was terrible: slow builds, sluggish website.

As one of my first tasks, I set up a Debian server on [Hetzner](https://www.hetzner.com/) and moved everything over. A single dedicated instance running the full stack. Cost: $75/month. Yes, setting up backups and auto-deploys on push took more work than Heroku's push-button experience. But we understood our stack from top to bottom, everything got significantly faster, and we were paying 85% less.

In 2025 we moved to [Coolify](https://coolify.io/), a self-hosted PaaS that gives you much of Heroku's developer experience without the lock-in or the price tag. We now run two Hetzner servers: a small $5/month instance for Coolify itself, and a $99/month server for the actual application (the $75/month instance was no longer offered by Hetzner). Setting up Coolify and getting a Django project running on it is really rather easy - I've written about it in detail: [Running Django on Coolify](/articles/2025/coolify-django/) and [Django static and media files on Coolify](/articles/2025/coolify-django-static-media/).

## Final thought

Heroku was genuinely great once. It pioneered the PaaS model and made deployment accessible to an entire generation of developers. But that was a long time ago. Between the security breaches, the death of the free tier, the outages, the technological stagnation, and now the explicit admission that no new features are coming - there's simply no reason to stay.

If you're still on Heroku, don't wait for the sunset announcement. Move now, while it's on your terms.
