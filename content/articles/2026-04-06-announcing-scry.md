---
tags: swift, news
summary: Scry is a pure-Swift, dependency-free, and fully Linux-compatible EXIF parser.
---

# Announcing Scry

This past weekend I've released a pure Swift EXIF parser  called [Scry](https://github.com/loopwerk/Scry). Unlike similar projects this one doesn't use Apple's ImageIO framework or other dependencies, and as such it's fully compatible with Linux. You don't even need to install libexif or anything like that.

Scry supports JPEG, PNG, and WebP images. Usage is simple with just a single public method:

```swift
import Scry

if let metadata = try? Scry.metadata(fromFileAt: "photo.jpg") {
  print(metadata["Make"])    // "Apple"
  print(metadata["Model"])   // "iPhone 14 Pro"
  print(metadata["FNumber"]) // 1.78
}
```

Scry is now also automatically used by [SagaImageReader](https://github.com/loopwerk/SagaImageReader), which is an image reader for [Saga](https://github.com/loopwerk/Saga) (which the name already gave away). It can be used to generate photo albums in your static site, and now you can show full EXIF info for each photo. Even better: SagaImageReader ships with a pre-built `ImageMetadata` struct, giving you type-safe access to all the available EXIF fields, rather than just a dictionary - all powered by Saga's built-in frontmatter decoder.