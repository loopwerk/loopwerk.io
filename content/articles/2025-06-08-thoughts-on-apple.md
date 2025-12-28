---
tags: apple, insights
summary: With WWDC around the corner, I'm reflecting on why I've fallen out of love with Apple. After more than a decade of iOS development, the company's anti-developer stance, Swift's growing complexity, and the eroding software quality led me back to the open web.
---

# Thoughts on Apple, and why I left iOS development behind

With hashtag WWDC right around the corner, I can't help but notice a feeling that would've been completely alien to me just a few years ago: a total lack of excitement. For over a decade, WWDC week used to swallow me up. I'd be glued to the keynote, and for weeks afterward, I'd be watching session videos. I started building iOS apps in 2010, and it felt like a new frontier. But now... I just don't care.

It's hard to pinpoint when the magic died. It wasn't a single event, but a slow, creeping realization. The company I once admired has changed, or maybe I have. In January of 2023 I left iOS development behind and returned to the open web. I left behind the walled garden for a world without an inconsistent review process and without a 30% tax on my work. Without an overlord telling you what kind of links and buttons are allowed in your app.

## Apple's petty and malicious behavior

On the big stage, Apple will loudly praise developers as the heart of their ecosystem. But in practice, it feels like they're squeezing those same developers at every turn. They need to be forced by courts to do the right thing, and when they are, their compliance is so petty and malicious it's almost insulting.

Look no further than their response to the EU's Digital Markets Act. Specifically alternative app stores, alternative browser engines, and allowing developers to link to external payment methods. Instead of embracing a more open future, they implemented a structure so convoluted and punitive that it was clearly designed to scare developers away from using the very freedoms the law was meant to provide. They then geoblock these "improvements" to ensure as few people as possible benefit. For those of us in Europe, this isn't new. We've grown accustomed to seeing features like Apple News, the Apple Card, Apple Cash (and the related Tap To Cash), and iPhone Mirroring announced with great fanfare, only to find them perpetually unavailable. We are an afterthought.

For developers there's also a constant, lingering fear of being "Sherlocked”; the phenomenon where you build a beloved and successful app, only for Apple to copy its core functions into the next OS update, effectively killing your business. It turns the App Store from a marketplace into a minefield, where your success can be the very trigger for your extinction.

## Swift no longer sparks joy

This developer-hostile attitude _might_ have been tolerable if the tools remained a joy to use. And for a long time, they were. I used to absolutely love Swift. I jumped in around Swift 3, and it felt like a revelation. A clean, safe, and expressive leap forward from Objective-C. Gone were the verbose brackets and header files; in their place were optionals, powerful enums, and value types that made reasoning about code a breeze. The language was opinionated in a way that guided you toward better, safer patterns. It sparked joy.

But over the years, that initial simplicity and focus have been buried under layers of ever-increasing complexity. It feels like the language sprinted from a practical tool for building apps to a highly academic exercise in language theory.

The turning point for me began around Swift 5.5. The introduction of `async`/`await` was a welcome and long-overdue addition, simplifying asynchronous code. But it didn't come alone. It brought with it the actor model, Structured Concurrency, and a whole new set of rules to memorize. Suddenly, simple background tasks required wrestling with a complex system.

Then came the real friction: `@Sendable` and the strict data-race protections. While noble in their goal, in practice they often lead to a demoralizing battle with the compiler. You spend less time building features and more time trying to appease the type checker, deciphering alien error messages about a type not conforming to Sendable. The language that once felt like a helpful partner now felt like a pedantic adversary.

This trend continued. Features like property wrappers and result builders, while powerful, added layers of "magic" that obscured what was actually happening. And the recent introduction of macros feels like the final departure from Swift's original promise of clarity. The code on the screen is no longer the code that runs; it's a template for generating other code, demanding a whole new level of mental gymnastics to debug and maintain.

Each new feature added power, yes, but at the cost of immense cognitive overhead. The language that once empowered the solo developer now feels tailored to large, specialized teams who can afford to have experts in its arcane corners. The joy was gone, replaced by burnout.

I still haven't updated [Saga](https://github.com/loopwerk/Saga), my static site generator written in Swift, to use Swift 6. I just can't be bothered, to be honest.

## It just... doesn't work as well

At the same time, the fundamental promise of the Apple ecosystem - that "it just works" - has been steadily eroding. The software quality isn't what it used to be. Filing bug reports into the black hole that is the Feedback Assistant still feels like a demoralizing and useless ritual. Tickets are left open without any form of reaction, or closed as duplicate, with absolutely no way of seeing the status of that other ticket. Or even worse: you're asked to double check if the bug is still a bug with every new OS version. Like, do your own work!

Their recent forays into new territory have been equally uninspiring. The AI efforts feel misguided and years behind the competition. And the only major new product category in a decade, the Vision Pro, is a marvel of engineering that is effectively dead on arrival for most people due to its insane price tag.

## The golden cage

Just last week I sold my Apple Watch, because I got so incredibly bored with being stuck with the same few watch faces. It's truly insane to me how developers are still not able to create third party watch faces, and I don't understand how it's in Apple's best interest. I bought an old-fashioned mechanical watch instead. I would've liked to buy another smart watch, but of course Apple makes it impossible for non-Apple watches to compete on features. They lock everything down, for example only with the Apple Watch can you reply to messages or act on other notifications.

This gatekeeping extends even to the web itself. For over a decade, Apple mandated that every single web browser on iOS (Chrome, Firefox, Edge) wasn't a real browser. It was just a different user interface built on top of Apple's own Safari engine, WebKit. This gave users the illusion of choice while ensuring Apple maintained absolute control over web standards on its platform, stifling innovation and holding back what developers could build. Only now, under legal pressure from regulators like the EU, are they reluctantly "allowing" true browser competition. Except that [they made this so incredibly painful](https://open-web-advocacy.org/blog/apples-browser-engine-ban-persists-even-under-the-dma/) that not even Google has been able to release a new version of Chrome with their own engine.

The reason for this is clear: greed. From OWA:

> Safari is the highest margin product Apple has ever made, accounts for 14-16% of Apple's annual operating profit and brings in $20 billion per year in search engine revenue from Google. For each 1% browser market share that Apple loses for Safari, Apple is set to lose $200 million in revenue per year.

Or what about the iMessage lock-in? By refusing to adopt modern, open messaging standards and instead stigmatizing non-iPhones with "green bubbles”, Apple actively degrades the experience of communicating with friends and family who dare to live outside their walls. It's a calculated strategy to leverage social pressure for profit, a perfect metaphor for their entire ecosystem.

And the control doesn't stop at software. With their war on repair, using serialized parts that only they can authenticate, Apple has tried to redefine the very concept of ownership. The device you paid a premium for is never truly yours to fix or modify. It's another wall in the garden, designed to lock you into their expensive services and push you towards the next upgrade cycle rather than a simple, sustainable repair.

## So, I left.

The Apple I fell in love with was an innovator that put the user and developer experience first. It was the scrappy underdog championing the user and the user experience above all else. The Apple of today feels out of touch, greedy, petty, and honestly sometimes downright evil.

So, I went back to Python and Django, back to the open web. I picked up TypeScript and SvelteKit. The contrast is stark. Here, the tools are open, the community is collaborative, and the platform doesn't demand a cut of my revenue for the privilege of existing. I can ship an update without asking the overlords for permission and waiting a week. And most important of all: I'm having fun again! Things are simpler to build, and they can be accessed by anyone in the world, on any device.

I don't know what will be announced at this year's WWDC, but I know it'll be presented with the usual polish and fanfare. For me, though, the trust is gone. Apple is a company that desperately needs a revolution from within. Until then, I'll be happily building on the outside.
