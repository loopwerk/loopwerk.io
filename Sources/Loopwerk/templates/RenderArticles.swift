import Saga
import HTML
import Foundation

func uniqueTagsWithCount(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  let tags = articles.flatMap { $0.metadata.tags }
  let tagsWithCounts = tags.reduce(into: [:]) { $0[$1, default: 0] += 1 }
  return tagsWithCounts.sorted { $0.1 > $1.1 }
}

func renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  section {
    h2 {
      a(href: article.url) { article.title }
    }
    div(class: "article_info") {
      span(class: "time") {
        article.published.formatted("MMMM dd, YYYY")
      }
      
      article.metadata.tags.sorted().enumerated().map { index, tag in
        Node.fragment([
          %tagPrefix(index: index, totalTags: article.metadata.tags.count),
           %a(href: "/articles/tag/\(tag.slugified)/") { tag }
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
    div(class: "flex") {
      div(class: "list") {
        sortedByYearDescending.map { year, articles in
          div(class: "archive") {
            h1 { year }
            
            div(class: "grid") {
              articles.map { renderArticleForGrid(article: $0) }
            }
          }
        }
      }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")
  
  return baseLayout(section: .articles, title: "Articles in \(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader) {
    div(class: "list") {
      context.items.map { article in
        section {
          h1 {
            a(href: article.url) { article.title }
          }
          renderArticleInfo(article)
          p {
            article.summary
          }
          p(class: "more") {
            a(class: "more", href: article.url) { "read more" }
          }
        }
      }
    }
    
    if let paginator = context.paginator {
      ul(class: "pagination") {
        li(class: "newer") {
          if let previous = paginator.previous {
            a(href: previous.url) { "newer articles" }
          }
        }
        li(class: "older") {
          if let next = paginator.next {
            a(href: next.url) { "older articles" }
          }
        }
      }
    }
  }
}
