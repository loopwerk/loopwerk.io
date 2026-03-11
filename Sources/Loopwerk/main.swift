import Bonsai
import Foundation
import SagaPathKit
import Saga
import SagaParsleyMarkdownReader
import SagaSwimRenderer
import SagaUtils
import SwiftTailwind

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
  static let projectRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .path
}

let articleProcessor = sequence(
  unescapeMarkVar,
  swiftSoupProcessor(generateTOC, convertAsides, processExternalLinks, addCodeBlockTitles),
  syntaxHighlight,
  publicationDateInFilename,
  permalink,
  heroImage
)

// Compile tailwind to output.css
let tailwind = SwiftTailwind(version: "3.4.17")
try await tailwind.run(
  input: "content/static/input.css",
  output: "content/static/output.css",
  options: .minify
)

try await Saga(input: "content", output: "deploy")
  // Non-archived articles (`$0.archive == false`)
  // We make sure that the filtered-out articles (i.e. archived articles) are NOT
  // marked as handled. Otherwise the next step can't process the archived articles.
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: articleProcessor,
    filter: { $0.archive == false },
    claimExcludedItems: false,
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

  // Archived articles: they get their own detail page but are not part of the list pages nor atom feeds
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: articleProcessor,
    filter: { $0.archive == true },
    writers: [
      .itemWriter(swim(renderArticle)),
    ]
  )

  // Portfolio stuff (paid work and open source projects)
  .register(
    folder: "work",
    metadata: WorkProjectMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    writers: [.listWriter(swim(renderWork))]
  )
  .register(
    folder: "open-source/support",
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    writers: [.itemWriter(swim(renderPage))]
  )
  .register(
    folder: "open-source",
    metadata: OpenSourceProjectMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    writers: [.listWriter(swim(renderOpenSource))]
  )

  // Render the homepage with its own template
  .register(
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    filter: { $0.relativeSource.string == "index.md" },
    claimExcludedItems: false,
    writers: [.itemWriter(swim(renderHome))]
  )

  // Other content pages (about, hire me)
  .register(
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    writers: [.itemWriter(swim(renderPage))]
  )

  // Hardcoded pages, no markdown file backing them
  .createPage("404.html", using: swim(render404))
  .createPage("search/index.html", using: swim(renderSearch))

  // Create article images (prod only)
  .register { saga in
    guard !isDev else {
      return
    }

    print("Generating article images, this takes a bit. If this unexpected, set SAGA_DEV=1.")

    let generator = ImageGenerator(rootPath: SiteMetadata.projectRoot + "/Sources")

    let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }
    for article in articles {
      let destination = (saga.outputPath + "static" + "images" + article.filenameWithoutExtension).string + ".png"
      generator?.generate(article: article, outputPath: destination)
    }
  }

  // Minify all HTML output (prod only)
  .postProcess { html, _ in
    guard !isDev else { return html }
    return Bonsai.minifyHTML(html)
  }

  // Run everything!
  .run()

// Index the site with Pagefind (prod only)
if !isDev {
  let pagefind = Process()
  pagefind.executableURL = URL(fileURLWithPath: "/usr/bin/env")
  pagefind.arguments = ["pnpm", "pagefind", "--site", "deploy"]
  pagefind.currentDirectoryURL = URL(fileURLWithPath: SiteMetadata.projectRoot)
  try pagefind.run()
  pagefind.waitUntilExit()
  if pagefind.terminationStatus != 0 {
    print("pagefind failed with exit code \(pagefind.terminationStatus)")
  }
}
