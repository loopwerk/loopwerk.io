import Foundation
import HTML
import Saga

func renderArticleForGrid(article: Item<ArticleMetadata>) -> Node {
  a(class: "relative group hover:text-orange", href: article.url) {
    h2(class: "font-bold text-2xl mb-3") {
      article.title
    }

    div(class: "text-gray gray-links text-xs font-mono mb-4") {
      article.date.formatted("MMMM dd, YYYY")
      Node.raw("&bull; ")

      article.metadata.tags.sorted().enumerated().map { index, tag in
        Node.fragment([
          %tagPrefix(index: index, totalTags: article.metadata.tags.count),
           Node.text("#\(tag)")
        ])
      }
    }

    p(class: "text-gray") {
      article.metadata.summary ?? ""
    }

    if article.metadata.heroImage != nil {
      img(
        alt: "",
        class: "hidden min-[1200px]:block absolute top-0 left-full pl-8 w-[200px] aspect-hero object-cover rounded-md opacity-0 group-hover:opacity-100",
        src: "/articles/heroes/\(article.filenameWithoutExtension)-315w.webp",
        customAttributes: ["loading": "lazy"]
      )
    }
  }
}

func renderArticles(context: ItemsRenderingContext<ArticleMetadata>) -> Node {
  _renderArticles(context.items, canocicalURL: "/articles/", title: "Articles")
}

func _renderArticles(_ articles: [Item<ArticleMetadata>], canocicalURL: String, title pageTitle: String, rssLink: String = "", extraHeader: NodeConvertible = Node.fragment([])) -> Node {
  return baseLayout(canocicalURL: canocicalURL, section: .articles, title: pageTitle, rssLink: rssLink, extraHeader: extraHeader) {
    div(class: "prose") {
      h1 { pageTitle }
    }

    // Search
    form(action: "/search/", class: "relative mt-12 mb-20", id: "search-form") {
      input(class: "w-full", id: "search", name: "q", placeholder: "Search articles", type: "text")
    }
    
    div(class: "flex flex-col gap-14 pb-14") {
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
