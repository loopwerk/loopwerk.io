import Saga
import HTML
import Foundation

func tagPrefix(index: Int, totalTags: Int) -> Node {
  if index > 0 {
    if index == totalTags - 1 {
      return " and "
    } else {
      return ", "
    }
  }

  return ""
}

func renderArticleInfo(_ article: Item<ArticleMetadata>) -> Node {
  div(class: "article_info") {
    span(class: "time") {
      article.published.formatted("MMMM dd") + ","
      a(href: "/articles/\(article.published.formatted("yyyy"))/") {
        article.published.formatted("yyyy")
      }
    }

    %.text("\(article.body.withoutHtmlTags.numberOfWords) words, posted in ")

    article.metadata.tags.sorted().enumerated().map { index, tag in
      Node.fragment([
        %tagPrefix(index: index, totalTags: article.metadata.tags.count),
        %a(href: "/articles/tag/\(tag.slugified)/") { tag }
      ])
    }
  }
}

@NodeBuilder
func getArticleHeader(_ article: Item<ArticleMetadata>, siteUrl: URL) -> NodeConvertible {
  link(href: "\(siteUrl)\(article.url)", rel: "canonical")
  meta(content: article.summary, name: "description")
  meta(content: "summary_large_image", name: "twitter:card")
  meta(content: "@kevinrenskers", name: "twitter:site")
  meta(content: siteUrl.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "twitter:image")
  meta(content: article.title, name: "twitter:image:alt")
  meta(content: siteUrl.appendingPathComponent(article.url).absoluteString, name: "og:url")
  meta(content: article.title, name: "og:title")
  meta(content: article.summary, name: "og:description")
  meta(content: siteUrl.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "og:image")
  meta(content: "1014", name: "og:image:width")
  meta(content: "530", name: "og:image:height")
  script(crossorigin: "anonymous", src: "https://kit.fontawesome.com/f209982030.js")
}

func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  let extraHeader = getArticleHeader(context.item, siteUrl: SiteMetadata.url)

  let allArticles = context.allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let currentIndex = allArticles.firstIndex(where: { $0.relativeDestination == context.item.relativeDestination })!
  let nextArticle = allArticles[safeIndex: currentIndex - 1]
  let previousArticle = allArticles[safeIndex: currentIndex + 1]

  return baseLayout(section: .articles, title: context.item.title, extraHeader: extraHeader) {
    article {
      h1 { context.item.title }

      renderArticleInfo(context.item)

      div(class: "article_content") {
        Node.raw(context.item.body)
        
        Node.raw("""
<script src="https://giscus.app/client.js"
        data-repo="loopwerk/loopwerk.io"
        data-repo-id="MDEwOlJlcG9zaXRvcnk0Nzg0NTA3MA=="
        data-category="Article discussions"
        data-category-id="DIC_kwDOAtoOzs4Ciykw"
        data-mapping="pathname"
        data-strict="1"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="bottom"
        data-theme="preferred_color_scheme"
        data-lang="en"
        data-loading="lazy"
        crossorigin="anonymous"
        async>
</script>
""")
      }

      ul(class: "pagination") {
        li(class: "newer") {
          if let nextArticle = nextArticle {
            a(href: nextArticle.url, title: "newer article") { nextArticle.title }
          }
        }
        li(class: "older") {
          if let previousArticle = previousArticle {
            a(href: previousArticle.url, title: "older article") { previousArticle.title }
          }
        }
      }
    }
  }
}
