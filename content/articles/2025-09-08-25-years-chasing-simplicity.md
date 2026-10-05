---
tags: insights
summary: 25 years of building for the web, and why I keep choosing simplicity.
---

# A quarter century of chasing simplicity

When I was seventeen I moved to a student flat in Groningen, where I shared a floor with 14 other people. One year later, in 2000, I created my first website, for our floor, with information about each student living there. It was built in Flash, with all kinds of silly animations. It was so much fun, and I was hooked.

Twenty-five years later I am still building for the web, though a lot has changed in that time.

## The age of innocence

I got my first real job in 2001, as a sysadmin at the University of Groningen. While I was managing Windows workstations and a few Debian servers, the real magic was happening next to me: my colleagues were building dynamic websites in PHP.

By this time my Flash website was now a collection of 15 static HTML pages, and every time I wanted to change the navigation menu, I had to edit all 15 files by hand. A colleague heard me complain about this and showed me a single line of PHP:

```php
<?php include 'header.html'; ?>
```

This one line was literally the beginning of my career as a developer. I spent every free moment digging through the PHP docs, and started using more and more PHP in my silly site. Eventually I created my own framework and CMS (didn't we all in those years), which turned into a huge Insane Clown Posse fansite, which I ran for five years.

Back then, building websites was pure joy. And it was so simple! PHP and HTML, a bit of MooTools, Prototype.js, and eventually jQuery. Deploying was as simple as dragging the files onto the server using SFTP, later replaced by `cvs update`.

I'm really lucky I got started in the early 2000s. PHP was quite simple but plenty powerful to build serious things, HTML, CSS and JavaScript could be learned by simply inspecting a site's source code, and deploying was very simple. I think the barrier to entry to becoming a paid web developer was a lot lower back then.

## Things got complicated

Sadly, things didn't stay this simple. In 2009 I moved from PHP to Python, where deploying wasn't as simple as just updating some files. But the real big change was on the frontend side: ES6, CommonJS, Babel, Webpack, npm... It felt like it came all at once.

Yes, JavaScript as a language was improving, but the tooling and its complexity exploded. I swear that the `webpack.config.js` file in my Angular project became sentient at some point. Even the simplest Hello World app in the framework of the week pulled in hundreds of megabytes of dependencies. And it got so fragile too; dependency updates broke the site half the time.

Deployment became a mysterious black box handled by CI/CD pipelines built by a separate DevOps team. I no longer understood and owned the whole development and deployment process like I used to. It felt like a step backwards.

Luckily it seems like things are moving in the right direction. I haven't needed Babel or Webpack since forever. We now have TypeScript, and frameworks like Svelte and SvelteKit, which brought back joy to making websites, which I had lost during the Angular / Babel years.

Then came htmx, allowing us to build multi-page server-rendered apps again without a build step, just like in those early days, but without the full page reloads and jQuery spaghetti. More and more developers recognize the need to bring back simplicity, and with it the joy.

And the deployment story got so much better as well. There are plenty of affordable hosting providers which build your code when you push changes, and of course there are the self-hosted options like Coolify, my weapon of choice.

## Keeping it simple

Time is a circle, and that holds true for technology as well. We go from simple to complex, and eventually back to simple again. But the return to simplicity isn't permanent, you have to work hard to keep it because if you don't, complexity always creeps back in.

I follow a few simple rules to aid me in this fight.

1.  Keep it simple. As the chef Marco Pierre White says, "Perfection is lots of little things done well", and "Consistency is born out of simplicity". That clever Python one-liner will be unreadable to my future self tomorrow. Don't over-engineer. The chances we'll need to scale to millions of users are almost zero, so think twice before introducing layers of abstraction and micro-services.
2.  Increase locality of behavior. Code is easier to understand and keep in my head when related logic, markup, and styles live close together. That's why Svelte files feel right, and why TailwindCSS makes sense to me.
3.  Less is more, especially when it comes to dependencies. Every dependency is a moving part I don't control, a ticking time bomb of breaking changes.
4.  Tend the code like a garden. Technical debt and code rot are absolutely real, so prune those old functions, cut dead styles, and rebuild messy parts before the project becomes unmaintainable.

If you have a project that could use a reintroduction of simplicity and better maintainability, please reach out and I'll be happy to help.
