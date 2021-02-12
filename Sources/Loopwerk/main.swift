import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer
import Foundation
import PathKit
import PythonKit

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let review: String?
  let rating: Float?
}

struct AppMetadata: Metadata {
  let images: [String]
  let url: String?
}

struct PageMetadata: Metadata {
  let section: String?
}

struct SiteMetadata: Metadata {
  let url: URL
  let name: String
  let now: Date
}

let siteMetadata = SiteMetadata(
  url: URL(string: "https://www.loopwerk.io")!,
  name: "Loopwerk",
  now: Date()
)

let pageProcessorDateFormatter = DateFormatter()
pageProcessorDateFormatter.dateFormat = "yyyy-MM-dd"
pageProcessorDateFormatter.timeZone = .current

func pageProcessor(page: Page<ArticleMetadata>) {
  // If the filename starts with a valid date, use that as the Page's date and strip it from the destination path
  let first10 = String(page.relativeSource.lastComponentWithoutExtension.prefix(10))
  guard first10.count == 10, let date = pageProcessorDateFormatter.date(from: first10) else {
    return
  }

  // Set the date
  page.date = date

  let year = String(page.relativeSource.lastComponentWithoutExtension.prefix(4))

  // Turn the destination into /articles/[year]/[filename-without-date-prefix]/index.html
  let first11 = String(page.relativeSource.lastComponentWithoutExtension.prefix(11))
  let newPath = Path("articles") + year + page.relativeSource.lastComponentWithoutExtension.replacingOccurrences(of: first11, with: "") + "index.html"
  page.relativeDestination = newPath
}

try Saga(input: "content", output: "deploy", siteMetadata: siteMetadata)
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader(pageProcessor: pageProcessor)],
    writers: [
      .pageWriter(swim(renderArticle)),
      .listWriter(swim(renderArticles)),
      .listWriter(swim(renderFeed), output: "feed.xml"),
      .tagWriter(swim(renderTag), tags: \.metadata.tags),
      .yearWriter(swim(renderYear)),
    ]
  )
  .register(
    folder: "apps",
    metadata: AppMetadata.self,
    readers: [.parsleyMarkdownReader()],
    writers: [
      .listWriter(swim(renderApps)),
    ]
  )
  .register(
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader()],
    pageWriteMode: .keepAsFile,
    writers: [
      .pageWriter(swim(renderPage))
    ]
  )
  .run()
  .staticFiles()
  .createArticleImages()


extension Saga {
  @discardableResult
  func createArticleImages() -> Self {
    guard shouldCreateImages() else {
      print("Skipping createArticleImages")
      return self
    }

    let rootPath = String(URL(fileURLWithPath: #file)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .pathComponents
      .joined(separator: "/")
      .dropFirst())

    let sys = Python.import("sys")
    sys.path.append(rootPath)

    let module = Python.import("ImageGenerator")
    let generator = module.ImageGenerator(rootPath)

    let createArticleImagesDateFormatter = DateFormatter()
    createArticleImagesDateFormatter.dateFormat = "MMMM dd, yyyy"
    createArticleImagesDateFormatter.timeZone = .current

    let articles = fileStorage.compactMap { $0.page as? Page<ArticleMetadata> }

    for article in articles {
      let date = createArticleImagesDateFormatter.string(from: article.date)
      let destination = (self.outputPath + "static" + "images" + article.relativeSource.lastComponentWithoutExtension).string + ".png"
      generator.generate(article.title, date, destination)
    }

    return self
  }
}

func shouldCreateImages() -> Bool {
  if CommandLine.arguments.count == 2 {
    let command = CommandLine.arguments[1]
    return command == "createArticleImages"
  }
  return false
}
