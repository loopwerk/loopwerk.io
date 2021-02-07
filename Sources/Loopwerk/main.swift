import Saga
import Foundation
import PathKit
import PythonKit

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  let review: String?
  let rating: Float?
}

struct PageMetadata: Metadata {
  let menu: String?
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

try Saga(input: "content", output: "deploy", templates: "templates", siteMetadata: siteMetadata)
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.markdownReader(pageProcessor: pageProcessor)],
    writers: [
      .pageWriter(template: "article.html"),
      .listWriter(template: "articles.html"),
      .listWriter(template: "feed.xml", output: "feed.xml"),
      .tagWriter(template: "tag.html", tags: \.metadata.tags),
      .yearWriter(template: "year.html"),
    ]
  )
  .register(
    metadata: PageMetadata.self,
    readers: [.markdownReader()],
    pageWriteMode: .keepAsFile,
    writers: [.pageWriter(template: "page.html")]
  )
  .run()
  .staticFiles()
  .createArticleImages()


extension Saga {
  @discardableResult
  func createArticleImages() -> Self {
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
