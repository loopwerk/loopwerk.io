---
tags: swift, saga, news
summary: I've created a brand new documentation website for Saga, built with Saga itself. It features full API reference docs, works without JavaScript, and looks pretty great.
---

# Announcing GetSaga.dev

I've created a brand new documentation website for Saga, built with Saga itself: [GetSaga.dev](https://getsaga.dev).

I already had the [DocC website](https://loopwerk.github.io/Saga/documentation/saga/), but it has some real shortcomings: ugly deep URLs, no proper landing page, and it doesn't work at all without JavaScript (which stops agents like Claude Code from reading the docs).

So I built my own. What started as a simple one-page website highlighting Saga's features has turned into a full-fledged documentation and API reference site, rivaling DocC in capabilities. It works completely without JavaScript, and I fully control how everything is rendered.

## How it works

GetSaga.dev is a Swift package that depends on Saga, Apple's [SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit), and some other packages (see below). Because GetSaga.dev depends on Saga, that means it has access to Saga's source code. Once I realized that, I figured that it must be possible to parse Saga's code in the same way that DocC does. And yes, in fact it's just a single swiftpm command away:

```shell-session
$ swift package --package-path .build/checkouts/Saga dump-symbol-graph --emit-extension-block-symbols
```

This generates a JSON file with all of Saga's symbols. For each symbol it contains the declaration, as fragments, any function parameters, docstring, if it's deprecated or not, etc. Everything you need to render the full API docs.

Using SymbolKit you can turn this giant JSON file into a strongly typed symbol graph:

```swift
let data = try Data(contentsOf: URL(fileURLWithPath: "path/to/Saga.symbols.json"))
let graph = try JSONDecoder().decode(SymbolGraph.self, from: data)
```

With this graph in hand, you can loop over the symbols and render each one as you see fit. There's a catch though: SymbolKit doesn't give you declarations as strings. Instead of something like:

```swift
init(
  supportedExtensions: [String],
  copySourceFiles: Bool = false,
  convert: @escaping Reader.Converter
)
```

You instead get an array of fragments that you have to piece together. Since it's not so trivial, I've turned the code responsible for this "symbol to HTML" logic into a brand new Swift package: [Sigil](https://github.com/loopwerk/Sigil).

All of this is consumed by Saga using its recently added `register(metadata:fetch:itemProcessor:sorting:writers:)` method, which can programmatically load items, instead of reading them from markdown files on disk. I then have HTML templates written with [Swim](https://github.com/robb/Swim) that render the items to HTML pages.

Once again Saga's flexibility made this website possible. Multiple strongly typed metadata types, the ability to programmatically load items and create pages, besides the normal markdown-file-to-HTML workflow, it all made this website a joy to work on. In a way, GetSaga.dev is the best demonstration of what Saga can do.

Feel free to check the [source code](https://github.com/loopwerk/getsaga.dev) of GetSaga.dev if you want to dig into how everything works.

## Tech stack

- [Saga](https://github.com/loopwerk/Saga): static site generation
- [SymbolKit](https://github.com/swiftlang/swift-docc-symbolkit): symbol graph parsing for the API reference
- [Sigil](https://github.com/loopwerk/Sigil): renders the SymbolKit declarations as syntax-highlighted HTML
- [SagaSwimRenderer](https://github.com/loopwerk/SagaSwimRenderer): type-safe HTML templates using [Swim](https://github.com/robb/Swim)
- [SagaParsleyMarkdownReader](https://github.com/loopwerk/SagaParsleyMarkdownReader): Markdown parsing using [Parsley](https://github.com/loopwerk/Parsley)
- [Moon](https://github.com/loopwerk/Moon): server-side syntax highlighting
- [Bonsai](https://github.com/loopwerk/Bonsai): HTML minification
- [SwiftTailwind](https://github.com/loopwerk/SwiftTailwind): Tailwind CSS