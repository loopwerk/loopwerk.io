import Foundation
import HTML
import Saga

func uniqueTagsWithCount(_ articles: [Item<ArticleMetadata>]) -> [(String, Int)] {
  let tags = articles.flatMap { $0.expandedTags }
  let tagsWithCounts = tags.reduce(into: [:]) { $0[$1, default: 0] += 1 }
  return tagsWithCounts.sorted {
    // Sort by number of articles (descending). If that's the same, sort by title (ascending).
    if $0.1 == $1.1 {
      return $0.0 < $1.0
    }
    return $0.1 > $1.1
  }
}

func _renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  a(class: "relative group hover:text-orange", href: article.url) {
    h2(class: "font-bold text-lg text-pretty") {
      article.title
      Node.trim
      span(class: "font-thin text-xs text-tertiarytext ml-3 whitespace-nowrap") {
        "\u{00A0}\(article.date.formatted("MMM dd, YYYY"))"
      }
    }

    p(class: "text-secondarytext") {
      article.metadata.summary ?? ""
    }
  }
}

func _renderArticlesHeader(title: String, allItems: [AnyItem]) -> Node {
  let articles = allItems.compactMap { $0 as? Item<ArticleMetadata> }.filter { !$0.archive }
  let tagsWithCounts = uniqueTagsWithCount(articles)

  return Node.fragment([
    div(class: "prose") {
      h1 { title }
    },

    // Search with integrated tag dropdown
    form(class: "relative mt-8 mb-12 lg:mt-12 lg:mb-16", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
      a(class: "absolute right-[66px] top-2 h-7 w-7 rounded text-center text-lg leading-7 text-searchfg/50 hover:bg-searchfg/10 hover:text-searchfg no-underline hidden", href: "./", id: "search-clear") { "\u{00D7}" }
      input(class: "hidden peer", id: "tag-toggle", type: "checkbox")
      label(class: "absolute right-2 top-2 h-7 px-3 rounded text-[0.8rem] font-medium leading-7 cursor-pointer select-none bg-searchfg/10 text-searchfg hover:bg-searchfg/20 peer-checked:bg-searchfg/20", for: "tag-toggle") { "tags" }
      div(class: "hidden peer-checked:block absolute top-full left-0 right-0 mt-2 p-4 rounded-md z-10 bg-searchbg") {
        div(class: "flex flex-wrap gap-x-2 text-secondarytext secondarytext-links text-sm") {
          a(href: "/articles/") { "all (\(articles.count))" }
          tagsWithCounts.map { tag, count in
            a(href: "/articles/tag/\(tag.slugified)/") {
              "#\(tag) (\(count))"
            }
          }
        }
      }
    },

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

          const input = document.getElementById("search");
          input.value = q;
          document.getElementById("search-clear").classList.remove("hidden");

          const articles = document.querySelectorAll("#articles-list a[href]");
          articles.forEach(a => {
            const result = resultsByUrl.get(a.getAttribute("href"));
            if (result) {
              const p = a.querySelector("p");
              if (p) p.innerHTML = result.excerpt;
            } else {
              a.style.display = "none";
            }
          });

          const yearSections = document.querySelectorAll("#articles-list > div");
          yearSections.forEach(section => {
            const visible = section.querySelectorAll("a[href]:not([style*='display: none'])");
            section.style.display = visible.length ? "" : "none";
          });
        })();
        """
      )
    },
  ])
}

func _renderArticlesList(_ articles: [Item<ArticleMetadata>], groupByYear: Bool = true) -> Node {
  let articlesPerYear = Dictionary(grouping: articles, by: { $0.year })
  let sortedByYearDescending = articlesPerYear.sorted { $0.key > $1.key }
  
  return div(class: "flex flex-col gap-16 pb-8", id: "articles-list") {
    sortedByYearDescending.map { year, articles in
      div {
        if groupByYear {
          h1(class: "font-title font-bold text-4xl mb-8") { "\(year)" }
        }
        div(class: "flex flex-col gap-8") {
          articles.map { _renderArticleForGrid(article: $0) }
        }
      }
    }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  return baseLayout(canocicalURL: "/articles/", section: .articles, title: "Articles") {
    _renderArticlesHeader(title: "Articles", allItems: context.allItems)
    _renderArticlesList(context.items)
  }
}

func renderTag(context: PartitionedRenderingContext<String, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")

  return baseLayout(canocicalURL: "/articles/tag/\(context.key.slugified)/", section: .articles, title: "Articles in #\(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader) {
    _renderArticlesHeader(title: "#\(context.key)", allItems: context.allItems)
    _renderArticlesList(context.items)
  }
}

func renderYear(context: PartitionedRenderingContext<Int, ArticleMetadata>) -> Node {
  baseLayout(canocicalURL: "/articles/\(context.key)/", section: .articles, title: "Articles in \(context.key)") {
    _renderArticlesHeader(title: "\(context.key)", allItems: context.allItems)
    _renderArticlesList(context.items, groupByYear: false)
  }
}
