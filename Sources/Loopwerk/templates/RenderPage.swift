import HTML
import Saga

func renderHome(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")!

  return baseLayout(canocicalURL: context.item.url, section: section, title: context.item.title) {
    div {
      div(class: "prose") {
        Node.raw(context.item.body)
        h2(class: "pb-9") { "Latest articles" }
      }

      div(class: "flex flex-col gap-8") {
        context.allItems
          .compactMap { $0 as? Item<ArticleMetadata> }
          .prefix(5)
          .map { _renderArticleForGrid(article: $0) }

        p(class: "prose") {
          a(href: "/articles/") { "› See all articles" }
        }
      }
    }
  }
}

func renderPage(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")!

  return baseLayout(canocicalURL: context.item.url, section: section, title: context.item.title) {
    article {
      div(class: "prose") {
        h1 { context.item.title }
        Node.raw(context.item.body)
      }
    }
  }
}

func render404(context: PageRenderingContext) -> Node {
  let articles = context.allItems
    .compactMap { $0 as? Item<ArticleMetadata> }
    .prefix(10)

  return baseLayout(canocicalURL: context.outputPath.url, section: .notFound, title: "404") {
    article(class: "prose") {
      h1 { "404" }
      h2 { "Oops!" }
      p { "Your page was not found." }
      p { "Looking for one of the articles?" }

      ul {
        articles.map { article in
          li {
            a(href: article.url) { article.title }
          }
        }
      }

      div {
        a(href: "/articles/") { "› See all articles" }
      }
    }
  }
}
