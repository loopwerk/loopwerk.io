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
  case search
  case notFound
}

func baseLayout(canocicalURL: String, section: Section, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([]), @NodeBuilder children: () -> NodeConvertible) -> Node {
  return [
    .documentType("html"),
    html(class: "bg-nav h-full font-ibm", lang: "en-US") {
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
        meta(content: "freelance, developer, swift, objective-c, django, python, iPhone, iPad, iOS, macOS, Apple, development, usability, design, css, html, javascript, typescript, review, full-stack, open source", name: "keywords")
        meta(content: "@kevinrenskers@hachyderm.io", name: "fediverse:creator")
        title { SiteMetadata.name + ": \(pageTitle)" }
        link(href: "/static/output.css", rel: "stylesheet")
        link(href: "/articles/feed.xml", rel: "alternate", title: SiteMetadata.name, type: "application/rss+xml")
        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        link(href: "/site.webmanifest", rel: "manifest")
        link(color: "#f1a948", href: "/mask.svg", rel: "mask-icon")
        link(href: "\(SiteMetadata.url)\(canocicalURL)", rel: "canonical")

        extraHeader
        script(async: true, defer: true, src: "https://plausible.io/js/plausible.js", customAttributes: ["data-domain": "loopwerk.io"])
      }
      body(class: "bg-page text-white pb-5 min-h-full \(section.rawValue)") {
        header(class: "bg-nav text-gray py-3 text-base/6 lg:fixed w-full z-10") {
          nav(class: "container flex gap-x-5 lg:gap-x-7 items-center lg:h-[44px]") {
            img(alt: "Loopwerk logo", height: "30", src: "/static/images/Loopwerk_mark.svg", width: "30")

            ul(class: "flex flex-wrap gap-x-2 lg:gap-x-5 flex-1") {
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
                a(class: section == .about ? "active" : "", href: "/about/") { "About" }
              }

              li {
                a(class: section == .hireMe ? "active" : "", href: "/hire-me/") { "Hire me" }
              }
            }
            
            form(action: "/search/", class: "hidden lg:block relative", id:"search-form") {
              input(class: "w-[260px]", id: "search", name: "q", placeholder: "Search articles", type: "text")
            }
          }
        }

        div(class: "container pt-12 lg:pt-28") {
          children()
        }

        div(class: "site-footer container text-gray gray-links border-t border-light text-center pt-6 mt-8 text-sm font-anonymous") {
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
            a(href: "mailto:kevin@loopwerk.io") { "Email" }
          }
        }
      }
    }
  ]
}
