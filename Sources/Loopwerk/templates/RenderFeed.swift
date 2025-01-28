import HTML
import Saga
import SagaSwimRenderer

func renderFeed(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  AtomFeed(
    title: SiteMetadata.name,
    author: SiteMetadata.author,
    baseURL: SiteMetadata.url,
    feedPath: context.outputPath.string,
    items: context.items,
    summary: { item in
      item.summary
    }
  ).node()
}

func renderTagFeed(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  AtomFeed(
    title: SiteMetadata.name,
    author: SiteMetadata.author,
    baseURL: SiteMetadata.url,
    feedPath: context.outputPath.string,
    items: context.items,
    summary: { item in
      item.summary
    }
  ).node()
}
