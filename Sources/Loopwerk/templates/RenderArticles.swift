import Saga
import HTML

func _renderArticles(_ articles: [Page<ArticleMetadata>], title pageTitle: String, siteMetadata: SiteMetadata) -> Node {
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

func renderArticles(context: PagesRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.pages, title: "Articles", siteMetadata: context.siteMetadata)
}

func renderTag(context: TagRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.pages, title: "Articles in \(context.tag)", siteMetadata: context.siteMetadata)
}

func renderYear(context: YearRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  _renderArticles(context.pages, title: "Articles in \(context.year)", siteMetadata: context.siteMetadata)
}
