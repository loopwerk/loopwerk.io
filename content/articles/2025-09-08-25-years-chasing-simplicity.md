---
tags: personal
summary: A reflection on 25 years of web development, from simplicity to complexity and back.
---

# A quarter century of chasing simplicity

Twenty-five years ago, in 2000, I built my first website. It was for me and the 14 other people on the student floor I lived on, it was made in Flash, and it was full of silly animations. It was fun, utterly unmaintainable, and I was hooked. Twenty-five years later, I'm still building for the web, but the journey from that Flash playground to today has been a bumpy road through simplicity, overwhelming complexity, and finally, a deliberate return to simplicity.

## The age of innocence

My professional journey began in 2001 as a sysadmin at the University of Groningen. While I was wrangling Windows workstations and a few Debian servers, the real magic was happening next to me: my colleagues were building dynamic websites in PHP.

By this time my Flash website was now a collection of 15 static HTML pages. And every time I wanted to change the navigation menu, I had to meticulously edit all 15 files. It was a nightmare! Hearing about my struggle, a colleague showed me a single line of PHP that would change everything: 

```php
<?php include 'header.html'; ?>
```

It was like magic to me. With this one function, my tangled mess of duplication vanished. There was no turning back. I spent every free moment digging through the PHP docs, and by the time I left my sysadmin job in 2003, I had transformed into a junior developer, thanks to that initial small discovery and the patient mentorship of colleagues.

Back then, building websites was pure joy. The stack: PHP + HTML, with a sprinkle of MooTools, Prototype.js, and later on: jQuery. The deployment: drag files into an SFTP window, or later, a quick `cvs update` on the server. You could go from idea to online in minutes. The barrier between writing code and sharing it with the world was almost non-existent.

## Welcome to the build step

But things didn’t stay simple.

JavaScript libraries started multiplying, and I started using Angular. Suddenly I was building Single Page Apps and the backend (Python instead of PHP by 2009) was reduced to a JSON API. And for the first time, I needed a build step. My simple workflow of “edit file → reload browser” was gone.

Then came the real tidal wave: ES6, CommonJS, Babel, Webpack, npm. JavaScript as a language was improving, but the tooling exploded. My `webpack.config.js` became its own mini-project. The `node_modules` folder turned into a black hole of dependencies. Even the simplest “hello world” app pulled in hundreds of megabytes. And it was fragile too; half the time a fresh install broke the build because of some upstream change.

Deployment became a mysterious black box handled by CI/CD pipelines built by a separate DevOps team. The directness was gone, replaced by layers of abstraction and fragility. Progress didn’t always feel like progress.

## Back to sanity

Eventually, the pendulum swung back.

TypeScript brought sanity to JavaScript. Svelte and SvelteKit made complexity vanish into the background, giving me the power of modern frameworks without the headaches of endless configuration. Writing code felt fun again.

Then came htmx and Alpine AJAX. Suddenly I was back to building multi-page apps without a build step, just like in the early days, but now with smooth interactivity. It felt almost old-school, but in the best way.

When it comes to deployment, I’ve seen it all over the years:

1.	SFTP (the beginning)
2.	A complex deploy process built by specialized DevOps people (a black box to everyone else)
3.	Heroku (easy, but expensive and a lack of control)
4.	`git pull` on a bare-metal server (full control but so complex to get everything running correctly)
5.	GitHub webhooks running a deploy script on that bare metal server (automation!)
6.	Coolify (the sweet spot: self-hosted, automated, free, and simple)
	
Push to GitHub, and it’s live. I think the deployment story is still too complex when it comes to Python apps, but with Coolify it got so much better than anything I’ve had before.

## The lessons learned

A quarter of a century later, I see the pattern clearly: technology cycles from simple to complex and back to simple again. But the return to simplicity isn't automatic. It's a choice. Left unchecked, complexity will always creep in, and you have to actively seek out and defend simplicity. The best tools are the ones that get out of your way, letting you focus on the creative act of building rather than wrestling with the machinery. 

My 25-year journey has crystalized a few truths. If I could share the lessons from all those years with a new developer, they would be these:

1. **Keep it simple.** This applies everywhere. As the chef Marco Pierre White says, “Perfection is lots of little things done well”, and "Consistency is born out of simplicity”. A clever one-liner might feel smart today, but it will be unreadable to your future self or a teammate tomorrow. Don't over-engineer. The chances you'll need to scale to millions of users are slim; build for the problem you have now, not the one you might have in five years. Keep it simple.
2. **Just start building.** Don’t worry about the perfect architecture. Just get started, doing it in a way that you know how to do. Don’t even worry about organizing code into separate files yet, if you’re not sure how to do so. It’s so much more important to get your hands dirty, and get the code flowing. You will naturally discover what works and what doesn’t, and you will find the patterns to organize your code.
3. **Practice practice practice.** The quote from Bojack Horseman is perfect: “It gets easier. Every day it gets a little easier. But you gotta do it every day — that’s the hard part. But it does get easier.” This is the soul of becoming a great programmer. You will understand that framework. You will master that language. You just have to keep going and dedicate yourself to the craft.
4. **Tend your code like a garden.** Code is not a static artifact; it's a living system. It needs trimming and regular maintenance, or it will be overgrown with weeds. Technical debt and code rot are a real things! Prune old unused functions, weed out those dead styles and images, refactor that messy class. A little bit of cleanup regularly prevents the project from becoming an unmaintainable wilderness.
5. **Automate the arguments away.** Debates over the placement of curly braces or variable naming conventions are a waste of creative energy, especially on a team. Pick a code style, use a formatter like Prettier or Ruff, and set it to run automatically on commit. This eliminates an entire class of pointless pull request comments and lets everyone focus on what actually matters: the logic.
6, **Less is more**, when it comes to dependencies. Fewer moving parts mean fewer surprises, easier upgrades, and code that remains understandable years later.
7. **Increase locality of behavior.** Code is easier to understand when related logic, markup, and styles live close together. The more you have to jump between files to see how something works, the harder it is to grasp the whole picture. That’s why I like Svelte files, where everything for a component lives in one place. It’s why TailwindCSS makes sense to me, because styles stay next to the elements they affect. It’s why Alpine and htmx feel so natural, with behavior declared inline. Keeping things local makes it immediately obvious what’s happening, instead of requiring knowledge of external files and hidden connections.

After all this time, I still find the most joy in the moments when things are simple, direct, and fun. Just like when I first discovered the magic of `include`.