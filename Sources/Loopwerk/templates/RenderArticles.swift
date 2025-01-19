import Saga
import HTML

func uniqueTagsWithCount(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  let tags = articles.flatMap { $0.metadata.tags }
  let tagsWithCounts = tags.reduce(into: [:]) { $0[$1, default: 0] += 1 }
  return tagsWithCounts.sorted { $0.1 > $1.1 }
}

func _renderArticles(_ articles: [Item<ArticleMetadata>], tags: [(String, Int)], paginator: Paginator?, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  baseLayout(section: .articles, title: pageTitle, rssLink: rssLink, extraHeader: extraHeader) {
    
    div(class: "flex") {
      div(class: "list") {
        articles.map { article in
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
      
      if !tags.isEmpty {
        div(class: "sidebar") {
          ul {
            tags.map { (tag: String, count: Int) in
              li {
                a(href: "/articles/tag/\(tag.slugified)/") { tag }
                %":"
                "\(count)"
              }
            }
          }
        }
      }
    }

    if let paginator = paginator {
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

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  let allArticles = context.allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let tags = uniqueTagsWithCount(allArticles as [Item<ArticleMetadata>])
  return _renderArticles(context.items, tags: tags, paginator: context.paginator, title: "Articles")
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")
  return _renderArticles(context.items, tags: [], paginator: context.paginator, title: "Articles in \(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader)
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  _renderArticles(context.items, tags: [], paginator: context.paginator, title: "Articles in \(context.key)")
}
