import Saga
import HTML
import Foundation

func renderArticleInfo(_ article: Page<ArticleMetadata>) -> Node {
  div(class: "article_info") {
    span(class: "time") {
      article.date.formatted("MMMM dd") + ","
      a(href: "/articles/\(article.date.formatted("yyyy"))/") {
        article.date.formatted("yyyy")
      }
    }

    %.text("\(article.body.withoutHtmlTags.numberOfWords) words, posted in ")

    article.metadata.tags.enumerated().map { index, tag in
      Node.fragment([
        index > 0 ? %", " : %"",
        %a(href: "/articles/tag/\(tag.slugify())/") { tag }
      ])
    }
  }
}

@NodeBuilder
func getArticleHeader(_ article: Page<ArticleMetadata>, siteUrl: URL) -> NodeConvertible {
  meta(content: "summary_large_image", name: "twitter:card")
  meta(content: "@kevinrenskers", name: "twitter:site")
  meta(content: siteUrl.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "twitter:image")
  meta(content: article.title.escapedXMLCharacters, name: "twitter:image:alt")
  meta(content: siteUrl.appendingPathComponent(article.url).absoluteString, name: "og:url")
  meta(content: article.title.escapedXMLCharacters, name: "og:title")
  meta(content: article.summary.escapedXMLCharacters, name: "og:description")
  meta(content: siteUrl.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "og:image")
  meta(content: "1014", name: "og:image:width")
  meta(content: "530", name: "og:image:height")
}

func renderArticle(context: PageRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  let extraHeader = getArticleHeader(context.page, siteUrl: context.siteMetadata.url)

  return baseLayout(section: .articles, title: context.page.title, siteMetadata: context.siteMetadata, extraHeader: extraHeader) {
    article {
      h1 { context.page.title }

      renderArticleInfo(context.page)

      div(class: "article_content") {
        context.page.body
      }

      div(id: "article_footer") {
        p {
          "Have feedback? Let me know on"
          a(href: "https://twitter.com/kevinrenskers") { "Twitter" }
          %"."
        }
      }
    }
  }
}
