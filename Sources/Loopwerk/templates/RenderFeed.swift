import Saga
import HTML
import SagaSwimRenderer

func renderFeed(context: ItemsRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  AtomFeed(
    title: context.siteMetadata.name,
    author: "Kevin Renskers",
    baseURL: context.siteMetadata.url,
    pagePath: "articles/",
    feedPath: "articles/feed.xml",
    items: Array(context.items.prefix(20)),
    summary: { item in
      if let article = item as? Item<ArticleMetadata> {
        return article.summary
      }
      return nil
    }
  ).node()
}
