import Foundation
import HTML
import Saga

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
    html(class: "font-main lg:scroll-pt-20", lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "#0e1112", name: "theme-color")
        script {
          Node.raw("""
          (function(){
            var m = matchMedia('(prefers-color-scheme:dark)'), t = localStorage.getItem('theme');
            if (t === 'dark' || !t&&m.matches) {
              document.documentElement.classList.add('dark');
            }
            function syncGiscus(){
              var f = document.querySelector('iframe.giscus-frame');
              if(!f) return;
              var theme = document.documentElement.classList.contains('dark') ? 'dark' : 'light';
              f.contentWindow.postMessage({giscus:{setConfig:{theme:theme}}}, 'https://giscus.app');
            }
            window.syncGiscus = syncGiscus;
            function syncThemeColor(){
              var dark = document.documentElement.classList.contains('dark');
              document.querySelector('meta[name=theme-color]').setAttribute('content', dark ? '#0e1112' : '#252f3f');
            }
            window.syncThemeColor = syncThemeColor;
            syncThemeColor();
            m.addEventListener('change',function(e){
              if(!localStorage.getItem('theme')) {
                document.documentElement.classList.toggle('dark',e.matches);
                syncGiscus();
                syncThemeColor();
              }
            })
          })()
          """)
        }
        meta(content: "Kevin Renskers", name: "author")
        meta(content: "Loopwerk", name: "apple-mobile-web-app-title")
        meta(content: "initial-scale=1.0, width=device-width", name: "viewport")
        meta(content: "telephone=no", name: "format-detection")
        meta(content: "True", name: "HandheldFriendly")
        meta(content: "320", name: "MobileOptimized")
        meta(content: "Loopwerk", name: "og:site_name")
        meta(content: "product lead, engineering lead, software architect, staff engineer, principal engineer, developer, swift, django, python, iOS, macOS, development, usability, design, product, ux, css, html, javascript, typescript, full-stack, open source", name: "keywords")
        meta(content: "@kevinrenskers@hachyderm.io", name: "fediverse:creator")
        title { SiteMetadata.name + ": \(pageTitle)" }
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
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
        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "81dabfb5-ff5a-4ae4-bc0f-7e5d91c71875", "data-performance": "true"])
        }
      }
      body(class: "bg-page text-primarytext pb-5 min-h-screen \(section.rawValue)") {
        input(class: "hidden", id: "mobile-menu-toggle", type: "checkbox")

        header(class: "bg-nav text-navlink py-3 text-base/6 fixed w-full z-50") {
          nav(class: "container flex gap-x-5 lg:gap-x-8 items-center lg:h-[44px]") {
            // Logo
            a(href: "/") {
              img(alt: "Loopwerk logo", height: "30", src: "/static/images/Loopwerk_mark.svg", width: "30")
            }

            // Spacer for mobile
            div(class: "flex-1 lg:hidden")

            // Theme toggle
            button(class: "text-navlink hover:text-orange cursor-pointer lg:order-last", type: "button", customAttributes: ["onclick": "document.documentElement.classList.toggle('dark');localStorage.setItem('theme',document.documentElement.classList.contains('dark')?'dark':'light');window.syncGiscus&&window.syncGiscus();window.syncThemeColor&&window.syncThemeColor()", "aria-label": "Toggle theme"]) {
              Node.raw("""
              <svg class="dark:hidden" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg><svg class="hidden dark:block" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
              """)
            }

            // Open menu button (mobile only)
            label(class: "menu-open cursor-pointer flex justify-center items-center w-10 h-10 text-secondarytext hover:text-orange transition lg:hidden", for: "mobile-menu-toggle", customAttributes: ["aria-label": "Open menu"]) {
              Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18M3 12h18M3 18h18"/></svg>"#)
            }

            // Close menu button (mobile only, shown while the menu is open)
            label(class: "menu-close hidden cursor-pointer justify-center items-center w-10 h-10 text-secondarytext hover:text-orange transition", for: "mobile-menu-toggle", customAttributes: ["aria-label": "Close menu"]) {
              Node.raw(#"<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
            }

            // Navigation panel - dropdown on mobile, inline on desktop
            div(class: "nav-panel hidden flex-col lg:flex lg:flex-row lg:flex-1 lg:items-center max-lg:absolute max-lg:top-full max-lg:inset-x-0 max-lg:bg-nav max-lg:py-4") {
              // Navigation links
              ul(class: "flex flex-col lg:flex-row lg:items-center gap-4 lg:gap-5 lg:flex-1 max-lg:container") {
                li {
                  a(class: section == .home ? "active" : "", href: "/") { "Home" }
                }
                li(class: "text-orange/70 max-lg:hidden") { "/" }
                li {
                  a(class: section == .articles ? "active" : "", href: "/articles/") { "Articles" }
                }
                li(class: "text-orange/70 max-lg:hidden") { "/" }
                li {
                  a(class: section == .work ? "active" : "", href: "/work/") { "Work" }
                }
                li(class: "text-orange/70 max-lg:hidden") { "/" }
                li {
                  a(class: section == .openSource ? "active" : "", href: "/open-source/") { "Open Source" }
                }
                li(class: "text-orange/70 max-lg:hidden") { "/" }
                li {
                  a(class: section == .about ? "active" : "", href: "/about/") { "About" }
                }
                li(class: "text-orange/70 max-lg:hidden") { "/" }
                li {
                  a(class: section == .hireMe ? "active" : "", href: "/hire-me/") { "Hire me" }
                }
              }
            }
          }
        }

        div(class: "container pt-22 lg:pt-28") {
          children()
        }

        div(class: "site-footer container text-secondarytext secondarytext-links text-center text-sm font-mono") {
          div(class: "border-t-2 border-divider pt-6 mt-12") {
            p {
              "Copyright © Loopwerk 2009-\(Date().description.prefix(4))."
            }
            p {
              "Built in Swift using"
              a(href: "https://getsaga.dev", rel: "nofollow", target: "_blank") { "Saga" }
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
