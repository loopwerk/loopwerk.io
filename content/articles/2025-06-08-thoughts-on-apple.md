---
tags: apple, insights
summary: WWDC is around the corner, and for the first time in over a decade I couldn't care less. Two and a half years after switching back to web development, I'm not sure if I'll return to iOS.
---

# Thoughts on Apple

In 2023 I took on a web development project at a new client, working on a webshop using SvelteKit and Django. This was my first big paid web development project in a decade; I switched to full-time iOS development in 2012. I worked on a few sites and backends in that time, but that wasn't my focus during those years.

We're now two and a half years further, and I have to say: I am not missing iOS development at all. Hashtag WWDC is right around the corner, and I feel a complete lack of excitement, which is a bit strange because for over a decade WWDC week used to swallow me up. I'd be glued to the keynote, and for weeks afterwards I'd be watching all the session videos. Even while I was working on a web project I'd be super excited about all the new features I'd be implementing soon enough. But this year, I feel none of this. I think I can declare that part of my life over.

When I took on the webshop project, I don't think I consciously said goodbye to Apple and iOS. But now that I think about it, I doubt I'll go back any time soon, for a few reasons.


## Apple vs. developers

On stage Apple will loudly praise developers as the beating heart of their ecosystem. But at the same time they're squeezing those same developers every way they can. It's absolutely clear that they don't care about us at all, when they need to be literally forced by the courts to do the right thing. And even then their compliance is so petty and malicious that it's insulting.

Just look at how they dealt with the EU's Digital Markets Act. Apple was required to allow alternative app stores, alternative browser engines, and to allow developers to link to external payment methods. All of that sounds very reasonable to me, things they should've done from the beginning (maybe not alternative app stores but certainly the rest). But instead of opening up and following the law, they implemented their solutions in such convoluted ways that it was clearly designed to scare developers away. And of course they geoblock these "improvements" to ensure that as few people as possible benefit.

Look for example at the alternative browser engines. For over a decade every browser on iOS was forced to use Apple's engine, WebKit. Users got the illusion of choice, while Apple kept absolute control over web standards, and held back what developers could build. Competition was simply not possible. Finally, under legal pressure from the EU, Apple is now reluctantly "allowing" true browser competitors. Except that they made this so incredibly painful that not even Google has been able to release a version of Chrome on iOS with their own engine.

The reason is simple: greed.

> Safari is the highest margin product Apple has ever made, accounts for 14-16% of Apple's annual operating profit and brings in $20 billion per year in search engine revenue from Google. For each 1% browser market share that Apple loses for Safari, Apple is set to lose $200 million in revenue per year.
> Source: [Open Web Advocacy](https://open-web-advocacy.org/blog/apples-browser-engine-ban-persists-even-under-the-dma/)

Then there's the fear of being "sherlocked". This is when Apple takes a popular and successful app, and copies its functionality into iOS itself, killing the app and their business. Look at [Continuity Camera](https://techcrunch.com/2022/06/13/all-the-things-apple-sherlocked-at-wwdc-2022/), which they stole from Camo. Or the recently added Freeform and Journal apps; does iOS *really* need this to be built-in? Where's the line?

## Swift no longer sparks joy

I used to absolutely love Swift. I jumped in around Swift 3, and it was a huge leap forward from Objective-C. We got an easier syntax, and optionals and enums. The language was small, easy to pick up.

But over the years the language grew and that initial simplicity was gone. It seemed like Apple wanted Swift to do everything for everyone, and lost focus.

For me the turning point came around Swift 5.5, in 2021. It introduced `async`/`await`, which was absolutely welcome and wonderful. It made async code so much easier! But it also brought actors, structured concurrency, `Sendable`, and a whole new set of rules. The language became quite a bit more complicated, the compiler errors harder to understand, and to me it felt like a different language.

Swift 6 said "hold my beer" and added data-race safety. It's a noble goal to prevent race conditions, proven by the compiler, but the language got exponentially more complex.

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

I now feel like I am in a constant battle to keep the compiler happy, applying its suggested fixes, because I don't understand what the hell it wants.

All of these features have good intentions, but they all add complexity. Property wrappers and result builders added layers of magic that hide what's actually happening. And now we have macros? The code you see is not the code that's running. Great.

I still haven't updated [Saga](https://getsaga.dev), my static site generator, to Swift 6. I just can't be bothered, to be honest.

## It just... doesn't work as well anymore

Remember when the promise that "it just works" largely was true? Apple's operating systems were not bug-free, but they were coherent and consistent. Their designs were nice, with the Human Interface Guidelines that every app developer followed, because it all just made sense.

That's definitely not the case any more. The software quality is going downhill fast, probably due to the relentless cycle of yearly updates. I run into so many bugs all the time, it's kind of insane. I used to report these bugs into the Feedback Assistant, but I stopped doing that long ago. It's a black hole where tickets are left open for years without any feedback. Or, if there is feedback, it's usually a request to please re-check the bug on every new OS version. Do your own work!

Their newer products don't excite me either. They're years behind the competition when it comes to AI, and the only major new product category in a decade, the Vision Pro, is a flop because of its insane price tag.

Cool features that do excite me, like iPhone Mirroring, Apple Card, Apple Cash and Tap to Cash, and Apple News, are not available in Europe. We're either forgotten about, or a casualty in Apple's war with Europe over the DMA. I'm not a fan of being an expendable pawn that Apple obviously doesn't care about.

## The golden cage

Just last week I sold my Apple Watch, because I got so incredibly bored with being stuck with the same few watch faces. It's truly insane to me how developers are still not able to create third party watch faces, and I don't understand how it's in Apple's best interest. I bought an old-fashioned mechanical watch instead. I would've liked to buy another smart watch, but of course Apple makes it impossible for non-Apple watches to compete on features. They lock everything down, for example only with the Apple Watch can you reply to messages or act on other notifications.

Of course there's also the famous iMessage lock-in. By stigmatizing non-iPhones with green bubbles, Apple knowingly degrades the experience of talking with friends and family who don't have an iPhone. Tim Cook's answer to that is literally that your friends should buy an iPhone. At least he's honest about his motives, I guess. Apple was finally pressured to add support for (some of) the universal RCS standard, so things are looking up; at least we'll be able to send pictures to Android users without having to install WhatsApp.

And the lock-in doesn't stop at software either. Apple really doesn't like the right-to-repair movement, and has lobbied heavily against this for years. When forced to make repairs easier, they did so in the most Apple-like petty way you could imagine. Apple's "Self Service Repair" program now lets you repair your iPhone, by renting you a 36-kilogram suitcase with specialized tools. Tools so costly that Apple requires a $1200 deposit. And because Apple uses serialized parts that only they can authenticate, they make it borderline impossible to use third-party replacement parts. Worse, even combining genuine Apple parts from different iPhones won't always properly work. It's *supposed* to work, but you can still end up with scary warnings in iOS about using non-Apple hardware.

## Conclusion

The Apple I fell in love with put the user and the developer experience first. Today's Apple feels out of touch, greedy, petty, and honestly: evil.

I'm quite happy to be back working in the open web, using Python and Django, TypeScript and SvelteKit. Open source tools that nobody controls, a collaborative community, and nobody that takes 30% of my revenue. I can deploy updates without asking the overlords for permission and waiting for a review. And most importantly: I am having fun again! Things are simpler to build, and they can be accessed by anyone in the world, on any device. I think there's much more value in that than building another iPhone app.