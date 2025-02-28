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
      img(alt: "Loopwerk logo", class: "my-24 w-[315px] h-200px mx-auto", src: "/static/images/Loopwerk.svg")
      
      div(class: "my-24 uppercase font-helvetica text-[40px] leading-[1.25] font-thin text-center [&>h1>strong]:font-bold") {
        Node.raw(context.item.body)
      }
      
      div(class: "text-center images") {
        a(href: "https://www.soundradix.com", title: "Sound Radix") { img(alt: "Sound Radix logo", src: "/static/images/soundradix.svg") }
        a(href: "https://www.wetransfer.com", title: "WeTransfer") { img(alt: "WeTransfer logo", src: "/static/images/we.svg") }
        a(href: "https://www.sentry.io", title: "Sentry") { img(alt: "Sentry logo", src: "/static/images/sentry.svg") }
        a(href: "https://www.unilever.nl", title: "Unilever") { img(alt: "Unilever logo", src: "/static/images/unilever.svg") }
        a(href: "https://www.last.fm", title: "Last.fm") { img(alt: "Last.fm logo", src: "/static/images/lastfm.svg") }
        a(href: "https://www.siminn.is", title: "Siminn") { img(alt: "Siminn logo", src: "/static/images/siminn.svg") }
        a(href: "https://www.cbs.com", title: "CBS") { img(alt: "CBS logo", src: "/static/images/cbs.svg") }
        a(href: "https://www.metrolyrics.com", title: "Metrolyrics") { img(alt: "Metrolyrics logo", src: "/static/images/metrolyrics.svg") }
      }
    }
  }
}

@NodeBuilder
func getSearchHeader() -> NodeConvertible {
  script(src: "/pagefind/pagefind-ui.js")
  script {
    Node.raw(
    """
    window.addEventListener('DOMContentLoaded', (event) => {
        let pageFind = new PagefindUI({ element: "#search", showImages: false, pageSize: 20 });
        let q = new URLSearchParams(window.location.search).get("q");
        pageFind.triggerSearch(q);
    });
    """
    )
  }
}

func renderSearch(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")!
  
  return baseLayout(canocicalURL: context.item.url, section: section, title: context.item.title, extraHeader: getSearchHeader()) {
    div(id: "search")
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
