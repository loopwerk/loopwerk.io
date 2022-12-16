---
tags: swift, saga, open source
summary: In part 1 of a series of articles I'm looking at the inspiration behind my static site generator Saga, now available on Github.
---

# Building my own static site generator, part 1: inspiration & goals
*I've been designing and building my own static site generator, written in Swift, and an early version has been [released on Github](https://github.com/loopwerk/Saga). In this series of articles I want to go over the inspiration, the constraints and goals, how I got to my current API, and the pros and cons of said API. Finally, I also want to brainstorm about where to go from here.*

# Part 1: Inspiration and goals

## liquidluck
By far the biggest inspiration has come from [liquidluck](https://github.com/avelino/liquidluck), a static site generator written in Python that I've used since December 2012. There are many things that I really love about that generator: 

1. The way it uses multiple readers and writers and the ease of adding your own
2. Minimal configuration with maximum effect
3. Incredibly flexible yet it's really friendly and easy to set up

To give you some examples of its flexibility, let me tell you about the setup of this very website you're reading now. By default, you would write your article in a Markdown file such as this:

```
# Hello World

- date: 2012-06-11
- tags: python, javascript

-------

Hello World!
```

You'd call that file `hello-world.md`, and it would result in an article with the url `articles/hello-world/index.html`. Which is fine for most people, but I wanted to name my file something like `2021-01-30-hello-world.md`, and then the article's date would be taken from that filename, and still result in the same url `articles/hello-world/index.html`, without that date in there. I also wanted to write the article like this:

```
# Hello World
- tags: python, javascript

Hello World!
```

I didn't want be forced to add that `-------` separator after the metadata. The solution was pretty simple: I wrote my own `MarkdownReader` class, added that in `settings.py` to be used, and it works. It was *very* easy to adjust the way liquickluck converts articles and their metadata.

I also love the way it has the concept of multiple "writers," like this:

``` python
writer = {
    "active": [
        "liquidluck.writers.core.PostWriter",
        "liquidluck.writers.core.PageWriter",
        "liquidluck.writers.core.ArchiveWriter",
        "liquidluck.writers.core.ArchiveFeedWriter",
        "liquidluck.writers.core.FileWriter",
        "liquidluck.writers.core.YearWriter",
        "liquidluck.writers.core.TagWriter",
        "SitemapWriter.SitemapWriter",
        "ImageWriter.ImageWriter",
    ],
    "vars": {
        "archive_output": "articles/index.html",
        "archive_feed_output": "articles/feed.xml",
        "year_template": "year.html",
        "tag_template": "tag.html",
        "post_template": "article.html",
    }
}
```

Both the `SitemapWriter` and the `ImageWriter` are custom writers built by myself. As you can see, it has built-in support for writing your articles to an archive page, pages per year and per tag, and of course the non-article pages (such as the homepage, about, apps and projects pages).

Another example. By default all your articles will be written to the articles folder (or whatever folder you configured in the site settings), as `articles/article-name-here/index.html`. But I wanted all my articles to have the year in the url, as you can see on this article, which is `articles/2021/saga-1-inspiration/`. Again, super easy:

``` python
config = {
    "permalink": "{{date.year}}/{{slug}}/index.html",
    # other config..
}
```

One simple config change, and all my articles now have different urls. Like I said: minimal configuration with maximum effect. I've been a very happy user of liquidluck for many years now, but sadly the project is pretty much dead. It's not being maintained anymore and it doesn't work well with Python 3, so I am still using Python 2.7 to build my website. It's becoming a liability.

When I started thinking about building my own static site generator, I knew I wanted to have the same flexibility of custom readers and writers, great defaults, and an easy way to change things to make it fit your site.

Some things I knew I wanted to change though: one thing that is not ideal about liquidluck is that it's very much limited to websites with one section of articles. Let's say I want to add another website section called Questions where I'd have a different kind of articles. I'd still want to use all those writers to create archives per year and per tag, but that would be impossible. It's not a problem for my current website (yet, at least), and probably not for most websites, but it was definitely on my mind when starting to think about designing my own static site generator: the possibility to have multiple kinds of pages, each with their own set of writers.

I'm also not sure why liquidluck has the concept of both posts and pages, there honestly is no real difference in how both are handled other than how one uses `liquidluck.writers.core.PostWriter` and the other `liquidluck.writers.core.PageWriter`, which in turn use different templates. If you could pass parameters to the writers, surely you would only need one writer and only one type instead of two.

## Publish
The second part of the inspiration for my own generator came from [Publish](https://github.com/johnsundell/publish). I really like the way it allows you to extend an `Item` with custom metadata. However, it only allows for one metadata type for all your items which didn't seem ideal. I started to think about how I could have multiple types of items each with their own set of metadata: articles would have `tags`, and I could have a different set for apps, using an optional App Store URL plus URLs to screenshots. That way I could split my quite long `apps/index.md` file into separate Markdown files; one for each app, each with strongly typed metadata, and from those files I could then generate the actual Apps webpage. I could have both an Articles *and* a Questions section each with their own metadata. The possibilities are endless!

I was also not too fond of the way Publish has the concept of sections, items and pages; it seemed a bit too complex to me, I just wanted to have the concept of pages and that's it.

Something that I did very much like is the way you can extend Publish with your own publishing steps, where you're free to modify sections, items and pages — although there were sadly [some limitations](/articles/2021/static-site-publish/) that stopped me from using Publish for my website.

## My take-aways
After thinking about how I would want my own generator to work I knew I wanted at least the following things:

1. If possible, have just the concept of Pages. No Pages and Posts, no Items, no Sections.
2. It should be possible to have multiple kinds of strongly typed metadata, so that you have different sets of Pages. One set of articles, one set of questions, one for apps, and a generic default one for all other pages.
3. Use liquidluck's concept of multiple readers and writers, but they have to operate on sets of pages, so that you can write a list of articles *and* a a list of questions or apps.
4. It should be super easy to add your own readers and writers, or other steps where you can modify pages. By default it should "just work" using the built-in functionality, but it should be possible to extract dates from filenames for example, or do whatever else you want.

Join me in [part 2](/articles/2021/saga-2-api-design/) next, where I dive into the API of Saga and how I got there.
