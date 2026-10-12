import Saga

let seriesPlaceholder = "%SERIES%"

/// All articles in the same series as `article` (including itself), oldest first.
func seriesMembers(of article: Item<ArticleMetadata>, in allItems: [AnyItem]) -> [Item<ArticleMetadata>] {
  guard let key = article.seriesKey else { return [] }
  return allItems
    .compactMap { $0 as? Item<ArticleMetadata> }
    .filter { $0.seriesKey == key }
    .sorted { $0.date < $1.date }
}

/// Replace the `%SERIES%` placeholder with links to every article in the series.
/// The link to the current article gets `aria-current="page"`, which is styled as underlined.
func replaceSeriesPlaceholder(in text: String, article: Item<ArticleMetadata>, allItems: [AnyItem]) -> String {
  guard text.contains(seriesPlaceholder) else { return text }

  let members = seriesMembers(of: article, in: allItems)
  guard !members.isEmpty else { return text }

  let links = members.map { member in
    let title = member.seriesTitle ?? member.title
    let current = member.url == article.url ? #" aria-current="page""# : ""
    return #"<a href="\#(member.url)"\#(current)>\#(title)</a>"#
  }

  return text.replacingOccurrences(of: seriesPlaceholder, with: links.joined(separator: " - "))
}

/// Expand the placeholder in the HTML body of every article.
func expandSeriesPlaceholders(saga: Saga) async throws {
  for article in saga.allItems.compactMap({ $0 as? Item<ArticleMetadata> }) {
    article.body = replaceSeriesPlaceholder(in: article.body, article: article, allItems: saga.allItems)
  }
}
