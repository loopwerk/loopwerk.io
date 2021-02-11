import Saga
import HTML
import SagaSwimRenderer

func renderFeed(context: PagesRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  AtomFeed(
    title: context.siteMetadata.name,
    author: "Kevin Renskers",
    baseURL: context.siteMetadata.url,
    pagesPath: "articles/",
    feedPath: "articles/feed.xml",
    pages: Array(context.pages.prefix(20)),
    summary: { page in
      if let article = page as? Page<ArticleMetadata> {
        return article.summary
      }
      return nil
    }
  ).node()
}
