import Bonsai
import Foundation
import Saga
import SagaImageReader
import SagaParsleyMarkdownReader
import SagaPathKit
import SagaSwimRenderer
import SagaUtils
import SwiftDotenv
import SwiftTailwind

try? Dotenv.configure()

struct ArticleMetadata: Metadata {
  let tags: [String]
  let summary: String?
  var archive: Bool?
  var expandedTags: [String]?
  let series: [String]?
  var toc: String?
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

/// Open source projects are listed per category, in this order
enum ProjectCategory: String, Codable, CaseIterable {
  case python = "Python"
  case swift = "Swift"
  case javascript = "JavaScript"
  case objectiveC = "Objective-C"
  case other = "Other"

  var title: String {
    switch self {
      case .javascript: "TypeScript / JavaScript"
      default: rawValue
    }
  }
}

struct OpenSourceProjectMetadata: Metadata {
  let category: ProjectCategory
  let repo: String
}

struct ImdbMetadata: Metadata {
  let position: Int
  let id: String
  let title: String
  let rating: Int
  let genres: [String]

  var posterURL: String {
    "/static/posters/imdb/\(id).jpg"
  }
}

struct AlbumMetadata: Metadata {
  let position: Int
  let id: String
  let artist: String
  let title: String
  let year: Int
  let url: String?

  var posterURL: String {
    "/static/posters/albums/\(id).jpg"
  }

  /// Albums that aren't on Apple Music get a hand-picked slug instead of a collection id
  var appleMusicURL: String? {
    Int(id) != nil ? "https://music.apple.com/album/\(id)" : nil
  }

  /// The URL column from the csv wins, so an album can point anywhere. Albums with neither
  /// a URL nor a store page aren't linked at all.
  var linkURL: String {
    url ?? appleMusicURL ?? "http://www.example.com/"
  }
}

struct GameMetadata: Metadata {
  let position: Int
  let id: String
  let title: String
  let url: String?

  var posterURL: String {
    "/static/posters/games/\(id).jpg"
  }

  var steamURL: String? {
    Int(id) != nil ? "https://store.steampowered.com/app/\(id)/" : nil
  }

  /// The URL column from the csv wins, so a game can point anywhere
  var linkURL: String {
    url ?? steamURL ?? "http://www.example.com/"
  }
}

struct PhotoAlbumMetadata: Metadata {}

/// The date a feed entry was published. For photos that's lastModified, the time their commit gave them
/// (see the Dockerfile's git restore-mtime), unlike the EXIF capture date in `date`.
func feedDate(_ item: AnyItem) -> Date {
  (item as? Item<ArticleMetadata>)?.creationDate ?? item.lastModified
}

/// Newest first by feedDate. Photos committed together share that date, so those are sorted by capture date instead.
/// Compared at whole seconds like the feed's <updated>, since local copies differ by fractions of one.
func feedOrder(_ lhs: AnyItem, _ rhs: AnyItem) -> Bool {
  let lhsDate = Int(feedDate(lhs).timeIntervalSince1970), rhsDate = Int(feedDate(rhs).timeIntervalSince1970)
  return lhsDate == rhsDate ? lhs.date > rhs.date : lhsDate > rhsDate
}

/// Photos have no title of their own, so their feed entries are named after their album and capture date
func feedTitle(_ item: AnyItem) -> String {
  guard let photo = item as? Item<ImageMetadata> else { return item.title }
  return "\(photo.parent(as: PhotoAlbumMetadata.self).title), \(photo.date.formatted("MMMM d, yyyy"))"
}

extension Item where M == ArticleMetadata {
  var archive: Bool {
    return metadata.archive ?? false
  }

  var expandedTags: [String] {
    return metadata.expandedTags ?? metadata.tags
  }

  /// Technical articles and journal posts share everything but their folder, which decides their section
  var section: Section {
    relativeSource.components.first == "journal" ? .journal : .articles
  }

  var year: Int {
    return Calendar.current.component(.year, from: date)
  }

  /// Frontmatter like `series: year-in-review, 2025` puts the article in a series
  var seriesKey: String? {
    return metadata.series?[safeIndex: 0]
  }

  var seriesTitle: String? {
    return metadata.series?[safeIndex: 1]
  }

  var creationDate: Date {
    // Use file modification date if it matches the filename date (accounting for timezone)
    // The git-restore-mtime script should have set proper file timestamps to the FIRST commit
    let amsterdamTimeZone = TimeZone(identifier: "Europe/Amsterdam")!
    var calendar = Calendar.current
    calendar.timeZone = amsterdamTimeZone

    let fileCreationComponents = calendar.dateComponents([.year, .month, .day], from: lastModified)
    let selfDateComponents = calendar.dateComponents([.year, .month, .day], from: date)

    // Check if the dates match in Amsterdam timezone
    if fileCreationComponents.year == selfDateComponents.year,
       fileCreationComponents.month == selfDateComponents.month,
       fileCreationComponents.day == selfDateComponents.day
    {
      return lastModified
    }

    // Fallback to self.date (filename date at noon)
    var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = TimeZone.current

    return Calendar.current.date(from: components) ?? date
  }
}

enum SiteMetadata {
  static let url = URL(string: "https://www.loopwerk.io")!
  static let name = "Loopwerk"
  static let author = "Kevin Renskers"
  static let now = Date()
  static let available = true
  static let projectRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .path
}

/// Journal posts live at /journal/slug/, articles get the year in their permalink
let journalProcessor = sequence(
  unescapeMarkVar,
  swiftSoupProcessor({ doc, item in item.metadata.toc = try buildTOCList(doc) }, convertAsides, processExternalLinks, addCodeBlockTitles),
  syntaxHighlight,
  publicationDateInFilename,
  expandTags
)

let articleProcessor = sequence(journalProcessor, permalink)

let tailwind = SwiftTailwind(version: "4.2.4")

try await Saga(input: "content", output: ".deploy")
  // Compile tailwind to output.css
  .beforeRead { saga in
    if let path = saga.buildReason.changedFile(),
       path.extension != "css",
       !path.components.contains("templates")
    {
      // It needs to be a css file or a template file, otherwise, skip it
      return
    }

    try await tailwind.run(
      input: "content/static/input.css",
      output: "content/static/output.css",
      options: .minify
    )
  }

  // Don't trigger a rebuild when output.css changes, otherwise we get into an endless loop
  .ignoreChanges("output.css")

  // Same for the posters and maps we download during the build
  .ignoreChanges("content/static/posters/*/*")
  .ignoreChanges("content/static/maps/*")

  // Non-archived articles with a publication date in the past.
  // We make sure that the filtered-out articles (i.e. archived articles) are NOT
  // marked as handled. Otherwise the next step can't process the archived articles.
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownWithAttributesReader],
    itemProcessor: articleProcessor,
    filter: { $0.archive == false && ($0.date < Date() || Saga.isDev) },
    claimExcludedItems: false,
    writers: [
      .itemWriter(swim(renderArticle)),
      .listWriter(swim(renderArticles)),
      .listWriter(renderArticlesMarkdown, output: "index.md"),
      .tagWriter(swim(renderTag), tags: \.expandedTags),
      .yearWriter(swim(renderYear)),

      // Atom feed for all articles, and a feed per tag
      .listWriter(
        Saga.atomFeed(
          title: "\(SiteMetadata.name) articles",
          author: SiteMetadata.author,
          baseURL: SiteMetadata.url,
          limit: 20,
          summary: \.metadata.summary,
          date: \.creationDate
        ),
        output: "feed.xml"
      ),
      .tagWriter(
        { context in
          Saga.atomFeed(
            title: "\(SiteMetadata.name) articles tagged \(context.key)",
            author: SiteMetadata.author,
            baseURL: SiteMetadata.url,
            limit: 20,
            summary: \.metadata.summary,
            date: \.creationDate
          )(context)
        },
        output: "tag/[key]/feed.xml", tags: \.expandedTags
      ),
    ]
  )

  // Archived articles: they get their own detail page but are not part of the list pages nor atom feeds
  .register(
    folder: "articles",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: articleProcessor,
    filter: { $0.archive == true && ($0.date < Date() || Saga.isDev) },
    writers: [
      .itemWriter(swim(renderArticle)),
    ]
  )

  // Journal: the personal writing, with its own list pages and feed
  .register(
    folder: "journal",
    metadata: ArticleMetadata.self,
    readers: [.parsleyMarkdownWithAttributesReader],
    itemProcessor: journalProcessor,
    filter: { $0.date < Date() || Saga.isDev },
    writers: [
      .itemWriter(swim(renderArticle)),
      .listWriter(swim(renderJournal)),
      .listWriter(renderJournalMarkdown, output: "index.md"),
      .tagWriter(swim(renderJournalTag), tags: \.expandedTags),
      .listWriter(
        Saga.atomFeed(
          title: "\(SiteMetadata.name) journal",
          author: SiteMetadata.author,
          baseURL: SiteMetadata.url,
          limit: 20,
          summary: \.metadata.summary,
          date: \.creationDate
        ),
        output: "feed.xml"
      ),
    ]
  )

  // Portfolio stuff (paid work and open source projects)
  .register(
    folder: "work",
    metadata: WorkProjectMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: swiftSoupProcessor(convertAsides, processExternalLinks),
    writers: [
      .listWriter(swim(renderWork)),
      .listWriter(renderWorkMarkdown, output: "index.md"),
    ]
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
    sorting: { $0.title < $1.title },
    writers: [
      .listWriter(swim(renderOpenSource)),
      .listWriter(renderOpenSourceMarkdown, output: "index.md"),
    ]
  )

  // Photo albums from markdown files, with nested photo pages per album
  .register(
    folder: "photos",
    metadata: PhotoAlbumMetadata.self,
    itemProcessor: { album in
      album.title = albumTitle(folder: album.title)
    },
    writers: [
      .listWriter(swim(renderPhotoAlbums)),
      .itemWriter(swim(renderPhotoAlbum)),
    ],
    nested: { nested in
      nested.register(
        metadata: ImageMetadata.self,
        readers: [.imageReader],
        itemProcessor: sequence(downloadMap, photoTitle, photoFeedBody),
        writers: [
          .itemWriter(swim(renderPhoto)),
        ]
      )
    }
  )

  // Load tv shows
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "shows", kind: .tv) },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [
      .listWriter(swim(renderShows), output: "shows/index.html"),
      .listWriter(renderShowsMarkdown, output: "shows/index.md"),
    ]
  )

  // Load movies
  .register(
    metadata: ImdbMetadata.self,
    fetch: { try await fetch(csvName: "movies", kind: .movie) },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [
      .listWriter(swim(renderMovies), output: "movies/index.html"),
      .listWriter(renderMoviesMarkdown, output: "movies/index.md"),
    ]
  )

  // Load games
  .register(
    metadata: GameMetadata.self,
    fetch: { try await fetchGames() },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [
      .listWriter(swim(renderGames), output: "games/index.html"),
      .listWriter(renderGamesMarkdown, output: "games/index.md"),
    ]
  )

  // Load albums
  .register(
    metadata: AlbumMetadata.self,
    fetch: { try await fetchAlbums() },
    cacheKey: nil,
    sorting: { $0.metadata.position < $1.metadata.position },
    writers: [
      .listWriter(swim(renderAlbums), output: "albums/index.html"),
      .listWriter(renderAlbumsMarkdown, output: "albums/index.md"),
    ]
  )

  // Content pages (home, about, legal notice)
  .register(
    metadata: PageMetadata.self,
    readers: [.parsleyMarkdownReader],
    itemProcessor: sequence(lastUpdated, swiftSoupProcessor(convertAsides, processExternalLinks, addHeadingAnchors)),
    writers: [.itemWriter(swim(renderPage))]
  )

  // Sitemap
  .createPage("sitemap.xml", using: Saga.sitemap(baseURL: SiteMetadata.url, filter: { path, item in
    if path.string.hasSuffix("feed.xml") || path.extension == "md" {
      return false
    }
    if let article = item as? Item<ArticleMetadata> {
      return !article.archive
    }
    return true
  }))

  // Hardcoded pages, no markdown file backing them
  .createPage("404.html", using: swim(render404))
  .createPage("feeds/index.html", using: swim(renderFeeds))

  // Atom feed of all photos. A writer on the nested photos step would create a feed per album instead.
  .createPage("photos/feed.xml", using: Saga.atomFeed(
    title: "\(SiteMetadata.name) photos",
    author: SiteMetadata.author,
    baseURL: SiteMetadata.url,
    filter: { $0 is Item<ImageMetadata> },
    sorting: feedOrder,
    limit: 20,
    itemTitle: feedTitle,
    date: feedDate
  ))

  // Atom feed of everything: articles, journal posts and photos
  .createPage("feed.xml", using: Saga.atomFeed(
    title: "\(SiteMetadata.name) feed of everything",
    author: SiteMetadata.author,
    baseURL: SiteMetadata.url,
    filter: { item in
      if let article = item as? Item<ArticleMetadata> {
        return !article.archive
      }
      return item is Item<ImageMetadata>
    },
    sorting: feedOrder,
    limit: 20,
    itemTitle: feedTitle,
    summary: { ($0 as? Item<ArticleMetadata>)?.metadata.summary },
    date: feedDate
  ))

  // Expand %SERIES% placeholders in article bodies. This needs all articles, so it can't be an item processor.
  .afterRead(expandSeriesPlaceholders)

  // Minify all HTML output (prod only)
  .postProcess { html, path in
    guard !Saga.isDev, path.extension != "md" else { return html }
    return Bonsai.minifyHTML(html)
  }

  // Markdown twins, for content negotiation (see nginx.conf)
  .afterWrite(writeMarkdownFiles)

  // Generate the CV PDF from the CV page's markdown
  .afterWrite { saga in
    guard let cv = saga.allItems.compactMap({ $0 as? Item<PageMetadata> }).first(where: { $0.url == "/about/cv/" }) else { return }

    let cvFolder = saga.outputPath + "about" + "cv"
    let document = cvFolder + "pdf.html"
    try document.write(renderCVDocument(item: cv).toString())
    defer { try? document.delete() }

    let weasyprint = Process()
    weasyprint.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    weasyprint.arguments = ["weasyprint", document.string, (saga.outputPath + "about" + "KevinRenskers.pdf").string]
    try weasyprint.run()
    weasyprint.waitUntilExit()
    if weasyprint.terminationStatus != 0 {
      print("weasyprint failed with exit code \(weasyprint.terminationStatus)")
    }
  }

  // Create article images (prod only)
  .afterWrite { saga in
    guard !Saga.isDev else { return }

    print("Generating article images, this takes a bit. If this unexpected, set SAGA_DEV=1.")
    let generator = ImageGenerator()

    let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }
    for article in articles {
      let destination = (saga.outputPath + "static" + "images" + article.filenameWithoutExtension).string + ".png"
      generator?.generate(article: article, outputPath: destination)
    }
  }

  // Index the site with Pagefind (prod only)
  .afterWrite { _ in
    guard !Saga.isDev else { return }

    let pagefind = Process()
    pagefind.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    pagefind.arguments = ["pnpm", "pagefind", "--site", ".deploy"]
    pagefind.currentDirectoryURL = URL(fileURLWithPath: SiteMetadata.projectRoot)
    try pagefind.run()
    pagefind.waitUntilExit()
    if pagefind.terminationStatus != 0 {
      print("pagefind failed with exit code \(pagefind.terminationStatus)")
    }
  }

  // Run everything!
  .run()
