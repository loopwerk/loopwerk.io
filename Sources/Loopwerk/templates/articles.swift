import Foundation
import HTML
import Saga

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  renderArticleList(context.items, section: .articles, allItems: context.allItems, title: "Articles", currentTag: nil, canonicalPath: context.outputPath.url, hasMarkdownTwin: true)
}

func renderTag(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  let feed = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/atom+xml")
  return renderArticleList(context.items, section: .articles, allItems: context.allItems, title: "#\(context.key)", currentTag: context.key, canonicalPath: context.outputPath.url, hasMarkdownTwin: false, extraHeader: feed)
}

func renderYear(context: PartitionedRenderingContext<Int, ArticleMetadata>) -> Node {
  renderArticleList(context.items, section: .articles, allItems: context.allItems, title: "\(context.key)", currentTag: nil, canonicalPath: context.outputPath.url, groupByYear: false, hasMarkdownTwin: false)
}

func renderJournal(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  renderArticleList(context.items, section: .journal, allItems: context.allItems, title: "Journal", currentTag: nil, canonicalPath: context.outputPath.url, groupByYear: false, hasMarkdownTwin: true)
}

func renderJournalTag(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  renderArticleList(context.items, section: .journal, allItems: context.allItems, title: "#\(context.key)", currentTag: context.key, canonicalPath: context.outputPath.url, groupByYear: false, hasMarkdownTwin: false)
}

/// The listed articles of a section: archived articles have a page, but aren't part of any list
private func listedArticles(in section: Section, allItems: [AnyItem]) -> [Item<ArticleMetadata>] {
  allItems
    .compactMap { $0 as? Item<ArticleMetadata> }
    .filter { $0.section == section && !$0.archive }
}

private func tagURL(_ tag: String, section: Section) -> String {
  "\(section.path)tag/\(tag.slugified)/"
}

private func renderArticleList(_ articles: [Item<ArticleMetadata>], section: Section, allItems: [AnyItem], title: String, currentTag: String?, canonicalPath: String, groupByYear: Bool = true, hasMarkdownTwin: Bool, extraHeader: Node = []) -> Node {
  let allArticles = listedArticles(in: section, allItems: allItems)
  let tags = tagsWithCounts(allArticles)
  let articlesPerYear: [(year: Int?, articles: [Item<ArticleMetadata>])] = groupByYear
    ? Dictionary(grouping: articles, by: \.year).sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    : [(nil, articles)]

  return baseHtml(title: section == .articles && title != "Articles" ? "Articles in \(title)" : title, canonicalPath: canonicalPath, section: section, hasMarkdownTwin: hasMarkdownTwin, extraHeader: extraHeader) {
    // Same grid as the article page, with the list in the text column so nothing shifts when you open an article
    div(class: "article-grid") {
      aside {
        nav(customAttributes: ["aria-label": "Tags"]) {
          p(class: "sidebar-header") { "Tags" }
          ul {
            li { tagLink("All \(section == .journal ? "posts" : "articles") (\(allArticles.count))", href: section.path, isCurrent: currentTag == nil) }
            tags.map { tag, count in
              li { tagLink("\(tag) (\(count))", href: tagURL(tag, section: section), isCurrent: tag == currentTag) }
            }
          }
        }
      }

      div {
        header(class: "page-header") {
          h1 { title }
          details(class: "group mt-4 lg:hidden print:hidden") {
            summary(class: "flex cursor-pointer list-none items-center gap-1.5 text-textfg/80 [&::-webkit-details-marker]:hidden") {
              Node.raw(#"<svg class="h-3.5 w-3.5 group-open:rotate-90" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg>"#)
              "Tags"
            }
            div(class: "mt-3 flex flex-wrap gap-x-4 gap-y-2 text-sm") {
              tagLink("All (\(allArticles.count))", href: section.path, isCurrent: currentTag == nil)
              tags.map { tag, count in
                tagLink("\(tag) (\(count))", href: tagURL(tag, section: section), isCurrent: tag == currentTag)
              }
            }
          }

          if section == .articles {
            searchForm()
          }
        }

        div(class: "flex flex-col gap-16", id: "articles-list") {
          articlesPerYear.map { year, articles in
            HTML.section {
              if let year {
                h2(class: "mb-6 font-title text-3xl font-bold") {
                  a(class: "hover:text-accent", href: "/articles/\(year)/") { "\(year)" }
                }
              }
              div(class: "flex flex-col gap-8") {
                articles.map { _renderArticleForGrid(article: $0) }
              }
            }
          }
        }
      }
    }
  }
}

/// Pagefind search over the technical articles: the list stays server-rendered, and a search
/// hides the articles that don't match and swaps in the excerpts of those that do.
@NodeBuilder
private func searchForm() -> Node {
  form(class: "relative mt-6 print:hidden", id: "search-form") {
    input(class: "w-full rounded-md border border-textfg/20 bg-transparent pl-11 py-2 pr-10 text-base focus:border-accent focus:outline-none", id: "search", name: "q", placeholder: "Search articles", type: "text")
    a(class: "absolute right-3 top-1/2 hidden -translate-y-1/2 text-lg text-textfg/60 hover:text-accent", href: "./", id: "search-clear", customAttributes: ["aria-label": "Clear search"]) { "\u{00D7}" }
  }

  script {
    Node.raw(
      """
      (async () => {
        const q = new URLSearchParams(window.location.search).get("q");
        if (!q) return;

        const pagefind = await import("/pagefind/pagefind.js");
        await pagefind.init();
        const search = await pagefind.search(q);
        const resultData = await Promise.all(search.results.map(r => r.data()));
        const resultsByUrl = new Map(resultData.map(r => [r.url, r]));

        document.getElementById("search").value = q;
        document.getElementById("search-clear").classList.remove("hidden");

        document.querySelectorAll("#articles-list [data-url]").forEach(article => {
          const result = resultsByUrl.get(article.dataset.url);
          if (result) {
            article.querySelector("[data-summary]").innerHTML = result.excerpt;
          } else {
            article.hidden = true;
          }
        });

        document.querySelectorAll("#articles-list > section").forEach(section => {
          section.hidden = !section.querySelector("[data-url]:not([hidden])");
        });
      })();
      """
    )
  }
}

private func tagsWithCounts(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  articles
    .flatMap(\.expandedTags)
    .reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
    .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
    .map { ($0.key, $0.value) }
}

private func tagSeparator(index: Int, totalTags: Int) -> Node {
  if index == 0 {
    return ""
  }
  if index == totalTags - 1 {
    return totalTags > 2 ? ", and " : " and "
  }
  return ", "
}

private func tagLink(_ title: String, href: String, isCurrent: Bool) -> Node {
  a(class: isCurrent ? "text-accent" : "", href: href) { title }
}

func _renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  a(class: "relative group hover:text-accent", href: article.url, customAttributes: ["data-url": article.url]) {
    h2(class: "font-bold text-lg text-pretty") {
      article.title
      Node.trim
      span(class: "font-thin text-xs text-textfg/60 ml-3 whitespace-nowrap") {
        "\u{00A0}\(article.date.formatted("MMM dd, yyyy"))"
      }
    }

    p(class: "text-textfg/80", customAttributes: ["data-summary": ""]) {
      article.metadata.summary ?? ""
    }
  }
}

func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  let item = context.item
  let section = item.section
  let date = item.date.formatted("MMMM dd, yyyy")
  let toc = item.metadata.toc
  let tags = item.expandedTags.sorted()
  let ogImage = "/static/images/\(item.filenameWithoutExtension).png"

  return baseHtml(title: item.title, canonicalPath: item.url, section: section, ogImage: (ogImage, 1200, 630), hasMarkdownTwin: true, extraHeader: [
    link(href: Saga.hashed("/static/prism.css"), rel: "stylesheet", customAttributes: ["media": "print", "onload": "this.media='all'"]),
    meta(content: item.metadata.summary, name: "description"),
    meta(content: "article", customAttributes: ["property": "og:type"]),
    meta(content: item.title, customAttributes: ["property": "og:title"]),
    meta(content: item.metadata.summary, customAttributes: ["property": "og:description"]),
    meta(content: SiteMetadata.url.appendingPathComponent(ogImage).absoluteString, name: "twitter:image"),
    meta(content: item.title, name: "twitter:image:alt"),
    item.archive ? meta(content: "noindex", name: "robots") : [],
  ]) {
    div(class: "article-grid") {
      aside {
        div(class: "flex flex-col gap-8") {
          if let toc {
            nav(class: "article-toc", customAttributes: ["aria-label": "Contents"]) {
              p(class: "sidebar-header") { "Contents" }
              Node.raw(toc)
            }
          }

          if !tags.isEmpty {
            nav(customAttributes: ["aria-label": "Tags"]) {
              p(class: "sidebar-header") { "Tags" }
              ul {
                tags.map { tag in
                  li { tagLink(tag, href: tagURL(tag, section: section), isCurrent: false) }
                }
              }
            }
          }

          div {
            p(class: "mb-2") { date }
          }
        }
      }

      div {
        article(customAttributes: section == .articles ? ["data-pagefind-body": "data-pagefind-body"] : [:]) {
          header(class: "mb-8 text-textfg/60") {
            h1(class: "heading-1") { item.title }

            if item.archive {
              span(class: "inline-block mt-4 p-1 rounded-md bg-textfg text-bodybg") { "archived" }
            }

            p(class: "mt-4 links lg:hidden print:block") {
              "Posted on"
              date
              // On desktop the tags are in the sidebar
              if !tags.isEmpty {
                span {
                  "in "
                  tags.enumerated().map { index, tag in
                    Node.fragment([
                      %tagSeparator(index: index, totalTags: tags.count),
                      %tagLink(tag, href: tagURL(tag, section: section), isCurrent: false),
                    ])
                  }
                }
              }
            }

            if let toc {
              details(class: "article-toc group mt-6 lg:hidden print:hidden") {
                summary(class: "flex cursor-pointer list-none items-center gap-1.5 [&::-webkit-details-marker]:hidden") {
                  Node.raw(#"<svg class="h-3.5 w-3.5 group-open:rotate-90" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg>"#)
                  "Contents"
                }
                div(class: "mt-3") { Node.raw(toc) }
              }
            }
          }

          div(class: "prose") {
            Node.raw(item.body)
          }
        }

        if section == .articles {
          writtenBy()
          moreArticles(item, allItems: context.allItems)
        }
      }
    }

    if toc != nil {
      tocHighlighter()
    }
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
          .map(link => ({ link, heading: document.getElementsByName(decodeURIComponent(link.hash.slice(1)))[0]?.parentElement }))
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

/// Who wrote the article, for readers who landed on it without knowing the site
private func writtenBy() -> Node {
  div(class: "mt-16 prose text-textfg/60 print:hidden") {
    p {
      "Written by Kevin Renskers, a freelance software engineer with over 25 years of experience. Subscribe to one of the"
      a(href: "/feeds/") { "RSS feeds" }
      %", or "
      a(href: "mailto:kevin@loopwerk.io") { "get in touch" }
      %" if you have questions or feedback about this article."

      if SiteMetadata.available {
        "Liked what you read? Kevin is currently"
        a(href: "/about/") { "available for hire" }
        %"!"
      }
    }

    div(class: "text-xs") {
      socialLinks()
    }
  }
}

private func moreArticles(_ article: Item<ArticleMetadata>, allItems: [AnyItem]) -> Node {
  let otherArticles = listedArticles(in: .articles, allItems: allItems).filter { $0.url != article.url }
  let latestArticles = otherArticles.prefix(2)
  let tags = Set(article.metadata.tags)

  let relatedArticles = otherArticles
    .map { article in
      let numberOfSharedTags = tags.intersection(Set(article.metadata.tags)).count
      return (article, numberOfSharedTags)
    }
    .filter { $0.1 > 0 } // filter out articles with zero matched tags
    .sorted { // sort by number of shared tags, and then by date
      if $0.1 == $1.1 {
        return $0.0.date > $1.0.date
      }
      return $0.1 > $1.1
    }
    .map(\.0) // extract the sorted articles
    .prefix(2)

  let seeMoreArticles = relatedArticles.count >= 2 ? relatedArticles : latestArticles
  let seeMoreArticlesTitle = relatedArticles.count >= 2 ? "Related articles" : "Recent articles"

  return div(class: "mt-16 md:mt-24 print:hidden") {
    h2(class: "heading-1 mb-8") { seeMoreArticlesTitle }

    div(class: "flex flex-col gap-8 pb-6") {
      seeMoreArticles.map { _renderArticleForGrid(article: $0) }
    }

    p(class: "prose") {
      a(href: "/articles/") { "› See all articles" }
    }
  }
}
