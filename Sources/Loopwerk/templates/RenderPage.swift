import HTML
import Saga

func renderPage(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = Section(rawValue: context.item.metadata.section ?? "")

  return baseLayout(section: section, title: context.item.title) {
    switch section {
      case .home:
        return renderHome(body: context.item.body)
      case .notFound:
        let articles = context.allItems
          .compactMap { $0 as? Item<ArticleMetadata> }
          .prefix(10)
        return render404(body: context.item.body, articles: Array(articles))
      default:
        return renderNonHome(body: context.item.body)
    }
  }
}

func renderHome(body: String) -> Node {
  div {
    img(alt: "Loopwerk logo", class: "my-24 w-[315px] h-200px mx-auto", src: "/static/images/Loopwerk.svg")

    div(class: "my-24 uppercase font-helvetica text-[40px] leading-[1.25] font-thin text-center [&>h1>strong]:font-bold") {
      Node.raw(body)
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

func renderNonHome(body: String) -> Node {
  article {
    div(class: "prose") {
      Node.raw(body)
    }
  }
}

func render404(body: String, articles: [Item<ArticleMetadata>]) -> Node {
  article {
    Node.raw(body)

    ul {
      articles.map { article in
        li {
          a(href: article.url) { article.title }
        }
      }
    }

    div {
      a(class: "more", href: "/articles/") { "archive" }
    }
  }
}
