import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderGames(context: ItemsRenderingContext<GameMetadata>) -> Node {
  baseHtml(title: "My favorite games", canonicalPath: context.outputPath.url, section: .games) {
    header(class: "page-header") {
      h1 {
        "My favorite games"
      }
      p {
        "\(context.items.count) games, ranked"
      }
    }

    ul(class: "fav-grid") {
      context.items.map { game in
        li {
          if let url = game.metadata.linkURL {
            a(class: "group block", href: url, target: "_blank") {
              gameCardContents(game)
            }
          } else {
            gameCardContents(game)
          }
        }
      }
    }
  }
}

@NodeBuilder
private func gameCardContents(_ game: Item<GameMetadata>) -> Node {
  div(class: "fav-poster aspect-[2/3]") {
    img(
      alt: game.title,
      loading: "lazy",
      src: game.metadata.posterURL
    )

    span(class: "fav-rank") {
      "#\(game.metadata.position)"
    }
  }

  h2(class: "fav-title") {
    game.title
  }
}
