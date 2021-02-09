---
tags: review, iOS
---

# Review roundup: iOS debug tools and inspectors
All of a sudden it seems there's a big effort to create debugging tools for iOS developers. Some are free, they all have different features... Time for a comparison.

## PonyDebugger
"Remote network and data debugging for your native iOS app using Chrome Developer Tools." Free on the [PonyDebugger repository](https://github.com/square/PonyDebugger).

![Network traffic in Chrome Developer Tools](/articles/images/ponydebugger.png)

### Features
- Debug network traffic
- Core Data browser
- View hierarchy debugging
- Remote logging

### Installation and usage
The iOS framework and its dependencies can be installed via Cocoapods, just add `pod 'PonyDebugger'`. You will also need to install the gateway server (one command in your terminal) and then start it via `ponyd serve --listen-interface=127.0.0.1`.

Now that the gateway server is listening, it's time to connect. You first need to add a bunch of code to your app delegate:

```objc
PDDebugger *debugger = [PDDebugger defaultInstance];
[debugger connectToURL:[NSURL URLWithString:@"ws://localhost:9000/device"]];
[debugger enableNetworkTrafficDebugging];
[debugger forwardAllNetworkTraffic];
[debugger enableCoreDataDebugging];
[debugger addManagedObjectContext:self.managedObjectContext withName:@"My MOC"];
[debugger enableViewHierarchyDebugging];
[debugger enableRemoteLogging];
```

When you then start the app on your device or on the simulator, point Chrome to http://localhost:9000/ and you can use the inspector to debug your app.

### Verdict
I'm not a big fan of adding all that code to my app delegate, but once that's done it's very easy to use PonyDebugger. I do like that it's using Chrome as the debugger, as its network inspector is very good. This then is also the best feature of PonyDebugger: the network inspector. That said, the [Charles Web Debugging Proxy](http://www.charlesproxy.com) is less hassle to setup, especially when using the simulator.

I found the view hierarchy inspector to be useful at times, but not at all user friendly to use. The Core Data browser is quite nice, while I question the usefulness of the remote logging feature.

Since PonyDebugger is free, I would recommend it, especially for the network traffic debugger.


## Spark Inspector
"Monitor your app and experiment in a way you never thought possible." About $30 on [sparkinspector.com](http://sparkinspector.com).

![Spark 3d visualization](/articles/images/spark.jpg)

### Features
- View hierarchy debugging via a 3d view of your interface
- Change view properties at runtime
- NSNotification monitor

### Installation and usage
Once again the iOS framework can be installed via Cocoapods, scoring points already. Just add `pod 'SparkInspector'`. You will also need to download their client app. Once you've started their client, you can start your app on your device or in the simulator and it works. No need to add any code at all.

### Verdict
If you need to debug your view hierarchy there's no question that Spark's 3d interface is a million times more useful and user friendly than the PonyDebugger solution. The ability to change view properties and see the results in real time is the real winner, it's very very easy to quickly try out different sizes, content modes, background colors, etc.

Being able to monitor all notifications (and even resend them) is very handy as well, but not something I would use all that often.

No idea why they didn't include a network monitor though, as that is what needs most debugging, at least in my apps.

All in all a very good, easy to integrate solution when you need to do a lot of UIView debugging or need to monitor notifications. The price is fair, just wish they added network monitoring as well.


## Reveal App
"Reveal brings the power of tools like Firebug and Web Inspector to iOS developers. See your application's view hierarchy at runtime with advanced 2D and 3D visualizations. Debug view layout and rendering problems in seconds." Free beta, available from [revealapp.com](http://revealapp.com).

![Reveal 3d visualization](/articles/images/reveal.jpg)

### Features
- View hierarchy debugging via a 3d view of your interface
- Change view properties at runtime

### Installation and usage
You download their client application, which also includes the framework you need to add to your iOS app. Simply drag the framework into your project, run your app and you're connected to Reveal - no code changes necessary. You can also install the framework via Cocoapods: `pod 'Reveal-iOS-SDK'`.

### Verdict
Reveal basically took Spark's 3d view inspector and added a bunch more properties that can be edited (like accessibility related properties) and other that can be viewed but not edited (like CALayer properties). I don't like their UI as much as Spark, but the added properties are incredibly useful: testing the VoiceOver feature is a lot easier now.

One minor problem I had with Reveal was that it doesn't automatically update the inspector like Spark does: when I switch views in my app, the inspector should be able to automatically update as well. It's not a deal breaker though.

If you don't need Spark's notification monitor and can live with the uncertainty of using a "free beta" product (no idea what's it going to cost later on), then I would recommend Reveal over Spark.

Once again though, I just wished they added a network traffic monitor.
