---
tags: news
---

# A new (static) website
More than a year ago I was [playing around with static site generators](/articles/2011/playing-around-static-site-generators/) because I wanted to simplify my code and ultimately get rid of my server.

My reasons back then were performance, version control and integration with GitHub. I tried a few generators, but never found one that felt right. Most generators expect me to add metadata to my posts, and I simply don't want to do that. I want my posts to be 100% valid Markdown with no added markup. The title of the article is already in the post (it's the first line, prefixed with a `#`), and the date of publication is in the filename. I don't need categories or tags, so why all this forced metadata crap?

Some generators came close to feeling right, but were written in Ruby. Hacking on them would've taken too much effort for me, I really wanted a system written in Python or Node.js.

In the end I found Felix Felicis (aka [liquidluck](https://github.com/lepture/liquidluck)), a simple system written in Python. It didn't support my style of writing articles in Markdown all the way but came very very close. And it was extremely easy to modify, so now it works exactly how I want it to.

This site itself looks almost like it always used to, it only lost the Twitter sidebar (don't need it), article categories (won't miss it) and comments (good riddance). I'm really pleased with the result: no more Python and Django and complicated code for something that’s quite a simple website. Articles can be kept in git and the site can be hosted anywhere without costing me a cent.

For anyone interested in static site generators, I'd say have a look at [liquidluck](https://github.com/lepture/liquidluck) and the [sourcecode](https://github.com/kevinrenskers/mixedcase.nl) of mixedCase.nl.
