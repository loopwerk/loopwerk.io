---
tags: saga, news
summary: I've created a Swift package that wraps the Tailwind CSS standalone CLI, removing the need for Node.js or npm in your build pipeline.
---

# Announcing SwiftTailwind

When I [announced Bonsai](/articles/2026/announcing-bonsai/) two days ago, the goal was to eliminate Node.js from this site's build pipeline by replacing html-minifier with a pure Swift alternative. That got rid of one Node dependency, but the biggest one remained: Tailwind CSS itself. The build process still shelled out to `pnpm tailwindcss` to compile CSS. So I built [SwiftTailwind](https://github.com/loopwerk/SwiftTailwind).

## What it does

SwiftTailwind wraps the [official Tailwind CSS standalone CLI](https://tailwindcss.com/blog/standalone-cli), which is a self-contained binary that doesn't need Node.js or NPM. The package downloads the correct binary for your platform (macOS or Linux, ARM or x64), caches it, and runs it via `Foundation.Process`.

It supports both Tailwind v3 and v4.

## Usage

Add it to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/loopwerk/SwiftTailwind", from: "1.0.0"),
],
targets: [
  .executableTarget(
    name: "YourApp",
    dependencies: ["SwiftTailwind"]
  ),
]
```

Then compile your CSS:

```swift
import SwiftTailwind

let tailwind = SwiftTailwind(version: "3.4.17")
try await tailwind.run(
  input: "content/static/input.css",
  output: "content/static/output.css",
  options: .minify
)
```

## Try it out

SwiftTailwind is available on GitHub: [loopwerk/SwiftTailwind](https://github.com/loopwerk/SwiftTailwind). It works with any Swift project, not just Saga.
