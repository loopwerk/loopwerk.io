import Foundation
import HTML
import Saga
import SagaSwimRenderer

func renderAlbums(context: ItemsRenderingContext<AlbumMetadata>) -> Node {
  baseHtml(title: "My favorite albums", canonicalPath: context.outputPath.url, section: .albums) {
    h1 {
      "My favorite albums"
    }
    p {
      "\(context.items.count) albums, ranked"
    }
  } content: {
    ul(class: "fav-grid") {
      context.items.map { album in
        li {
          a(class: "group block", href: album.metadata.linkURL, target: "_blank") {
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
