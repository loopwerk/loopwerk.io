---
tags: review, analytics
summary: After years on Plausible I switched to self-hosting and discovered just how much they hold back from their open source version.
---

# Self-hosting Plausible broke my analytics

For years I used Google Analytics, because it was free and powerful and everybody used it. But Google gives you all of that for a reason: they track your visitors across the web and build advertising profiles out of your site's data, and you get to put up one of those cookie consent banners that everybody hates. I didn't want my websites to be part of that machine.

So, in July 2020 I switched to [Plausible Analytics](https://plausible.io): lightweight, privacy-friendly, no cookies, no cross-site tracking, and GDPR-compliant without a consent banner. You pay with money instead of with your visitors' data, and I was happy to pay.

For a while I was able to stay on their 10k pageviews plan, which cost $48 per year. When I outgrew that in July 2022, their 100k plan had jumped from $96 to $190 per year. Luckily I was grandfathered into the old pricing and only had to pay $96. I stayed on that plan until about a week ago.

The past few months I kept hitting the limits of my 100k plan, and I knew that soon I'd be asked to upgrade to their 200k plan. This would cost either $144 per year (my grandfathered price) or $290 per year (the current price). Neither felt worth it, so I decided to self-host Plausible instead. I installed it on my Coolify server using [these instructions](https://coolify.io/docs/services/plausible), exported all my data from the hosted version, imported it into my self-hosted instance, and deleted my old account.

Sadly, I'm not exactly happy with the result.

## Overrun with bots

Plausible's cloud offering uses advanced bot detection: user-agent filtering, referrer spam blocking, around 32,000 data center IP ranges, and behavioral pattern analysis. The self-hosted Community Edition? Just basic user-agent filtering and referrer spam blocking. None of the IP or behavioral detection.

For example, [critical-notes.com](https://www.critical-notes.com) normally gets around 200 unique visitors per day. After the switch to self-hosted Plausible, I'm seeing huge numbers every day, sometimes more than 5,000. This makes the analytics completely meaningless.

See if you can tell when I switched to self-hosting:

![Plausible screenshot](/articles/images/plausible-bots.webp)

Without proper bot filtering, the numbers stop representing real people. At that point, what are you even measuring?

## When open source and making money collide

And it doesn't stop there. Funnels and revenue tracking are also locked to the paid cloud version. Which is fine by me, reserving some premium features for the cloud version is a totally reasonable way to make money. Bot filtering is different though. Without it the numbers don't mean anything, at least not for sites like mine that get hammered by bots, which makes the self-hosted version essentially useless for me.

Managed hosting and backups should be more than enough to justify a paid tier. But Plausible loves to talk about how they're open source, while stripping core functionality out of that open source version to push you towards the paid one.

In fact, in the case of funnels they even show the missing feature in a useless report that can't be removed, always in your face:

![Funnels: 'This feature is unavailable'](/articles/images/funnels.webp)

Not a great look for an open source project. Personally I'm looking for alternatives.

> [!UPDATE]
> **February 18, 2026:** I've written a follow up, [comparing Umami to Plausible](/articles/2026/umami-vs-plausible/).