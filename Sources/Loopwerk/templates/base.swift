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
  case hireMe
  case cv
  case uses

  var title: String {
    switch self {
      case .home: "Home"
      case .articles: "Articles"
      case .journal: "Journal"
      case .work: "Work"
      case .openSource: "Open source"
      case .photos: "Photos"
      case .games: "My favorite games"
      case .movies: "My favorite movies"
      case .shows: "My favorite TV shows"
      case .albums: "My favorite albums"
      case .about: "About"
      case .uses: "What I use"
      case .hireMe: "Hire me"
      case .cv: "CV"
    }
  }

  /// The title in a submenu, where the nav item's own page needs a name of its own
  var submenuTitle: String {
    self == .about ? "About me" : title
  }

  var path: String {
    switch self {
      case .home: "/"
      case .articles: "/articles/"
      case .journal: "/journal/"
      case .work: "/work/"
      case .openSource: "/open-source/"
      case .photos: "/photos/"
      case .games: "/about/games/"
      case .movies: "/about/movies/"
      case .shows: "/about/shows/"
      case .albums: "/about/albums/"
      case .about: "/about/"
      case .uses: "/about/uses/"
      case .hireMe: "/hire-me/"
      case .cv: "/hire-me/cv/"
    }
  }

  /// The nav item that is highlighted on this section's pages
  var navSection: Section {
    subpages.first { $0.value.contains(self) }?.key ?? self
  }
}

/// Sections that share one nav item (the key), which gets a submenu linking to the others
let subpages: [Section: [Section]] = [
  .about: [.about, .uses, .games, .movies, .shows, .albums],
]

let logoSVG = #"<svg class="h-7 w-7" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 12 12"><path d="M12 12H0V0H5V1H1V11H11V8H4V3H3V9H10V10H2V2H5V7H12Z"/></svg>"#

private let navItems: [Section] = [
  .articles,
  .journal,
  .work,
  .openSource,
  .photos,
  .about,
  .hireMe,
]

/// The document shell (head and body) without any layout, for pages like the photo page that do their own.
/// Pages with a markdown twin (see MarkdownOutput.swift) set `hasMarkdownTwin` to link to it.
func rootHtml(title pageTitle: String?, canonicalPath: String, section: Section?, ogImage: (path: String, width: Int, height: Int) = ("/static/images/opengraph.png", 1200, 630), extraHeader: Node = [], hasMarkdownTwin: Bool = false, @NodeBuilder children: () -> NodeConvertible) -> Node {
  let canonicalURL = SiteMetadata.url.appendingPathComponent(canonicalPath).absoluteString

  return [
    .documentType("html"),
    // From lg the root font size is 18px, so everything sized in rem (text, spacing, widths) grows with it
    html(class: "font-main scroll-pt-20 lg:text-lg print:text-base", lang: "en-US") {
      head {
        meta(charset: "utf-8")
        meta(content: "width=device-width, initial-scale=1", name: "viewport")
        title { pageTitle.map { "\(SiteMetadata.name): \($0)" } ?? SiteMetadata.name }
        meta(content: SiteMetadata.author, name: "author")
        meta(content: "@kevinrenskers@hachyderm.io", name: "fediverse:creator")
        link(href: canonicalURL, rel: "canonical")
        if hasMarkdownTwin {
          link(href: SiteMetadata.url.appendingPathComponent(canonicalPath).appendingPathComponent("index.md").absoluteString, rel: "alternate", type: "text/markdown")
        }
        link(href: Saga.hashed("/static/output.css"), rel: "stylesheet")
        meta(content: "", name: "theme-color")
        // After the stylesheet, so the theme-color can be read from --color-bodybg
        script {
          Node.raw("""
          (function(){
            if (localStorage.getItem('theme') === 'dark') {
              document.documentElement.classList.add('dark');
            }
            function syncThemeColor(){
              var color = getComputedStyle(document.documentElement).getPropertyValue('--color-bodybg');
              document.querySelector('meta[name=theme-color]').setAttribute('content', color);
            }
            window.syncThemeColor = syncThemeColor;
            syncThemeColor();
          })()
          """)
        }
        style {
          Node.raw("""
          @font-face {
            font-family: "Main Sans";
            src: url(/static/fonts/main.woff2) format("woff2");
            font-style: normal;
            font-weight: 400 700;
            font-display: swap;
          }
          @font-face {
            font-family: "Code Mono";
            src: url(/static/fonts/code.woff2) format("woff2");
            font-style: normal;
            font-weight: 400;
            font-display: swap;
          }
          """)
        }

        link(href: "/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) feed of everything", type: "application/atom+xml")
        link(href: "/articles/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) articles", type: "application/atom+xml")
        link(href: "/journal/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) journal", type: "application/atom+xml")
        link(href: "/photos/feed.xml", rel: "alternate", title: "\(SiteMetadata.name) photos", type: "application/atom+xml")

        link(href: "/favicon-96x96.png", rel: "icon", sizes: "96x96", type: "image/png")
        link(href: "/favicon.svg", rel: "icon", type: "image/svg+xml")
        link(href: "/favicon.ico", rel: "shortcut icon")
        link(href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180")
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
      body(class: "bg-bodybg flex min-h-svh print:min-h-0 flex-col text-textfg antialiased \(section?.rawValue ?? "")") {
        children().asNode()
      }
    },
  ]
}

/// The site layout: nav, centered content, and footer. The page is its `header` (title and whatever goes with it)
/// followed by its `content`. A `toc` is shown in the sidebar, and on mobile between the header and
/// the content. Pages with a `toc` or `sidebarContent` get a sidebar.
func baseHtml(title pageTitle: String?, canonicalPath: String, section: Section?, ogImage: (path: String, width: Int, height: Int) = ("/static/images/opengraph.png", 1200, 630), hasMarkdownTwin: Bool = false, extraHeader: Node = [], toc: Node? = nil, sidebarContent: Node? = nil, @NodeBuilder header pageHeader: () -> NodeConvertible = { Node.fragment([]) }, @NodeBuilder content: () -> NodeConvertible) -> Node {
  // Pages that don't pass a header get the default, an empty fragment
  let headerContent = pageHeader().asNode()
  let mobileTOC = toc.map(mobileTableOfContents) ?? []

  let page: Node = [
    headerContent == [] ? mobileTOC : header(class: "page-header") {
      headerContent
      mobileTOC
    },
    content().asNode(),
    toc == nil ? [] : tocHighlighter(),
  ]

  return rootHtml(title: pageTitle, canonicalPath: canonicalPath, section: section, ogImage: ogImage, extraHeader: extraHeader, hasMarkdownTwin: hasMarkdownTwin) {
    if SiteMetadata.available, section?.navSection != .hireMe {
      availableForHire()
    }

    nav(class: "site-nav sticky top-0 md:-top-12 z-50 border-b border-transparent bg-bodybg sticky-nav-border print:static print:border-0") {
      // On desktop the nav uses the same columns as sidebar-grid, so the menu lines up with the content column
      div(class: "relative container flex items-center pt-4 md:pt-16 pb-4 text-sm lg:grid lg:grid-cols-[var(--sidebar-width)_1fr] lg:gap-(--sidebar-gap) print:block print:max-w-none print:p-0 print:pb-8") {
        a(class: "lg:justify-self-start", href: Section.home.path, title: Section.home.title) {
          Node.raw(logoSVG)
        }

        input(class: "peer sr-only", id: "nav-toggle", type: "checkbox")

        label(
          class: "-m-2 ml-auto cursor-pointer p-2 peer-focus-visible:text-accent md:hidden peer-checked:hidden print:hidden",
          for: "nav-toggle",
          customAttributes: ["aria-label": "Open menu"]
        ) {
          Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg>"#)
        }

        label(
          class: "-m-2 ml-auto hidden cursor-pointer p-2 peer-focus-visible:text-accent peer-checked:max-md:block print:hidden",
          for: "nav-toggle",
          customAttributes: ["aria-label": "Close menu"]
        ) {
          Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>"#)
        }

        div(
          class: "hidden lg:pl-[3px] md:ml-auto lg:ml-0 md:flex md:items-center gap-4 md:gap-4 lg:gap-5 max-md:absolute max-md:top-full max-md:right-0 max-md:left-0 max-md:flex-col max-md:border-b max-md:border-divider max-md:bg-bodybg max-md:px-6 max-md:py-4 peer-checked:max-md:flex print:hidden"
        ) {
          navItems.map { item in
            div(class: "relative") {
              if let sections = subpages[item] {
                // A submenu that opens on click. `name` makes the submenus exclusive: opening one closes the other.
                details(class: "group", customAttributes: ["name": "submenu"]) {
                  summary(class: "flex cursor-pointer list-none items-center gap-1 hover:text-accent [&::-webkit-details-marker]:hidden \(item == section?.navSection ? "text-accent" : "")") {
                    item.title
                    Node.raw(#"<svg class="h-3 w-3 group-open:rotate-180" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>"#)
                  }

                  // Mobile: indented under the nav item. Desktop: a dropdown below it.
                  ul(class: "mt-2 ml-4 flex flex-col gap-2 md:absolute md:top-full md:-left-4 md:z-10 md:mt-5 md:ml-0 md:rounded-b-lg md:border md:border-divider md:bg-bodybg md:px-4 md:py-3 md:shadow-lg") {
                    sections.map { subpage in
                      li {
                        a(class: subpage == section ? "whitespace-nowrap text-accent" : "whitespace-nowrap", href: subpage.path) { subpage.submenuTitle }
                      }
                    }
                  }
                }
              } else {
                navLink(section: item, currentSection: section)
              }

              if item == .hireMe, SiteMetadata.available, section?.navSection != .hireMe {
                availableForHireAboveLink()
              }
            }
          }

          div(class: "lg:ml-auto flex gap-1") {
            a(href: "/feeds/", title: "RSS feeds") {
              Node.raw(#"<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24"><path d="M3 17a4 4 0 0 1 4 4H3zm0-7c6.075 0 11 4.925 11 11h-2a9 9 0 0 0-9-9zm0-7c9.941 0 18 8.059 18 18h-2c0-8.837-7.163-16-16-16z"/></svg>"#)
            }

            // Theme toggle
            button(class: "cursor-pointer", type: "button", customAttributes: ["onclick": "document.documentElement.classList.toggle('dark');localStorage.setItem('theme',document.documentElement.classList.contains('dark')?'dark':'light');window.syncThemeColor&&window.syncThemeColor()", "aria-label": "Toggle theme"]) {
              Node.raw("""
              <svg class="dark:hidden" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg><svg class="hidden dark:block" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
              """)
            }
          }
        }
      }
    }

    // An open submenu closes when you click anywhere outside it
    script {
      Node.raw("""
      document.addEventListener("click", (event) => {
        for (const submenu of document.querySelectorAll(".site-nav details[open]")) {
          if (!submenu.contains(event.target)) submenu.open = false;
        }
      });
      """)
    }

    main(class: "container flex flex-1 flex-col py-6 md:py-12 lg:py-16 print:max-w-none print:p-0 \(section == .home ? "lg:short:py-8" : "")") {
      if toc != nil || sidebarContent != nil {
        // Sidebar on the left, page in the text column, so nothing shifts between pages with a sidebar
        div(class: "sidebar-grid") {
          aside {
            div(class: "flex flex-col gap-8") {
              toc.map(tableOfContents) ?? []
              sidebarContent ?? []
            }
          }

          div { page }
        }
      } else {
        page
      }
    }

    // Footer
    if section != .home {
      footer(class: "container flex flex-col items-center gap-1 py-8 text-sm text-textfg/60 links print:hidden") {
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

private func tableOfContents(_ toc: Node) -> Node {
  nav(class: "article-toc", customAttributes: ["aria-label": "Contents"]) {
    p(class: "sidebar-header") { "Contents" }
    toc
  }
}

/// On mobile the sidebar is hidden, so the TOC folds out between the page header and the content
private func mobileTableOfContents(_ toc: Node) -> Node {
  details(class: "article-toc group mt-6 text-textfg/60 lg:hidden print:hidden") {
    summary(class: "flex cursor-pointer list-none items-center gap-1.5 [&::-webkit-details-marker]:hidden") {
      Node.raw(#"<svg class="h-3.5 w-3.5 group-open:rotate-90" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg>"#)
      "Contents"
    }
    div(class: "mt-3") { toc }
  }
}

/// Marks the TOC link of the section being read: the last heading that has scrolled past the top of the screen.
/// Before the first heading, nothing is marked.
private func tocHighlighter() -> Node {
  script {
    Node.raw(
      """
      (() => {
        const entries = [...document.querySelectorAll(".article-toc a[href^='#']")]
          .map(link => {
            const slug = decodeURIComponent(link.hash.slice(1));
            return { link, heading: document.getElementById(slug) ?? document.getElementsByName(slug)[0]?.parentElement };
          })
          .filter(entry => entry.heading);
        const headings = [...new Set(entries.map(entry => entry.heading))];
        let active = null;
        let scheduled = false;

        const update = () => {
          scheduled = false;
          let current = null;
          for (const heading of headings) {
            if (heading.getBoundingClientRect().top > 160) break;
            current = heading;
          }
          if (current === active) return;
          active = current;
          for (const { link, heading } of entries) {
            if (heading === active) {
              link.setAttribute("aria-current", "location");
            } else {
              link.removeAttribute("aria-current");
            }
          }
        };

        const schedule = () => {
          if (scheduled) return;
          scheduled = true;
          requestAnimationFrame(update);
        };

        addEventListener("scroll", schedule, { passive: true });
        addEventListener("resize", schedule, { passive: true });
        update();
      })();
      """
    )
  }
}

/// Mobile only: centered in the nav's logo row, but positioned against the page rather than inside the sticky nav,
/// so it scrolls away while the nav stays put
private func availableForHire() -> Node {
  div(class: "pointer-events-none absolute inset-x-0 top-4 z-60 flex h-7 items-center justify-center text-[12px] md:hidden print:hidden") {
    a(class: "pointer-events-auto bg-codebg py-1 px-4 rounded-full hover:underline", href: Section.hireMe.path) { "I'm available for hire" }
  }
}

/// Desktop only: floats above the About link with an arrow pointing down at it. Browsers with scroll-driven
/// animations fade it out as the nav sticks, so it can sit closer; others keep it inside the part that scrolls away.
private func availableForHireAboveLink() -> Node {
  a(class: "fade-on-scroll absolute bottom-full left-1/2 mb-7 supports-[animation-timeline:scroll()]:mb-4 hidden -translate-x-1/2 whitespace-nowrap rounded-full bg-codebg py-1 px-4 text-[12px] text-codefg hover:text-inherit! hover:underline md:block font-mono", href: Section.hireMe.path) {
    "I'm currently available!"
    span(class: "absolute top-full left-1/2 -translate-x-1/2 border-x-[8px] border-t-[8px] border-x-transparent border-t-codebg")
  }
}

private func navLink(section: Section, currentSection: Section?) -> Node {
  a(
    class: section == currentSection?.navSection
      ? "text-accent"
      : "",
    href: section.path
  ) {
    section.title
  }
}
