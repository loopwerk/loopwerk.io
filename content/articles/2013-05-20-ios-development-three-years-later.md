---
tags: iOS
---

# iOS development: three years later
In April 2010 I [started to work](/articles/2010/getting-started-iphone-app-development/) on my very first iPhone app. A new language, a new IDE, a completely new way of thinking about development (threads! memory! crashes!), it was very exciting. In these three years quite a lot has happened to us iOS developers. Yes, we still complain about Xcode from time to time, but everything is better and easier to do, with less code to write.

The biggest advances for me as an iOS developer in the past three years, in order of impact it makes every day, were:

## ARC
When I just got started with iOS development, I came from the web world. Nine years of PHP and six months of Python, a lot of Javascript, some Ruby… never having to think about memory management. And now all of a sudden I had to increment and decrement reference counts on objects. Retain and release, oh how you confused me. This was definitely the biggest hurdle for me, and the source of quite some crashes. Thankfully iOS 5 brought Automated Reference Counting, or ARC, doing all this work for you. Definitely the biggest improvement with the biggest impact.

## Xcode 4
Remember the days of Xcode 3? When every update meant you needed to download 1.5 gigabytes? And Interface Builder was a separate app? We've come a long way for sure. These days Xcode is distributed via the Mac App Store, and updates are only tens of megabytes. Installing the updates still take forever and still need iTunes to be closed, but at least it's no longer using all my bandwidth for the month.

A much more welcome change was the integration of Interface Builder into Xcode. The ability to drag connections from your interface straight to your code is amazingly handy and is saving me quite a lot of time every day.

## Auto synthesized properties
It might not be the most amazing "new" thing from the past three years, but I love it that I no longer need to create a property, its backing instance variable and then to also `@synthesize` it. Now one `@property` line is all it takes. Another welcome time saver.

## Modern Objective-C
I have always hated this:

```objc
[NSDictionary dictionaryWithObjectsAndKeys:object1, @"key1", object2, @"key2"];
[NSArray arrayWithObjects:object1, object2];
```

Instead, now we have these shortcuts:

```objc
@{ @"key1": object1, @"key2": object2 };
@[ object1, object2 ]
```

Add some other handy ways to access objects within dictionaries and arrays, and quicker ways to create NSNumbers objects as well, and this is a really nice update to the Objective-C language. But wait! There's more! Blocks. Kind of amazing really that we didn't have blocks before, they take away so much delegation mess. For me, all framework classes should support block based operations.

## Storyboards
The idea of having all your screens in one storyboard file with all their relationships clearly defined is very neat, but sadly completely impossible when you work in a team. The storyboard file can't be merged, so when one developer is working on one of the screens and you're working on another screen in the same storyboard, you have a big problem. All the work from one of the developers will most likely be lost. Apple, when's this going to be solved?

Still, we use storyboards, but split them up across multiple files: one storyboard per scene. This way we can all work simultaneously on different parts of the app. The big advantage over good old xib files? Prototype cells! When you're working with UITableView or UICollectionView, it's so much better to have your cells' design directly there in the storyboard. A major time saver, and I never want to go back, even if I don't use any other storyboard feature.

## UIAppearance
It used to be so damn hard to customize standard UI controls, and of course some clients always demanded customization. Luckily we now how UIAppearance, solving most of the clients' needs.

## UICollectionView
Grids (mostly used on the iPad) used to be a pain in the ass to create. Yes, there were some third party libraries that helped, but none were super good and of course you didn't have Interface Builder integration. iOS 6 changed all this, finally adding collection views. A huge shout out should go to the incredible [PSTCollectionView library](https://github.com/steipete/PSTCollectionView) which backports all this goodness to iOS 5. Seriously, check it out.

## Auto Layout
Never used it in any app yet, since our clients still need iOS 5 support. Of course I've played around with it, and while it seems quite cool and powerful, it's also a lot more complicated than the simple struts and springs system. I don't see myself adopting Auto Layout any time soon.
