---
tags: swift, saga, review
summary: I built the same site with Hugo, Publish, and Saga to compare how each static site generator handles real-world requirements.
---

# A real-world comparison of static site generators: Hugo vs Publish vs Saga

I've been building static sites for a very long time, and I've always been curious how different generators handle the same requirements. Not toy examples, but real features like blog pagination, RSS feeds, custom URL schemes, and multiple content types with different metadata.

So I built the same site three times to find out: once with [Hugo](https://gohugo.io/), once with [Publish](https://github.com/JohnSundell/Publish), and once with [Saga](https://github.com/loopwerk/Saga). Same content, same URLs, same output. The full source code is available at [loopwerk/realworld-ssg](https://github.com/loopwerk/realworld-ssg).

Full disclosure: I'm the author of Saga. I'll try to be fair, but I obviously have opinions about how a static site generator should work. That's why I built one.

**TL;DR:** Hugo is the most mature option with an excellent dev server, but everything runs through untyped config and Go templates that fail silently. Publish had the right idea with Swift type safety, but a shared metadata type, no built-in pagination, limited flexibility, and hard dependencies on Plot and Ink hold it back. Saga offers typed metadata per section, pluggable readers and template languages, programmable URLs, and built-in pagination, all without the custom workarounds that Publish requires for basic features.

Let's start simple and add complexity step by step.

## Getting started

Before we even look at templates and content, the setup experience is worth mentioning.

**Hugo** is a single binary. Install it, run `hugo new site`, and you have a working project structure with directories for content, layouts, and a config file. Start writing. The flip side is that Hugo has an enormous configuration surface. Your `hugo.toml` file controls everything from URL schemes to output formats to markup rendering, and none of it is discoverable without reading the documentation. There's no compiler, no autocomplete, no error if you misspell a config key. You just get default behavior you didn't want and have to figure out why.

**Publish** is a Swift package, so you need a `Package.swift` file. But the real ceremony starts in your Swift code. You have to define a `Website` struct with a `SectionID` enum, a shared `ItemMetadata` struct, and properties for `url`, `name`, `description`, `language`, and `imagePath`. Then you implement an `HTMLFactory` protocol with six required methods. (The idea behind `HTMLFactory` is that people can publish themes as Swift packages, but do you really want to build a website using an off-the-shelf theme from someone else?)

Before you've written a single line of template code, you've already written a lot of boilerplate to satisfy the framework. It doesn't help that Publish's documentation is rudimentary. The README covers the basics, but once you need anything beyond the happy path, you're reading source code. And Publish is effectively unmaintained at this point: pull requests sit unreviewed for years, bug reports aren't welcome, and the last meaningful update was a long time ago.

**Saga** is also a Swift package, but it has a companion CLI you can install via Homebrew or Mint. Run `saga init mysite` and you get a complete project with articles, tags, templates, and a stylesheet, ready to build and serve. Under the hood you write a `run.swift` with the pipeline and add template functions for the pages you want. No required protocols to satisfy, no boilerplate to set up. The trade-off is that Saga is a much smaller project: you won't find a large community or ecosystem around it.

## Step 1: Simple markdown pages

Every static site generator needs to turn markdown into HTML using some kind of template. This is where the fundamental design difference between these three tools becomes clear.

We're starting very simple with an `index.md` which will be rendered to `/index.html`, and `about.md` which will be rendered to `/about/index.html`.

### Hugo

The config is minimal at this point:

```toml title="hugo.toml"
baseURL = "https://example.com/"
languageCode = "en-us"
title = "RealWorld SSG"
```

Hugo uses Go's `text/template` language. You need three template files even for this simple case. First, a base layout:

```html title="layouts/baseof.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ .Title }} - {{ .Site.Title }}</title>
</head>
<body>
    <header>
        <nav>
            <a href="/">Home</a>
            <a href="/about/">About</a>
        </nav>
    </header>
    <main>
        {{ block "main" . }}{{ end }}
    </main>
</body>
</html>
```

A homepage template:

```html title="layouts/home.html"
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}
{{ end }}
```

And the same thing again for the about page:

```html title="layouts/single.html"
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}
{{ end }}
```

The two page templates are identical, but Hugo needs them as separate files because the homepage is a different "kind" than a regular page.

If you've used Go templates before, the syntax is straightforward. If you haven't, there's a learning curve. What does the dot mean? What's `{{ block "main" . }}` doing, and why does the dot need to be passed explicitly?

The discoverability problem from `hugo.toml` also applies to the templates. How would you know that `.Title`, `.Content`, `.IsHome`, and `.Site.Title` are available? None of these are discoverable from your editor. You find them by reading Hugo's documentation, which is extensive but organized by concept rather than "here's everything available in this template type".

And when you get it wrong, Hugo won't tell you. Use `.Titel` instead of `.Title` and Hugo silently renders nothing: no error, no warning, just missing output on the page. You'll only notice when you look at the generated HTML and wonder where your heading went.

### Publish

Publish uses [Plot](https://github.com/JohnSundell/Plot), a Swift DSL for HTML. Here's the full setup to render a simple page. First, you define a `Website` struct:

```swift
struct RealWorldSite: Website {
  enum SectionID: String, WebsiteSectionID {
    case about
  }

  struct ItemMetadata: WebsiteItemMetadata {}

  var url = URL(string: "https://example.com")!
  var name = "RealWorld SSG"
  var description = ""
  var language: Language { .english }
  var imagePath: Path? { nil }
}
```

Then an `HTMLFactory` with six required methods. Here's the one that renders the homepage and the about page:

```swift
struct RealWorldHTMLFactory: HTMLFactory {
  typealias Site = RealWorldSite

  func baseLayout(title: String, _ content: Node<HTML.BodyContext>) -> HTML {
    HTML(
      .head(
        .encoding(.utf8),
        .viewport(.accordingToDevice),
        .title(title)
      ),
      .body(
        .header(
          .nav(
            .a(.href("/"), .text("Home")),
            .a(.href("/about/"), .text("About"))
          )
        ),
        .main(content)
      )
    )
  }
  
  func makeIndexHTML(for index: Index, context: PublishingContext<Site>) throws -> HTML {
    baseLayout(title: "\(index.content.title) - \(context.site.name)", .group(
      .h1(.text(index.content.title)),
      .div(.raw(index.content.body.html))
    ))
  }
  
  func makePageHTML(for page: Page, context: PublishingContext<Site>) throws -> HTML {
    baseLayout(title: "\(page.title) - \(context.site.name)",
      .h1(.text(page.title)),
      .div(.raw(page.body.html))
    )
  }

  // Plus four more required methods:
  func makeSectionHTML(for section: Section<Site>, context: PublishingContext<Site>) throws -> HTML { HTML(.body()) }
  func makeItemHTML(for item: Item<Site>, context: PublishingContext<Site>) throws -> HTML { HTML(.body()) }
  func makeTagListHTML(for page: TagListPage, context: PublishingContext<Site>) throws -> HTML? { nil }
  func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<Site>) throws -> HTML? { nil }
}
```

This is type-safe Swift, which is great. But the dot-syntax is verbose. Every element is `.element`, every attribute is `.attribute(value)`, every piece of text needs `.text()`. A simple link becomes `.a(.href("/"), .text("Home"))`. It's correct, but it doesn't *read* like HTML. 

And just as with Hugo, we have duplicate templates for the homepage and the about page.

Finally the pipeline that runs it all:

```swift
let factory = RealWorldHTMLFactory()
try RealWorldSite().publish(using: [
  .addMarkdownFiles(),
  .generateHTML(withTheme: Theme(htmlFactory: factory)),
])
```

### Saga

Saga doesn't prescribe a template language (more on that later), but for this comparison I'm using [Swim](https://github.com/robb/Swim), a Swift HTML DSL that uses trailing closures. Here's the full setup:

```swift
struct PageMetadata: Metadata {}

func baseLayout(title pageTitle: String, @NodeBuilder children: () -> NodeConvertible) -> Node {
  html(lang: "en") {
    head {
      meta(charset: "UTF-8")
      meta(content: "width=device-width, initial-scale=1", name: "viewport")
      title { "\(pageTitle) - RealWorld SSG" }
    }
    body {
      header {
        nav {
          a(href: "/") { "Home" }
          a(href: "/about/") { "About" }
        }
      }
      main {
        children()
      }
    }
  }
}

func renderPage(context: ItemRenderingContext<PageMetadata>) -> Node {
  baseLayout(title: context.item.title) {
    h1 { context.item.title }
    Node.raw(context.item.body)
  }
}

try await Saga(input: "content", output: "deploy")
  .register(
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader],
    writers: [.itemWriter(swim(renderPage))]
  )
  .run()
```

This is also type-safe Swift, but the nesting reads more like the HTML it produces. If you know HTML and you know Swift, there's not much new to learn.

## Step 2: A blog with articles

Now things get interesting. We're adding articles with metadata (author, date, tags, summary), individual article pages, a paginated article list, a page per tag, an RSS feed, and custom URLs that include the year (`/articles/2024/building-with-hugo/`).

### Frontmatter

The markdown content is almost identical across all three generators, with some notable differences when it comes to the frontmatter -- the embedded metadata at the top of the markdown file:

```text title="Hugo"
---
title: Building a Site with Hugo
date: 2024-06-10
tags: [hugo, tutorial]
summary: A practical walkthrough of building a simple site with Hugo.
author: Kevin Renskers
---

Hugo is one of the most popular static site generators [...]
```

```text title="Publish"
---
title: Building a Site with Hugo
date: 2024-06-10 12:00
tags: hugo, tutorial
description: A practical walkthrough of building a simple site with Hugo.
author: Kevin Renskers
---

Hugo is one of the most popular static site generators [...]
```

```text title="Saga"
---
date: 2024-06-10
tags: hugo, tutorial
summary: A practical walkthrough of building a simple site with Hugo.
author: Kevin Renskers
---

# Building a Site with Hugo

Hugo is one of the most popular static site generators [...]
```

Hugo requires the title in frontmatter and wants tags as a YAML sequence. 

Saga derives the title from the first `#` heading in the content and removes it from the body, so you can render the title, then the date and author, then the body — each separately. 

Publish *can* also read the title from a `#` heading, but it leaves the heading in the body HTML. That means if you want to render anything between the title and the body (like a date or author byline), you need the title in frontmatter instead. 

Publish also requires a time component on dates (`12:00`) and uses `description` instead of `summary`. That's a fixed field name you can't change.

> [!SIDENOTE]
> On loopwerk.io, my article files are named with a date prefix, like `2024-06-10-building-with-hugo.md`. So instead of having to add a frontmatter `date` property, can the static site generators take the date from the filename?
> 
> Saga handles this with the `publicationDateInFilename` item processor, stripping the date prefix from the filename to derive the slug, so that you end up with the URL `/articles/building-with-hugo/` (without the date).
> 
> Hugo can handle this too, with a [special config option](https://gohugo.io/configuration/front-matter/#filename). It's amazing how many special options Hugo has to add (and document) to enable all of its flexibility!
>  
> Publish derives the slug directly from the filename with no way to strip a prefix at all. Your file `2024-06-10-building-with-hugo.md` would produce the URL `/articles/2024-06-10-building-with-hugo/`. I [wrote about this](/articles/2021/static-site-publish/) back in 2021, and sadly nothing has changed.

### Metadata types

This is where the design philosophies really start to diverge.

**Hugo** doesn't have explicit metadata types. You access custom frontmatter fields through `.Params`, which is an untyped map. `.Params.summary` might be a string, might be nil, might be something else entirely. You won't find out until the template renders.

**Publish** has a single `ItemMetadata` struct shared across all sections of your site. For articles, it looks fine:

```swift
struct ItemMetadata: WebsiteItemMetadata {
  var author: String
  // `date`, `tags`, and `description` are built-in properties of the `Item` itself
}
```

With just one section, this works. We'll see why it becomes a problem when we add the projects section.

**Saga** lets you define separate metadata types per section:

```swift
struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let author: String
  // `date` is a built-in property of the `Item` itself
}
```

`author` is a required `String`, not an optional. If you forget to add it to one of your markdown files, Saga logs an error pointing at the exact file and skips it. Publish would crash on the same mistake. Both catch the problem at build time, but Saga lets you keep working.

### Rendering an article

The single article templates show each tool's character:

**Hugo:**

```html title="layouts/articles/single.html"
{{ define "main" }}
<article>
    <h1>{{ .Title }}</h1>
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>
    {{ with .Params.author }}<p>By {{ . }}</p>{{ end }}
    {{ with .Params.tags }}
    <ul class="tags">
        {{ range . }}<li><a href="/articles/tags/{{ . | urlize }}/">{{ . }}</a></li>{{ end }}
    </ul>
    {{ end }}
    <div>{{ .Content }}</div>
</article>
{{ end }}
```

**Publish:**

```swift
func makeItemHTML(for item: Item<Site>, context: PublishingContext<Site>) throws -> HTML {
  baseLayout(title: "\(item.title) - \(context.site.name)", .article(
    .h1(.text(item.title)),
    .time(.datetime(item.date.formatted("yyyy-MM-dd")), .text(item.date.formatted("MMMM d, yyyy"))),
    .p(.text("By \(item.metadata.author)")),
    .if(
      !item.tags.isEmpty,
      .ul(.forEach(item.tags.sorted()) { tag in
        .li(.a(.href(context.site.path(for: tag).absoluteString), .text(tag.string)))
      })
    ),
    .div(.raw(item.body.html))
  ))
}
```

**Saga:**

```swift
func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  baseLayout(title: "\(context.item.title) - RealWorld SSG") {
    article {
      h1 { context.item.title }
      time(datetime: context.item.date.formatted("yyyy-MM-dd")) {
        context.item.date.formatted("MMMM d, yyyy")
      }
      p { "By \(context.item.metadata.author)" }
      if !context.item.metadata.tags.isEmpty {
        ul {
          context.item.metadata.tags.map { tag in
            li { a(href: "/articles/tags/\(tag.slugified)/") { tag } }
          }
        }
      }
      div {
        Node.raw(context.item.body)
      }
    }
  }
}
```

The function signature tells you exactly what this template is for: it renders an `ArticleMetadata` item, with strongly typed metadata just for the articles. You can't accidentally use this template for a different kind of item.

### Pagination, RSS, and custom URLs

Up to this point, all three tools can be made to work reasonably well. From here on, the amount of friction starts to diverge sharply.

**Hugo** handles all three through configuration:

```toml title="hugo.toml"
[pagination]
  pagerSize = 2

[permalinks.page]
  articles = "/articles/:year/:contentbasename/"

[outputFormats.RSS]
  baseName = "feed"

[outputs]
  section = ["HTML", "RSS"]
```

```html title="layouts/articles/list.html"
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}

{{ range .Paginator.Pages }}
<article>
    <h2><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>
    {{ with .Params.summary }}<p>{{ . }}</p>{{ end }}
</article>
{{ end }}

<nav>
    {{ with .Paginator }}
    {{ if .HasPrev }}<a href="{{ .Prev.URL }}">Previous</a>{{ end }}
    <span>Page {{ .PageNumber }} of {{ .TotalPages }}</span>
    {{ if .HasNext }}<a href="{{ .Next.URL }}">Next</a>{{ end }}
    {{ end }}
</nav>
{{ end }}
```

Four config blocks, a new `list.html` template, and you're done. This is Hugo's strength: if what you want matches what Hugo supports, configuration is all you need. (Conversely: if you need something that isn't exposed as a config option, you're stuck.)

**Publish** already requires a custom publishing step. Here's the pipeline:

```swift
try RealWorldSite().publish(using: [
  .addMarkdownFiles(),
  .sortItems(by: \.date, order: .descending),
  .generateHTML(withTheme: Theme(htmlFactory: factory)),
  .generatePaginatedArticles(factory: factory),
  .generateRSSFeed(
    including: [.articles],
    config: .init(targetPath: "articles/feed.xml")
  ),
])
```

Publish has no equivalent of Hugo's `permalinks` config or Saga's `itemProcessor` for custom URLs. To get the year in the URL (`/articles/2024/building-with-hugo/`), you either organize your content files into year subfolders, or add a `path: 2024/building-with-hugo` frontmatter key to every single article. There's no way to derive it automatically from the date.

Pagination is also telling. Publish simply doesn't paginate, so you build it yourself:

```swift
static func generatePaginatedArticles(factory: RealWorldHTMLFactory) -> Self {
  .step(named: "Generate paginated articles") { context in
    let allItems = context.sections[.articles].items.sorted { $0.date > $1.date }
    let perPage = 2
    let totalPages = Int(ceil(Double(allItems.count) / Double(perPage)))

    for page in 2 ... totalPages {
      let html = factory.makeArticlesListHTML(items: allItems, context: context, page: page)
      let path = Path("articles/page/\(page)/index.html")
      try context.createOutputFile(at: path).write(html.render())
    }
  }
}
```

You calculate page counts, slice arrays, render HTML, and write files to disk. I don't understand why a static site generator used for blogs doesn't support pagination out of the box?

**Saga** handles all three in the pipeline configuration:

```swift
.register(
  folder: "articles",
  metadata: ArticleMetadata.self,
  readers: [.parsleyMarkdownReader],
  itemProcessor: permalink,
  writers: [
    .itemWriter(swim(renderArticle)),
    .listWriter(swim(renderArticles), paginate: 2),
    .listWriter(atomFeed(title: "RealWorld SSG", baseURL: URL(string: "https://example.com")!, summary: \.metadata.summary), output: "feed.xml"),
  ]
)
```

Pagination is `paginate: 2` on the list writer. The Atom feed is a built-in writer you configure with a title and a key path to the summary field. Custom permalinks are handled by an item processor that runs before pages are written:

```swift
func permalink(item: Item<ArticleMetadata>) {
  // Insert the publication year into the permalink.
  // If the `relativeDestination` was "articles/building-with-hugo/index.html", then it becomes "articles/2024/building-with-hugo/index.html"
  var components = item.relativeDestination.components
  components.insert("\(Calendar.current.component(.year, from: item.date))", at: 1)
  item.relativeDestination = Path(components: components)
}
```

Saga gives you full control to modify everything about an `Item`, including its destination path.

### Tag pages

Since we're tagging articles, we probably want a page per tag listing all articles with that tag. This is a common requirement, and the three generators handle it very differently.

**Hugo** generates tag pages automatically. It actually generates two kinds by default: "term" pages (one page per tag) and a "taxonomy" page (a list of all tags). If you want the per-tag pages but not the taxonomy index, you need `disableKinds = ["taxonomy"]` in your config. Then you create a `term.html` template and Hugo does the rest:

```html title="layouts/term.html"
{{ define "main" }}
<h1>Articles tagged with "{{ .Data.Term }}"</h1>

{{ range .Pages }}
<article>
    <h2><a href="{{ .RelPermalink }}">{{ .Title }}</a></h2>
    <time datetime="{{ .Date.Format "2006-01-02" }}">{{ .Date.Format "January 2, 2006" }}</time>
    {{ with .Params.summary }}<p>{{ . }}</p>{{ end }}
</article>
{{ end }}
{{ end }}
```

The magic is in knowing that this template needs to be called `term.html` and placed in the right directory. Hugo picks it up based on naming conventions. It works, but once again, you have to know the convention exists.

**Publish** has this one built in, sort of. The `HTMLFactory` protocol has a required method `makeTagDetailsHTML`. You fill it in and Publish generates the pages:

```swift
func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<Site>) throws -> HTML? {
  let items = context.items(taggedWith: page.tag, sortedBy: \.date, order: .descending)

  return baseLayout(title: "\(page.tag.string) - \(context.site.name)", .group(
    .h1(.text("Articles tagged with \"\(page.tag.string)\"")),
    .forEach(items) { item in
      .article(
        .h2(.a(.href(articlePath(item)), .text(item.title))),
        .time(.datetime(item.date.formatted("yyyy-MM-dd")), .text(item.date.formatted("MMMM d, yyyy"))),
        .if(!item.description.isEmpty, .p(.text(item.description)))
      )
    }
  ))
}
```

**Saga** adds a `.tagWriter` to the writers array:

```swift
.tagWriter(swim(renderTag), output: "tags/[key]/index.html", tags: \.metadata.tags),
```

One line in the pipeline: the template function, the output path pattern (`[key]` gets replaced with the slugified tag name), and a key path to the tags field on your metadata. The template receives a `PartitionedRenderingContext` with the tag as `context.key` and the matching articles as `context.items`:

```swift
func renderTag(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  baseLayout(title: "Articles tagged with \"\(context.key)\" - RealWorld SSG") {
    h1 { "Articles tagged with \"\(context.key)\"" }

    context.items.map { item -> Node in
      article {
        h2 { a(href: item.url) { item.title } }
        time(datetime: item.date.formatted("yyyy-MM-dd")) {
          item.date.formatted("MMMM d, yyyy")
        }
        item.metadata.summary.map { summary in p { summary } } ?? Node.fragment([])
      }
    }
  }
}
```

The key path `\.metadata.tags` is what makes this type-safe. Saga knows it's partitioning `ArticleMetadata` items by their `tags` field. If you renamed the field or changed its type, the compiler would catch it.

> [!SIDENOTE]
> What if you also wanted category pages, not just tag pages? 
> 
> Hugo handles this out of the box: `tags` and `categories` are both built-in taxonomies, and you can add custom ones (like `authors`) with a few lines in your config. 
> 
> Saga just needs another `.tagWriter` with a different key path. 
> 
> Publish, however, has tags hardcoded into the framework. There's a single `Tag` type, a single `tags` property on items, and exactly one `makeTagDetailsHTML` method. To add a second taxonomy you'd have to store the data in `ItemMetadata` and build the pages yourself in a custom publishing step.

## Step 3: A projects section

The final requirement: a projects section where each project is a markdown file with its own metadata (category, repo URL, display order), rendered as a single list page. No individual project pages.

### Hugo

Hugo's approach is straightforward. Each project is a markdown file with custom frontmatter:

```yaml
---
title: saga
category: Swift
repo: https://github.com/loopwerk/Saga
order: 1
---

Saga is a static site generator written in Swift.
```

And a custom list template for the projects section:

```html title="layouts/projects/list.html"
{{ define "main" }}
<h1>{{ .Title }}</h1>
{{ .Content }}

{{ range sort (sort .Pages "Title") "Params.order" }}  
<article>
    <h2>{{ .Title }}</h2>
    {{ .Content }}
    <dl>
        <dt>Category</dt>
        <dd>{{ .Params.category }}</dd>
        <dt>Repository</dt>
        <dd><a href="{{ .Params.repo }}">{{ .Params.repo }}</a></dd>
    </dl>
</article>
{{ end }}
{{ end }}
```

This works fine. Hugo sorts by `.Params.order`, renders each project's markdown body and metadata, done. The downside is familiar by now: custom frontmatter fields like `category` and `repo` are loosely typed. Misspell a field name in your markdown and you get empty output, not an error.

### Publish

Publish gets more awkward here. Remember that single shared `ItemMetadata`? Now that we need project fields too, it grows into a bag of optionals:

```swift
struct ItemMetadata: WebsiteItemMetadata {
  var author: String?
  var category: String?
  var repo: String?
  var order: Int?
}
```

Every section shares this type. Articles don't have `category`, `repo`, or `order`. Projects don't have `author`. But the type system doesn't know that, so everything has to be optional. This gets worse as your site grows: add a "talks" section with `videoURL` and `conference` fields, and now every article and project technically has those fields too.

The template has to deal with all those optionals:

```swift
func makeProjectsHTML(for section: Publish.Section<Site>, context: PublishingContext<Site>) -> HTML {
  let sorted = section.items.sorted { ($0.metadata.order ?? 1, $0.title) < ($1.metadata.order ?? 1, $1.title) }

  return baseLayout(title: "Projects - \(context.site.name)", .group(
    .h1(.text("Projects")),
    .forEach(sorted) { project in
      .article(
        .h2(.text(project.title)),
        .div(.raw(project.body.html)),
        .dl(
          .dt(.text("Category")),
          .dd(.text(project.metadata.category ?? "")),
          .dt(.text("Repository")),
          .dd(.unwrap(project.metadata.repo) { repo in
            .a(.href(repo), .text(repo))
          })
        )
      )
    }
  ))
}
```

And there's another issue. Publish automatically generates an individual page for every item in every section. We don't want individual project pages, just the list. So you need a custom step to delete them after they've been generated:

```swift
static func removeProjectPages() -> Self {
  .step(named: "Remove project pages") { context in
    let items = context.sections[.projects].items
    for item in items {
      let slug = item.path.string.replacingOccurrences(of: "projects/", with: "")
      try context.outputFile(at: "projects/\(slug)/index.html").parent?.delete()
    }
  }
}
```

Generate pages, then delete them. It works, but it feels like fighting the framework.

> [!SIDENOTE]
> If you'd want to create a project page per category, Publish would make that extremely awkward since it only supports tags, and one `makeTagDetailsHTML` method. You'd be fighting the "one taxonomy" design the whole way.

### Saga

In Saga, you register the projects folder with its own metadata type and only a list writer. No item writer means no individual pages:

```swift
.register(
  folder: "projects",
  metadata: ProjectMetadata.self,
  readers: [.parsleyMarkdownReader],
  writers: [
    .listWriter(swim(renderProjects)),
  ]
)
```

Saga supports multiple metadata types where each field lives where it belongs:

```swift
struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let author: String
}

struct ProjectMetadata: Metadata {
  let category: String
  let repo: String
  let order: Int
}
```

`category` and `repo` are required on projects. `author` is required on articles. If a markdown file is missing a required field, you get an error at build time. No silent failures, no `?? ""` fallbacks in templates.

The template is the most readable of the three:

```swift
func renderProjects(context: ItemsRenderingContext<ProjectMetadata>) -> Node {
  return baseLayout(title: "Projects - RealWorld SSG") {
    h1 { "Projects" }

    context.items
      .sorted { ($0.metadata.order, $0.title) < ($1.metadata.order, $1.title) }
      .map { project -> Node in
        article {
          h2 { project.title }
          Node.raw(project.body)
          dl {
            dt { "Category" }
            dd { project.metadata.category }
            dt { "Repository" }
            dd { a(href: project.metadata.repo) { project.metadata.repo } }
          }
        }
      }
  }
}
```

No optionals to unwrap for `category` and `repo`: the types guarantee they're there. The function signature tells you this is a list of `ProjectMetadata` items, so the compiler ensures you're working with project data.

## Developer experience

With the full site built ([source on GitHub](https://github.com/loopwerk/realworld-ssg)), let's talk about the daily workflow.

**Hugo** has the best dev server of the three. Run `hugo server` and you get file watching and live reload out of the box. Builds are extremely fast, even for large sites. The trade-off is that Hugo can't help you catch mistakes. Misspell a config key, reference a nonexistent template variable, or typo a frontmatter field name, and you get silent wrong output instead of an error. There's no compiler standing between you and a broken site. The biggest problem is of course the huge amount of config options, and (in my opinion) a bad template language.

**Publish** and **Saga** are both Swift packages, which means you get the compiler on your side. Xcode gives you autocomplete, jump-to-definition, and inline errors. Rename a metadata field and the compiler shows you every template that needs updating. Pass the wrong type to a function and it won't build. This is a real advantage over Hugo's "run it and see" workflow. That said, Publish's type safety has a ceiling: with one shared `ItemMetadata` for all sections, most fields end up optional, and the compiler can't tell you that you're accessing an article field on a project page. Saga's per-section metadata types give you the full benefit.

The dev server story for Publish isn't great. **Publish** has a `publish run` command, but it's minimal. It compiles your Swift package, generates the site, and then launches Python's built-in `http.server` to serve the output folder. That's it. No file watching, no live reload, no auto-rebuild. When you change a markdown file or a Swift source file, you have to stop the server, rebuild, and restart. If you're using Xcode, the workflow is Cmd+R to rebuild, then manually refresh your browser.

**Saga** has a `saga dev` command that watches your content and source folders, triggers a rebuild when a file changes, and live-reloads the browser. It works on both macOS and Linux, so developing or deploying on a Linux server is no problem.

## Extensibility

The comparison above covers what each generator provides. But what happens when you need something it *doesn't* provide? Say you want a different template language, or you need to read content from something other than Markdown.

### Template languages

**Hugo** uses Go's `text/template`. That's it. You cannot swap in a different template language. Hugo historically supported Ace and Amber as alternatives, but those were deprecated and removed. Go doesn't have a runtime plugin mechanism, so this is a hard architectural constraint.

**Publish** uses [Plot](https://github.com/JohnSundell/Plot) for HTML generation. This is also a hard dependency. The `HTMLFactory` protocol requires all methods to return Plot's `HTML` type, not a protocol or a string. You can't use a different HTML DSL like [swift-html](https://github.com/pointfreeco/swift-html) without forking Publish.

**Saga** doesn't care what you use for templates. Writers just expect a function that returns a `String`. The [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer) package is a thin adapter that converts Swim nodes to strings, and there's also [SagaStencilRenderer](https://github.com/loopwerk/SagaStencilRenderer) for [Stencil](https://github.com/stencilproject/Stencil) templates (Django/Jinja2-style). You could just as easily return a plain string:

```swift
func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> String {
  "<html><body><h1>\(context.item.title)</h1>\(context.item.body)</body></html>"
}
```

### Content readers

**Hugo** supports Markdown, HTML, and Org Mode natively, plus AsciiDoc, reStructuredText, and Pandoc via external tools. That covers most formats, but you can't add your own. There's no plugin system for content readers.

**Publish** uses [Ink](https://github.com/JohnSundell/Ink), its own Markdown parser. Ink is a concrete type in Publish's internals, not a protocol you can swap. You can add Ink "modifiers" to customize how specific Markdown elements render, but you can't replace the parser itself. To read a different content format, you'd skip `.addMarkdownFiles()` entirely and write a custom publishing step that reads files, parses them into HTML, and calls `context.addItem()` manually. There's no reader abstraction to conform to.

**Saga** treats readers as plugins: you give each step in the pipeline a reader that handles the file conversion (for example `readers: [.parsleyMarkdownReader]`). Three Markdown readers already exist as separate packages ([Parsley](https://github.com/loopwerk/SagaParsleyMarkdownReader), [Ink](https://github.com/loopwerk/SagaInkMarkdownReader), and [Python-Markdown](https://github.com/loopwerk/SagaPythonMarkdownReader)), and writing one for a new format is straightforward. You can even pass multiple readers and Saga picks the right one based on file extension, so a folder can contain a mix of `.md` and `.rst` files.

## Wrapping up

Hugo is the most mature of the three and has a fantastic dev server. If your site fits Hugo's model, you can go far with just configuration, and if Hugo's conventions match your mental model, it's incredibly productive. But everything you do is mediated by config keys you have to look up and Go templates you can't type-check. When something doesn't work, you're searching docs and forums instead of reading compiler errors.

Publish had the right idea: use Swift for type safety. But the execution is frustrating. A single shared metadata type, hard dependencies on Plot and Ink, no programmatic control over permalinks, and custom steps for everything the framework doesn't anticipate (like pagination!). Combine that with rudimentary documentation and a project that's effectively unmaintained, and it's hard to recommend for new sites.

Saga takes a different approach: explicit pipelines, typed metadata per section, swappable readers and renderers, and built-in support for the things every blog needs. If you want individual pages, you say so. If you want pagination, you pass a parameter. If you want an RSS feed, you add a writer. Don't want individual project pages? Don't add an item writer. The pipeline does exactly what you tell it to, nothing more.

Which one you prefer depends on how much control you want, and how much magic you're willing to tolerate.

*The full source code for all three implementations is on GitHub: [loopwerk/realworld-ssg](https://github.com/loopwerk/realworld-ssg). Clone it, check the code, build each one, compare the output. Consider starring [Saga](https://github.com/loopwerk/Saga) or the RealWorld SSG repo.*

> [!UPDATE]
> **February 24, 2026**: I've added a new example to [loopwerk/realworld-ssg](https://github.com/loopwerk/realworld-ssg): creating a page that isn't backed by a markdown file at all, like a contact form. Hugo requires a "content adapter" file that defines a custom type, plus a custom type template tied together through naming conventions. Publish needs a custom publishing step that imperatively writes the file to disk, and a line in the pipeline to wire it all up. Saga: one line in the pipeline. The [full comparison](https://github.com/loopwerk/realworld-ssg/commit/50f9ed1e02a23d8694458dabc58f0769527359ca) is worth a look.