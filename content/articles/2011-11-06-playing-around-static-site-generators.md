---
tags: review
---

# Playing around with static site generators
Even though I'm quite happy with this website and its code, I want to rebuild it using a static site generator: you write your posts and pages with Markdown, write a couple of page html templates, and simply by pushing a new file to Git, your new article is published. 

Of course since everything is then based on static html files things like comments need to be Javascript based, which I don't really like, and searching will need to happened on Google, but the positives are many:

- Performance. Since it's all static html, your site will be able to handle millions of visitors without breaking a sweat.
- Backups. Since it's all in a version control system instead of a database-backed CMS, you always have a backup and versioning.
- Integration with Github. Static sites can be hosted on Github for free. People can also send you pull requests on articles, for example when they find a typo. Github also lets you directly edit files online.
- Easy. I write all my articles in Markdown. It's more work for me to login in a CMS, create a new article and paste the text, instead of pushing one new file to Git.

Also, it's just a cool new thing to try :)

So, time to find a static site generator. I've looked at a couple of them last weekend, and sadly wasn't very happy with the results so far.

## Jekyll (Ruby)
Jekyll is one of the best known generators, as it's used by Github Pages. This is absolutely its biggest pro: you really only need to push your articles, and Github will generate your site and host it. When you combine this the ability to edit files directly in Github, you now have the ability to edit your posts from everywhere in the world.

While I like Jekyll, it's too bad it's way too simple. It doesn't handle category- or date based archives for example. It's very hard to combine Markdown text and HTML templates, the templating system is annoying, and it's not easy to place two pieces of Markdown text into one page. On this website, all pages (homepage, projects and about) have a sidebar with text. I'd like to keep this in Markdown, but Jekyll makes it quite difficult to work with: each page now consists of three different files.

Some other (small) problems: I wish it's possible to set a default template for your posts, and that it's possible to turn off the Liquid template system inside my Markdown files.

You can extend Jekyll with plugins, for example to generate category pages, but as Github doesn't support them, you will lose Jekyll's biggest feature. So, you might as well use a better generator all together.

## Octopress (Ruby)
This is a bit of a weird one: it's not a generator itself but more like a framework of plugins and a default template for Jekyll. Octopress can generate category pages for you and has some other nice plugins, but most of their featureset is their default template with some Javascript files for Twitter, Github profile, Disqus, etc. Which I won't use.

Octopress is a very nice project for people who want to use Jekyll and aren't set on the Github integration. However, as you still have the template limitations, it's not for me.

## Hyde (Python)
I believe Hyde used to simply be a Python port of Jekyll, built on Django. The new version is no longer based on Django but on Jinja2 and includes many of their own ideas.

Because I love Jinja2 templates I was of course very interested in Hyde. As soon as I wanted to get started and looked at the documentation however, my enthusiasm waned: it's almost non-existent. Still, I installed it and tried it out.

I quickly found a negative so big, that I didn't need to look at Hyde any more: you can't write your articles in clean Markdown files: they need to be Jinja2 templates. Of course you can extend another template and just place your post inside `{% block content %}` and `{% markdown %}` tags, but for me it feels wrong. I have Googled this problem, and it seems that it's not possible to write your posts in pure Markdown files and have them first render and then be placed inside a template.

## Blogofile (Python)
Unlike Hyde, Blogofile is built on the Mako template language which is not my favorite. Based on this I was hesitant to do much more research, but luckily I did. Once you look past Mako, Blogofile is a remarkably flexible and hackable system. Post are written in pure Markdown, you have Python controllers for things like blog posts and pages, filters and deployment helpers.

I still need to use it in practice to see if it works for me, I'll update this post as soon as I have.

## Other generators I want to look at are:

### Toto (Ruby)
From the creator of Less CSS.

### Chisel (Python)
Crap documentation, but looks promising. Markdown plus Jinja2.

### Nanoc (Ruby)
Embedded Ruby in templates, not so nice. Project and docs look professional.

# Update (December 3, 2011)
I've tried to recreate mixedCase.nl in Jekyll, but I am not happy with it. Working with categories is too hard, there are no date-based archives, but worst of all: the syntax for blocks of codes has changed, as compared to how all my articles are written (and rendered with Python-Markdown). Jekyll's code blocks are not "official" Markdown, and as such don't play nice with my Markdown editor. I did like many of Jekyll's other features. It's easy, it's fast, and plays very nice with GitHub.

I did create a new blog for my immigration adventure, called [MoveToArctic.com](http://movetoarctic.com). It's made with Jekyll and hosted on GitHub. As long as you don't need archives, categories, RSS feeds per category and code highlighting, Jekyll simply kicks ass.

Moving mixedCase.nl to static pages is still a plan, but I'll need to try one of the other generators for it.
