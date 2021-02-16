---
tags: iOS
---

# Getting started with iPhone app development
For a pretty long time I wanted to make an iPhone app, ever since the App Store opened really. But, I've never programmed for Mac OS, never done any C or C++ (let alone Objective-C). In fact, I've never created a desktop application, only working on web applications and websites in PHP and Python.

I found it pretty tough to get started with XCode, Interface Builder and Objective-C. And without a good idea what to actually make for the iPhone, morale to learn all this was pretty low. The turning point came last week, when my company decided they wanted to create an iPhone app for a client, and wanted me to get on it. Thankfully, there is no deadline, so I can tinker in peace. I now had a project to sink my teeth in, and a reason to really get going.

## Trying to ignore Objective-C

After looking at some tutorials, I decided that I didn't like Interface Builder and Objective-C all that much. I came across two tools that let you write applications in javascript and/or html and css, and decided that this was the way forward. These tools are:

[PhoneGap](http://www.phonegap.com/), allowing you to use html, css and javascript to create native applications. Basically PhoneGap is just a mobile website inside a native iPhone container, with access to native functions like maps, contacts, multi touch, etc. Very easy to use, but it still kinda looks like a mobile sites (which in fact, it is).

[Appcelerator Titanium Mobile](http://www.appcelerator.com/), which gives you a javascript API for creating real native elements on screen. You won't use html or css, everything is done with their APIs. Of course, applications created with Titanium have full access to all native functions too.

After looking at PhoneGap for about a day, I decided that it wasn't good enough for creating "native feeling" applications and downloaded Titanium instead. Getting started was easy enough, and you really do create native applications that even compile for the Android platform too. However, poor documentation and paid support costing $200 per month made progress slow as I wanted to do more complicated things.

## Embracing truly native apps

Apple then changed section 3.3.1 of the developer agreements, now forbidding cross-compilers: _"Only code written in C, C++, and Objective-C may compile and directly link against the Documented APIs (e.g., Applications that link to Documented APIs **through an intermediary translation or compatibility layer** or tool are prohibited)."_

While Appcelerator is optimistic about its chances to still be allowed by Apple, I am not so sure. This meant that I really needed to learn Objective-C after all. After looking into many tutorials and manuals, I finally found some resources that really helped me. I hope this list will help you too! I would advice using these resources in this order.

* [C tutorial for Cocoa](http://cocoadevcentral.com/articles/000081.php), a small introduction into basic C. Turns out, it looks a lot like PHP.
* [BecomeAnXcoder](http://www.cocoalab.com/?q=node/5), a free e-book with a good introduction to Objective-C, with no previous C knowledge required. Understanding Object Oriented programming really helps though.
* [Learn Objective-C](http://cocoadevcentral.com/d/learn_objectivec), also from the excellent site [cocoadevcentral.com](http://cocoadevcentral.com/). Goes deeper into some subjects as compared to the BecomeAnXcoder e-book.
* [iPhone Application development (winter 2010) on iTunes U](http://deimos3.apple.com/WebObjects/Core.woa/Browse/itunes.stanford.edu.3124430053). Stanford University gave lectures on iPhone development back in January 2010. They are recorded on video and available for free on iTunes U. Not always easy to follow (you should really read the 3 links above first), but packed with information and an introduction to the assignments you will need to do.
* [The assignments for the Standford courses](http://www.stanford.edu/class/cs193p/cgi-bin/drupal/downloads-2010-winter), do them after watching a lecture on iTunes U. This is a really big help for me! These assignments are the best tutorials you could wish for, showing you where to find information in the official Apple documentation and then you get to use it in the assignment. Much better than just watching video's. Learn by doing!
* [Help with the assignments](http://www.iphoneosdevcafe.com/category/cs193p-winter-2010/), on iphoneosdevcafe.com.
