import Foundation
import HTML
import Saga
import SagaImageReader

func render404(context: PageRenderingContext) -> Node {
  let photos = context.allItems
    .compactMap { $0 as? Item<ImageMetadata> }
    .map { ["src": "/\($0.relativeSource)", "url": $0.url, "album": $0.parent(as: PhotoAlbumMetadata.self).title] }

  let photosJSON = (try? JSONEncoder().encode(photos)).map { String(decoding: $0, as: UTF8.self) } ?? "[]"

  return baseHtml(title: "404", canonicalPath: context.outputPath.url, section: nil) {
    h1(class: "photo-404", id: "photo-404") {
      span(class: "sr-only") { "404" }
    }

    p(class: "sr-only") { "Your page was not found." }
    div(class: "hidden text-center mt-12 links -mb-6 lg:-mb-12", id: "photo-caption") {
      "Your page was not found. Here's a"
      a(href: "/photos/") { "photo" }
      "from the "
      span(id: "photo-album")
      "album instead."
    }

    script {
      Node.raw(
        """
        (() => {
          const photos = \(photosJSON);
          const heading = document.getElementById("photo-404");
          const caption = document.getElementById("photo-caption");
          const link = caption.querySelector("a");
          const album = document.getElementById("photo-album");
          let queue = [];
          let current = null;

          const show = () => {
            if (!photos.length) return;
            if (!queue.length) {
              // Fisher-Yates shuffle, so every photo is shown once before any repeats
              queue = [...photos];
              for (let i = queue.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [queue[i], queue[j]] = [queue[j], queue[i]];
              }
            }
            const photo = queue.pop();
            current = photo;

            // Only swap once the photo has loaded, so the 404 is never transparent with nothing behind it
            const image = new Image();
            image.onload = () => {
              if (current !== photo) return;
              heading.style.backgroundImage = `url("${image.src}")`;
              heading.classList.add("has-photo", "cursor-pointer");
              link.href = photo.url;
              album.textContent = photo.album;
              caption.classList.remove("hidden");
            };
            image.src = encodeURI(photo.src);
          };

          heading.addEventListener("click", show);
          show();
        })();
        """
      )
    }
  }
}

func renderFeeds(context: PageRenderingContext) -> Node {
  return baseHtml(title: "RSS feeds", canonicalPath: context.outputPath.url, section: nil) {
    h1 { "RSS feeds" }
  } content: {
    article(class: "prose") {
      p { "The following feeds are available to subscribe to:" }

      h2 { "Everything" }
      ul {
        li {
          a(href: "/feed.xml", target: "_blank") { "\(SiteMetadata.url)/feed.xml" }
        }
      }

      h2 { "Articles" }
      ul {
        li {
          a(href: "/articles/feed.xml", target: "_blank") { "\(SiteMetadata.url)/articles/feed.xml" }
        }
      }

      h3 { "Articles per tag" }
      ul {
        li {
          "\(SiteMetadata.url)/articles/tag/[tag]/feed.xml, for example:"
        }
        ["django", "python", "javascript", "swift", "saga", "sveltekit"].map { tag in
          li {
            a(href: "/articles/tag/\(tag)/feed.xml", target: "_blank") { "\(SiteMetadata.url)/articles/tag/\(tag)/feed.xml" }
          }
        }
      }

      h2 { "Journal" }
      ul {
        li {
          a(href: "/journal/feed.xml", target: "_blank") { "\(SiteMetadata.url)/journal/feed.xml" }
        }
      }

      h2 { "Photos" }
      ul {
        li {
          a(href: "/photos/feed.xml", target: "_blank") { "\(SiteMetadata.url)/photos/feed.xml" }
        }
      }
    }
  }
}

func renderPage(context: ItemRenderingContext<PageMetadata>) -> Node {
  let section = context.item.metadata.section.flatMap { Section(rawValue: $0) }

  switch section {
    case .home:
      return renderHome(context: context)
    case .about:
      return renderAbout(context: context)
    case .hireMe:
      return renderHireMe(context: context)
    case .cv:
      return renderCV(context: context)
    default:
      return baseHtml(title: context.item.title, canonicalPath: context.item.url, section: section, hasMarkdownTwin: true, toc: context.item.metadata.toc.map(Node.raw)) {
        h1 { context.item.title }
      } content: {
        article(class: "prose") {
          Node.raw(context.item.body)
        }
      }
  }
}

private func renderHome(context: ItemRenderingContext<PageMetadata>) -> Node {
  baseHtml(title: nil, canonicalPath: context.item.url, section: .home, hasMarkdownTwin: true) {
    div(class: "md:mt-auto md:ml-auto md:max-w-xl md:rounded-2xl md:bg-bodybg/30 md:short:p-6 md:p-10 md:backdrop-blur-lg") {
      article(class: "prose") {
        h1(class: "mb-0!") { Node.raw(context.item.title) }
        Node.raw(context.item.body)
      }

      div(class: "mt-10 lg:short:mt-6 links") {
        socialLinks()
      }
    }
  }
}

private func renderAbout(context: ItemRenderingContext<PageMetadata>) -> Node {
  let sidebarContent = div(class: "flex justify-center text-sm text-textfg") {
    socialLinks()
  }

  return baseHtml(title: context.item.title, canonicalPath: context.item.url, section: .about, hasMarkdownTwin: true, toc: context.item.metadata.toc.map(Node.raw), sidebarContent: sidebarContent) {
    div(class: "flex items-baseline justify-between") {
      h1 { context.item.title }
      div(class: "lg:hidden") {
        socialLinks()
      }
    }
  } content: {
    article(class: "prose") {
      Node.raw(context.item.body)
    }
  }
}

private func renderHireMe(context: ItemRenderingContext<PageMetadata>) -> Node {
  let sidebarContent = div(class: "text-sm") {
    div(class: "flex justify-center text-textfg") {
      socialLinks()
    }

    if SiteMetadata.available {
      div(class: "text-[12px] mt-4 w-[120px] relative bg-codebg text-codefg p-2 rounded-lg font-mono") {
        "I'm currently available for new projects! Reach out to discuss yours."
        span(class: "absolute bottom-full left-[16px] border-x-[8px] border-b-[8px] border-x-transparent border-b-codebg")
      }
    } else {
      div(class: "text-[12px] mt-8") {
        "I am currently not available for new projects, but feel free to contact me to set something up for the future."
      }
    }
  }

  return baseHtml(title: context.item.title, canonicalPath: context.item.url, section: .hireMe, hasMarkdownTwin: true, toc: context.item.metadata.toc.map(Node.raw), sidebarContent: sidebarContent) {
    div(class: "flex items-baseline justify-between") {
      h1 { context.item.title }
      div(class: "lg:hidden") {
        socialLinks()
      }
    }

    if SiteMetadata.available {
      div(class: "text-[12px] lg:hidden mt-6") {
        p(class: "bg-codebg text-codefg p-2 rounded-lg") {
          "I'm currently available for hire! Reach out to discuss your project."
        }
      }
    }
  } content: {
    article(class: "prose") {
      Node.raw(context.item.body)
    }
  }
}

/// The CV page. The PDF version at /about/KevinRenskers.pdf is generated from the same markdown file.
func renderCV(context: ItemRenderingContext<PageMetadata>) -> Node {
  return baseHtml(title: "CV", canonicalPath: context.item.url, section: .hireMe, hasMarkdownTwin: true, toc: context.item.metadata.toc.map(Node.raw)) {
    div(class: "print:hidden text-sm mb-8 links") {
      a(href: "/about/KevinRenskers.pdf", target: "_blank") { "Download as PDF" }
    }

    h1 { context.item.title }
  } content: {
    article(class: "prose [&_h3+p]:-mt-4 [&_h3+p]:text-sm [&_h3+p]:text-textfg/70 [&_h4]:mb-0 [&_h4+p]:mt-1") {
      Node.raw(context.item.body)
    }
  }
}

func socialLinks() -> Node {
  div(class: "flex gap-[0.8em] md:gap-[1em] [&_a]:block [&_a]:h-[1.5em] md:[&_a]:h-[1.75em] [&_a]:w-[1.5em] md:[&_a]:w-[1.75em]") {
    a(href: "mailto:kevin@loopwerk.io", title: "Email") {
      Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 512 512"><path d="M256 48C141.1 48 48 141.1 48 256s93.1 208 208 208h32v48H256C114.6 512 0 397.4 0 256S114.6 0 256 0S512 114.6 512 256v96 24H488 440c-36.9 0-69.6-17.8-90-45.4c-22 27.6-55.9 45.4-94 45.4c-66.3 0-120-53.7-120-120s53.7-120 120-120c27 0 51.9 8.9 72 24v-8h48v24 80 8c0 35.3 28.7 64 64 64h24V256c0-114.9-93.1-208-208-208zm72 208a72 72 0 1 0 -144 0 72 72 0 1 0 144 0z"/></svg>"#)
    }

    a(href: "https://hachyderm.io/@kevinrenskers", rel: "me", target: "_blank", title: "Mastodon") {
      Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 448 512"><path d="M433 179.1c0-97.2-63.7-125.7-63.7-125.7-62.5-28.7-228.6-28.4-290.5 0 0 0-63.7 28.5-63.7 125.7 0 115.7-6.6 259.4 105.6 289.1 40.5 10.7 75.3 13 103.3 11.4 50.8-2.8 79.3-18.1 79.3-18.1l-1.7-36.9s-36.3 11.4-77.1 10.1c-40.4-1.4-83-4.4-89.6-54a102.5 102.5 0 0 1 -.9-13.9c85.6 20.9 158.7 9.1 178.8 6.7 56.1-6.7 105-41.3 111.2-72.9 9.8-49.8 9-121.5 9-121.5zm-75.1 125.2h-46.6v-114.2c0-49.7-64-51.6-64 6.9v62.5h-46.3V197c0-58.5-64-56.6-64-6.9v114.2H90.2c0-122.1-5.2-147.9 18.4-175 25.9-28.9 79.8-30.8 103.8 6.1l11.6 19.5 11.6-19.5c24.1-37.1 78.1-34.8 103.8-6.1 23.7 27.3 18.4 53 18.4 175z"/></svg>"#)
    }

    a(href: "https://github.com/kevinrenskers", target: "_blank", title: "GitHub") {
      Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 496 512"><path d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3 .3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5 .3-6.2 2.3zm44.2-1.7c-2.9 .7-4.9 2.6-4.6 4.9 .3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3 .7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3 .3 2.9 2.3 3.9 1.6 1 3.6 .7 4.3-.7 .7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3 .7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3 .7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9s4.3 3.3 5.6 2.3c1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"/></svg>"#)
    }

    a(href: "https://www.linkedin.com/in/kevinrenskers/", target: "_blank", title: "LinkedIn") {
      Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 448 512"><path d="M100.28 448H7.4V148.9h92.88zM53.79 108.1C24.09 108.1 0 83.5 0 53.8a53.79 53.79 0 0 1 107.58 0c0 29.7-24.1 54.3-53.79 54.3zM447.9 448h-92.68V302.4c0-34.7-.7-79.2-48.29-79.2-48.29 0-55.69 37.7-55.69 76.7V448h-92.78V148.9h89.08v40.8h1.3c12.4-23.5 42.69-48.3 87.88-48.3 94 0 111.28 61.9 111.28 142.3V448z"/></svg>"#)
    }
  }
}
