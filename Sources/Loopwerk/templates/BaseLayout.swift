import Foundation
import HTML

enum Section: String {
  case home
  case articles
  case work
  case openSource
  case mentorshipProgram
  case about
  case hireMe
  case search
  case notFound
}

func baseLayout(canocicalURL: String, section: Section, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([]), @NodeBuilder children: () -> NodeConvertible) -> Node {
  return [
    .documentType("html"),
    html(class: "bg-nav h-full font-main", lang: "en-US") {
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
        style {
          Node.raw("""
          @font-face {
            font-family: "Title Serif";
            src: url(/static/fonts/title.woff2) format("woff2");
            font-style: normal;
            font-weight: 100 900;
            font-display: swap;
          }
          @font-face {
            font-family: "Main Sans";
            src: url(/static/fonts/main.woff2) format("woff2");
            font-style: normal;
            font-weight: 400 700;
            font-display: swap;
          }
          """)
        }
        link(href: "/articles/feed.xml", rel: "alternate", title: SiteMetadata.name, type: "application/rss+xml")
        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        link(href: "/site.webmanifest", rel: "manifest")
        link(color: "#f1a948", href: "/mask.svg", rel: "mask-icon")
        link(href: "\(SiteMetadata.url)\(canocicalURL)", rel: "canonical")
        extraHeader
        script(defer: true, src: "https://stats.loopwerk.io/js/script.js", customAttributes: ["data-domain": "loopwerk.io"])
      }
      body(class: "bg-page text-white pb-5 min-h-full \(section.rawValue)") {
        input(class: "hidden", id: "mobile-menu-toggle", type: "checkbox")

        // Mobile overlay (click to close)
        label(class: "mobile-overlay fixed inset-0 z-40 bg-black/80 opacity-0 transition-opacity pointer-events-none lg:hidden", for: "mobile-menu-toggle")

        header(class: "bg-nav text-gray py-3 text-base/6 lg:fixed w-full z-10") {
          nav(class: "container flex gap-x-5 lg:gap-x-7 items-center lg:h-[44px]") {
            // Logo
            a(href: "/") {
              img(alt: "Loopwerk logo", height: "30", src: "/static/images/Loopwerk_mark.svg", width: "30")
            }

            // Spacer for mobile
            div(class: "flex-1 lg:hidden")

            // Hamburger menu button
            label(class: "hamburger cursor-pointer flex flex-col justify-center items-center w-10 h-10 gap-[5px] lg:hidden", for: "mobile-menu-toggle") {
              span(class: "sr-only") { "Open menu" }
              span(class: "hamburger-line block w-6 h-[2px] bg-gray transition-all duration-300")
              span(class: "hamburger-line block w-6 h-[2px] bg-gray transition-all duration-300")
              span(class: "hamburger-line block w-6 h-[2px] bg-gray transition-all duration-300")
            }

            // Navigation panel - sidebar on mobile, inline on desktop
            div(class: "nav-panel max-lg:fixed top-0 right-0 h-full max-lg:w-[280px] bg-nav z-50 flex flex-col lg:flex-row lg:flex-1 max-lg:p-6 max-lg:pt-16 lg:items-center max-lg:translate-x-full transition-transform") {
              // Close button (mobile only)
              label(class: "nav-close absolute top-4 right-4 w-10 h-10 cursor-pointer flex items-center justify-center lg:hidden", for: "mobile-menu-toggle") {
                span(class: "sr-only") { "Close menu" }
              }

              // Navigation links
              ul(class: "flex flex-col lg:flex-row gap-4 lg:gap-5 lg:flex-1 max-lg:order-2") {
                li {
                  a(class: section == .home ? "active" : "", href: "/") { "Home" }
                }
                li {
                  a(class: section == .articles ? "active" : "", href: "/articles/") { "Articles" }
                }
                li {
                  a(class: section == .work ? "active" : "", href: "/work/") { "Work" }
                }
                li {
                  a(class: section == .openSource ? "active" : "", href: "/open-source/") { "Open Source" }
                }
                li {
                  a(class: section == .about ? "active" : "", href: "/about/") { "About" }
                }
                li {
                  a(class: section == .hireMe ? "active" : "", href: "/hire-me/") { "Hire me" }
                }
              }

              // Search form
              form(action: "/search/", class: "relative max-lg:mb-6", id: "search-form") {
                input(class: "w-full lg:w-[260px]", id: "search", name: "q", placeholder: "Search articles", type: "text")
              }
            }
          }
        }

        if section != .home {
          div(class: "container pt-4 lg:pt-20") {
            div(class: "bg-orange p-4 text-black text-lg rounded-md shadow-lg shadow-nav") {
              "For the first time since 2023 I'm available again for new projects. If you need a developer with 25 years of experience building websites and iOS apps, check out the "
              a(class: "underline", href: "/hire-me/") {
                "Hire me"
              }
              "page."
            }
          }
        } else {
          div(class: "container lg:pt-16") {}
        }

        div(class: "container pt-12") { // lg:pt-28
          children()
        }

        div(class: "site-footer container text-gray gray-links text-center text-sm font-mono") {
          div(class: "border-t-2 border-light pt-6 mt-8") {
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
              a(href: "https://www.linkedin.com/in/kevinrenskers/", target: "_blank") { "LinkedIn" }
              " | "
              a(href: "mailto:kevin@loopwerk.io") { "Email" }
            }
          }
        }
      }
    },
  ]
}
