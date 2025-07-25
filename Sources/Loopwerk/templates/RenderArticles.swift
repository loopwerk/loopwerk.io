import Foundation
import HTML
import Saga

func uniqueTagsWithCount(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  let tags = articles.flatMap { $0.metadata.tags }
  let tagsWithCounts = tags.reduce(into: [:]) { $0[$1, default: 0] += 1 }
  return tagsWithCounts.sorted {
    // Sort by number of articles (descending). If that's the same, sort by title (ascending).
    if $0.1 == $1.1 {
      return $0.0 < $1.0
    }
    return $0.1 > $1.1
  }
}

func renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  section {
    h2 {
      a(class: "bg-light rounded-md overflow-hidden text-2xl font-bold p-4 relative min-h-[4em] flex items-end [&:hover]:bg-orange", href: article.url) { article.title }
    }
    div(class: "bg-sub rounded-b-md overflow-hidden -mt-3 pt-3") {
      div(class: "text-gray gray-links text-sm p-4") {
        span(class: "border-r border-gray pr-2 mr-2") {
          article.date.formatted("MMMM dd, YYYY")
        }
        
        article.metadata.tags.sorted().enumerated().map { index, tag in
          Node.fragment([
            %tagPrefix(index: index, totalTags: article.metadata.tags.count),
             %a(href: "/articles/tag/\(tag.slugified)/") { tag },
          ])
        }
      }
      p(class: "p-4 pt-1") {
        a(href: article.url) { article.summary }
      }
    }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "yyyy"

  let articlesPerYear = Dictionary(grouping: context.items, by: { dateFormatter.string(from: $0.date) })
  let sortedByYearDescending = articlesPerYear.sorted { $0.key > $1.key }
  
  let tagsWithCounts = uniqueTagsWithCount(context.items)

  return baseLayout(canocicalURL: "/articles/", section: .articles, title: "Articles", rssLink: "") {
    // Tag cloud section
    div(class: "mb-12") {
      h2(class: "text-lg font-light") { "Browse by tag" }
      
      div(class: "flex flex-wrap gap-x-2 text-gray gray-links text-sm") {
        tagsWithCounts.map { tag, count in
          a(href: "/articles/tag/\(tag.slugified)/") {
            "\(tag) (\(count))"
          }
        }
      }
    }
    
    // Articles by year
    sortedByYearDescending.map { year, articles in
      div {
        h1(class: "text-4xl font-extrabold mb-12") { year }

        div(class: "grid lg:grid-cols-2 gap-8 mb-16") {
          articles.map { renderArticleForGrid(article: $0) }
        }
      }
    }
  }
}

func _renderArticles(_ articles: [Item<ArticleMetadata>], canocicalURL: String, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  return baseLayout(canocicalURL: canocicalURL, section: .articles, title: "articles in \(pageTitle)", rssLink: rssLink, extraHeader: extraHeader) {
    
    h1(class: "text-4xl font-extrabold mb-12") { pageTitle }
    
    div(class: "grid lg:grid-cols-2 gap-8 mb-16") {
      articles.map { renderArticleForGrid(article: $0) }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")

  return _renderArticles(context.items, canocicalURL: "/articles/tag/\(context.key.slugified)/", title: "#\(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader)
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  _renderArticles(context.items, canocicalURL: "/articles/\(context.key)/", title: "\(context.key)")
}
