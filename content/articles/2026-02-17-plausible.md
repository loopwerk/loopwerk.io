---
tags: review, analytics
summary: After years on Plausible I switched to self-hosting and discovered just how much they hold back from their open source version.
---

# Self-hosting Plausible broke my analytics

For years I used Google Analytics. It was free, it was powerful, and everyone used it. But I grew increasingly uncomfortable with what "free" actually meant: Google tracking visitors across the web, building advertising profiles from my site's data, and requiring cookie consent banners that annoyed everyone. I didn't want my websites to be part of that machine.

So, in July 2020 I switched to [Plausible Analytics](https://plausible.io). It was everything Google Analytics wasn't: lightweight, privacy-friendly, no cookies, no cross-site tracking, and fully compliant with GDPR without needing a consent banner. The trade-off was simple and honest: you pay with money instead of with your visitors' data. I was happy to make that deal.

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

And it doesn't stop there. Funnels and revenue tracking are also locked to the paid cloud version. Look, I don't mind that some premium features are reserved for the cloud version. But bot filtering isn't a nice-to-have; it's what makes the numbers meaningful. Without it, at least for sites like mine that get hammered by bots, the self-hosted version is essentially useless.

Offering managed hosting and backups should be enough to justify a paid tier. Instead, Plausible talks up being open source while they strip out core functionality to push you towards it.

In fact, in the case of funnels they even show the missing feature in a useless report that can't be removed, always in your face:

![Funnels: 'This feature is unavailable'](/articles/images/funnels.webp)

Not a great look for an open source project. Personally I'm looking for alternatives.

> [!UPDATE]
> **February 18, 2026:** I've written a follow up, [comparing Umami to Plausible](/articles/2026/umami-vs-plausible/).