---
tags: review, iOS, swift
review: Thinking in SwiftUI
rating: 4.5
summary: A while ago I asked on Twitter which Swift-related book I should review next, and overwhelmingly Thinking in SwiftUI by the objc.io guys was chosen. An excellent choice!
---

# Book review: Thinking in SwiftUI
**Thinking in SwiftUI**  
*Chris Eidhof, Florian Kugler*

A while ago I asked on Twitter which Swift-related book I should review next, and overwhelmingly [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/) by the [objc.io](https://www.objc.io) guys was chosen. An excellent choice! It took me a while to read the book but now the review is finally done. A small disclaimer before I start: I already used SwiftUI and Combine a good deal before I read this book, so I can't really comment on what it's like reading this as a beginner. There is also a version of the book which comes with almost five hours of video content, but I have not watched those videos. This review is purely about the ebook.

Okay, with that out of the way; who is the book for, and what is it about? Let me first tell you what the book is *not*: a tutorial teaching you how to create an iOS app using SwiftUI. It's not a reference discussing all the different APIs -- it doesn't even talk about navigation views for example. Instead, the book teaches you how to think in SwiftUI, in this new declarative way. Or, as the book says itself: "The primary goal of this book is to help you develop and hone your intuition of SwiftUI and the new approach it entails." The book is suitable for anyone with some SwiftUI experience, but a complete beginner would be more helped with a tutorial -- I highly recommend the CS193p series from Standford, [available on YouTube](https://www.youtube.com/watch?v=jbtqIBpUG7g), Apple's [own introduction site](https://developer.apple.com/tutorials/swiftui) with videos and example code, or Paul Hudson's [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui). Once you have the basics down though, I do recommend this book to improve your skills. 

Roughly speaking *Thinking in SwiftUI* dives into four areas of SwiftUI: views and layout, state and view updates, the environment, and finally animations.

## Views and layout
Spread out over three chapters, Thinking in SwiftUI discusses everything from view construction, layout logic, and how to build custom layouts using geometry readers and anchors. The book immediately starts off with a deep dive into the real type of a very simple SwiftUI view showing just one button and one text label:

```
VStack<
  TupleView<
    (
      Button<
        ModifiedContent<
          ModifiedContent<
            ModifiedContent<
              Text,
              _PaddingLayout
            >,
            _BackgroundModifier<Color>
          >,
          _ClipEffect<RoundedRectangle>
        >
      >,
      _ConditionalContent<Text, Text>
    )
  >
>
```

I think that will give you a bit of an idea what kind of content to expect. Like I said, this is not for beginners! It's super important to understand *how* a SwiftUI is made though, to know how the order of applied view modifiers impacts what you're seeing on screen. Throughout the book they refer to these kinds of diagrams, and it has helped me a *lot* with understanding why a certain order of things makes a view behave the way it does:

![SwiftUI view diagram](/articles/images/swiftui-diagram.png)

A big part of *Thinking in SwiftUI* discusses SwiftUI's layout system, and in my opinion it's one of the most valuable parts of the book. If you ever wondered why a certain view looks the way it does, or how to replicate a design in SwiftUI, the chapters on layout and custom layout are very good. It explains in great detail SwiftUI's layout system, how views get their frame (size and position), how view modifiers work, how to debug your views. If you want to go further than the average SwiftUI tutorial, I'd recommend the book just for the information about views and layout alone.

## State and view updates
Thinking in SwiftUI does a good job explaining the different state-related property wrappers `@State`, `@Binding`, `@ObservedObject` and `@StateObject`, and which one to use in which situation. It also explains in detail how SwiftUI's view update system works -- helping you write better views that'll perform better (for example, how to prevent using `AnyView` and why that is bad).

What this book doesn't do is teach good practices like using view models, or teach when to use a struct versus a class, which would've been a nice inclusion but to be fair a bit more suitable for a tutorial. When I just got into SwiftUI, I think that dealing with state was by far the most complicated thing to get my head around, it was such a big departure from the way I built UIKit apps. Yes, of course the declarative way you create the views was also a huge departure from the old ways, but I found that a lot easier to adopt, especially since Xcode Previews make it really easy to immediately see what every tiny change does to a view. How to connect your data to those views, that took more time to get comfortable with. I wouldn't recommend to use *just* this book to get more comfortable with state handling.

*(If anyone has a great resource that teaches best practices of state handling in SwiftUI, I'd be happy to link them here!)*

## Environment
The SwiftUI environment is a big piece of the SwiftUI puzzle that touches almost everything. Basically it's used for passing down values down a view tree, which can be view-related things like fonts and colors, but also data (state) and even dependencies. So it goes without saying that understanding the environment is quite important!

Thinking in SwiftUI explains everything from the basics of what the environment is, how to use existing values (defined by SwiftUI) to creating custom environment values, and why you'd want to do that. Dependency Injection has its own section here, which short but sweet. Again it doesn't really teach good practices here and expects you to already know the basics.

## Animations
Animations have never been my strongest iOS skill; most of the (UIKit) apps I've worked on have simply not needed anything more than very basic animations. It's good then that these animations are now much easier to do with SwiftUI, often only needing one single line. *Thinking in SwiftUI* explains the animation system from the very basic automatic (implicit) animations to transitions between views or state to completely custom animations. 

Compared to some of the other chapters I felt that this one was most suitable for SwiftUI beginners.

## Conclusion
As long as you keep in mind who this book is for and what to expect, I whole-heartedly recommend *Thinking in SwiftUI*. Get the basics down first, then dive deep and improve your understanding of SwiftUI and the way you build apps using this book. Especially the chapters on layout are extremely useful in my opinion and well worth the $39 for the book all by themselves. And knowing the quality of past objc.io videos, I would recommend considering the version of the ebook with the five hours of videos, even when it's an extra $40.
