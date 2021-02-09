---
tags: javascript
---

# Researching front end tools, part 3: Angular & Webpack vs Browserify
Since early 2014 I've been working on a pretty big and complex Angular app called [Sling](http://getsling.com) and sadly it's not using any module system and it's still using ES5 only. It uses Gulp to bundle and minify all the JavaScript, compile and minify our Less files, add Angular injection annotations to our code, start a webserver with live reloading functionality, watches the source for changes and so on. It actually works really well but after doing the [previous](/articles/2015/research-front-end-part-1/) [two](/articles/2015/research-front-end-part-2/) experiments that use modules, ES6 and webpack I got a little bit tired of looking at this old fashioned project 😀.

So, for my third experiment I wanted to combine Angular with Webpack, mainly to see if this is something we can use for our project at work.

### Angular
I already have about one and a half years of experience with developing a big single page app in Angular so this experiment wasn't about looking into Angular itself. It was more about how it works together with modules, ES6 and Webpack. In case you have no idea what Angular is: it's a big framework that offers almost everything you need out of the box. Big features are its dependancy injection and extending the HTML language with new tags and attributes via directives. It's kind of the opposite of React and Deku in a way, where the JavaScript generates the HTML: with Angular the HTML drives the JavaScript. To me that always felt as a very nice and natural way of doing things, and I still like Angular a lot.

On the other hand, it's pretty damn big and if you're not careful you can run into some pretty big performance problems. But of course this is possible in any framework and really in Sling we never ran into problems that we couldn't solve.

The biggest problem with Angular for me is that version 2 is coming soon(ish) and won't offer an easy migration. These front end experiments are all about "what would I use if I had to start a brand new project", and I simply wouldn't use Angular 1.x because it's basically end-of-life. But like I said, this experiment wasn't about finding that out.

### Webpack
Just as I concluded in my [first experiment](/articles/2015/research-front-end-part-1/), Webpack is a bit of a blessing and a curse. Very cool features but that config.. it's good that there are some good examples to copy from because I would never be able to come to this config just by using their documentation. It still feels like a magic black box to me, although at least I understand the loaders, how they work and what they allow me to do (like importing CSS and HTML templates).

The big question is if I would switch Sling to use Webpack. The config is done, it works, so why not? On the other hand it would be great to have a build system that the entire team would understand. With that in mind I immediately dived into my fourth experiment: replacing Webpack with Browserify.

The code for this version can be found in my [angularjs-webpack branch](https://github.com/kevinrenskers/js-skeleton/tree/angularjs-webpack).

### Browserify
Because of the complexity of the Webpack config I really wanted to replace it with Browserify and see what that would be like. You view find the result in the [angularjs-browserify branch](https://github.com/kevinrenskers/js-skeleton/tree/angularjs-browserify). I can only describe this process as yak shaving or falling down the rabbit hole.

1. I started with using NPM scripts simply executing Browserify: take an input file, write it somewhere else.
2. Rebuilds were very slow though, so then I looked into Watchify. This works a lot better, so now I had 2 run scripts, one for building a bundle for production and one that kept watching for changes.
3. Using a CSS transform for Browserify worked fine so I could import CSS and have it rebuild on changes (via Watchify) too. However, I could not figure out how to extract the CSS into its own external stylesheet, so I decided to no longer import the CSS file in my JS controllers, but instead simply use Less and have that build a single external CSS file.
4. Less doesn't a have watch mode so I had to use more packages  and another NPM script to watch for changes, build the CSS, and in production minify as well.
5. Then I started thinking about auto reloading the browser on file changes as well as how to create the JS and CSS bundles with unique filenames (with a hash or package.json version or something to bust the browser cache) and it all became a bit too much to figure out. All of this stuff that simply worked with my Webpack config were now all separate pieces that had to work together and I couldn't figure out how to get it working (at least not within one weekend) so I gave up on the idea of not using Gulp.

So, now I've introduced Gulp to the mix. Watching JS and Less, using Browserify and Watchify, starting a web server that reloads the browser on changes, building production bundles with unique hashed names.. I got it all working! But instead of a 144 line Webpack config file and 22 packages (including Angular, ESLint, Bootstrap etc) I now have a [141 line gulpfile](https://github.com/kevinrenskers/js-skeleton/blob/angularjs-browserify/gulpfile.js) and 36 packages. And I'm still not requiring CSS from my JavaScript code.

And is this gulpfile easier to understand for my team than the Webpack config? I seriously doubt it. We're depending on more packages, so that means more chance of things to go wrong in the future as well.

## Conclusions
As far as Angular 1.x is concerned I already knew that it wasn't a contender in my "find my next library or framework" search. I still like it a lot, but I think switching to Angular 2 or something completely different simply makes a lot more sense.

That brings us to Webpack versus Browserify. Of course it's only a very simple project that I was testing with, I don't really know how Webpack'll hold up as soon as you introduce non-CommonJS dependancies (from Bower) for example, whereas I know that Browserify has a debowerify transform. Note to self: I should really look into this!

But for me I really like that Webpack, once configured, works beautifully with less dependancies and offering more features to boot. I think it's where the community is moving to as well, with good reason. I just wish their documentation was better so I would feel safer about introducing this to the rest of the team. I'm definiltey going to introduce it though, I think everyone will get pretty excited about using proper modules and ES6 (and won't even care if it's powered by Webpack or Browserify and Gulp anyway 😀)!

## Up next
I really want to look into unit testing. If I stick with Webpack, which seems very likely, how does that work with testing? And I should also look into using Bower packages, since there is a TON of good stuff not on NPM, especially for the Angular ecosystem.

Stay tuned!
