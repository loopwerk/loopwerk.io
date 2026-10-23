import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderAlbums(context: ItemsRenderingContext<AlbumMetadata>) -> Node {
  baseHtml(title: "My favorite albums", canonicalPath: context.outputPath.url, section: .albums) {
    header(class: "page-header") {
      h1 {
        "My favorite albums"
      }
      p {
        "\(context.items.count) albums, ranked"
      }
    }

    ul(class: "fav-grid") {
      context.items.map { album in
        li {
          if let url = album.metadata.linkURL {
            a(class: "group block", href: url, target: "_blank") {
              albumCardContents(album)
            }
          } else {
            albumCardContents(album)
          }
        }
      }
    }
  }
}

@NodeBuilder
private func albumCardContents(_ album: Item<AlbumMetadata>) -> Node {
  div(class: "fav-poster aspect-square") {
    img(
      alt: "\(album.metadata.artist) - \(album.title)",
      loading: "lazy",
      src: album.metadata.posterURL
    )

    span(class: "fav-rank") {
      "#\(album.metadata.position)"
    }
  }

  h2(class: "fav-title") {
    album.title
  }

  p(class: "fav-subtitle") {
    "\(album.metadata.artist) · \(album.metadata.year)"
  }
}
