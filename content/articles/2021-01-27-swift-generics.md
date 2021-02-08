---
tags: swift, saga
---

# Swift generics and arrays
I'm in the very early stages of building my own static site generator in Swift. I want the library to provide a basic `Page` type, that the user can then extend with custom metadata, and I need to be able to put Pages with different kinds of metadata into one array, which currently does work:

``` swift
// ---- LIBRARY

protocol Metadata: Decodable {}

struct Page {
  public var title: String
  public var body: String
  public var metadata: Metadata
}

// ---- USER APP

struct ArticleMetadata: Metadata {
  let isPublic: Bool
}

struct AppMetadata: Metadata {
  let appStoreUrl: URL?
}

let articles: [Page] = [
  .init(title: "Article 1", body: "", metadata: ArticleMetadata(isPublic: true)),
  .init(title: "Article 2", body: "", metadata: ArticleMetadata(isPublic: false)),
]

let apps: [Page] = [
  .init(title: "App", body: "", metadata: AppMetadata(appStoreUrl: URL(string: "https://www.example.com")))
]

// Different kinds of pages in one array
let allPages = articles + apps

// Let's filter only public articles
print(allPages.filter { page in
  if let metadata = page.metadata as? ArticleMetadata, metadata.isPublic {
    return true
  }
  return false
})
```

So here's the thing: in that last example where I filter only public articles from the array of all pages, it's quite annoying that I have to typecast the metadata, since it's just any Decodable, no other type info is present. 

If I want to make it generic though, I am running into different problems:

``` swift
// ---- LIBRARY

protocol Metadata: Decodable {}

struct Page<M: Metadata> {
  public var title: String
  public var body: String
  public var metadata: M
}

// ---- USER APP

struct ArticleMetadata: Metadata {
  let isPublic: Bool
}

struct AppMetadata: Metadata {
  let appStoreUrl: URL?
}

let articles: [Page<ArticleMetadata>] = [
  .init(title: "Article 1", body: "", metadata: .init(isPublic: true)),
  .init(title: "Article 2", body: "", metadata: .init(isPublic: false)),
]

let apps: [Page<AppMetadata>] = [
  .init(title: "App", body: "", metadata: .init(appStoreUrl: URL(string: "https://www.example.com")))
]

let allPages = articles + apps
// ❌ Cannot convert value of type '[Page<AppMetadata>]' to expected argument type 'Array<Page<ArticleMetadata>>'
```

I thought that type erasure might help, but then you're still forced to type cast the metadata so I'm back at the beginning just with an added layer of AnyMetadata complexity.

``` swift
// ---- LIBRARY

protocol Metadata: Decodable {}

struct AnyMetadata {
  var value: Any

  init<M: Metadata>(_ value: M) {
    self.value = value
  }
}

struct Page {
  public var title: String
  public var body: String
  public var metadata: AnyMetadata
}

// ---- USER APP

struct ArticleMetadata: Metadata {
  let isPublic: Bool
}

struct AppMetadata: Metadata {
  let appStoreUrl: URL?
}

let articles: [Page] = [
  .init(title: "Article 1", body: "", metadata: AnyMetadata(ArticleMetadata(isPublic: true))),
  .init(title: "Article 2", body: "", metadata: AnyMetadata(ArticleMetadata(isPublic: false))),
]

let apps: [Page] = [
  .init(title: "App", body: "", metadata: AnyMetadata(AppMetadata(appStoreUrl: URL(string: "https://www.example.com"))))
]

let allPages = articles + apps

print(allPages.filter { page in
  if let metadata = page.metadata.value as? ArticleMetadata, metadata.isPublic {
    return true
  }
  return false
})
```

I don't think I can use an enum for the metadata, since enums can't be extended with new cases, and the library doesn't know what cases should be available. As you can see in the example below, the library would now have to ship with this `PageMetadata` enum, which is not possible since the library doesn't know about `ArticleMetadata` and `AppMetadata`. 

``` swift
import Foundation

// ---- LIBRARY

protocol Metadata: Decodable {}

enum PageMetadata {
  case article(ArticleMetadata)
  case app(AppMetadata)
}

struct Page {
  public var title: String
  public var body: String
  public var metadata: PageMetadata
}

// ---- USER APP

struct ArticleMetadata: Metadata {
  let isPublic: Bool
}

struct AppMetadata: Metadata {
  let appStoreUrl: URL?
}

let articles: [Page] = [
  .init(title: "Article 1", body: "", metadata: .article(ArticleMetadata(isPublic: true))),
  .init(title: "Article 2", body: "", metadata: .article(ArticleMetadata(isPublic: false))),
]

let apps: [Page] = [
  .init(title: "App", body: "", metadata: .app(AppMetadata(appStoreUrl: URL(string: "https://www.example.com"))))
]

let allPages = articles + apps

print(allPages.filter { page in
  switch page.metadata {
    case .article(let article):
      return article.isPublic
    case .app:
      return false
  }
})
```

Am I just stuck with type casting, or is there another brilliant solution to have an array of Pages using generics?
