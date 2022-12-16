---
tags: swift, saga, open source
summary: An unexpectedly quick fourth article about Saga, after a complete redesign of the API.
---

# Building my own static site generator, part 4: a complete redesign
I've been busy! Yesterday evening I was playing around with what it would take to use a generic `Page` type. I ended up with a branch that did exactly that: instead of the `Page` object having a non-generic `Metadata` type (a simple typealias for `Decodable`), I ended up with a `Page<M: Metadata>` type, and it worked. I didn't really see big benefit though, as I was forced to use type erasure to be able to put all pages with mixed metadata types into one array, so in the end instead of doing things like `page.metadata as? ArticleMetadata`, you were now doing `page as? Page<ArticleMetadata>`. No big win, right.

Today, I kept going. What if my idea from yesterday, to combine the read and write steps into one, could actually work? That way the whole workflow from reading to processing to writing a `Page` would indeed use a proper strongly typed generic `Page`, and typecasting would not be necessary. So I came up with the following new API:

``` swift
try Saga(input: "content", output: "deploy", templates: "templates")
  .process(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.markdownReader(pageProcessor: pageProcessor)],
    filter: \.public,
    writers: [
      .pageWriter(template: "article.html"),
      .listWriter(template: "articles.html"),
      .tagWriter(template: "tag.html", tags: \.metadata.tags),
      .yearWriter(template: "year.html"),
    ]
  )
  .process(
    folder: "apps",
    metadata: AppMetadata.self,
    readers: [.markdownReader()],
    writers: [.listWriter(template: "apps.html")]
  )
  .process(
    metadata: EmptyMetadata.self,
    readers: [.markdownReader()],
    writers: [.pageWriter(template: "page.html")]
  )
```

There are some real big benefits compared to the old API. First of all, that `folder` parameter can now be used for both reading *and* writing, so manually prefixing the output folder is no longer needed. In fact, I was able to completely remove the old `section` writer. There is also a huge improvement when it comes to the `filter` parameter. In the old API, all Markdown files within a folder would be converted to a `Page`, even if you wanted to exclude some of them from the website - for example, non-public articles. That meant you had to keep excluding them in all writers. This is now a lot better; the whole process step simply ignores files if the `filter` doesn't match. 

There was one problem though. What if you want to combine Pages from different folders? Let's say on the articles page you also want to show a list of apps, and vice-versa. With the new API, this was sadly not possible, since every process step only knows about its own files. Even if I would also write those pages to a global storage array, the order in which the process steps are added means it's simply not possible that both articles and apps could know about the other pages, since one is processed before the other.

Luckily the solution wasn't too bad. I am now first registering and storing steps, and then running them later, like so:

``` swift
try Saga(input: "content", output: "deploy", templates: "templates")
  /*HLS*/.register/*HLE*/(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.markdownReader(pageProcessor: pageProcessor)],
    filter: \.public,
    writers: [
      .pageWriter(template: "article.html"),
      .listWriter(template: "articles.html"),
      .tagWriter(template: "tag.html", tags: \.metadata.tags),
      .yearWriter(template: "year.html"),
    ]
  )
  /*HLS*/.register/*HLE*/(
    folder: "apps",
    metadata: AppMetadata.self,
    readers: [.markdownReader()],
    writers: [.listWriter(template: "apps.html")]
  )
  /*HLS*/.register/*HLE*/(
    metadata: EmptyMetadata.self,
    readers: [.markdownReader()],
    writers: [.pageWriter(template: "page.html")]
  )
  /*HLS*/.run()/*HLE*/
```

That `run` function first runs all the readers for all the registered steps, saving the resulting pages into each step *and* to a global storage array. Then, it runs all the writers for all the steps, giving it the pages that "belong to" that step (as proper `Page<Metadata>` instances), *and* the global array's pages, which are of course forced to be `AnyPage` type erased versions.

This means that for almost all normal use-cases, you're always working with proper types, with a smooth API that is better than the old one. And if you want to do out-of-the-ordinary things like combining multiple types of pages into other pages, you can - you'll just be typecasting `AnyPage` to the page type you're interested in.

As a quick reminder, this was the old API:

``` swift
try Saga(input: "content", output: "deploy")
  .read(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.markdownReader()]
  )
  .read(
    folder: "apps",
    metadata: AppMetadata.self,
    readers: [.markdownReader()]
  )
  .read(
    readers: [.markdownReader()]
  )
  .write(
    templates: "templates",
    writers: [
      .section(prefix: "articles", filter: \.isPublicArticle, writers: [
        .pageWriter(template: "article.html"),
        .listWriter(template: "articles.html"),
        .tagWriter(template: "tag.html", tags: \.tags),
        .yearWriter(template: "year.html"),
      ]),
      .listWriter(
        template: "apps.html", 
        output: "apps/index.html", 
        filter: \.isApp
      ),
      .pageWriter(
        template: "page.html", 
        filter: { $0.metadata is EmptyMetadata }
      ),
    ]
  )
```

The new version is more concise, more powerful, and needs a lot fewer hacks inside of the Saga codebase to deal with less-constrained writers running after more constrained writers and overwriting their pages. And a pet-peeve is solved: check that `output` parameter of the articles `listWriter`: `apps/index.html`. It really annoyed me that I had to prefix it with `apps`, since in the read step, I was also telling the system to work in the `apps` folder. This is so much better now.
  
I'm very happy, and can't wait to see where the API goes from here. Check out the [pull request](https://github.com/loopwerk/Saga/pull/1) I created with these changes, in case you're interested.
