---
tags: review
summary: A review roundup of a whole bunch of browsers.
---

# It’s 2026 and there’s still no perfect browser

Back in 2011 I asked myself [why there's no perfect browser](/articles/2011/why-there-no-perfect-browser/), in an admittedly pretty terribly written article.

Since then I've almost exclusively used Safari, and mostly it's been good. There's one huge problem though: the longer I work on a website, the more memory Safari eats, until it takes ten seconds just to open the web inspector. So fifteen years after the previous article I decided to revisit this question, and review a bunch of different browsers.

Let's start with a list of features which are important to me, and which I'll use to judge the different browsers.

1. Support for multiple profiles, each with their own cookies, and ideally their own bookmarks. For example when I use a Google Workspace with my work account in one tab, and then I open YouTube in a second tab, I don't want that to use my work account. But switching to my personal Google account there affects that first tab too. So, a browser should have support for profiles with separate cookies. Ideally I can use different profiles side by side in one window, with per-tab containers or by switching profiles in place.
2. Support for the latest and greatest CSS and HTML features. My website uses CSS's brand new [scroll-driven animations feature](https://caniuse.com/mdn-css_properties_animation-timeline_scroll), which until recently was not supported by Firefox, even though other browsers added support between one and three years ago.
3. Privacy features, such as blocking ads and trackers (ideally even within YouTube videos), and a way to hide my email address by generating a temporary one.
4. Bookmark syncing to iPhone and iPad.
5. Access to my passwords and passkeys, which are stored in Apple's Passwords app.
6. And just as important is what's not included: I don't want ads, AI features, or cryptocurrency crap. No bloat, just a browser.

## Safari

This browser ticks all the boxes, plus I like how it looks and feels. For example the two-finger swipes to go back and forth in the history feel so much better in Safari than they do in other browsers.

<video src="/articles/images/still-no-perfect-browser/swipes.mp4" autoplay loop muted playsinline></video>

\*chef's kiss\*

It obviously has the best integration with the rest of the Apple ecosystem. It has native support for Apple Passwords and iCloud's Hide My Email service. It can even read OTP codes sent via email and SMS, and automatically fill them in. Good stuff.

Safari might not have the most extensions, but all the important things are there.

There are some downsides though. I don't love its profiles implementation. Yes, you can create multiple profiles, and each one has its own cookies and bookmarks. But the only way to use different profiles is by opening multiple Safari windows. This means that I basically always have two windows open, one behind the other, and it gets annoying to always switch between them. Per-tab profiles (containers) would solve a lot of this hassle.

Its responsive design tool works and is easily accessible via the Develop menu (once enabled), but when you're mimicking an iPhone it still shows a normal cursor and all mouse-over styles. This makes it harder than necessary to test how a website feels on a mobile phone.

But by far the biggest problem is memory bloat, and the web inspector performance hit that comes with it. The longer you have a website open, especially when you refresh that site a bunch of times, the more memory that tab will eat up. When I work on my website, the site auto-refreshes when I make changes. This can easily happen a hundred times per hour, and the memory usage keeps on growing and growing. And at some point it takes literally ten seconds to open the web inspector. The only way to fix it is to close the site and open it in a new tab.

Safari has the huge ecosystem advantage and it genuinely has the best look and feel, but for web development it's simply not good enough. It got so annoying that about a month ago I stopped using Safari for all web development tasks. It's still my daily driver for everything else though.

## Firefox

Before I started using Safari, in the summer of 2007, I only used [Firefox](https://www.firefox.com/). So when Safari was becoming unbearable for web development work, I turned to Firefox again to fill the role of dedicated development browser.

It still has a lot going for it, like a mountain of extensions. It supports both profile windows and container tabs. And unlike Safari, here separate profile windows open as individual apps in the Dock, which makes switching between them a lot easier.

While Firefox doesn't support iCloud's Hide My Email service, it has its own thing called [Relay](https://relay.firefox.com), which does the same. It's free for 50 forwarded addresses, after which it costs like $1 per month for unlimited addresses, which isn't too bad.

I haven't seen the performance and memory problems that I ran into with Safari, so for web development Firefox has been much better. Its responsive design tool is also a bit better, because it can mimic touches and hide the normal mouse-over styles.

Two-finger dragging isn't as satisfying as in Safari. Instead of dragging a page "off screen", it just shows a small arrow on the edge of the screen. It works, but doesn't feel as good. I also don't like the look of the browser itself, with the pill-shaped tabs and their multi-colored borders.

Sadly Firefox is often slow to adopt new HTML and CSS features, sometimes lagging behind the other browsers by multiple years. They also keep pushing their AI chatbot and VPN, and have enabled a whole bunch of data collection by default. Then there's also the "suggestions from Firefox and our partners in your address bar" setting, which is enabled by default. Sure, everything can be disabled, but it shows that Firefox is on a course that I don't agree with.

## Zen

It's basically Firefox with vertical tabs, and all the AI features and tracking removed. For me its best feature is actually the way that profiles work: instead of having to open a new [Zen](https://zen-browser.app/) window, one per profile, you can simply swipe on the sidebar to switch between the profiles. This is by far the best implementation of profiles that I've seen so far.

I'm not convinced by the vertical tabs though. The sidebar takes up a lot more space than a simple short tab bar, and on my screen I have more vertical space available than horizontal.

Because it's based on Firefox, it gains support for all the same extensions (good) and slow support for new HTML and CSS features (bad). Zen also has no support for DRM, so you can't use it to watch Netflix.

One thing that I am missing in Zen is the "new tab page", which normally shows you your favorites or most recently visited websites. I use this *all the time* in Safari, but in Zen opening a new tab only gives you a small popup with a search slash address bar.

It's a good browser, and I definitely prefer it over Firefox, although the vertical tabs are not my first choice. It won't take over daily driver duties from Safari, because that means having to switch to Firefox on my iPhone and iPad, if I want bookmarks to sync.

## DuckDuckGo

[DuckDuckGo](https://duckduckgo.com/), the privacy-focused search engine, has a WebKit-based [browser](https://duckduckgo.com/app), which out of the box blocks the most ads, cookies, and trackers of any browser I've tried. It was the first one to reliably block ads within YouTube, and just for that I've used it as my second browser for about a year. Yes, just to watch YouTube.

I do love DuckDuckGo's integrated email protection, where you can generate a @duck.com address on the fly, which then forwards to your real email address. It's similar to iCloud's Hide My Email, and Firefox's Relay, but better and free.

It's an okay browser, but it's too limited. You can't switch search engines, which I guess makes sense for a browser made by DuckDuckGo, but I prefer (and pay for) Kagi myself. More than that though, you can't install any extensions. That means no Apple Passwords integration, which is immediately a dealbreaker for a daily browser. And that lovely email protection feature? It's available in Firefox and Chrome (and browsers based on them) using DuckDuckGo's [extension](https://duckduckgo.com/duckduckgo-help-pages/desktop/adding-duckduckgo-to-your-browser).

Even its world-class ad blocking is pretty easily replicated in other browsers. Safari with the [Ghostery](https://apps.apple.com/app/id6504861501) and [Wipr 2](https://apps.apple.com/app/id1662217862) extensions installed now gives me ad-free YouTube, so for me there's no reason left to use the DuckDuckGo browser.

## Orion

Another WebKit-based browser, [this one](https://orionbrowser.com/) is made by [Kagi](https://kagi.com/welcome), the search engine. Its unique selling point is that it can install Safari, Firefox and Chrome extensions, opening up a world of possibilities. It has a mobile browser too, with bookmarks synced between them.

I don't really see the point of Orion over Safari though, when I can just install the Kagi extension in Safari, and enjoy first-party Passwords integration for example. Yes, Orion can install more extensions than Safari can, but I just have no need for that.

## Chrome

It doesn't really need an introduction, right? It's [Chrome](https://www.google.com/chrome/). The browser that supports new web features first, and it comes with easily the best web inspector. I just love the way it makes fonts, colors, and accessibility info immediately visible:

![](/articles/images/still-no-perfect-browser/inspector.webp)
{.shadow}

It also has the best responsive design mode where you don't even get a normal mouse cursor. Instead you get a small circle, mimicking a finger.

Chrome supports profiles, but just like with Safari it's a whole-window affair, and I really don't like the way the two-finger swipes look and feel.

But Google is slowly turning its back on the open web, and they are limiting what extensions in Chrome can do, so that ad-blocking is less effective. There's also the push to put AI into everything, and they really want you to sign into the browser with your Google account, so that they can track literally everything you do on any website.

I simply do not trust Google with my data, and I do not feel comfortable with their browser.

## Helium

It's Chrome, but without all the Google stuff. That makes [it](https://helium.computer/) basically the perfect browser for web development, and I do use it next to Safari.

Helium is pretty basic, for example it doesn't have any bookmark syncing at all, but that doesn't really matter for my dev-only browser. 

Much more important is access to my passwords, which I get via Apple's [Chrome extension](https://chromewebstore.google.com/detail/icloud-passwords/pejdijmoenmkgeppbflobdenhhabjlaj). It gets the job done, but sadly it's a sub-par experience: you need to re-authenticate on every browser start, and it doesn't even suggest strong passwords. I don't really want to switch to a new password manager just to switch browsers though, and for a web development-only browser this is good enough.

## Vivaldi

[Vivaldi](https://vivaldi.com/) is another Chromium-based browser without the Google stuff, but it also includes email, calendar and an RSS reader. It does have mobile versions and a sync service, so it could in theory take over from Safari, unlike Helium.

But I do really like Safari as my daily driver, and if all I need is a second browser for web development, then Helium does the job without the added bloat.

## Brave

Based on Chromium, and it's yet another browser that promises to block a bunch of ads and trackers by default. Their [website](https://brave.com/) makes a lot of persuasive arguments.

But it's also full of AI, crypto crap, and their own "first-party, privacy-protecting ads while you browse". You can get the same ad and tracker blocking in other browsers by installing [uBlock Origin Lite](https://ublockorigin.com/), without the addition of other ads.

## Conclusion

Safari is pretty close to my perfect browser. It ticks all the boxes, it has the best integration with the rest of the Apple ecosystem, and it simply feels the best, down to the two-finger swipes. If it didn't have its memory and performance problems with long-running and often-refreshing websites, I would only use Safari.
 
But because of those problems, I now use two browsers: Safari as my daily driver, and Helium for web development.
 
A challenger to the throne would have to do everything Safari does, plus the things Safari can't, such as Zen's profile switching without needing multiple windows, and Chrome's developer tools. And until that browser exists, there's sadly still no perfect browser.