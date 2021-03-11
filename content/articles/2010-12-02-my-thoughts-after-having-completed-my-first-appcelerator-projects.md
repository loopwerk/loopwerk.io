---
tags: iOS
---

# My thoughts after having completed my first Appcelerator project
A while ago I set out to build my third mobile application. Only this time the client wanted not only an iPhone app, but one for Android too. So that's why I [turned to Appcelerator](/articles/2010/once-again-i-turn-appcelerator/) once again, after my [failed first attempt](/articles/2010/getting-started-iphone-app-development/).

In case you don't know what Appcelerator is and don't want to read the previous articles, I'l explain it in a few words. Appcelerator is a cross-compiler: you write your app in Javascript using a strict API, and this app is then compiled to both iPhone and Android versions. These apps are truly native apps and use native widgets, tableviews, etc. Sounds pretty good, right?

Well yes. A bit too good actually. While you get a working skeleton app very quickly that does indeed compile to both iPhone and Android, there are quite some disadvantages.

* You can only use the Appcelerator API to build the interface of your app. If they don't support feature X, you're pretty much out of luck. In theory you can build native extensions that can then be used from within your Appcelerator app, but in practice this kind of defeats the purpose and requires you to still know Java and/or Objective-C.
* Even though Appcelerator tries very hard to keep up to date, it is always a bit behind in terms of features offered by the native SDKs.
* Debugging is a lot harder if you are used to Xcode's excellent tools.
* Performance on Android is less than stellar. Real native apps perform better, especially when you try to use a tableview containing images.
* I miss Interface Builder! Of course this is only valid for native iPhone development, but I guess Eclipse for Android development is better for laying out interfaces too. With Appcelerator you have to lay everything out by hand, using absolute pixel-positions.
* Making an app that is complicated in terms of interface is very hard in Appcelerator. I've never seen the 80/20 rule (the last 20% of work takes 80% of your time) in effect as clear as when developing with Appcelerator. Starting with your project is very nice, very quick. And then everything kind of grinds to a halt while you "fight the API" to make it do what you want.
* Even though you can compile your app to two different platforms with the click of a button, it is never as easy as it sounds. Some widgets are only supported on one platform, so in your code you tend to get quite a few `if platform == "iPhone"` statements. You still have to do a lot of work twice.
* And last but not least: normally your iPhone app can be made into an iPad app as well, with only a fairly small amount of work. With Appcelerator this is not possible: as far as I can tell, you need to build it as a separate app.

After having completed my first Appcelerator app, I have come to the conclusion that it is nice for pretty simple, low-profile apps. The advantage of building your app once with Javascript simply outweighs the disadvantages. However, as soon as you want to do complicated things, need better performing apps or when quality is very important, I would never use Appcelerator. Let's say that building an iPhone app would take 100 hours and building the Android version would take another 100 hours. Using Appcelerator to build both apps would instead take 150 hours. That's a nice 25% reduction, but my feeling is that you would never get the same quality.

In short, if the budget allows for it, building two native apps will result in higher quality apps. That's why we at [Goldmund, Wyldebeast & Wunderliebe](http://www.goldmund-wyldebeast-wunderliebe.com/) are now training two people in building Android apps, and one developer will join me in developing native iPhone apps.
