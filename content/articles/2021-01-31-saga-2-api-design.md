---
tags: swift, saga, open source
summary: Part 2, where I'm looking back at the current API of Saga.
---

# Building my own static site generator, part 2: API design
*I've been designing and building my own static site generator, written in Swift, and an early version has been [released on Github](https://github.com/loopwerk/Saga). In this series of articles I want to go over the inspiration, the constraints and goals, how I got to my current API, and the pros and cons of said API. Finally, I also want to brainstorm about where to go from here.*

*If you missed part 1, where I discuss the inspiration and goals of Saga, you can find it [here](/articles/2021/saga-1-inspiration/).*

# Part 2: API design
To explain the basic API design, let's start with a simple usage example, that we will then improve upon and extend later.

``` swift
try Saga(input: "content", output: "deploy")
  .read(
    readers: [.markdownReader()]
  )
  .write(
    templates: "templates",
    writers: [
      .pageWriter(template: "page.html"),
    ]
  )
```

Above is the most simple example that simply reads all Markdown files inside of the `input` folder without declaring any sort of custom metadata, transforms them to HTML, and writes the results to the `output` folder using the template `templates/page.html`. As I explained in the [previous article](/articles/2021/saga-1-inspiration/), I wanted to have the ability to have multiple readers and writers. I'm only shipping Saga with one reader at the moment, the `markdownReader`, but I could imagine a RestructuredText reader for example, or maybe you'd want to read Word documents, who knows. I do ship multiple build-in writers besides the `pageWriter`, which I'll demonstrate in the next example.

Another goal I set for Saga was the ability to extend pages with your own metadata. Let's imagine we want to create a blog with articles that have tags, a summary and a `public` boolean. And of course we still have "normal" pages like the homepage, about page, things like that.

``` swift
struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let `public`: Bool?

  var isPublic: Bool {
    return `public` ?? true
  }
}

extension Page {
  var isPublicArticle: Bool {
    return (metadata as? ArticleMetadata)?.isPublic ?? false
  }
  var tags: [String] {
    return (metadata as? ArticleMetadata)?.tags ?? []
  }
}

try Saga(input: "content", output: "deploy")
  .read(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.markdownReader()]
  )
  .read(
    readers: [.markdownReader()]
  )
  .write(
    templates: "templates",
    writers: [
      // Articles
      .pageWriter(
        template: "article.html", 
        filter: \.isPublicArticle
      ),
      .listWriter(
        template: "articles.html", 
        output: "articles/index.html", 
        filter: \.isPublicArticle
      ),
      .tagWriter(
        template: "tag.html", 
        output: "articles/[tag]/index.html", 
        tags: \.tags, 
        filter: \.isPublicArticle
      ),
      .yearWriter(
        template: "year.html", 
        output: "articles/[year]/index.html", 
        filter: \.isPublicArticle
      ),

      // Other pages
      .pageWriter(
        template: "page.html", 
        filter: { $0.metadata is EmptyMetadata }
      ),
    ]
  )
```

As you can see, a lot more is going on now. First of all we declare our own metadata type, `ArticleMetadata`. In our case we declare this type to have an array of tags, an optional summary and an optional `public` flag, that we default to `true` via the `isPublic` computed property. This means that we can write articles like this and the metadata contained within the Markdown file with be parsed as expected:

```
---
tags: article, news
summary: First!
public: false
---
# Hello world
Hello there.
```

It's strongly typed too, so when the parsing fails, you'll be notified.

Let's look at how running Saga has changed. You'll notice that we're now calling the `read` function twice:

``` swift
.read(
  folder: "articles",
  metadata: ArticleMetadata.self,
  readers: [.markdownReader()]
)
.read(
  readers: [.markdownReader()]
)
```

First we tell Saga that the files with the `articles` folder should use `ArticleMetadata`. Then, we run the `read` function a second time, which will then render the rest of the files, ignoring files that were already picked up by previous `read` step. Since we're not handing a custom metadata type to the second `read` step, it defaults to the built-in `EmptyMetadata` type, which is just an empty struct.

Now comes the `write` step, which has a lot more lines then before:

``` swift
.write(
  templates: "templates",
  writers: [
    // Articles
    .pageWriter(
      template: "article.html", 
      filter: \.isPublicArticle
    ),
    .listWriter(
      template: "articles.html", 
      output: "articles/index.html", 
      filter: \.isPublicArticle
    ),
    .tagWriter(
      template: "tag.html", 
      output: "articles/[tag]/index.html", 
      tags: \.tags, 
      filter: \.isPublicArticle
    ),
    .yearWriter(
      template: "year.html", 
      output: "articles/[year]/index.html", 
      filter: \.isPublicArticle
    ),

    // Other pages
    .pageWriter(
      template: "page.html", 
      filter: { $0.metadata is EmptyMetadata }
    ),
  ]
)
```

As you can see, we heavily rely on the `filter` parameter to tell the writers on which of the pages, created by the `read` steps, to operate. We're rendering the articles themselves using the `pageWriter`, and then we generate 3 kinds of "list" pages: a page with a list of articles using `listWriter`, a page for each existing tag with all the articles that uses that tag (`tagWriter`) and finally one page per year with a list of articles published in that year using the `yearWriter`. We end with another `pageWriter` to write all the other pages.

You may notice that the four writers that deal with articles have a lot of repeated logic, like the filter and the `articles/` prefix in the output parameters. That's why this can be simplified using the `section` writer, which acts like a wrapper:

``` swift
.write(
  templates: "templates",
  writers: [
    // Articles
    .section(prefix: "articles", filter: \.isPublicArticle, writers: [
      .pageWriter(template: "article.html"),
      .listWriter(template: "articles.html"),
      .tagWriter(template: "tag.html", tags: \.tags),
      .yearWriter(template: "year.html"),
    ]),
    
    // Other pages
    .pageWriter(template: "page.html", filter: { $0.metadata is EmptyMetadata }),
  ]
)
```

That looks a lot better!

And of course we're able to have different kinds of metadata for different kinds of pages, which was a huge goal I had for Saga. In the example below we have the articles like before using `ArticleMetadata`, but we now also have "apps" using `AppMetadata`, which are only written using the `listWriter`:

``` swift
struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let `public`: Bool?

  var isPublic: Bool {
    return `public` ?? true
  }
}

struct AppMetadata: Metadata {
  let url: URL?
  let images: [String]?
}

extension Page {
  var isPublicArticle: Bool {
    return (metadata as? ArticleMetadata)?.isPublic ?? false
  }
  var tags: [String] {
    return (metadata as? ArticleMetadata)?.tags ?? []
  }
  var isApp: Bool {
    return metadata is AppMetadata
  }
}

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
      // Articles
      .section(prefix: "articles", filter: \.isPublicArticle, writers: [
        .pageWriter(template: "article.html"),
        .listWriter(template: "articles.html"),
        .tagWriter(template: "tag.html", tags: \.tags),
        .yearWriter(template: "year.html"),
      ]),
      
      // Apps
      .listWriter(
        template: "apps.html", 
        output: "apps/index.html", 
        filter: \.isApp
      ),

      // Other pages
      .pageWriter(
        template: "page.html", 
        filter: { $0.metadata is EmptyMetadata }
      ),
    ]
  )
  .staticFiles()
```

I'm not super happy that the last `pageWriter` needs that `{ $0.metadata is EmptyMetadata }` filter but sadly I haven't found a better solution yet. The problem is that you can have pages which were not written to disk using a previous `pageWriter`: for example articles with the `public` flag set to `false`, and all the apps (which are only written using a `listWriter`). So when the final `pageWriter` comes along, it sees unwritten pages and wants to write it to disk - which is not what we want, and as such we make sure to only deal with `EmptyMetadata` pages here.

Finally we end with a call to `.staticFiles()`, which takes all the files in the input folder that were not read using one of the readers, and copies them to the output folder as-is. In practice, this means that all static files like images, css, raw html pages and so on are copied to your output folder as expected.

All the `read` steps write the resulting pages into an internal storage array, which all subsequent steps have access to. This means it's very easy to add your own step which has full access to all pages with the freedom to modify them however you wish. Let's see this in action with a very silly example, that appends an exclamation mark to the title of all pages:

``` swift
extension Saga {
  @discardableResult
  func modifyPages() -> Self {
    let pages = fileStorage.compactMap(\.page)
    for page in pages {
      page.title.append("!")
    }

    return self
  }
}

try Saga(input: "content", output: "deploy")
  .read(
    readers: [.markdownReader()]
  )
  .modifyPages() // <-- new step in action
  .write(
    templates: "templates",
    writers: [
      .pageWriter(template: "page.html"),
    ]
  )
```

Another way to do this is by supplying a processor function to the reader itself, like this:

``` swift
func pageProcessor(page: Page) {
  page.title.append("!")
}

try Saga(input: "content", output: "deploy")
  .read(
    readers: [.markdownReader(pageProcessor: pageProcessor))]
  )
  .write(
    templates: "templates",
    writers: [
      .pageWriter(template: "page.html"),
    ]
  )
```

The `pageProcessor` way is a bit simpler, but the custom step is more powerful since it has access to *all* files, even the ones not transformed to a `Page` using one of the read steps.

Check out the [example that ships with Saga](https://github.com/loopwerk/Saga/blob/main/Example/Sources/Example/main.swift) for more use cases, such as transforming files with filenames like `2021-01-31-saga-2-api-design.md` into articles with that date as the published date, and creating Twitter preview images for all articles.

[Part 3 is up](/articles/2021/saga-3-thoughts-so-far/), where I discuss the pros and cons of the current setup, what I do and don't like about the API, and where I might see this going forward.
