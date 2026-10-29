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
/// clients sending "Accept: text/markdown". Pages are emitted without their frontmatter. Articles
/// keep theirs, with the publication date (which only exists in the source filename) injected
/// so agents can see when an article was written.
func writeMarkdownFiles(saga: Saga) async throws {
  let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let pages = saga.allItems.compactMap { $0 as? Item<PageMetadata> }

  let cvProjectsMarkdown = try cvProjects(saga: saga)
    .map { project in
      // The source markdown without its `# Title` line, which becomes the `####` heading
      let markdown = try withoutFrontmatter(project.absoluteSource.read())
      let body = markdown.hasPrefix("# ") ? markdown.drop(while: { $0 != "\n" }).trimmingCharacters(in: .whitespacesAndNewlines) : markdown
      return "#### \(project.title) (\(project.metadata.tech.joined(separator: ", ")))\n\n\(body)"
    }
    .joined(separator: "\n\n")

  for page in pages {
    let destination = saga.outputPath + page.relativeDestination.parent() + "index.md"
    try destination.parent().mkpath()
    try destination.write(replacePlaceholders(in: withoutFrontmatter(page.absoluteSource.read()), markdown: true)
      .replacingOccurrences(of: "{{ cv_projects }}", with: cvProjectsMarkdown))
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

private func withoutFrontmatter(_ markdown: String) -> String {
  let lines = markdown.components(separatedBy: "\n")
  guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else { return markdown }
  return lines[(end + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
}
