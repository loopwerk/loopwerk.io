---
tags: saga, news
summary: I've created a new HTML minifier in pure Swift, with zero dependencies and performance on par with the best Node.js minifiers.
---

# Announcing Bonsai, a new HTML minifier in pure Swift

This site is built with [Saga](https://getsaga.dev), my static site generator written in Swift. For a long time I relied on the Node project [html-minifier](https://github.com/kangax/html-minifier) to minify the generated HTML. It worked fine, but it always bugged me that my otherwise all-Swift build pipeline had this one Node.js dependency just for minification. So I built [Bonsai](https://github.com/loopwerk/Bonsai), a pure Swift HTML minifier with zero external dependencies.

## What it does

Inspired by [html-minifier-next](https://github.com/j9t/html-minifier-next), Bonsai applies a set of safe transformations that will never break your HTML:

- Collapses whitespace runs to a single space (while preserving content inside `<pre>` and `<textarea>`)
- Removes comments (preserving conditional comments and bang comments)
- Collapses boolean attributes (`disabled="disabled"` becomes `disabled`)
- Removes redundant attributes (like `type="text"` on inputs or `method="get"` on forms)
- Removes empty attributes when safe to do so
- Shortens the doctype to `<!doctype html>`
- Removes redundant `type` attributes from `<script>` and `<style>` tags

There are no options or configuration flags. These rules produce correct output for all valid HTML, and I don't see a need for configurability that risks breaking things.

## How it works

The API is a single function call:

```swift
import Bonsai

let minified = Bonsai.minifyHTML(html)
```

> [!NERD ALERT]
> Under the hood, Bonsai operates in a single pass over the input, working directly on UTF-8 bytes rather than Swift `String` or `Character` types, because that's way too slow. No intermediate DOM or AST is constructed. Attribute names are compared using FNV-1a hashes against pre-computed lookup tables, avoiding string allocations for case-insensitive comparisons.

These choices keep it fast. On a ~143 KB HTML file, benchmarked over 1,000 iterations on an M1 Max:

| Tool                           | Avg time per page |
| ------------------------------ | ----------------- |
| html-minifier (Node.js)        | 12.1 ms           |
| html-minifier-terser (Node.js) | 14.3 ms           |
| html-minifier-next (Node.js)   | 0.6 ms            |
| **Bonsai (Swift)**             | **0.9 ms**        |

Bonsai is almost 15x faster than html-minifier, and only fractionally slower than html-minifier-next, which is its direct inspiration. For any realistic workload (hundreds of pages), the difference is negligible.

## Using Bonsai with Saga

The timing of this release isn't a coincidence. [Saga 2.16.0](https://github.com/loopwerk/Saga/releases/tag/2.16.0) shipped today with a few new features, one of which is the `postProcess` hook. This lets you transform every HTML file just before it's written to disk, which is exactly what you need for minification:

```swift
try await Saga(input: "content", output: "deploy")
  .register(
    readers: [.parsleyMarkdownReader()],
    writers: [.itemWriter(swim(renderPage))]
  )
  .postProcess { html, path in
    guard !isDev else { return html }
    return Bonsai.minifyHTML(html)
  }
  .run()
```

The `isDev` flag is another Saga 2.16.0 addition. Saga's `dev` command now automatically sets this flag, so you can skip expensive work like minification and image generation during development. In production builds, every HTML file passes through Bonsai before being written to disk.

## Try it out

Bonsai is available on GitHub: [github.com/loopwerk/Bonsai](https://github.com/loopwerk/Bonsai). Add it to your `Package.swift` and you're good to go:

```swift
.package(url: "https://github.com/loopwerk/Bonsai", from: "1.0.0")
```

It works with any Swift project that produces HTML, not just Saga. If you've been looking for a way to minify HTML without pulling in Node.js, give it a try.
