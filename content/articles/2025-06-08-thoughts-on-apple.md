---
tags: apple, insights
summary: After more than a decade of iOS development, the company's anti-developer stance, Swift's growing complexity, and the eroding software quality led me back to the open web.
---

# Thoughts on Apple, and why I left iOS development behind

With hashtag WWDC right around the corner, I can't help but notice a feeling that would've been completely alien to me just a few years ago: a total lack of excitement. For over a decade, WWDC week used to swallow me up. I'd be glued to the keynote, and for weeks afterward, I'd be watching session videos. I started building iOS apps in 2010, and it felt like a new frontier. But now... I just don't care.

It's hard to pinpoint when the magic died; there wasn't a single event, just a slow, creeping realization. The company I once admired has changed, or maybe I have. In January of 2023 I left iOS development behind and returned to the open web. I left behind the walled garden for a world without an inconsistent review process and without a 30% tax on my work. Without an overlord telling you what kind of links and buttons are allowed in your app.

## Apple's petty and malicious behavior

On the big stage, Apple will loudly praise developers as the heart of their ecosystem. But in practice, it feels like they're squeezing those same developers wherever they can. They need to be forced by courts to do the right thing, and when they are, their compliance is so petty and malicious it's almost insulting.

Just look at their response to the EU's Digital Markets Act. Specifically alternative app stores, alternative browser engines, and allowing developers to link to external payment methods. Instead of opening up, they implemented a structure so convoluted and punitive that it was clearly designed to scare developers away from using the freedoms the law was meant to provide. They then geoblock these "improvements" to ensure as few people as possible benefit. For those of us in Europe, this isn't new. We've grown accustomed to seeing features like Apple News, the Apple Card, Apple Cash (and the related Tap To Cash), and iPhone Mirroring being announced, only for them to never become available here. We are an afterthought.

For developers there's also the constant fear of being "Sherlocked"; the phenomenon where you build a beloved and successful app, and then Apple copies its core functions into the next OS update, killing your business. It turns the App Store into a minefield: the more successful your app, the bigger the chance that Apple comes for it.

## Swift no longer sparks joy

This developer-hostile attitude _might_ have been tolerable if the tools remained a joy to use. And for a long time, they were. I used to absolutely love Swift. I jumped in around Swift 3, and it felt like a revelation: such a leap forward from Objective-C. No more verbose brackets and header files; instead we got optionals, enums, and value types, and reasoning about code became so much easier. The language was opinionated in a way that guided you toward better, safer patterns. It sparked joy.

But over the years, that initial simplicity and focus have been buried under more and more complexity. The language turned from a practical tool for building apps into a highly academic exercise in language theory.

The turning point for me began around Swift 5.5. The introduction of `async`/`await` was a welcome and long-overdue addition, simplifying asynchronous code. But it also brought the actor model and Structured Concurrency, and a whole new set of rules to memorize. Suddenly even simple background tasks meant wrestling with a complex system.

The real friction came with `@Sendable` and the strict data-race protections. The goal is noble, but in practice it's a demoralizing battle with the compiler. You spend less time building features and more time trying to appease the type checker, deciphering alien error messages about a type not conforming to Sendable.

```swift
// What you want:
func doThing() {
  thing()
}

// What Swift 6 demands:
@MainActor
nonisolated(unsafe)
func doThing() async throws -> sending some Sendable {
  await withCheckedThrowingContinuation { continuation in
    Task { @MainActor in
      // 47 compiler warnings later
    }
  }
}
```

This trend continued. Features like property wrappers and result builders added layers of "magic" that obscure what's actually happening. And the recent introduction of macros feels like the final departure from Swift's original promise of clarity. The code you see is a template for generating other code that you don't see, and debugging that is a whole new level of mental gymnastics.

Each new feature added power, but at the cost of immense cognitive overhead. Swift used to be a great language for a solo developer like me; now it feels tailored to large teams who can afford to have experts in its arcane corners. The joy was gone.

I still haven't updated [Saga](https://getsaga.dev), my static site generator written in Swift, to use Swift 6. I just can't be bothered, to be honest.

## It just... doesn't work as well

At the same time, the fundamental promise of the Apple ecosystem - that "it just works" - has been steadily eroding. The software quality isn't what it used to be. Filing bug reports into the black hole that is the Feedback Assistant still feels like a demoralizing and useless ritual. Tickets are left open without any form of reaction, or closed as duplicate, with absolutely no way of seeing the status of that other ticket. Or even worse: you're asked to double check if the bug is still a bug with every new OS version. Like, do your own work!

Their newer products don't excite me either. The AI efforts feel misguided and years behind the competition. And the only major new product category in a decade, the Vision Pro, is impressive engineering that's dead on arrival for most people because of its insane price tag.

## The golden cage

Just last week I sold my Apple Watch, because I got so incredibly bored with being stuck with the same few watch faces. It's truly insane to me how developers are still not able to create third party watch faces, and I don't understand how it's in Apple's best interest. I bought an old-fashioned mechanical watch instead. I would've liked to buy another smart watch, but of course Apple makes it impossible for non-Apple watches to compete on features. They lock everything down, for example only with the Apple Watch can you reply to messages or act on other notifications.

They even gatekeep the web itself. For over a decade, every browser on iOS (Chrome, Firefox, Edge) was forced to be a different user interface on top of Apple's own Safari engine, WebKit. Users got the illusion of choice, while Apple kept absolute control over web standards on its platform and held back what developers could build. Now, under legal pressure from the EU, they're reluctantly "allowing" true browser competition. Except that [they made this so incredibly painful](https://open-web-advocacy.org/blog/apples-browser-engine-ban-persists-even-under-the-dma/) that not even Google has been able to release a new version of Chrome with their own engine.

The reason for this is clear: greed. From OWA:

> Safari is the highest margin product Apple has ever made, accounts for 14-16% of Apple's annual operating profit and brings in $20 billion per year in search engine revenue from Google. For each 1% browser market share that Apple loses for Safari, Apple is set to lose $200 million in revenue per year.

Or what about the iMessage lock-in? By refusing to adopt modern, open messaging standards and instead stigmatizing non-iPhones with "green bubbles", Apple actively degrades the experience of communicating with friends and family who don't have an iPhone. It's a calculated strategy to use social pressure for profit.

And the control doesn't stop at software. With their war on repair, using serialized parts that only they can authenticate, Apple has tried to redefine what it means to own a device. The device you paid a premium for is never truly yours to fix or modify; Apple would rather push you towards the next upgrade cycle than allow a simple repair.

## So, I left.

The Apple I fell in love with put the user and the developer experience first. The Apple of today feels out of touch, greedy, petty, and honestly sometimes downright evil.

So, I went back to Python and Django, back to the open web. I picked up TypeScript and SvelteKit. Here the tools are open, the community is collaborative, and nobody takes a cut of my revenue. I can ship an update without asking the overlords for permission and waiting a week. And most important of all: I'm having fun again! Things are simpler to build, and they can be accessed by anyone in the world, on any device.

I don't know what will be announced at this year's WWDC, but I know it'll be presented with the usual polish and fanfare. For me, though, the trust is gone. Apple is a company that desperately needs a revolution from within. Until then, I'll be happily building on the outside.
