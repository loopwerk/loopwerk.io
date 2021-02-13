import Saga
import HTML

func _renderArticles(_ articles: [Item<ArticleMetadata>], title pageTitle: String, siteMetadata: SiteMetadata) -> Node {
  baseLayout(section: .articles, title: pageTitle, siteMetadata: siteMetadata) {
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
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.items, title: "Articles", siteMetadata: context.siteMetadata)
}

func renderPartition<T>(context: PartitionedRenderingContext<T, ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.items, title: "Articles in \(context.key)", siteMetadata: context.siteMetadata)
}
