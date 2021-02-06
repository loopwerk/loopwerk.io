import Saga
import Foundation
import PathKit

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
}

let siteMetadata = SiteMetadata(
  url: URL(string: "https://www.loopwerk.io")!,
  name: "Loopwerk"
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
  page.relativeDestination = newPath.makeOutputPath(keepExactPath: true)
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
    writers: [.pageWriter(template: "page.html", keepExactPath: true)]
  )
  .run()
  .staticFiles()
  //.createArticleImages()


extension Saga {
  private func run(_ cmd: String) -> String? {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", String(format:"%@", cmd)]
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    process.launch()
    return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
  }

  @discardableResult
  func createArticleImages() -> Self {
    let createArticleImagesDateFormatter = DateFormatter()
    createArticleImagesDateFormatter.dateFormat = "MMMM dd, yyyy"
    createArticleImagesDateFormatter.timeZone = .current

    let articles = fileStorage.compactMap { $0.page as? Page<ArticleMetadata> }

    for article in articles {
      let date = createArticleImagesDateFormatter.string(from: article.date)
      let destination = (self.outputPath + "static" + "images" + article.relativeSource.lastComponentWithoutExtension).string + ".png"
      _ = run("cd \((self.rootPath + "ImageGenerator").string) && python image.py \"\(article.title)\" \"\(date)\" \(destination)")
    }

    print("\(Date()) Finished writing article images")

    return self
  }
}
