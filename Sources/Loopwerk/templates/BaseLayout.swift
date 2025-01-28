import Foundation
import HTML

enum Section: String {
  case home
  case articles
  case apps
  case projects
  case mentorshipProgram
  case about
  case hireMe
  case notFound
}

func baseLayout(section: Section?, title pageTitle: String?, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([]), @NodeBuilder children: () -> NodeConvertible) -> Node {
  let titleSuffix = pageTitle.map { ": \($0)" } ?? ""

  return [
    .documentType("html"),
    html(lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "#0e1112", name: "theme-color", customAttributes: ["media": "(prefers-color-scheme: dark)"])
        meta(content: "#566B78", name: "theme-color", customAttributes: ["media": "(prefers-color-scheme: light)"])
        meta(content: "Kevin Renskers", name: "author")
        meta(content: "Loopwerk", name: "apple-mobile-web-app-title")
        meta(content: "initial-scale=1.0, width=device-width", name: "viewport")
        meta(content: "telephone=no", name: "format-detection")
        meta(content: "True", name: "HandheldFriendly")
        meta(content: "320", name: "MobileOptimized")
        meta(content: "Loopwerk", name: "og:site_name")
        meta(content: "freelance, developer, swift, objective-c, django, python, iPhone, iPad, iOS, macOS, Apple, development, usability, design, css, html5, javascript, review, groningen", name: "keywords")
        title { SiteMetadata.name + titleSuffix }
        link(href: "/static/output.css", rel: "stylesheet")
        link(href: "/articles/feed.xml", rel: "alternate", title: SiteMetadata.name, type: "application/rss+xml")
        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        link(href: "/site.webmanifest", rel: "manifest")
        link(color: "#f1a948", href: "/mask.svg", rel: "mask-icon")

        extraHeader
        script(async: true, defer: true, src: "https://plausible.io/js/plausible.js", customAttributes: ["data-domain": "loopwerk.io"])
      }
      body(class: "bg-page text-white pb-5 \(section?.rawValue ?? "")") {
        header(class: "bg-nav text-gray-1 py-4 text-base/6 fixed w-full lg:h-[62px]") {
          nav(class: "container flex gap-x-5 lg:gap-x-7 items-center") {
            img(alt: "Loopwerk logo", height: "30", src: "/static/images/Loopwerk_mark.svg", width: "30")

            ul(class: "flex flex-wrap gap-x-2 lg:gap-x-5") {
              li {
                a(class: section == .home ? "active" : "", href: "/") { "Home" }
              }

              li {
                a(class: section == .articles ? "active" : "", href: "/articles/") { "Articles" }
              }

              li {
                a(class: section == .apps ? "active" : "", href: "/apps/") { "Apps" }
              }

              li {
                a(class: section == .projects ? "active" : "", href: "/projects/") { "Open Source" }
              }

              li {
                a(class: section == .mentorshipProgram ? "active" : "", href: "/mentor/") { "Mentorship" }
              }

              li {
                a(class: section == .about ? "active" : "", href: "/about/") { "About" }
              }

              li {
                a(class: section == .hireMe ? "active" : "", href: "/hire-me/") { "Hire me" }
              }
            }
          }
        }

        div(class: "container pt-28") {
          children()
        }

        div(class: "site-footer container text-gray-2 border-t border-gray-2 text-center pt-6 mt-8 text-sm font-anonymous") {
          p {
            "Copyright © Loopwerk 2009-\(Date().description.prefix(4))."
          }
          p {
            "Built in Swift using"
            a(href: "https://github.com/loopwerk/Saga", rel: "nofollow", target: "_blank") { "Saga" }
            "("
            %a(href: "https://github.com/loopwerk/loopwerk.io", rel: "nofollow", target: "_blank") { "source" }
            %")."
          }
          p {
            a(href: "\(SiteMetadata.url.absoluteString)/articles/\(rssLink)feed.xml", rel: "nofollow", target: "_blank") { "RSS" }
            " | "
            a(href: "https://hachyderm.io/@kevinrenskers", rel: "me", target: "_blank") { "Mastodon" }
            " | "
            a(href: "https://bsky.app/profile/loopwerk.io", rel: "nofollow", target: "_blank") { "Bluesky" }
          }
        }

        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-core.min.js")
        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/keep-markup/prism-keep-markup.min.js")
        script(src: "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/plugins/autoloader/prism-autoloader.min.js")
      }
    },
  ]
}
