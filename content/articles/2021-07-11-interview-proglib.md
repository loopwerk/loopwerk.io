---
tags: iOS, swift, random
summary: Recently I was interviewed for the Russian IT website proglib.io. Since it might be interesting for non-Russian speakers, here it is in the original English version.
---

# Interview with proglib.io

Recently I was interviewed for the Russian IT website [proglib.io](https://proglib.io/p/put-v-professiyu-intervyu-s-ios-razrabotchikom-kevinom-renskersom-2021-07-02). Since it might be interesting for non-Russian speakers, here it is in the original English version.

### What was your path to iOS development?
In 2009 I started working at a local company as a Python developer where we built websites for big companies, using Plone and Django. In 2010 some clients started asking for iPhone apps, I expressed an extreme interest in learning to build said apps, and that was the beginning of my career as an iOS developer: getting paid to learn how to build iPhone apps.

I already had ten years of experience as a software developer by then though. I started in 2000 building website with HTML and Flash, in 2001 I started with PHP and JavaScript, and in 2009 I made the switch to Python.

### You started your journey to iOS in 2010. How much has changed now?
Almost everything. When I started, not only were we all still using Objective-C (which I actually really liked), but even ARC didn't exist yet. Wrapping my head around retain counts, dropping in retain and release calls until code didn't crash anymore, was hard.

Xcode wasn't one integrated tool yet; Interface Builder was its own app, so you could open both side by side. That was pretty nice.

Even "blocks" (closures, completion handlers), didn't exist yet, optionals didn't exist, array and dictionary literals didn't exist, storyboards didn't exist, the list goes on and on.

### 11 years is a long time frame. What did you have to learn during this time?
Obviously I had to first learn Objective-C, UIKit, Foundation, and all those other frameworks. Later on I had to learn Swift, functional programming, reactive programming, and all the new frameworks and APIs Apple have introduced over the years. MVC, MVVM, Coordinators, the Composable Architecture. Learning never stops!

Most of all though, writing iOS apps is so much different from writing a web app, so learning the right patterns, like delegates and how to deal with (background) threads, was a bit of a learning curve.

### Apple wasn't a big company in 2010. The iPhone 4 just came out. Why did you choose iOS development?
I wouldn't say they weren't a big company in 2010. Sure, they're massive now, but the iPhone had been a huge hit since the very first one. In any case, I didn't care about the size of Apple, I just knew from the very first rumors of an "Apple phone", that it was going to be great. When Jobs introduced the iPhone, I was in love, and I knew I had to get one. It took until the iPhone 3GS until it was available in the Netherlands.

I wanted to develop apps for this device because it was so polished and slick. Everything was fast and smooth, the apps user friendly and well designed... it was so much better than anything before it, it was revolutionary.

### What do you think about Swift and SwiftUI? Do you want to change something in them?
I love Swift! I waited until Swift 3 until I started using it. There were way too may changes in the early Swift versions, I was working on big complex Objective-C apps, I did like Objective-C just fine, so I waited until the right moment to start using it. That moment came in December 2016; I just started working as a freelancer, and I started a brand new project from scratch, so Swift seemed like the obvious choice at that moment.

SwiftUI on the other hand... I love the concept of it, I would love to be able to use it, but it's just not ready yet. I've built a medium-complex side project using SwiftUI 1 when it was just released, and while I loved the initial boost in productivity, that quickly turned to annoyance as I spent way waaaaay too much time working around bugs and glitches in SwiftUI itself. Easy things became really easy, but hard things became impossible. I scrapped that side project.

I do have hopes that SwiftUI has gotten better with iOS 15, but unless you build an app for iOS 15+ only, it kind of doesn't matter how good it is now. Realistically I don't see myself using SwiftUI for production for the next 2 or 3 years.

What I'd want to change is for Swift and SwiftUI changes to be usable with older iOS versions. For example Swift's new async/await support is really really awesome. But.. iOS 15+ only. I'd love for Apple to find a way to remove these kind of dependencies from the core OS itself, so that individual frameworks can get updated without a whole major OS upgrade. Same goes for apps like Mail, Weather, Notes, etc. Why are they part of iOS itself? If they were in the App Store like any other app, they could be updated more often with less trouble.

### What resources do you use for work and training?

https://www.pointfree.co
https://www.donnywals.com
https://www.hackingwithswift.com

### Did you have any mistakes, and what would you suggest for the guys from Russia who are just starting to understand iOS development?

Not really a mistake, but I kinda wish I would've jumped on the FRP bandwagon a bit earlier than I did. I never really liked RxSwift (or ReactiveCocoa back in the Obj-C days), it never really clicked until I started using ReactiveKit and Bond back in 2019. I am now using Combine in all my apps since 2020 and I can't imagine going back to the old way of building apps. 

If you're just starting out with iOS development, the number one piece of advice I would give is to not get overwhelmed with all the different architecture options, or wanting to do it "perfect" from the beginning. Just go with MVC, don't care if you end up with massive view controllers or not. Use storyboard with segues if you like those, don't even think about Coordinators yet. Forget about Combine and reactive functional programming. Just start with the basics and have fun! You'll figure out what doesn't scale when you start building bigger and better apps, and you'll search for solutions for those problems as you come across them. But if you want to do everything perfect from the beginning, you're just going to end with analysis paralysis and not doing anything at all.

### What is the future of iOS development?

SwiftUI and async/await. Too bad that future is still a few years off for real world apps where you have to support older iOS versions.

### What are you doing now and what are your plans?

I am working on a project for a client, where I work on the iOS app and the server code as well. I plan to keep having fun as a freelance developer, taking projects that interest me.

I am almost 40 though, I don't know how long I want to keep being a developer, freelance or not. So eventually I might want to focus more on being a mentor, something I really enjoy doing now a few hours a week. We'll see!