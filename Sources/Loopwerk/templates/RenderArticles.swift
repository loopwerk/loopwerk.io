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
    h2(class: "text-2xl font-bold mb-2") {
      a(href: article.url) { article.title }
    }
    div(class: "text-gray-2 text-sm [&>a]:text-gray-2 [&>a]:underline [&>a]:hover:text-white mb-4") {
      span(class: "border-r border-gray-2 pr-2 mr-2") {
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
    sortedByYearDescending.map { year, articles in
      div {
        h1(class: "text-4xl font-extrabold mb-12") { year }
        
        div(class: "grid grid-cols-2 gap-10 mb-16") {
          articles.map { renderArticleForGrid(article: $0) }
        }
      }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")
  
  return baseLayout(section: .articles, title: "Articles in \(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader) {
    context.items.map { article in
      section(class: "mb-10") {
        h1(class: "text-2xl font-bold mb-2") {
          a(href: article.url) { article.title }
        }
        renderArticleInfo(article)
        p(class: "mt-4") {
          article.summary
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
