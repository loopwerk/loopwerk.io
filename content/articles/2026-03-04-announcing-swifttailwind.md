---
tags: saga, news
summary: I've created a Swift package that wraps the Tailwind CSS standalone CLI, removing the need for Node.js or npm in your build pipeline.
---

# Announcing SwiftTailwind

When I [announced Bonsai](/articles/2026/announcing-bonsai/) two days ago, the goal was to eliminate Node.js from this site's build pipeline by replacing html-minifier with a pure Swift alternative. That got rid of one Node dependency, but the biggest one remained: Tailwind CSS itself. The build process still shelled out to `pnpm tailwindcss` to compile CSS. So I built [SwiftTailwind](https://github.com/loopwerk/SwiftTailwind).

## What it does

SwiftTailwind wraps the [official Tailwind CSS standalone CLI](https://tailwindcss.com/blog/standalone-cli), which is a self-contained binary that doesn't need Node.js. The package downloads the correct binary for your platform (macOS or Linux, ARM or x64), validates its SHA-256 checksum against the official release, caches it at `~/.swifttailwind/`, and runs it via `Foundation.Process`. No Node, no npm, no `node_modules`.

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

That's it. Paths can be relative to your project root (detected automatically from `Package.swift`) or absolute.

In this website I run SwiftTailwind right before building the rest of the website. But instead of Tailwind living in pnpm scripts and a justfile, it's now all part of the same Swift pipeline.

## Why not just use the standalone CLI directly?

You could download the Tailwind standalone binary yourself and call it from a shell script. SwiftTailwind saves you from dealing with platform detection, downloading the right binary, verifying checksums, caching across versions, and wiring up `Foundation.Process`. It's a single `import` and two lines of code.

## Inspiration

SwiftTailwind is inspired by [SwiftyTailwind](https://github.com/nicklama/SwiftyTailwind), which is now archived and no longer maintained. SwiftTailwind is a fresh implementation with checksum verification, cleaner error handling, and full `Sendable` conformance for Swift concurrency.

## Try it out

SwiftTailwind is available on GitHub: [loopwerk/SwiftTailwind](https://github.com/loopwerk/SwiftTailwind). It works with any Swift project that needs Tailwind CSS, not just Saga.
