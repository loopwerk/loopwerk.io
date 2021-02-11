import Saga
import HTML

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

func renderArticle(context: PageRenderingContext<ArticleMetadata, SiteMetadata>) -> Node {
  baseLayout(section: .articles, title: context.page.title, siteMetadata: context.siteMetadata) {
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
