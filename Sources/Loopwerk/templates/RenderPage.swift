import HTML
import Saga

func renderPage(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")
  assert(section != nil)

  switch section {
    case .home:
      return renderHome(context: context)
    case .search:
      return renderSearch(context: context)
    case .notFound:
      return render404(context: context)
    default:
      return renderNonHome(context: context)
  }
}

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

@NodeBuilder
func getSearchHeader() -> NodeConvertible {
  script(src: "/pagefind/pagefind-modular-ui.js")
  script {
    Node.raw(
      """
      window.addEventListener('DOMContentLoaded', (event) => {
          let q = new URLSearchParams(window.location.search).get("q");
          document.getElementById("search").value = q;

          const instance = new PagefindModularUI.Instance();
          instance.add(new PagefindModularUI.Input({
              inputElement: "#search"
          }));
          instance.add(new PagefindModularUI.ResultList({
              containerElement: "#results"
          }));
          instance.add(new PagefindModularUI.Summary({
            containerElement: "#summary"
          }));
          instance.triggerSearch(q);
      });
      """
    )
  }
}

func renderSearch(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")!

  return baseLayout(canocicalURL: context.item.url, section: section, title: context.item.title, extraHeader: getSearchHeader()) {
    div(class: "prose") {
      h1 { "Search" }
    }

    // Search
    form(action: "/search/", class: "relative mt-12 mb-20", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
    }

    div(id: "summary")
    div(id: "results")
  }
}

func renderNonHome(context: ItemRenderingContext<PageMetadata>) -> Node {
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

func render404(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")!

  let articles = context.allItems
    .compactMap { $0 as? Item<ArticleMetadata> }
    .prefix(10)

  return baseLayout(canocicalURL: context.item.url, section: section, title: context.item.title) {
    article(class: "prose") {
      Node.raw(context.item.body)

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
