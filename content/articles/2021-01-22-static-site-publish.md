---
tags: review, swift
summary: I'm taking a look at the static site generator Publish, written in Swift.
---

# Looking at the static site generator Publish
I've had a long history with static site generators for this website. I first [reviewed a bunch of them](/articles/2011/playing-around-static-site-generators/) in November 2011, and finally [settled on liquidluck](/articles/2012/new-static-website/) back in December 2012. And while there have been plenty of changes to this website in those eight years, I am still using liquidluck to this day. And that's beginning to be a bit of a problem; it's been over four years since it had its last commit, and over *seven years* since its last release. The biggest problem is that it doesn't work well with Python 3, and of course Python 2 is (finally) EOL'd.

I do still really appreciate liquidluck, I've made it work exactly how I want it to. For example, I can simply create a new file called `2021-01-22-static-site-publish.md`, and have its contents be like this:

```
# Looking at the static site generator Publish

I've had a long history with static site generators for this website.
```

And it works. The date of the article is taken from the filename, the url becomes `/articles/2021/static-site-publish/`. I am not forced to add metadata to the article, but I can if I want to, like this:

```
# Looking at the static site generator Publish
- tags: review

I've had a long history with static site generators for this website.
```

I can also easily add a custom summary like the example below, but it's not required. One will be generated from the article itself if I leave it out.

```
# Looking at the static site generator Publish
- tags: review

Here goes the summary for the list of articles.

---

I've had a long history with static site generators for this website.
```

The point is, it was very easy to make liquidluck [work this way](https://github.com/loopwerk/loopwerk.io/blob/3ba81efe1f1ff10305b54dbed3e5963b048491b8/MarkdownReader.py) as it's very easily customizable. I made it work with the way I write my articles, not the other way around. Another example: it was extremely easy to add a [static image generator](https://github.com/loopwerk/loopwerk.io/blob/3ba81efe1f1ff10305b54dbed3e5963b048491b8/ImageWriter/__init__.py) which creates a Twitter preview image for each and every article.

But as much as I enjoy this setup (and I am not looking forward to redo the whole site), the fact that liquidluck is unmaintained is becoming a liability and so I decided to take a look at a static site generator written in Swift, by famous developer John Sundell: [Publish](https://github.com/johnsundell/publish).

## First impressions
The project's README is a bit overwhelming, it immediately dives in to show you how flexible the system is, without giving much context yet. I really wasn't sure how to even get started. There is no real quick start guide, there is no example project. The only documentation consists of eight advanced "how to's," but there is no basic documentation. John made this generator primarily for himself and for [his website](https://swiftbysundell.com) so obviously he knows Publish in and out, but when he made it open source I think it needed a little bit more documentation. I hope the community steps up to do this so that Publish becomes friendlier to pick up.

I also wish his website was open source so you could take a look at how he made it all work with different kind of articles ("normal" articles as well as podcasts and videos) and their subtypes and tags and all that complexity.

## Getting started
I installed the command line interface via Homebrew (`brew install publish`), ran `publish new` and took a look at the example article it created in the new site.

```
---
date: 2021-01-22 13:15
description: A description of my first post.
tags: first, article
---
# My first post

My first post's text.
```

Uh oh, this is completely different from the way I want to structure my articles. I'd have to change my 59 existing articles to work with Publish, which is really not ideal — I don't want my tools to determine the formatting of my Markdown files, that makes changing tools later on a lot harder. Let's instead see how I can make Publish work for me, instead of the other way around.

## Dealing with dates
First up: using the date from the filename. I created a custom `PublishingStep`:

``` swift
extension PublishingStep where Site == Loopwerk {
  static func useDateFromFilename() -> Self {
    .mutateAllItems { item in
      item.date = itemDate(item)
    }
  }

  static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private static func itemDate(_ item: Item<Loopwerk>) -> Date {
    let itemPath = item.path.string.split(separator: .init("/")).last!
    let dateString = String(itemPath.prefix(10))
    return formatter.date(from: dateString) ?? item.date
  }
}
```

Which can be used like this:

``` swift
try Loopwerk().publish(using: [
  .addMarkdownFiles(),
  /*HLS The new step*/.useDateFromFilename()/*HLE*/,
  .copyResources(),
  .generateHTML(withTheme: .foundation),
  .generateSiteMap()
])
```

While this does the trick, taking the date from a file named `2021-01-22-static-site-publish.md` for example, it doesn't remove that date from the article's url, which is something my current setup with liquidluck does do. Sadly the `Item`'s `relativePath` property is `internal` so can't be modified, and `path` is a get-only property. I'd have to fork Publish just to make `relativePath` public so I'd be able to modify an article's slug. A second option would be to create my own `MarkdownFileHandler` and `addMarkdownFiles` step, which honestly is quite a bit of code that then needs to be kept in sync with Publish releases. Not a good idea.

## Dealing with metadata
The second problem is the way Publish (or really the Markdown parser it uses, [Ink](https://github.com/JohnSundell/Ink)) deals with metadata. As I showed above, it expects the metadata on top of the file between two `---` markers in a format called "YAML front matter," whereas I am used to having the metadata directly below the article title. Sadly I don't see an easy option here. The problem is that the `addMarkdownFiles` step does all the parsing and after that all you have access to is the parsed HTML of your Markdown file — not the original raw Markdown. I'd have to write my own `MarkdownFileHandler` and `addMarkdownFiles` step, use a different Markdown parser.. it's just not worth it. So realistically I'd have to modify all my articles. Not great, but to be fair: it does seem that the YAML front matter style is most common these days so maybe it wouldn't be a bad idea to adopt it already and make liquidluck work with it as well.

## More problems
There is no easy build-in way to have an archive per year. For example on this website you can visit https://www.loopwerk.io/articles/2021/ and see a list of all articles from 2021. Individual articles have their year in the url as well, creating a nice url hierarchy: https://www.loopwerk.io/articles/2021/static-site-publish/. This is really easily done in liquidluck in `settings.py`:

``` python
config = {
    "permalink": "{{date.year}}/{{slug}}/index.html",
}

writer = {
    "active": [
        "liquidluck.writers.core.PostWriter",
        "liquidluck.writers.core.PageWriter",
        "liquidluck.writers.core.ArchiveWriter",
        "liquidluck.writers.core.YearWriter", # <- the magic bit
        "liquidluck.writers.core.TagWriter",
    ],
}
```

Something like this is simply not possible with Publish as far as I can see. Even though Publish is really flexible in some ways, it still is mostly built for one specific site and its needs. Extending it is nowhere near as easy or obvious to do as with liquidluck.

It would be a major pain to transform all my existing templates (written using Jinja2) to Publish, which uses a [strongly-typed DSL](https://github.com/JohnSundell/Publish/blob/master/Sources/Publish/API/Theme%2BFoundation.swift#L64-L85) which, to be honest, I don't think I would enjoy using. Of course that is a completely personal and subjective opinion.

Finally, it seems that the maintenance of Publish and its dependencies (also written by John) is rather slow. At the time of writing, Publish has 17 open pull requests, Plot has 9, and Ink has 18. Many of them have been open for many months, some more than a year, without a response from John, even though another maintainer gave his blessing and requested John to look at the PR. I get that maintaining open source software is not easy at all, let alone so many packages of such complexity, but I wouldn't be confident in switching to Publish where there is one driving force who doesn't seem to respond to pull requests. My next static site generator needs a bigger community behind it so that I am not in the same situation later on where it's left unmaintained.

## Conclusion
In theory I'd love to switch to Publish. It uses my favorite programming language, everything is type safe. But the way it works means it's not flexible enough for me and I don't think I would want to use its HTML DSL. There is a serious lack of documentation and pull requests are left untouched. I'm sad to say that this is not the right static site generator for me. But again, this is a personal opinion in big part driven by my particular needs for my particular website, your milage may vary.
