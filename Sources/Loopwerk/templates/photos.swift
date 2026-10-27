import Foundation
import HTML
import Saga
import SagaImageReader

extension Item where M == ImageMetadata {
  var thumbnailURL: String {
    let album = relativeSource.parent().lastComponent
    let path = "static/thumbnails/\(album)/\(relativeSource.lastComponentWithoutExtension).webp"
    return FileManager.default.fileExists(atPath: "content/\(path)") ? "/\(path)" : "/\(relativeSource)"
  }

  /// Id of the photo's thumbnail on the album page, which closing the photo scrolls back into view
  var thumbnailID: String {
    "photo-\(relativeSource.lastComponentWithoutExtension)"
  }
}

private func photoCount(_ count: Int) -> String {
  "\(count) \(count == 1 ? "photo" : "photos")"
}

// MARK: - Albums

func renderPhotoAlbums(context: ItemsRenderingContext<PhotoAlbumMetadata>) -> Node {
  baseHtml(title: "Photos", canonicalPath: context.outputPath.url, section: .photos) {
    header(class: "page-header") {
      h1 { "Photos" }
      p { "\(context.items.count) \(context.items.count == 1 ? "album" : "albums")" }
    }

    ul(class: "grid grid-cols-2 gap-8 lg:grid-cols-3 lg:gap-12") {
      context.items.map { album in
        li { albumCard(album) }
      }
    }
  }
}

private func albumCard(_ album: Item<PhotoAlbumMetadata>) -> Node {
  let photos = album.children(as: ImageMetadata.self)
  let cover = Array(photos.prefix(4))

  return a(class: "group block", href: album.url) {
    div(class: "grid aspect-square grid-cols-2 grid-rows-2 overflow-hidden") {
      (0 ..< 4).map { index in
        div(class: "relative bg-textfg/5") {
          if index < cover.count {
            img(
              alt: cover[index].title,
              // Safari draws the rows at the half-pixel offset the text above can leave, showing a light seam
              // between them. The top photos overlap the bottom row by 1px to cover it.
              class: index < 2 ? "absolute inset-x-0 top-0 z-10 h-[calc(100%+1px)] w-full object-cover" : "absolute inset-0 h-full w-full object-cover",
              decoding: "async",
              loading: "lazy",
              src: cover[index].thumbnailURL
            )
          }
        }
      }
    }
    h2(class: "mt-3 font-semibold group-hover:text-accent") { album.title }
    p(class: "mt-1 text-sm text-textfg/60") { photoCount(photos.count) }
  }
}

// MARK: - Album

func renderPhotoAlbum(context: ItemRenderingContext<PhotoAlbumMetadata>) -> Node {
  let album = context.item
  let photos = album.children(as: ImageMetadata.self)

  return baseHtml(title: "Photos | \(album.title)", canonicalPath: context.item.url, section: .photos) {
    header(class: "page-header") {
      h1 { album.title }
      p { photoCount(photos.count) }
    }

    div(class: "grid grid-cols-1 gap-x-8 gap-y-12 md:grid-cols-2 lg:grid-cols-3 lg:gap-x-12 lg:gap-y-16") {
      photos.map { photo in
        a(class: "group block aspect-square overflow-hidden", href: photo.url, id: photo.thumbnailID) {
          img(
            alt: photo.title,
            class: "h-full w-full object-cover transition duration-500 group-hover:scale-105",
            decoding: "async",
            height: "\(photo.metadata.imageHeight)",
            loading: "lazy",
            src: photo.thumbnailURL,
            width: "\(photo.metadata.imageWidth)"
          )
        }
      }
    }

    // Closing a photo after paging to other photos comes back here with "#return=<thumbnail id>" (see
    // photoNavigation). The hash is removed right away and that photo's thumbnail is centered on the screen.
    script {
      Node.raw(
        """
        (() => {
          const match = location.hash.match(/^#return=(.+)$/);
          if (!match) return;
          history.replaceState(history.state, "", location.pathname + location.search);
          document.getElementById(decodeURIComponent(match[1]))?.scrollIntoView({ block: "center" });
        })();
        """
      )
    }
  }
}

// MARK: - Photo

func renderPhoto(context: ItemRenderingContext<ImageMetadata>) -> Node {
  let photo = context.item
  let album = photo.parent(as: PhotoAlbumMetadata.self)
  let date = photo.date.formatted("MMMM d, yyyy")

  // No site nav, footer or centered container: the photo gets the whole screen
  return rootHtml(
    title: "Photos | \(album.title) | \(date)",
    canonicalPath: context.item.url,
    section: .photos,
    ogImage: ("/\(photo.relativeSource)", photo.metadata.imageWidth, photo.metadata.imageHeight)
  ) {
    a(class: "fixed right-4 top-4 z-10 p-2 text-textfg hover:text-accent print:hidden", href: album.url, id: "photo-close", title: "Close", customAttributes: ["aria-label": "Close", "data-thumbnail": photo.thumbnailID]) {
      Node.raw(#"<svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
    }

    div(class: "hidden pb-8 print:block") {
      Node.raw(logoSVG)
    }

    main(class: "lg:grid lg:grid-cols-[20rem_minmax(0,1fr)] print:block") {
      // On desktop the photo column is exactly as tall as the screen, so the previous/next links stay put whatever the photo's orientation
      div(class: "flex flex-col px-6 pt-16 pb-6 lg:order-last lg:h-screen lg:p-10 lg:pt-16 print:h-auto print:p-0") {
        div(class: "flex min-h-0 flex-1 items-center justify-center print:justify-start") {
          img(
            alt: photo.title,
            class: "h-auto max-h-[80vh] w-auto max-w-full border-white border-[16px] md:border-[24px] lg:max-h-full print:max-h-[22cm] print:border-0",
            decoding: "async",
            height: "\(photo.metadata.imageHeight)",
            src: "/\(photo.relativeSource)",
            width: "\(photo.metadata.imageWidth)"
          )
        }

        // Two fixed columns with a dimmed stand-in for a missing link, so the links don't move between photos
        nav(class: "mt-6 grid grid-cols-2 gap-8 text-sm print:hidden", customAttributes: ["aria-label": "Photos"]) {
          if let previous = context.previous {
            a(class: "justify-self-end hover:text-accent", href: previous.url, id: "photo-previous", customAttributes: ["data-image": "/\(previous.relativeSource)"]) { "← Previous" }
          } else {
            span(class: "justify-self-end text-textfg/30") { "← Previous" }
          }
          if let next = context.next {
            a(class: "justify-self-start hover:text-accent", href: next.url, id: "photo-next", customAttributes: ["data-image": "/\(next.relativeSource)"]) { "Next →" }
          } else {
            span(class: "justify-self-start text-textfg/30") { "Next →" }
          }
        }
      }

      aside(class: "flex flex-col justify-between gap-12 p-6 lg:h-screen lg:p-10 text-xs text-textfg/60 print:hidden") {
        photoDetails(photo, album: album)

        div(class: "flex flex-col gap-1 text-textfg/60 links") {
          p { "© 2009-\(Calendar.current.component(.year, from: SiteMetadata.now)) Kevin Renskers" }
          a(href: "/legal/") { "legal notice" }
        }
      }
    }

    // Escape closes the photo, the left and right arrow keys go to the previous and next photo.
    // Closing a photo opened straight from the album goes back in history, so the album keeps its exact scroll position.
    // After paging to other photos it opens the album with "#return=<thumbnail id>" to show the last viewed photo there.
    // Once this photo has loaded, the previous and next photos are downloaded so paging to them is instant.
    script {
      Node.raw(
        """
        (() => {
          const closeLink = document.getElementById("photo-close");

          const close = () => {
            if (document.referrer === closeLink.href && history.length > 1) return history.back();
            window.location.href = `${closeLink.href}#return=${encodeURIComponent(closeLink.dataset.thumbnail)}`;
          };

          closeLink.addEventListener("click", event => {
            if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey || event.button !== 0) return;
            event.preventDefault();
            close();
          });

          document.addEventListener("keydown", event => {
            if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
            if (event.key === "Escape") return close();
            const id = { ArrowLeft: "photo-previous", ArrowRight: "photo-next" }[event.key];
            const link = id && document.getElementById(id);
            if (link) window.location.href = link.href;
          });

          window.addEventListener("load", () => {
            for (const link of document.querySelectorAll("#photo-previous, #photo-next")) {
              new Image().src = link.dataset.image;
            }
          });
        })();
        """
      )
    }
  }
}

/// Exposure time in seconds as photographers write it: 0.01 → "1/100s", 2.5 → "2.5s"
private func shutterSpeed(_ exposureTime: String) -> String {
  guard let seconds = Double(exposureTime), seconds > 0 else { return "\(exposureTime)s" }
  if seconds >= 1 {
    return "\(seconds.formatted(.number))s"
  }
  return "1/\(Int((1 / seconds).rounded()))s"
}

// Remix Icon line icons for the photo settings: ruler, camera-lens, timer and film
private let focalLengthIcon = #"<svg class="size-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M6.34323 14.728L3.5148 17.5565L7.05033 21.092L20.4854 7.65696L16.9498 4.12143L14.8285 6.24275L16.2427 7.65696L14.8285 9.07118L13.4143 7.65696L11.293 9.77828L13.4143 11.8996L12.0001 13.3138L9.87876 11.1925L7.75744 13.3138L9.17165 14.728L7.75744 16.1422L6.34323 14.728ZM17.6569 2.00011L22.6067 6.94986C22.9972 7.34038 22.9972 7.97354 22.6067 8.36407L7.75744 23.2133C7.36692 23.6038 6.73375 23.6038 6.34323 23.2133L1.39348 18.2636C1.00295 17.873 1.00295 17.2399 1.39348 16.8494L16.2427 2.00011C16.6332 1.60958 17.2664 1.60958 17.6569 2.00011Z"/></svg>"#
private let apertureIcon = #"<svg class="size-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M9.85802 19.71L12 16H5.07026C6.10692 17.7921 7.8188 19.1447 9.85802 19.71ZM4.25204 14H8.5359L5.07103 7.99867C4.38987 9.17566 4 10.5423 4 12C4 12.6906 4.08751 13.3608 4.25204 14ZM6.39496 6.29179L8.5359 10L12 4C9.8171 4 7.8384 4.87429 6.39496 6.29179ZM14.142 4.28998L12 8H18.9297C17.8931 6.20791 16.1812 4.85529 14.142 4.28998ZM19.748 10H15.4641L18.929 16.0013C19.6101 14.8243 20 13.4577 20 12C20 11.3094 19.9125 10.6392 19.748 10ZM17.605 17.7082L15.4641 14L12 20C14.1829 20 16.1616 19.1257 17.605 17.7082ZM12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12C22 17.5228 17.5228 22 12 22ZM13.1547 10H10.8453L9.6906 12L10.8453 14H13.1547L14.3094 12L13.1547 10Z"/></svg>"#
private let shutterSpeedIcon = #"<svg class="size-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M17.6177 5.9681L19.0711 4.51472L20.4853 5.92893L19.0319 7.38231C20.2635 8.92199 21 10.875 21 13C21 17.9706 16.9706 22 12 22C7.02944 22 3 17.9706 3 13C3 8.02944 7.02944 4 12 4C14.125 4 16.078 4.73647 17.6177 5.9681ZM12 20C15.866 20 19 16.866 19 13C19 9.13401 15.866 6 12 6C8.13401 6 5 9.13401 5 13C5 16.866 8.13401 20 12 20ZM11 8H13V14H11V8ZM8 1H16V3H8V1Z"/></svg>"#
private let isoIcon = #"<svg class="size-4 shrink-0" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M2 3.9934C2 3.44476 2.45531 3 2.9918 3H21.0082C21.556 3 22 3.44495 22 3.9934V20.0066C22 20.5552 21.5447 21 21.0082 21H2.9918C2.44405 21 2 20.5551 2 20.0066V3.9934ZM8 5V19H16V5H8ZM4 5V7H6V5H4ZM18 5V7H20V5H18ZM4 9V11H6V9H4ZM18 9V11H20V9H18ZM4 13V15H6V13H4ZM18 13V15H20V13H18ZM4 17V19H6V17H4ZM18 17V19H20V17H18Z"/></svg>"#

private func photoDetails(_ photo: Item<ImageMetadata>, album: Item<PhotoAlbumMetadata>) -> Node {
  let m = photo.metadata
  let camera = [m.make, m.model].compactMap(\.self).joined(separator: " ")
  let settingParts: [(icon: String, value: String?)] = [
    (focalLengthIcon, m.focalLenIn35mmFilm.map { "\($0)mm" } ?? m.focalLength.map { "\($0)mm" }),
    (apertureIcon, m.fNumber.map { "f/\($0)" }),
    (shutterSpeedIcon, m.exposureTime.map(shutterSpeed)),
    (isoIcon, m.iso.map { "ISO \($0)" }),
  ]
  let settings: [(icon: String, value: String)] = settingParts.compactMap { part in
    part.value.map { (part.icon, $0) }
  }

  let details: [(String, String?)] = [
    ("Date", photo.date.formatted("MMMM d, yyyy")),
    ("Camera", camera),
    ("Lens", m.lensModel),
  ]
  let rows: [(String, String)] = details.compactMap { label, value in
    guard let value, !value.isEmpty else { return nil }
    return (label, value)
  }

  return dl(class: "flex flex-col gap-6") {
    rows.map { label, value in
      div {
        dt(class: "sidebar-header") { label }
        dd(class: "font-mono") { value }
      }
    }
    if !settings.isEmpty {
      div {
        dt(class: "sidebar-header") { "Settings" }
        dd(class: "flex flex-col gap-1") {
          settings.map { icon, value in
            span(class: "flex items-center gap-2 font-mono") {
              Node.raw(icon)
              value
            }
          }
        }
      }
    }

    if let mapURL = photo.mapURL, let coordinates = photo.coordinates {
      div {
        dt(class: "sidebar-header") { "Location" }
        dd {
          a(href: "https://www.google.com/maps/search/?api=1&query=\(coordinates.latitude),\(coordinates.longitude)", target: "_blank") {
            img(alt: "Map of where this photo was taken", height: "220", src: mapURL, width: "220")
          }
        }
      }
    }

    div {
      dt(class: "sidebar-header") { "Album" }
      dd {
        a(class: "underline underline-offset-2 hover:text-accent font-mono", href: album.url) { album.title }
      }
    }
  }
}
