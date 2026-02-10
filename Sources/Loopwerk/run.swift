import Foundation
import PathKit
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer
import SwiftGD

struct HeroImage: Decodable {
  let path: String
  let width: Int
  let height: Int
}

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  var heroImage: HeroImage?
  var archive: Bool?
}

struct WorkProjectMetadata: Metadata {
  let images: [String]
  let roundOffImages: Bool?
  let breakImages: Int?
  let url: String?
}

struct PageMetadata: Metadata {
  let section: String?
}

struct OpenSourceProjectMetadata: Metadata {
  let category: String
  let repo: String
  let order: Int?
}

extension Item where M == OpenSourceProjectMetadata {
  var order: Int {
    return metadata.order ?? 999
  }
}

extension Item where M == ArticleMetadata {
  var archive: Bool {
    return metadata.archive ?? false
  }

  var year: Int {
    return Calendar.current.component(.year, from: self.date)
  }

  var creationDate: Date {
    // Use file modification date if it matches the filename date (accounting for timezone)
    // The git-restore-mtime script should have set proper file timestamps to the FIRST commit
    let amsterdamTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
    var calendar = Calendar.current
    calendar.timeZone = amsterdamTimeZone

    let fileCreationComponents = calendar.dateComponents([.year, .month, .day], from: self.lastModified)
    let selfDateComponents = calendar.dateComponents([.year, .month, .day], from: self.date)

    // Check if the dates match in Amsterdam timezone
    if fileCreationComponents.year == selfDateComponents.year &&
      fileCreationComponents.month == selfDateComponents.month &&
      fileCreationComponents.day == selfDateComponents.day
    {
      return self.lastModified
    }

    // Fallback to self.date (filename date at noon)
    var components = Calendar.current.dateComponents([.year, .month, .day], from: self.date)
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = TimeZone.current

    return Calendar.current.date(from: components) ?? self.date
  }
}

enum SiteMetadata {
  static let url = URL(string: "https://www.loopwerk.io")!
  static let name = "Loopwerk"
  static let author = "Kevin Renskers"
  static let now = Date()
  static let projectRoot = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .path
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

func heroImage(item: Item<ArticleMetadata>) {
  // Check if a hero image exists for this article. If so, get its dimensions.
  let imageFilename = item.filenameWithoutExtension + "-1680w.webp"
  let heroesPath = Path(SiteMetadata.projectRoot) + "content/articles/heroes"
  let imagePath = heroesPath + imageFilename

  if imagePath.exists {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath.string)),
       let image = try? Image(data: data, as: .webp)
    {
      item.metadata.heroImage = HeroImage(
        path: "/articles/heroes/" + imageFilename,
        width: image.size.width,
        height: image.size.height
      )
    }
  }
}

@main
struct Run {
  static func main() async throws {
    try await Saga(input: "content", output: "deploy")
      .register(
        folder: "articles",
        metadata: ArticleMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: sequence(improveHTML, publicationDateInFilename, permalink, heroImage),
        filter: { $0.archive == false },
        filteredOutItemsAreHandled: false,
        writers: [
          .itemWriter(swim(renderArticle)),
          .listWriter(swim(renderArticles)),
          .tagWriter(swim(renderTag), tags: \.metadata.tags),
          .yearWriter(swim(renderYear)),

          // Atom feed for all articles, and a feed per tag
          .listWriter(
            atomFeed(
              title: SiteMetadata.name,
              author: SiteMetadata.author,
              baseURL: SiteMetadata.url,
              summary: \.metadata.summary,
              image: \.metadata.heroImage?.path,
              dateKeyPath: \.creationDate
            ),
            output: "feed.xml"
          ),
          .tagWriter(
            atomFeed(
              title: SiteMetadata.name,
              author: SiteMetadata.author,
              baseURL: SiteMetadata.url,
              summary: \.metadata.summary,
              image: \.metadata.heroImage?.path,
              dateKeyPath: \.creationDate
            ),
            output: "tag/[key]/feed.xml", tags: \.metadata.tags
          ),
        ]
      )
      .register(
        folder: "articles",
        metadata: ArticleMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: sequence(improveHTML, publicationDateInFilename, permalink, heroImage),
        filter: { $0.archive == true },
        writers: [
          .itemWriter(swim(renderArticle)),
        ]
      )
      .register(
        folder: "work",
        metadata: WorkProjectMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        writers: [.listWriter(swim(renderWork))]
      )
      .register(
        folder: "open-source/support",
        metadata: PageMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        writers: [.itemWriter(swim(renderPage))]
      )
      .register(
        folder: "open-source",
        metadata: OpenSourceProjectMetadata.self,
        readers: [.parsleyMarkdownReader],
        itemProcessor: improveHTML,
        writers: [.listWriter(swim(renderOpenSource))]
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
  }
}

extension Saga {
  @discardableResult
  func createArticleImages() -> Self {
    guard shouldCreateImages() else {
      print("Skipping createArticleImages")
      return self
    }

    let sourcesPath = SiteMetadata.projectRoot + "/Sources"

    let createArticleImagesDateFormatter = DateFormatter()
    createArticleImagesDateFormatter.dateFormat = "MMMM dd, yyyy"
    createArticleImagesDateFormatter.timeZone = .current

    let articles = fileStorage.compactMap { $0.item as? Item<ArticleMetadata> }

    for article in articles {
      let destination = (outputPath + "static" + "images" + article.filenameWithoutExtension).string + ".png"
      let generator = ImageGenerator(rootPath: sourcesPath)
      generator?.generate(article: article, outputPath: destination)
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
