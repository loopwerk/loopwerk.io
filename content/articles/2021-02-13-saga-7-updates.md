---
tags: swift, saga, open source, news
summary: In the past few days I’ve made some pretty substantial improvements to Saga, to make it work for me and my website, which is now built using Saga.
---

# Building my own static site generator, part 7: updates & the road to 1.0.0
A while ago I [wrote](/articles/2021/saga-3-thoughts-so-far/) the following:

> If I can make Saga work for my own website without loosing any functionality, I will. I’ll switch away from liquidluck and maintain Saga going forward, adding things like an auto-watch server mode. If I can’t find good third-party libraries to do the Markdown parsing and code highlighting, I’ll write Saga off as a nice experiment that I had fun playing around with, but I won’t put more time into it. We’ll see how it goes, you can definitely expect at least one more article about Saga in the future.

I'm happy to say that I am now using Saga for my own website! As such it's my promise to maintain Saga going forward, I'm in it for the long haul. In the past few days I've made some pretty substantial improvements to Saga, to make it work for me and my website. All of these improvements can be seen in the included [example project](https://github.com/loopwerk/Saga/tree/main/Example/Sources/Example), or in the [source of loopwerk.io](https://github.com/loopwerk/loopwerk.io). [This is the pull request](https://github.com/loopwerk/loopwerk.io/pull/2) where I switched from liquidluck to Saga.

## Removed the default reader from the core Saga project
I've made multiple readers for Saga: [SagaInkMarkdownReader](https://github.com/loopwerk/SagaInkMarkdownReader), [SagaPythonMarkdownReader](https://github.com/loopwerk/SagaPythonMarkdownReader), and [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader). The last one was the [default reader for a little while](/articles/2021/saga-6-replacing-swiftmarkdown/), and came included with Saga. I've now made the decision to not include any readers with Saga itself; instead you'll choose one and include it with your project. This makes sure you're not downloading and compiling potentially large dependencies for a reader you might not end up using at all. I like that the core of Saga is now quite lean, and that I can easily make new readers without having to choose a default one and make breaking changes.

SagaParsleyMarkdownReader is the recommended reader, even though for now it doesn't support compile-time code syntax highlighting. Something that's easily solved with a client side library such as prism.js of course.

## Swim renderer
Until now Saga's writers all used the Stencil template language, which had some serious drawbacks. For example I kept having to include more and more "filters" for everything you might want to do in a template, and this simply wasn't going to scale. It was also pretty slow; rendering 64 articles took over three seconds.

The solution came in two parts. First of all, I changed the function signature of the writers, they no longer receive a template name and then internally use Stencil. Instead they now receive a closure that knows how to turn a RenderingContext into a String. That means that you can use anything you want in such a closure, as long as it can return a String. I call this closure a "renderer".

The second part of the solution is a brand new renderer based on [Swim](https://github.com/robb/Swim), called [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer). Swim is a strongly typed HTML DSL for Swift using function builders. It's very fast and really nice to work with.

Old syntax:

``` swift
writers: [
  .listWriter(template: "articles.html"),
  .tagWriter(template: "tag.html", tags: \.metadata.tags),
  .yearWriter(template: "year.html"),
]
```

New syntax:

``` swift
writers: [
  .listWriter(swim(renderArticles)),
  .tagWriter(swim(renderPartition), tags: \.metadata.tags),
  .yearWriter(swim(renderPartition)),
]
```

Here, `swim` is a function that comes from SagaSwimRenderer, which turns a HTML Node into a String, and `renderArticles` and `renderPartition` are functions that turn a RenderingContext into a HTML Node. Taken together, we have a function that goes from RenderingContext to String, and so they fulfill the requirement to be used in the writers. 

It should be quite easy to build different renderers for Saga, for example for [Plot](https://github.com/JohnSundell/Plot), [swift-html](https://github.com/pointfreeco/swift-html), [Vaux](https://github.com/dokun1/Vaux) or even Stencil, if you do choose to use that.

All this work can be seen in [this pull request](https://github.com/loopwerk/Saga/pull/6).

## Development server: recompile and reload on changes
A very important thing that I loved having in liquidluck was its development server, which looks for changes in your content, recompiles your website and then even refreshes your web browser. I'm happy to say this has now been added to Saga!

It does depend on a globally installed [lite-server](https://github.com/johnpapa/lite-server), but after that you can simply run one command from within your website project and you're off to the races.

```
swift run watch [input-folder] [output-folder]
```

The work that went into this can be viewed in [this pull request](https://github.com/loopwerk/Saga/pull/7).

## Atom feed support
It was always possible to generate Atom feeds, as long as you used a renderer (or previously a Stencil template) that supports outputting that format. [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer) got improved with a helper function that makes it very easy to generate Atom feeds of your items (for example your articles).

``` swift
writers: [
  // Atom feed for all articles, and a feed per tag
  .listWriter(swim(renderFeed), output: "feed.xml"),
  .tagWriter(swim(renderTagFeed), output: "tag/[key]/feed.xml", tags: \.metadata.tags),
]

func renderFeed(context: ItemsRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  AtomFeed(
    title: context.siteMetadata.name,
    author: "Kevin Renskers",
    baseURL: context.siteMetadata.url,
    pagePath: "articles/",
    feedPath: "articles/feed.xml",
    items: Array(context.items.prefix(20)),
    summary: { item in
      if let article = item as? Item<ArticleMetadata> {
        return article.summary
      }
      return nil
    }
  ).node()
}
```

## Paginator
Even though it's not something that I personally use for my own website, I do recognize that having some kind of paginating is quite important for most blogs. This has now also been added to Saga, with a very simple syntax.

``` swift
writers: [
  .listWriter(swim(renderArticles), paginate: 5),
  .tagWriter(swim(renderPartition), paginate: 5, tags: \.metadata.tags),
  .yearWriter(swim(renderPartition), paginate: 5),
]
```

Of course this is completely optional, so if you leave off that `paginate` parameter, no paginating will happen. The urls of the generated pages are also completely customizable:

``` swift
writers: [
  .listWriter(swim(renderArticles), paginate: 5, paginatedOutput: "[page].html"),
  .listWriter(swim(renderArticles), paginate: 5, paginatedOutput: "page/[page]/index.html"),
]
```

As part of the paginating support, all reference to the old `Page` type were renamed to `Item`. Otherwise it was causing confusion with a paginator also having a concept of pages, with things `itemsPerPage`, `numberOfPages`, `currentPage`, etc.

Also this work can be viewed in [a pull request](https://github.com/loopwerk/Saga/pull/8).

## Road to 1.0.0
I feel confident that the API isn't going to change a lot anymore, and all the TODO items I wrote down a while ago have been completed. Some more documentation might be nice and unit tests are definitely welcome, and after that I think I'll release 1.0.0 and commit to a stable public API.