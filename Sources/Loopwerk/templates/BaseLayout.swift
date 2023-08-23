import HTML
import Foundation

enum Section: String {
  case home
  case articles
  case apps
  case projects
  case mentorshipProgram
  case about
  case notFound
}

func baseLayout(section: Section?, title pageTitle: String?, siteMetadata: SiteMetadata, extraHeader: NodeConvertible = Node.fragment([]), @NodeBuilder children: () -> NodeConvertible) -> Node {
  let titleSuffix = pageTitle.map { ": \($0)" } ?? ""

  return [
    .documentType("html"),
    html(lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "#0e1112", name: "theme-color", customAttributes: ["media": "(prefers-color-scheme: dark)"])
        meta(content: "#566B78", name: "theme-color", customAttributes: ["media": "(prefers-color-scheme: light)"])
        meta(content: "Kevin Renskers", name: "author")
        meta(content: "initial-scale=1.0, width=device-width", name: "viewport")
        meta(content: "telephone=no", name: "format-detection")
        meta(content: "True", name: "HandheldFriendly")
        meta(content: "320", name: "MobileOptimized")
        meta(content: "Loopwerk", name: "og:site_name")
        meta(content: "freelance, developer, swift, objective-c, django, python, iPhone, iPad, iOS, macOS, Apple, development, usability, design, css, html5, javascript, review, groningen", name: "keywords")
        title { siteMetadata.name + titleSuffix }
        link(href: "/static/style.css", rel: "stylesheet")
        link(href: "/static/prism.css", rel: "stylesheet")
        link(href: "/articles/feed.xml", rel: "alternate", title: siteMetadata.name, type: "application/rss+xml")
        link(href: "/static/images/favicon-32x32.png", rel: "icon", sizes: "32x32", type: "image/png")
        link(href: "/static/images/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/static/images/favicon-16x16.png", rel: "icon", sizes: "16x16", type: "image/png")

        switch section {
          case .home:
            link(href: "/static/home.css", rel: "stylesheet")
          default:
            link(href: "/static/not-home.css", rel: "stylesheet")
        }

        extraHeader
        script(async: true, defer: true, src: "https://plausible.io/js/plausible.js", customAttributes: ["data-domain": "loopwerk.io"])
      }
      body {
        header {
          nav {
            img(alt: "Loopwerk logo", height: "30", src: "/static/images/Loopwerk_mark.svg", width: "30")

            ul {
              li {
                a(class: "link_1\(section == .home ? " active" : "")", href: "/") { "Home" }
              }

              li {
                a(class: "link_2\(section == .articles ? " active" : "")", href: "/articles/") { "Articles" }
              }

              li {
                a(class: "link_3\(section == .apps ? " active" : "")", href: "/apps/") { "Apps" }
              }

              li {
                a(class: "link_4\(section == .projects ? " active" : "")", href: "/projects/") { "Open Source" }
              }

              li {
                a(class: "link_5\(section == .mentorshipProgram ? " active" : "")", href: "/mentor/") { "Mentorship Program" }
              }

              li {
                a(class: "link_6\(section == .about ? " active" : "")", href: "/about/") { "About" }
              }
            }
          }
        }

        div(id: "content") {
          children()

          div(id: "site-footer") {
            p {
              "Copyright © Loopwerk 2009-\(Date().description.prefix(4))."
            }
            p {
              "Built in Swift using"
              a(href: "https://github.com/loopwerk/Saga", rel: "nofollow", target: "_blank") { "Saga" }
              %"."
            }
            p {
              a(href: "https://hachyderm.io/@kevinrenskers", rel: "nofollow", target: "_blank") { "Mastodon" }
              " | "
              a(href: "\(siteMetadata.url.absoluteString)/articles/feed.xml", rel: "nofollow", target: "_blank") { "RSS" }
            }
          }
        }

        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-core.min.js")
        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/keep-markup/prism-keep-markup.min.js")
        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/autoloader/prism-autoloader.min.js")
      }
    }
  ]
}
