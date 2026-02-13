import Foundation
import HTML
import Saga

func renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  section {
    div {
      a(class: "hover:text-orange", href: article.url) {
        h2(class: "text-2xl font-bold mb-3") {
          article.title
        }
      }

      div(class: "text-gray gray-links text-xs font-mono") {
        article.date.formatted("MMMM dd, YYYY")
        "in "
        article.metadata.tags.sorted().enumerated().map { index, tag in
          Node.fragment([
            %tagPrefix(index: index, totalTags: article.metadata.tags.count),
             %a(href: "/articles/tag/\(tag.slugified)/") { "#\(tag)" },
          ])
        }
      }
      
      p(class: "text-gray text-sm mt-3") {
        article.metadata.summary ?? ""
      }
    }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  let articlesPerYear = Dictionary(grouping: context.items, by: { $0.year })
  let sortedByYearDescending = articlesPerYear.sorted { $0.key > $1.key }

  return baseLayout(canocicalURL: "/articles/", section: .articles, title: "Articles", rssLink: "") {
    // Search
    form(action: "/search/", class: "relative mb-20", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
    }

    // Articles by year
    div(class: "flex flex-col gap-20 pb-12") {
      sortedByYearDescending.map { year, articles in
        div {
          h1(class: "font-title font-bold text-5xl mb-12") { "\(year)" }
          
          div(class: "flex flex-col gap-12") {
            articles.map { renderArticleForGrid(article: $0) }
          }
        }
      }
    }
  }
}

func _renderArticles(_ articles: [Item<ArticleMetadata>], canocicalURL: String, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  return baseLayout(canocicalURL: canocicalURL, section: .articles, title: "articles in \(pageTitle)", rssLink: rssLink, extraHeader: extraHeader) {
    // Search
    form(action: "/search/", class: "relative mb-20", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
    }

    h1(class: "font-title font-bold text-5xl mb-12") { pageTitle }

    div(class: "flex flex-col gap-12 pb-12") {
      articles.map { renderArticleForGrid(article: $0) }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")

  return _renderArticles(context.items, canocicalURL: "/articles/tag/\(context.key.slugified)/", title: "#\(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader)
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  _renderArticles(context.items, canocicalURL: "/articles/\(context.key)/", title: "\(context.key)")
}
