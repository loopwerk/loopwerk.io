---
tags: javascript
---

# Researching front end tools, part 2: Deku, page.js and cssnext
Two weeks ago I started my journey into researching front end tools, with the idea to find my ultimate stack of build tools, JavaScript frameworks and/or libraries, CSS processors, a code style to follow and code linter to enforce it, and finally testing tools.

In [my first experiment](/articles/2015/research-front-end-part-1/) I looked into Ampersand.js, React, PostCSS, the AirBnB code style and ESLint. I liked React but wanted something smaller, and didn't really see the need for Ampersand.js if I could find a better router. So for my second experiment the plan was to look into Deku and page.js.

You can find the code for this experiment on my [deku-cssnext-webpack](https://github.com/kevinrenskers/js-skeleton/tree/deku-cssnext-webpack) branch.

### Deku
Deku is pretty similar to React: it's only the UI layer, it uses JSX (optional), it's all about components and virtual DOM diffing. The big difference is the size: not only will it add way less to the payload of your app, the API is also a lot smaller (and much more functional) so it's easier to learn. The app from my first experiment was 141 KB, with Deku it shrunk to 31 KB. That is a huge difference! So what do you loose, compared to React? Deku doesn't support legacy browsers and doesn't have support for animations yet, but other then that everything seems to be pretty much there really. It makes me wonder even more why React is so big.

There are some pretty big downsides to Deku though. First and most importantly, it's not very well documented, there aren't a lot of examples, and the examples that are there are mostly out of date. Then again the API is pretty small so there's not a whole lot to learn, but it definitely needs more than this. I really do hope that they'll improve this soon.

Second is the size of the community, with which also comes the  number of available tools. Stuff like the React hotloader for webpack-dev-server for example. Or how easy it'll be to get answers on StackOverflow. There is a huge community forming around React, people are sharing components and tools, it's very exciting. This is definitely missing from a small young library like Deku.

So which framework would I choose? The small Deku with the much more functional programming style? Or the big React with the huge community and everything that brings? Probably Deku, but I'm not totally sure to be honest. Luckily I don't have to make that decision yet, as I still have plenty more frameworks to look into.

### page.js
I wanted to move away from Ampersand.js and found [page.js](https://github.com/visionmedia/page.js), a small (2.6 KB) client side router with the possibility to map multiple callbacks to a route which I really like. An even bigger win is that it automatically binds the onClick of links so you won't have full page reloads and don't need a weird `Link` element like I needed with Ampersand's router.

### cssnext
I was pretty happy with postcss. I used a couple of plugins and it all worked fine, it behaved a lot like my trusted old Less actually. And then I read the article [On writing real CSS (again)](https://blog.colepeters.com/on-writing-real-css-again/) and it made me want to switch to cssnext to stay closer to "real" CSS. 

The [cssnext](http://cssnext.io) project is really nothing more than a bunch of postcss plugins combined into one easy package. It focuses on the latest (future) CSS syntax, which will become part of the standard some day. I like this idea, to follow a stricter standard compared to Less, Sass or even postcss with all those plugins - like nested rules. Yes, I've been using nested rules a lot until now, but I have noticed that this CSS tends to become big and hard to manage, and I'd really like to try to follow a more [object oriented approach](http://www.smashingmagazine.com/2011/12/12/an-introduction-to-object-oriented-css-oocss/), where descendent selectors are avoided. Switching to cssnext is good first step.

Another very nice effect is that my list of dependencies has shrunk quite a bit and setting it up for webpack has also became a lot simpler.

## Conclusions
* Still very happy with the AirBnB code style and ESLint!
* Page.js is a good replacement for Ampersand's router with some pretty cool features and it's about the same size.
* cssnext is a lot simpler to setup than postcss + a bunch of plugins. It's also more like one standard, you use "cssnext". Compare that with postcss, where you'll never know what to expect because each project can use wildly different plugins.
* And then of course Deku.. It's pretty much the same as React in a lot of ways, just with almost no docs or examples, and no community around it - yet. It sure is small though!

## Up next
I'm not totally sure what I'm going to look into next: either another framework (probably Riot) while keeping the rest of the stack the same, or switch from webpack to browserify while sticking with Deku for now. I only want to change one big thing at the time, so it's easier to see its effect.

Currently I'm leaning towards looking into browserify, also with testing in mind. Using webpack and webpack-only features like CSS imports means that you're locking yourself in and that testing now also has to go through webpack. If all code would just be standard ES6, it could very simply be tested in Node.js without using webpack or browserify or anything, especially when using CommonJS modules. I really like the idea of not locking myself in.
