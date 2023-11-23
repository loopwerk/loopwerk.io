import Saga
import HTML
import SagaSwimRenderer

func renderFeed(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  AtomFeed(
    title: SiteMetadata.name,
    author: SiteMetadata.author,
    baseURL: SiteMetadata.url,
    feedPath: context.outputPath.string,
    items: Array(context.items.prefix(20)),
    summary: { item in
      return item.summary
    }
  ).node()
}
