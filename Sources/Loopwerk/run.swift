import Foundation
import PathKit
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
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

func improveHTML<M>(item: Item<M>) {
  // Improve the HTML by adding target="_blank" to external links
  item.body = item.body.improveHTML()
}

func permalink(item: Item<ArticleMetadata>) {
  // Insert the publication year into the permalink.
  // If the `relativeDestination` was "articles/looking-for-django-cms/index.html", then it becomes "articles/2009/looking-for-django-cms/index.html"
  var components = item.relativeDestination.components
  components.insert("\(Calendar.current.component(.year, from: item.date))", at: 1)
  item.relativeDestination = Path(components: components)
}

@main
struct Run {
  static func main() async throws {
    try await Saga(input: "content", output: "deploy")
      .register(
        folder: "articles",
        metadata: ArticleMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: sequence(improveHTML, publicationDateInFilename, permalink),
        writers: [
          .itemWriter(swim(renderArticle)),
          .listWriter(swim(renderArticles)),
          .tagWriter(swim(renderTag), tags: \.metadata.tags),
          .yearWriter(swim(renderYear)),

          // Atom feed for all articles, and a feed per tag
          .listWriter(atomFeed(title: SiteMetadata.name, author: SiteMetadata.author, baseURL: SiteMetadata.url, summary: \.self.metadata.summary), output: "feed.xml"),
          .tagWriter(atomFeed(title: SiteMetadata.name, author: SiteMetadata.author, baseURL: SiteMetadata.url, summary: \.self.metadata.summary), output: "tag/[key]/feed.xml", tags: \.metadata.tags),
        ]
      )
      .register(
        folder: "apps",
        metadata: AppMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        writers: [.listWriter(swim(renderApps))]
      )
      .register(
        folder: "projects",
        metadata: ProjectMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        writers: [.listWriter(swim(renderProjects))]
      )
      .register(
        metadata: PageMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        itemWriteMode: .keepAsFile, // need to keep 404.md as 404.html, not 404/index.html
        writers: [.itemWriter(swim(renderPage))]
      )
      .run()
      .staticFiles()
      .createArticleImages()
      .createPageFindIndex()
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

    let createArticleImagesDateFormatter = DateFormatter()
    createArticleImagesDateFormatter.dateFormat = "MMMM dd, yyyy"
    createArticleImagesDateFormatter.timeZone = .current

    let articles = fileStorage.compactMap { $0.item as? Item<ArticleMetadata> }

    for article in articles {
      let destination = (outputPath + "static" + "images" + article.filenameWithoutExtension).string + ".png"
      let generator = ImageGenerator(rootPath: rootPath)
      generator?.generate(title: article.title, outputPath: destination)
    }

    return self
  }
  
  @discardableResult
  func createPageFindIndex(originFilePath: StaticString = #file) throws -> Self {
    guard shouldCreateImages() == false else {
      print("Skipping createPageFindIndex")
      return self
    }

    let folder = try Path("\(originFilePath)").resolveSwiftPackageFolder()

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["pnpm", "index"]
    process.currentDirectoryURL = URL(fileURLWithPath: folder.string)
    process.environment = ["PATH": "/Users/kevin/Library/pnpm:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
    try process.run()
    process.waitUntilExit()

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
