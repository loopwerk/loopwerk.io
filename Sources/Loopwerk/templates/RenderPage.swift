import Saga
import HTML

func renderPage(context: PageRenderingContext<PageMetadata, SiteMetadata>) -> Node {
  let section = Section(rawValue: context.page.metadata.section ?? "")

  return baseLayout(section: section, title: context.page.title, siteMetadata: context.siteMetadata) {
    switch section {
      case .home:
        return renderHome(body: context.page.body)
      case .notFound:
        let articles = context.allPages
          .compactMap { $0 as? Page<ArticleMetadata> }
          .prefix(10)
        return render404(body: context.page.body, articles: Array(articles))
      default:
        return renderNonHome(body: context.page.body)
    }
  }
}

func renderHome(body: String) -> Node {
  div {
    div(class: "header") {
      img(alt: "Loopwerk logo", src: "/static/images/Loopwerk.svg")
    }

    div(class: "content") {
      h1 {
        Node.text("""
A <b>good app</b> is like<br>
a <b>mechanical</b><br>
<b>watch</b>: lots of<br>
moving parts all<br>
working<br>
<b>together</b> to<br>
create a<br>
<b>beautiful</b> and<br>
<b>simple</b> interface.
""")
      }

      div(class: "right") {
        body
      }
    }

    div(class: "footer") {
      a(href: "https://www.unilever.nl", title: "Unilever") { img(alt: "Unilever logo", src: "/static/images/unilever.png") }
      a(href: "https://www.getsling.com", title: "Sling") { img(alt: "Sling logo", src: "/static/images/sling.png") }
      a(href: "https://www.persgroep.nl/", title: "De Persgroep") { img(alt: "De Persgroep logo", src: "/static/images/persgroep.png") }
      a(href: "https://www.siminn.is", title: "Siminn") { img(alt: "Siminn logo", src: "/static/images/siminn.png") }
      a(href: "https://www.last.fm", title: "Last.fm") { img(alt: "Last.fm logo", src: "/static/images/lastfm.png") }
      a(href: "https://www.radio.com", title: "Radio.com") { img(alt: "Radio.com logo", src: "/static/images/radiocom.png") }
      a(href: "https://www.cbs.com", title: "CBS") { img(alt: "CBS logo", src: "/static/images/cbs.png") }
      a(href: "https://www.metrolyrics.com", title: "Metrolyrics") { img(alt: "Metrolyrics logo", src: "/static/images/metrolyrics.png") }
    }
  }
}

func renderNonHome(body: String) -> Node {
  article {
    div(class: "page_content") {
      body
    }
  }
}

func render404(body: String, articles: [Page<ArticleMetadata>]) -> Node {
  article {
    body

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
