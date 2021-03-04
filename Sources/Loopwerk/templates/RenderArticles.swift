import Saga
import HTML

func _renderArticles(_ articles: [Item<ArticleMetadata>], paginator: Paginator?, title pageTitle: String, siteMetadata: SiteMetadata, extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  baseLayout(section: .articles, title: pageTitle, siteMetadata: siteMetadata, extraHeader: extraHeader) {
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

func renderArticles(context: ItemsRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.items, paginator: context.paginator, title: "Articles", siteMetadata: context.siteMetadata)
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata, SiteMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key)/feed.xml", rel: "alternate", title: "\(siteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")
  return _renderArticles(context.items, paginator: context.paginator, title: "Articles in \(context.key)", siteMetadata: context.siteMetadata, extraHeader: extraHeader)
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.items, paginator: context.paginator, title: "Articles in \(context.key)", siteMetadata: context.siteMetadata)
}
