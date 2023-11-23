import Saga
import HTML
import SagaSwimRenderer

func renderTagFeed(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
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
