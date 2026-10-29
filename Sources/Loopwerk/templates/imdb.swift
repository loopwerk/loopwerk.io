import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderShows(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "My favorite TV Shows", canonicalPath: context.outputPath.url, section: .shows) {
    h1 {
      "My favorite TV Shows"
    }
    p {
      "\(context.items.count) shows, ranked"
    }
  } content: {
    ul(class: "fav-grid") {
      context.items.map(showCard)
    }
  }
}

func renderMovies(context: ItemsRenderingContext<ImdbMetadata>) -> Node {
  baseHtml(title: "My favorite movies", canonicalPath: context.outputPath.url, section: .movies) {
    h1 {
      "My favorite movies"
    }
    p {
      "\(context.items.count) movies, ranked"
    }
  } content: {
    ul(class: "fav-grid") {
      context.items.map(showCard)
    }
  }
}

private func showCard(_ show: Item<ImdbMetadata>) -> Node {
  li {
    a(class: "group block", href: "https://www.imdb.com/title/\(show.metadata.id)/", target: "_blank") {
      div(class: "fav-poster aspect-[2/3]") {
        img(
          alt: show.title,
          loading: "lazy",
          src: show.metadata.posterURL
        )

        span(class: "fav-rank") {
          "#\(show.metadata.position)"
        }

        span(class: "absolute right-2 top-2 rounded-md bg-accent px-2 py-0.5 text-xs font-bold tabular-nums text-black") {
          "\(show.metadata.rating)/10"
        }
      }

      h2(class: "fav-title") {
        show.title
      }

      p(class: "fav-subtitle") {
        show.metadata.genres.prefix(2).joined(separator: ", ")
      }
    }
  }
}
