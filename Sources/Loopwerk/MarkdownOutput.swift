import Foundation
import Saga
import SagaPathKit

private let markdownDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  formatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
  return formatter
}()

/// Write a markdown twin next to each article's and page's index.html, served by nginx to
/// clients sending "Accept: text/markdown". The source file is emitted verbatim, except that
/// for articles the publication date (which only exists in the source filename) is injected
/// into the frontmatter so agents can see when an article was written.
func writeMarkdownFiles(saga: Saga) async throws {
  let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let pages = saga.allItems.compactMap { $0 as? Item<PageMetadata> }

  for page in pages {
    let destination = saga.outputPath + page.relativeDestination.parent() + "index.md"
    try destination.parent().mkpath()
    try destination.write(page.absoluteSource.read() as String)
  }

  for article in articles {
    var markdown: String = try article.absoluteSource.read()
    let dateLine = "date: \(markdownDateFormatter.string(from: article.date))\n"

    if markdown.hasPrefix("---\n") {
      markdown.insert(contentsOf: dateLine, at: markdown.index(markdown.startIndex, offsetBy: 4))
    } else {
      markdown = "---\n\(dateLine)---\n\n" + markdown
    }

    let destination = saga.outputPath + article.relativeDestination.parent() + "index.md"
    try destination.parent().mkpath()
    try destination.write(markdown)
  }
}

// Markdown twins of the list pages, written by list writers with output "index.md"

private func articleLine(_ article: Item<ArticleMetadata>) -> String {
  var line = "- [\(article.title)](\(article.url)), \(markdownDateFormatter.string(from: article.date))"
  if let summary = article.metadata.summary {
    line += ": \(summary)"
  }
  return line + "\n"
}

func renderArticlesMarkdown(context: ItemsRenderingContext<ArticleMetadata>) -> String {
  return "# Articles\n\n" + context.items.map(articleLine).joined()
}

func renderJournalMarkdown(context: ItemsRenderingContext<ArticleMetadata>) -> String {
  return "# Journal\n\n" + context.items.map(articleLine).joined()
}

/// The source markdown of an item, without its frontmatter and leading `# Title` heading
private func markdownBody(_ item: AnyItem) throws -> String {
  var lines = try (item.absoluteSource.read() as String).components(separatedBy: "\n")[...]

  if lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") {
    lines = lines[(end + 1)...]
  }

  lines = lines.drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
  if lines.first?.hasPrefix("# ") == true {
    lines = lines.dropFirst()
  }

  return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
}

func renderWorkMarkdown(context: ItemsRenderingContext<WorkProjectMetadata>) throws -> String {
  var markdown = "# Work\n\n\(workIntro)\n"

  for app in context.items {
    markdown += "\n## \(app.title)\n\n\(try markdownBody(app))\n"
    if let url = app.metadata.url {
      markdown += "\n\(url.contains(".apple.com") ? "App Store" : "Website"): \(url)\n"
    }
  }

  return markdown
}

func renderOpenSourceMarkdown(context: ItemsRenderingContext<OpenSourceProjectMetadata>) throws -> String {
  var markdown = "# Open Source\n\n\(openSourceIntro)\n"

  let projectsByCategory = Dictionary(grouping: context.items, by: { $0.metadata.category })

  for category in ProjectCategory.allCases {
    guard let projects = projectsByCategory[category] else { continue }
    markdown += "\n## \(category.title)\n"

    for project in projects {
      markdown += "\n### \(project.title)\n\n\(try markdownBody(project))\n\nGitHub: https://github.com/\(project.metadata.repo)\n"
    }
  }

  return markdown
}

private func favoritesMarkdown<M>(title: String, items: [Item<M>], line: (Item<M>) -> String) -> String {
  return "# \(title)\n\n" + items.enumerated().map {
    "\($0.offset + 1). \(line($0.element))"
  }.joined(separator: "\n") + "\n"
}

private func link(_ text: String, _ url: String) -> String {
  return "[\(text)](\(url))"
}

func renderShowsMarkdown(context: ItemsRenderingContext<ImdbMetadata>) -> String {
  favoritesMarkdown(title: "My favorite TV Shows", items: context.items) {
    link($0.title, "https://www.imdb.com/title/\($0.metadata.id)/")
  }
}

func renderMoviesMarkdown(context: ItemsRenderingContext<ImdbMetadata>) -> String {
  favoritesMarkdown(title: "My favorite movies", items: context.items) {
    link($0.title, "https://www.imdb.com/title/\($0.metadata.id)/")
  }
}

func renderGamesMarkdown(context: ItemsRenderingContext<GameMetadata>) -> String {
  favoritesMarkdown(title: "My favorite games", items: context.items) {
    link($0.title, $0.metadata.linkURL)
  }
}

func renderAlbumsMarkdown(context: ItemsRenderingContext<AlbumMetadata>) -> String {
  favoritesMarkdown(title: "My favorite albums", items: context.items) {
    link("\($0.metadata.artist) - \($0.title)", $0.metadata.linkURL)
  }
}
