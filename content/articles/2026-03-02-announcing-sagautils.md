---
tags: saga, news
summary: A collection of reusable utilities for Saga, extracted from this very website: composable HTML transformations and useful String extensions.
---

# Announcing SagaUtils

Over the years, I've built up a collection of HTML post-processing utilities for this website. Things like generating a table of contents from headings, converting blockquotes with `[!TYPE]` syntax into styled asides, adding `target="_blank"` to external links, and various String helpers for stripping HTML tags or truncating text.

All of this lived in a single `String+Extensions.swift` file inside the loopwerk.io codebase. It was one big `improveHTML()` method that did everything at once: parse the HTML with [SwiftSoup](https://github.com/scinfu/SwiftSoup), loop through headings, process links, convert blockquotes, and return the result. It worked, but it wasn't reusable, and adding or removing a transformation meant editing a monolithic function.

I've now extracted and restructured these utilities into their own package: [SagaUtils](https://github.com/loopwerk/SagaUtils).

## Composable HTML transformations

The key improvement is that transformations are now composable. Each one is a standalone function with the signature `(Document) throws -> Void`, and you combine them using `swiftSoupProcessor`:

```swift
import SagaUtils

try await Saga(input: "content", output: "deploy")
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(generateTOC, convertAsides, processExternalLinks),
    writers: [.itemWriter(swim(renderArticle))]
  )
  .run()
```

The built-in transformations are:

- **`generateTOC`**: Replaces a `%TOC%` placeholder with a `<nav class="toc">` generated from headings. Also adds anchor links to each heading.
- **`convertAsides`**: Converts blockquotes with `[!TYPE]` syntax (like `[!WARNING]`) into `<aside class="warning">` elements.
- **`processExternalLinks`**: Adds `target="_blank"` and `rel="nofollow"` to external links.
- **`addHeadingAnchors`**: Adds named anchors to h1, h2, and h3 elements. (Included in `generateTOC` already, so you only need this if you want anchors without a table of contents.)

Writing your own transformation is straightforward since it's just a function that takes a SwiftSoup `Document`:

```swift
func addCodeBlockTitles(_ doc: Document) throws {
  let preElements = try doc.select("pre[data-title]")
  for pre in preElements {
    let title = try pre.attr("data-title")
    try pre.prepend("<span class=\"code-title\">\(title)</span>")
  }
}

// Then just add it to the pipeline:
swiftSoupProcessor(generateTOC, convertAsides, processExternalLinks, addCodeBlockTitles)
```

## String extensions

SagaUtils also includes a few handy String extensions:

```swift
// Strip HTML tags, keeping code block content
"<p>Hello <strong>world</strong></p>".plainText // "Hello world"

// Strip HTML tags and code blocks (useful for word counting)
body.textOnly

// Count words
body.textOnly.wordCount

// Truncate with word boundary awareness (inspired by Jinja2)
text.truncate(length: 200)
```

## Try it out

SagaUtils is available on GitHub: [github.com/loopwerk/SagaUtils](https://github.com/loopwerk/SagaUtils). Add it to your `Package.swift`:

```swift
.package(url: "https://github.com/loopwerk/SagaUtils", from: "1.0.2")
```

If you're using Saga and find yourself writing HTML post-processing code, this might save you some work.
