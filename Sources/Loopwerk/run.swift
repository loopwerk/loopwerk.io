import Foundation
import PathKit
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  var heroImage: String?
  var archive: Bool?
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

struct ProjectMetadata: Metadata {
  let category: String
  let repo: String
  let image: String?
  let order: Int?
}

extension Item where M == ProjectMetadata {
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
    guard shouldCreateImages() else {
      return self.date
    }

    // Try to get creation date from git history
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = ["log", "--follow", "--format=%aI", "--reverse", self.relativeSource.string]

    // Extract path up to and including "content"
    let pathComponents = self.absoluteSource.string.components(separatedBy: "/")
    if let contentIndex = pathComponents.firstIndex(of: "content") {
      let contentPath = pathComponents[0...contentIndex].joined(separator: "/")
      process.currentDirectoryPath = contentPath
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
      try process.run()
      process.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: .utf8), let firstLine = output.split(separator: "\n").first {
        let iso8601Formatter = ISO8601DateFormatter()
        if let gitDate = iso8601Formatter.date(from: String(firstLine)) {
          // Convert git date to Amsterdam timezone to check if date matches
          let amsterdamTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
          var calendar = Calendar.current
          calendar.timeZone = amsterdamTimeZone
          
          let gitDateComponents = calendar.dateComponents([.year, .month, .day], from: gitDate)
          let selfDateComponents = calendar.dateComponents([.year, .month, .day], from: self.date)
          
          // Check if the dates match in Amsterdam timezone
          if gitDateComponents.year == selfDateComponents.year &&
             gitDateComponents.month == selfDateComponents.month &&
             gitDateComponents.day == selfDateComponents.day {
            return gitDate
          }
        }
      }
    } catch {
      // If git fails, fall back to the date from filename
    }
    
    // Fallback: use the date from filename with noon in Amsterdam timezone
    let amsterdamTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
    var calendar = Calendar.current
    calendar.timeZone = amsterdamTimeZone

    var components = calendar.dateComponents([.year, .month, .day], from: self.date)
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = amsterdamTimeZone

    return calendar.date(from: components) ?? self.date
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

let imageExtensions: Set<String> = ["webp", "jpg", "png"]

func heroImage(item: Item<ArticleMetadata>) {
  for imageExtension in imageExtensions {
    let imageFilename = item.filenameWithoutExtension + ".\(imageExtension)"
    if (Path("content/articles/heroes") + imageFilename).exists {
      item.metadata.heroImage = imageFilename
      break
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
          .listWriter(atomFeed(title: SiteMetadata.name, author: SiteMetadata.author, baseURL: SiteMetadata.url, summary: \.self.metadata.summary, dateKeyPath: \.creationDate), output: "feed.xml"),
          .tagWriter(atomFeed(title: SiteMetadata.name, author: SiteMetadata.author, baseURL: SiteMetadata.url, summary: \.self.metadata.summary, dateKeyPath: \.creationDate), output: "tag/[key]/feed.xml", tags: \.metadata.tags),
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
