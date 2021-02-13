import Saga
import HTML
import SagaSwimRenderer

func renderTagFeed(context: PartitionedRenderingContext<String, ArticleMetadata, SiteMetadata>) -> Node {
  AtomFeed(
    title: context.siteMetadata.name,
    author: "Kevin Renskers",
    baseURL: context.siteMetadata.url,
    pagePath: "articles/tag/\(context.key)/",
    feedPath: "articles/tag/\(context.key)/feed.xml",
    items: Array(context.items.prefix(20)),
    summary: { item in
      if let article = item as? Item<ArticleMetadata> {
        return article.summary
      }
      return nil
    }
  ).node()
}
