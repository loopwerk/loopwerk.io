---
tags: faq, iOS, swift
summary: Resources for learning Swift and UIKit, what to build first, opinions on Unit Testing, and more.
---

# Mentee Question 2: How to get started
In this article I'll go over a few questions I've received from my mentees and a few other people via Twitter, all centered on the idea of "how to get started."

## "How do I get started with iOS development?"
Great news, there are a ton of free resources on the internet for learning iOS development! From articles to free courses and books to videos, tutorials and references. No matter how you prefer to learn, there's free content out there for you. Here are some resources which I recommend:

### [100 Days of Swift](https://www.hackingwithswift.com/100)
An amazing free course using articles and videos. It first teaches you all the basics of Swift itself and after 12 days you'll be building multiple iOS apps with UIKit. You'll touch on everything you need to know as an iOS developer. Can't recommend it highly enough.

### [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui)
Rather learn SwiftUI than UIKit? I would actually recommend learning UIKit first (see [this article](/articles/2021/faq-uikit-vs-swiftui/) for my reasons), but this course is *the* best resource for learning SwiftUI if you want to.

### [CS193p](https://cs193p.sites.stanford.edu)
Stanford University has been teaching iOS development for a long time now, and since spring 2020 the course focuses on SwiftUI. The videos are available on YouTube which is really handy! Its older course, focusing on UIKit and iOS 11, is still available on [iTunes U](https://itunes.apple.com/us/course/developing-ios-11-apps-with-swift/id1309275316).

### [Swift By Sundell](https://swiftbysundell.com/basics/#filter)
John Sundell writes very high quality articles about all things Swift, and his series of Basics articles is highly recommended when you're getting started and want to read more about things like properties, protocols, optionals, enums, and much much more.

### [Apple's Getting Started guide](https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/index.html)
The official guide from Apple. I never went through it myself so I can't tell you how good it is, but it's definitely nowhere near as complete as [100 Days of Swift](https://www.hackingwithswift.com/100).

### [Apple's SwiftUI tutorial](https://developer.apple.com/tutorials/SwiftUI)
The official SwiftUI tutorial from Apple, 4.5 hours of videos teaching you the basics. Very slick and well made content.

## "What should I build first?"
So you've learned the basics and are ready to build your first app. What should you build first? Easy: whatever you *want* to build! Preferably an app that you would actually use yourself, so if you have an itch to scratch, build that. If you have no ideas on what to build, I would recommend to build a todo app. They're not too complex as to be overwhelming, but complex enough to really teach you a bunch of things on the way. You'll need to build a list of todos, a way to add, edit and delete them, a way to store them between app starts, maybe a detail view to look at individual todo items. It's just big enough that you can play around with multiple architectures as well.

## "What architecture should I use?"
At first, I would just keep it simple and stick to MVC. Focus on building the UI, moving from one screen to the next, dealing with state — it'll be enough to keep you busy for some time. After that, look into MVVM and, if you're using UIKit, Coordinators which will decouple your view controllers from one another and improve the way you can test your code. But if you worry about "getting everything perfect" from the very beginning (something I heard from multiple mentees), you'll never get started and instead keep reading more and more articles about all kinds of architectures and their pros and cons. So, just get started, keep it simple, keep it small, and on the way you'll learn what works well for you and what you want to improve on.

## "What and how should I test?"
Here's my (possibly controversial) opinion: I wouldn't worry about it at first. While you're still learning to write iOS apps, just focus on that, and test them manually in the simulator. You won't be writing mission-critical apps just yet, most likely. Later on when Swift comes more natural and you feel like you can build basic apps without looking up everything all the time, that's a great time to start to look into testing. Or when you want to start applying for jobs, that's the time to get started with tests.

There are a few types of test: unit tests, UI tests, integration tests, snapshot tests, and they all have their uses and drawbacks. Start by testing important logic using unit tests, and with important logic, I do really mean only the important bits. For example when you make a network request to fetch some articles from a server, decode them using the built-in Decodable protocol and then sort them by date and limit them to the newest 5 articles, the only important bit is that sorting and limiting. You don't need to test Apple's networking and decoding code, Apple does that. You don't want to do the actual network request in your test either; the test would fail if the website is down or if you don't have internet. So if you extract the "business logic" of sorting and picking the top 5 articles into its own function that simply takes an array of articles and returns a modified array of articles, that's something you can easily test.

Start by testing your models, your view models (if you have any), "manager" or utility classes: extract the important logic into pure functions where possible (simple functions that take input as parameters and return output and have no other side effects), and test those. Skip your views and view controllers for now, test your layouts and transitions manually in the simulator until you're ready to look into the other kinds of tests. But don't feel like you need to learn everything right away!
