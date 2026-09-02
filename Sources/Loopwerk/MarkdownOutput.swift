import Foundation
import Saga
import SagaPathKit

private let markdownDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  formatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
  return formatter
}()

/// Write a markdown twin next to each article's index.html, served by nginx to clients
/// sending "Accept: text/markdown". The source file is emitted verbatim, except that the
/// publication date (which only exists in the source filename) is injected into the
/// frontmatter so agents can see when an article was written.
func writeMarkdownFiles(saga: Saga) async throws {
  let articles = saga.allItems.compactMap { $0 as? Item<ArticleMetadata> }

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
