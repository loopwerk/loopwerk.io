import Foundation
import HTML
import Saga

func uniqueTagsWithCount(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  let tags = articles.flatMap { $0.metadata.tags }
  let tagsWithCounts = tags.reduce(into: [:]) { $0[$1, default: 0] += 1 }
  return tagsWithCounts.sorted { $0.1 > $1.1 }
}

func renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  section {
    h2(class: "text-2xl font-bold mb-2") {
      a(class: "[&:hover]:border-b border-orange", href: article.url) { article.title }
    }
    div(class: "text-gray gray-links text-sm mb-4") {
      span(class: "border-r border-gray pr-2 mr-2") {
        article.published.formatted("MMMM dd, YYYY")
      }

      article.metadata.tags.sorted().enumerated().map { index, tag in
        Node.fragment([
          %tagPrefix(index: index, totalTags: article.metadata.tags.count),
          %a(href: "/articles/tag/\(tag.slugified)/") { tag },
        ])
      }
    }
    p {
      a(href: article.url) { article.summary }
    }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy"

  let articlesPerYear = Dictionary(grouping: context.items, by: { dateFormatter.string(from: $0.published) })
  let sortedByYearDescending = articlesPerYear.sorted { $0.key > $1.key }

  return baseLayout(section: .articles, title: "Articles", rssLink: "", extraHeader: "") {
    sortedByYearDescending.map { year, articles in
      div {
        h1(class: "text-4xl font-extrabold mb-12") { year }

        div(class: "grid lg:grid-cols-2 gap-10 mb-16") {
          articles.map { renderArticleForGrid(article: $0) }
        }
      }
    }
  }
}

func _renderArticles(_ articles: [Item<ArticleMetadata>], title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  return baseLayout(section: .articles, title: pageTitle, rssLink: rssLink, extraHeader: extraHeader) {
    articles.map { article in
      section(class: "mb-10") {
        h1(class: "text-2xl font-bold mb-2") {
          a(class: "[&:hover]:border-b border-orange", href: article.url) { article.title }
        }
        renderArticleInfo(article)
        p(class: "mt-4") {
          a(href: article.url) { article.summary }
        }
      }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")

  return _renderArticles(context.items, title: "Articles in \(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader)
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  _renderArticles(context.items, title: "Articles in \(context.key)")
}
