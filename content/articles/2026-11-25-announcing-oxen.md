---
tags: django, news
summary: Open source, self-hosted, and made with Django.
---

# Announcing Oxen, a simple self-hosted time-tracking and invoicing service

I've used [Harvest](https://www.getharvest.com/) for over ten years, as a freelance developer. It offered everything that I needed, in a neat little package. No feature bloat, nice UI, affordable price.

But over time it has added bloat, added AI integration, replaced its UI with a worse version, been sold to [Bending Spoons](https://www.reddit.com/r/HarvestApp/comments/1q25xpy/purchase_by_bending_spoons/) and got more expensive. And while Harvest does have a free account (limited to one user and 2 projects), you can't use it to create invoices unless you connect to Stripe to get paid - costing you 2% of your gross revenue!

I went looking for a replacement, but nothing really offered the same minimal features for a low price. If I wanted to self-host something, the list of options got much smaller. So, I decided to build something myself.

The result is [Oxen](https://github.com/loopwerk/Oxen), and it's available right now. It's hand-built with love using Django, and I've already created my first real invoice with it.

## Features

- Clients and projects, each with their own currency and VAT rates.
- Multiple users, with two roles available. Users can be assigned to specific projects.
- Timesheets: keep track of your hours per project, per day.
- Invoices: generate beautiful PDF invoices based on hours or free form.

I think more notable might be what's not included. No ads or tracking, no AI features. No expense tracking, per-employee rates, costs, budgets, profits. No tasks. No teams. No automated / scheduled invoice generation. No public invoice links. No online payments. No retainers.

On the roadmap: reports, an API, custom invoice templates, e-invoices, data export & import, and auto-saving timesheets with htmx.

<div class="images">
  <a href="/articles/images/announcing-oxen/oxen-01.webp"><img src="/articles/images/announcing-oxen/oxen-01.webp"></a>
  <a href="/articles/images/announcing-oxen/oxen-02.webp"><img src="/articles/images/announcing-oxen/oxen-02.webp"></a>
  <a href="/articles/images/announcing-oxen/oxen-03.webp"><img src="/articles/images/announcing-oxen/oxen-03.webp"></a>
  <a href="/articles/images/announcing-oxen/oxen-04.webp"><img src="/articles/images/announcing-oxen/oxen-04.webp"></a>
</div>

## Self-hosted

Oxen is fully open source and self-hosted. There's no hosted cloud version, and no plans to create one. There's no monetization plan. I've built this because I needed it for myself, and I am making it available for others to use.

There is first-class support for Coolify, as well as regular ol' Docker Compose. The readme should get you up and running.