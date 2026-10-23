import Foundation
import HTML
import Saga
import SagaSwimRenderer

enum Section: String, CaseIterable, Codable {
  case home
  case articles
  case journal
  case work
  case openSource
  case photos
  case games
  case movies
  case shows
  case albums
  case about

  var title: String {
    switch self {
      case .home: "Home"
      case .articles: "Articles"
      case .journal: "Journal"
      case .work: "Work"
      case .openSource: "Open Source"
      case .photos: "Photos"
      case .games: "Games"
      case .movies: "Movies"
      case .shows: "TV shows"
      case .albums: "Albums"
      case .about: "About"
    }
  }

  var path: String {
    switch self {
      case .home: "/"
      case .articles: "/articles/"
      case .journal: "/journal/"
      case .work: "/work/"
      case .openSource: "/open-source/"
      case .photos: "/photos/"
      case .games: "/games/"
      case .movies: "/movies/"
      case .shows: "/shows/"
      case .albums: "/albums/"
      case .about: "/about/"
    }
  }

  /// Sections that share one nav item get a sidebar linking to each of them, instead of a submenu
  var sidebar: (title: String, sections: [Section])? {
    if [.openSource, .work].contains(self) {
      return ("Projects", [.openSource, .work])
    }
    if [.games, .movies, .shows, .albums].contains(self) {
      return ("Favorites", [.games, .movies, .shows, .albums])
    }
    return nil
  }

  /// The nav item that is highlighted on this section's pages
  var navSection: Section {
    sidebar?.sections.first ?? self
  }
}

private let navItems: [(title: String, section: Section)] = [
  ("Articles", .articles),
  ("Journal", .journal),
  ("Projects", .openSource),
  ("Photos", .photos),
  ("Favorites", .games),
  ("About", .about),
]

/// The document shell (head and body) without any layout, for pages like the photo page that do their own
func rootHtml(title pageTitle: String?, canonicalPath: String, section: Section?, ogImage: (path: String, width: Int, height: Int) = ("/static/images/opengraph.png", 1200, 630), extraHeader: Node = [], @NodeBuilder children: () -> NodeConvertible) -> Node {
  let canonicalURL = SiteMetadata.url.appendingPathComponent(canonicalPath).absoluteString

  return [
    .documentType("html"),
    // From lg the root font size is 18px, so everything sized in rem (text, spacing, widths) grows with it
    html(class: "font-main scroll-pt-20 lg:text-lg", lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "width=device-width, initial-scale=1", name: "viewport")
        title { pageTitle.map { "\(SiteMetadata.name): \($0)" } ?? SiteMetadata.name }
        meta(content: SiteMetadata.author, name: "author")
        meta(content: "@kevinrenskers@hachyderm.io", name: "fediverse:creator")
        link(href: canonicalURL, rel: "canonical")
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
        meta(content: "", name: "theme-color")
        // After the stylesheet, so the theme-color can be read from --color-bodybg
        script {
          Node.raw("""
          (function(){
            var m = matchMedia('(prefers-color-scheme:dark)'), t = localStorage.getItem('theme');
            if (t === 'dark' || !t&&m.matches) {
              document.documentElement.classList.add('dark');
            }
            function syncThemeColor(){
              var color = getComputedStyle(document.documentElement).getPropertyValue('--color-bodybg');
              document.querySelector('meta[name=theme-color]').setAttribute('content', color);
            }
            window.syncThemeColor = syncThemeColor;
            syncThemeColor();
            m.addEventListener('change',function(e){
              if(!localStorage.getItem('theme')) {
                document.documentElement.classList.toggle('dark',e.matches);
                syncThemeColor();
              }
            })
          })()
          """)
        }
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

        link(href: "/articles/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) articles", type: "application/atom+xml")
        link(href: "/journal/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) journal", type: "application/atom+xml")
        link(href: "/photos/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) photos", type: "application/atom+xml")

        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
        link(color: "#f1a948", href: "/mask.svg", rel: "mask-icon")
        meta(content: SiteMetadata.name, name: "apple-mobile-web-app-title")
        link(href: "/site.webmanifest", rel: "manifest")

        meta(content: SiteMetadata.name, customAttributes: ["property": "og:site_name"])
        meta(content: SiteMetadata.url.appendingPathComponent(ogImage.path).absoluteString, customAttributes: ["property": "og:image"])
        meta(content: "\(ogImage.width)", customAttributes: ["property": "og:image:width"])
        meta(content: "\(ogImage.height)", customAttributes: ["property": "og:image:height"])
        meta(content: canonicalURL, customAttributes: ["property": "og:url"])
        meta(content: "summary_large_image", name: "twitter:card")

        extraHeader

        if !Saga.isDev {
          script(defer: true, src: "/script.js", customAttributes: ["data-website-id": "81dabfb5-ff5a-4ae4-bc0f-7e5d91c71875", "data-performance": "true"])
        }
      }
      body(class: "bg-bodybg flex min-h-screen flex-col text-textfg antialiased \(section?.rawValue ?? "")") {
        children().asNode()
      }
    },
  ]
}

/// The site layout: nav, centered content, and footer
func baseHtml(title pageTitle: String?, canonicalPath: String, section: Section?, ogImage: (path: String, width: Int, height: Int) = ("/static/images/opengraph.png", 1200, 630), extraHeader: Node = [], @NodeBuilder children: () -> NodeConvertible) -> Node {
  rootHtml(title: pageTitle, canonicalPath: canonicalPath, section: section, ogImage: ogImage, extraHeader: extraHeader) {
    siteNav(section: section)

    main(class: "container flex flex-1 flex-col py-6 md:py-12 lg:py-16 \(section == .home ? "lg:short:py-8" : "")") {
      if let section, let sidebar = section.sidebar {
        // Same grid as the articles, with the page in the text column
        div(class: "article-grid") {
          aside(class: "max-lg:hidden") {
            nav(class: "sticky top-24 text-xs", customAttributes: ["aria-label": sidebar.title]) {
              p(class: "mb-4 sidebar-header") { sidebar.title }
              ul(class: "flex flex-col gap-2") {
                sidebar.sections.map { item in
                  li { sectionLink(item, currentSection: section) }
                }
              }
            }
          }

          div {
            nav(class: "mb-8 flex flex-wrap gap-x-4 gap-y-2 text-sm lg:hidden", customAttributes: ["aria-label": sidebar.title]) {
              sidebar.sections.map { sectionLink($0, currentSection: section) }
            }

            children().asNode()
          }
        }
      } else {
        children().asNode()
      }
    }

    if section != .home {
      footer(class: "container flex flex-col items-center gap-1 py-8 text-sm text-textfg/60 links") {
        p {
          "Built in Swift using"
          a(href: "https://getsaga.dev", rel: "nofollow", target: "_blank") { "Saga" }
          "("
          %a(href: "https://github.com/loopwerk/loopwerk.io", rel: "nofollow", target: "_blank") { "source" }
          %")."
        }
        div(class: "flex gap-2") {
          p { "© 2009-\(Calendar.current.component(.year, from: SiteMetadata.now)) Kevin Renskers" }
          a(href: "/legal/") { "legal notice" }
        }
      }
    }
  }
}

private func siteNav(section: Section?) -> Node {
  nav(class: "sticky top-0 md:-top-12 z-50 border-b border-transparent bg-bodybg sticky-nav-border") {
    // On desktop the nav uses the same columns as article-grid, so the menu lines up with the content column
    div(class: "relative container flex items-center pt-4 md:pt-16 pb-4 text-sm lg:grid lg:grid-cols-[var(--sidebar-width)_1fr] lg:gap-(--sidebar-gap)") {
      a(class: "text-textfg hover:text-accent lg:justify-self-start", href: Section.home.path, title: Section.home.title) {
        Node.raw(#"<svg class="h-7 w-7" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 315 315"><path d="m529 315h-315v-315h143v26h-114v263h258v-79h-173v-131h-28v157h172v26h-201v-209h86v130h172z" transform="translate(-214)"/></svg>"#)
      }

      input(class: "peer sr-only", id: "nav-toggle", type: "checkbox")

      label(
        class: "-m-2 ml-auto cursor-pointer p-2 text-textfg peer-focus-visible:text-accent hover:text-accent md:hidden peer-checked:hidden",
        for: "nav-toggle",
        customAttributes: ["aria-label": "Open menu"]
      ) {
        Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg>"#)
      }

      label(
        class: "-m-2 ml-auto hidden cursor-pointer p-2 text-textfg peer-focus-visible:text-accent hover:text-accent peer-checked:max-md:block",
        for: "nav-toggle",
        customAttributes: ["aria-label": "Close menu"]
      ) {
        Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
      }

      div(
        class: "hidden md:pl-[3px] md:ml-auto lg:ml-0 md:flex md:items-center gap-4 md:gap-5 lg:gap-8 max-md:absolute max-md:top-full max-md:right-0 max-md:left-0 max-md:flex-col max-md:border-b max-md:border-divider max-md:bg-bodybg max-md:px-6 max-md:py-4 peer-checked:max-md:flex"
      ) {
        navItems.map { navLink($0.title, section: $0.section, currentSection: section) }

        a(class: "text-textfg hover:text-accent lg:ml-auto", href: "/feeds/", title: "RSS feeds") {
          Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M3 17a4 4 0 0 1 4 4H3zm0-7c6.075 0 11 4.925 11 11h-2a9 9 0 0 0-9-9zm0-7c9.941 0 18 8.059 18 18h-2c0-8.837-7.163-16-16-16z"/></svg>"#)
        }

        // Theme toggle
        button(class: "text-textfg hover:text-accent cursor-pointer md:-ml-2 lg:-ml-5", type: "button", customAttributes: ["onclick": "document.documentElement.classList.toggle('dark');localStorage.setItem('theme',document.documentElement.classList.contains('dark')?'dark':'light');window.syncThemeColor&&window.syncThemeColor()", "aria-label": "Toggle theme"]) {
          Node.raw("""
          <svg class="dark:hidden" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg><svg class="hidden dark:block" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
          """)
        }
      }
    }
  }
}

private func navLink(_ title: String, section: Section, currentSection: Section?) -> Node {
  a(
    class: section == currentSection?.navSection
      ? "font-medium text-accent"
      : "text-textfg hover:text-accent",
    href: section.path
  ) {
    title
  }
}

private func sectionLink(_ section: Section, currentSection: Section) -> Node {
  a(class: section == currentSection ? "text-accent" : "text-textfg/80 hover:text-accent", href: section.path) { section.title }
}
