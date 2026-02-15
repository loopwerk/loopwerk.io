import Foundation
import HTML
import Saga

func _renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  a(class: "relative group hover:text-orange", href: article.url) {
    h2(class: "font-bold text-lg text-pretty") {
      article.title
      Node.trim
      span(class: "font-thin text-xs text-light ml-3 whitespace-nowrap") {
        "\u{00A0}\(article.date.formatted("MMM dd, YYYY"))"
      }
    }
    
    p(class: "text-gray") {
      article.metadata.summary ?? ""
    }
  }
}

func _renderArticlesHeader(title: String) -> Node {
  return Node.fragment([
    div(class: "prose") {
      h1 { title }
    },
    
    // Search
    form(action: "/search/", class: "relative mt-8 mb-12 lg:mt-12 lg:mb-16", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
    }
  ])
}


func _renderArticlesList(_ articles: [Item<ArticleMetadata>]) -> Node {
  div(class: "flex flex-col gap-8") {
    articles.map { _renderArticleForGrid(article: $0) }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  let articlesPerYear = Dictionary(grouping: context.items, by: { $0.year })
  let sortedByYearDescending = articlesPerYear.sorted { $0.key > $1.key }
  
  return baseLayout(canocicalURL: "/articles/", section: .articles, title: "Articles") {
    _renderArticlesHeader(title: "Articles")
    
    div(class: "flex flex-col gap-16 pb-8") {
      sortedByYearDescending.map { year, articles in
        div {
          h1(class: "font-title font-bold text-4xl mb-8") { "\(year)" }
          _renderArticlesList(articles)
        }
      }
    }
  }
}

func renderTag<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  let extraHeader = link(href: "/articles/tag/\(context.key.slugified)/feed.xml", rel: "alternate", title: "\(SiteMetadata.name): articles with tag \(context.key)", type: "application/rss+xml")
  
  return baseLayout(canocicalURL: "/articles/tag/\(context.key.slugified)/", section: .articles, title: "Articles in #\(context.key)", rssLink: "tag/\(context.key.slugified)/", extraHeader: extraHeader) {
    _renderArticlesHeader(title: "#\(context.key)")
    _renderArticlesList(context.items)
  }
}

func renderYear<T>(context: PartitionedRenderingContext<T, ArticleMetadata>) -> Node {
  baseLayout(canocicalURL: "/articles/\(context.key)/", section: .articles, title: "Articles in \(context.key)") {
    _renderArticlesHeader(title: "\(context.key)")
    _renderArticlesList(context.items)
  }
}
