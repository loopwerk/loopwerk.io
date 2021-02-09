---
tags: iOS
summary: WWDC is just around the corner, and we're all waiting like little kids at Christmas to see what Apple is going to announce. Most of us also are hoping for specific changes, here are my top wishes.
---

# WWDC20 wishlist
WWDC is just around the corner, and we're all waiting like little kids at Christmas to see what Apple is going to announce. Most of us also are hoping for specific changes, here are my top wishes.

## SwiftUI 2.0
I love SwiftUI! Well, mostly. While it's super quick and easy to build complex and good looking interfaces, it's also quite buggy, needs a ton of workarounds, and is missing a lot of features. I'll have more to say on all of this in [an upcoming article](/articles/2020/swiftui-review/).

Of all my wishes for this year's WWDC, a new version of SwiftUI is by far the biggest one.

Likelihood: 100%. Of course this is coming.

## Combine 2.0
Combine is pretty awesome. I never really liked RxSwift a lot, but have been in love with ReactiveKit for about a year now. But in my iOS 13+ apps I am now exclusively using Combine (even with UIKit app where I am not using SwiftUI). Yes the need to type-erase everything is kind of annoying, but overall it's a really really good v1.

What I am missing are nicer bindings to the UI. Something like ReactiveKit's [Bond](https://github.com/DeclarativeHub/Bond), RxSwift's [RxCocoa](https://github.com/ReactiveX/RxSwift) or ReactiveSwift's [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa). There are the open source libraries [CombineCocoa](https://github.com/CombineCommunity/CombineCocoa) and [CombineDataSources](https://github.com/CombineCommunity/CombineDataSources) which helps, but I would prefer first-party support from Apple. I wouldn't mind Apple including most of the stuff from [CombineExt](https://github.com/CombineCommunity/CombineExt) either.

Likelihood: 50%. I think this will come at some point, but maybe not this year.

## Custom Watch faces
Apple Watch was introduced five years ago, and we still don't have custom watch faces. It wasn't until iPhoneOS 4.0 that we had background images on the iPhone, but WatchOS 7 is coming up now and it's about time we have a store for new watch faces.

Likelihood: 25%. Apple just doesn't seem that interested in making the most personal Apple device even more personal and customizable. If they add it, it's probably only for the latest generation of the Watch.

## TestFlight for macOS
With the arrival of Catalyst (the "magic checkbox" to turn an iOS app into an macOS app) there are going to be more and more iOS apps ported over to the Mac, and it's currently simply a pain to distribute test builds. We need TestFlight for the Mac.

Likelihood: 75%. I think Apple know this needs to happen, and I think it should be rather easy for them to make this happen.

## Improved Catalyst
Speaking of Catalyst, the results of that magic checkbox certainly have room for improvement. Catalyst apps by default look way too much like misplaced iOS apps on the Mac, with a lot of developer time and effort needed to turn them into proper macOS apps. Even Apple is struggling with for example the Developer app. Still, it seems to me that Catalyst is a stop-gap solution until SwiftUI is mature enough and the majority of all apps for all their platforms will be written with SwiftUI. 

Likelihood: 95%. I definitely think we'll see at least some improvements to the default output, with probably new APIs to make it easier to customize the resulting app without having to reach for AppKit.

## Apple-hosted CI/CD (a.k.a. bring back BuddyBuild!)
I loved BuddyBuild, it was by far the best CI/CD platform out there for iOS apps, with superb crash reporting and build signing. Apple bought them in 2018, and since then it's impossible to sign up for a new account. Sadly my old account belonged to an old employer so I don't have access to it anymore, and I really do miss BuddyBuild.

Likelihood: 10%. I think Apple will use (or is already using) BuddyBuild tech into their existing stack, but I don't think it's super likely that we'll get an Apple-branded CI/CD platform any time soon.

## Upgrade pricing for iOS apps
We need it. Enough said.

Likelihood: 0%. 😢

## Lower Apple cut for In App Purchases
The 30% Apple tax is insanely high. They just don't provide enough to justify this amount, especially considering that you also have to pay $99 a year to be in the developer program to begin with.

Likelihood: 1%. Not quite 0% due to all the investigations around the world into Apple's anti-competitive behavior, but yeah, I don't see this happening.

## Xcode on iPad
Okay, not the whole thing, but I want to at least work on SwiftUI apps on the iPad, with live previews.

Likelihood: 5%. Hopefully in the future.

## Other bits and pieces
* Change default apps
* Fix iPad multitasking
* Bring back the old "magnifying glass" cursor control to iOS
* Apple Watch sleep tracking
