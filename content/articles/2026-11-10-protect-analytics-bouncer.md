---
tags: analytics, news
summary: I've built Bouncer, a self-hosted man-in-the-middle service that protects my analytics from being polluted with bot traffic.
---

# Protect your analytics from bots with Bouncer

There are so many bots roaming the internet nowadays, crawling every site they can find. Some are useful to website owners, like search bots. Others are useful to users, like AI agents looking up answers or information. Most are just parasites, sucking up every bit of text they can.

And honestly, I don't really care about bots visiting my website. It's all static HTML cached with Cloudflare, and trying to block all the bots is a losing battle that will probably impact real users too. It's just not worth it. But that doesn't mean I want to see these bots in my damn analytics!

So far I've used a few Cloudflare rules to block bots from accessing the analytics script and endpoint, and this has worked pretty well. I [wrote about it](/articles/2026/protect-analytics/) in February of this year. But while it works well enough, it is kind of a hassle to set up on every site. Making a change to a rule means having to go through every site, ugh. And of course not everyone uses (or wants to use) Cloudflare.

To make my own life - and hopefully that of others - a bit better, I've created [Bouncer](https://github.com/loopwerk/Bouncer). It sits between your site and your analytics tool, and filters out bots. The rest is sent through as normal. You self-host Bouncer (a Docker image is provided), change your website to point to Bouncer instead of your analytics endpoint, and that's it.

Bouncer comes with seven filters, and logs what passes and what is blocked. It's pretty simple right now: only self-hosted [Umami](https://umami.is/) is supported, but Plausible support is on the roadmap. Give it a go and let me know what you think.