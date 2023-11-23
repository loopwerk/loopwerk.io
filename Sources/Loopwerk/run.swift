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
  let roundOffImages: Bool?
  let breakImages: Int?
  let url: String?
}

struct PageMetadata: Metadata {
  let section: String?
}

enum ProjectInvolvement: String, Decodable {
  case author
  case contributor
}

struct ProjectMetadata: Metadata {
  let category: String
  let parent: String?
  let repo: String
  let image: String?
  let text: String
  let order: Int?
  let involvement: ProjectInvolvement?
}

extension Item where M == ProjectMetadata {
  var order: Int {
    return metadata.order ?? 999
  }

  var involvement: ProjectInvolvement {
    return metadata.involvement ?? .author
  }
}

enum SiteMetadata {
  static let url = URL(string: "https://www.loopwerk.io")!
  static let name = "Loopwerk"
  static let author = "Kevin Renskers"
  static let now = Date()
}

func itemProcessor<M>(item: Item<M>) {
  // Improve the HTML by adding target="_blank" to external links
  item.body = item.body.improveHTML()

  // If the filename starts with a valid date, use that as the Page's date and strip it from the destination path
  let first10 = String(item.relativeSource.lastComponentWithoutExtension.prefix(10))
  guard first10.count == 10, let date = Run.itemProcessorDateFormatter.date(from: first10) else {
    return
  }

  // Set the date
  item.date = date

  let year = String(item.relativeSource.lastComponentWithoutExtension.prefix(4))

  // Turn the destination into /articles/[year]/[filename-without-date-prefix]/index.html
  let first11 = String(item.relativeSource.lastComponentWithoutExtension.prefix(11))
  let newPath = Path("articles") + year + item.relativeSource.lastComponentWithoutExtension.replacingOccurrences(of: first11, with: "") + "index.html"
  item.relativeDestination = newPath
}

@main
struct Run {
  static var itemProcessorDateFormatter: DateFormatter = {
    let itemProcessorDateFormatter = DateFormatter()
    itemProcessorDateFormatter.dateFormat = "yyyy-MM-dd"
    itemProcessorDateFormatter.timeZone = .current
    return itemProcessorDateFormatter
  }()

  static func main() async throws {
    try await Saga(input: "content", output: "deploy")
      .register(
        folder: "articles",
        metadata: ArticleMetadata.self,
        readers: [.parsleyMarkdownReader(itemProcessor: itemProcessor)],
        writers: [
          .itemWriter(swim(renderArticle)),
          .listWriter(swim(renderArticles), paginate: 20),
          .tagWriter(swim(renderTag), tags: \.metadata.tags),
          .yearWriter(swim(renderYear)),

          // Atom feed for all articles, and a feed per tag
          .listWriter(swim(renderFeed), output: "feed.xml"),
          .tagWriter(swim(renderTagFeed), output: "tag/[key]/feed.xml", tags: \.metadata.tags),
        ]
      )
      .register(
        folder: "apps",
        metadata: AppMetadata.self,
        readers: [.parsleyMarkdownReader(itemProcessor: itemProcessor)],
        writers: [
          .listWriter(swim(renderApps)),
        ]
      )
      .register(
        folder: "projects",
        metadata: ProjectMetadata.self,
        readers: [.parsleyMarkdownReader(itemProcessor: itemProcessor)],
        writers: [
          .listWriter(swim(renderProjects)),
        ]
      )
      .register(
        metadata: PageMetadata.self,
        readers: [.parsleyMarkdownReader(itemProcessor: itemProcessor)],
        itemWriteMode: .keepAsFile,
        writers: [
          .itemWriter(swim(renderPage))
        ]
      )
      .run()
      .staticFiles()
      .createArticleImages()
  }
}

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

    let articles = fileStorage.compactMap { $0.item as? Item<ArticleMetadata> }

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
