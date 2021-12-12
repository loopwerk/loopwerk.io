---
tags: swift, saga, open source
summary: About ten months ago I wrote that I was confident that the API of Saga wasn't going to change a lot anymore, and that I'd release 1.0.0. Well, it's taken a little bit longer than I expected back then, but 1.0.0 has finally been released!
---

# Saga 1.0.0 has been released
About ten months ago I [wrote](/articles/2021/saga-7-updates/) that I was confident that the API of Saga wasn't going to change a lot anymore, and that I'd release 1.0.0. Well, it's taken a little bit longer than I expected back then, but 1.0.0 has finally been released!

The changes in the last 10 months have been pretty minor:

- I've added unit tests.
- Support for throwing renderers.
- Some small performance improvements and bug fixes.
- And finally, the reason for the delay, I've added support for asynchronous readers and item processing functions using the new async/await syntax.

This does mean that version 1.0.0 and up need Swift 5.5 and only run on macOS 12 (and Linux). If you need to run it on older versions of macOS, please stick with versions 0.22.x.

If you haven't looked at Saga yet, I'd highly recommend it – it's a pretty cool static site generator if I do say so myself. Check it out [on GitHub](https://github.com/loopwerk/Saga), or look at this website's [source code](https://github.com/loopwerk/loopwerk.io).