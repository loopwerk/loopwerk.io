---
tags: django, python, open source
summary: I love RSS feeds, but it’s not ideal that you’re stuck with all the articles that are in the feed. So I built RSSfilter.com, offering a way to filter the feed based on keywords and categories.
---

# Announcing RSSfilter.com: a Trump filter for RSS feeds, built with Django

I love RSS feeds. It’s how I keep up with all of my (tech) news, for example from [The Verge](https://www.theverge.com) and [Ars Technica](https://arstechnica.com). If a news site or blog doesn’t have a RSS feed, I won’t keep up with it, sorry.

The big downside with RSS though? You get all the articles that are in the feed. And unless your RSS reader of choice offers built-in mute or filter functionality, you’re just stuck with those articles. And sadly most RSS readers do not offer any kind of filtering capabilities, or when they do, it’s locked behind a paid plan (looking at you, Feedly Pro+, requiring a $9/month plan if you want to “mute the noise”). For example I love The Verge, but I don’t want to read anything related to Trump, their podcast, shopping deals (that are only valid in the U.S. anyway), or their very basic how-to articles.

The solution seemed pretty simple to me: build a service that filters public RSS feeds, and spits out a new RSS feed without the articles that match keywords or categories you’re not interested in. So I built [RSSfilter.com](https://rssfilter.com), that does exactly this. The core logic is open-sourced as a Django app, called [django-rss-filter](https://github.com/loopwerk/django-rss-filter). You can use this to self-host your own version of RSSfilter.com. It includes unit tests and an example Django project. Version 0.1.0 has just been published to PyPI!

And with that I can create the perfect version of The Verge’s RSS feed just for me:

![](/articles/images/rssfilter.png)