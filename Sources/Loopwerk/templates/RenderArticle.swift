import Foundation
import HTML
import Saga

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
  div(class: "text-gray gray-links text-sm") {
    span(class: "border-r border-gray pr-2 mr-2") {
      article.date.formatted("MMMM dd, yyyy")
    }

    %.text("\(article.body.withoutHtmlTags.numberOfWords) words, posted in ")

    article.metadata.tags.sorted().enumerated().map { index, tag in
      Node.fragment([
        %tagPrefix(index: index, totalTags: article.metadata.tags.count),
        %a(href: "/articles/tag/\(tag.slugified)/") { tag },
      ])
    }
  }
}

@NodeBuilder
func getArticleHeader(_ article: Item<ArticleMetadata>) -> NodeConvertible {
  link(href: "/static/prism.css", rel: "stylesheet")
  meta(content: article.summary, name: "description")
  meta(content: "summary_large_image", name: "twitter:card")
  meta(content: "@kevinrenskers", name: "twitter:site")
  meta(content: SiteMetadata.url.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "twitter:image")
  meta(content: article.title, name: "twitter:image:alt")
  meta(content: SiteMetadata.url.appendingPathComponent(article.url).absoluteString, name: "og:url")
  meta(content: article.title, name: "og:title")
  meta(content: article.summary, name: "og:description")
  meta(content: SiteMetadata.url.appendingPathComponent("/static/images/\(article.filenameWithoutExtension).png").absoluteString, name: "og:image")
  meta(content: "1014", name: "og:image:width")
  meta(content: "530", name: "og:image:height")
  script(crossorigin: "anonymous", src: "https://kit.fontawesome.com/f209982030.js")
}

func renderArticle(context: ItemRenderingContext<ArticleMetadata>) -> Node {
  let extraHeader = getArticleHeader(context.item)
  let allArticles = context.allItems.compactMap { $0 as? Item<ArticleMetadata> }
  let otherArticles = allArticles.filter { $0.url != context.item.url }
  let latestArticles = otherArticles.prefix(2)
  let tags = Set(context.item.metadata.tags)

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
    .map { $0.0 } // extract the sorted articles
    .prefix(2)

  let seeMoreArticles = relatedArticles.count >= 2 ? relatedArticles : latestArticles
  let seeMoreArticlesTitle = relatedArticles.count >= 2 ? "Related articles" : "Recent articles"

  return baseLayout(canocicalURL: context.item.url, section: .articles, title: context.item.title, extraHeader: extraHeader) {
    article(class: "prose") {
      h1 { context.item.title }
      div(class: "-mt-6") {
        renderArticleInfo(context.item)
      }
      Node.raw(context.item.body)
    }

    div(class: "border-t border-light mt-8 pt-8") {
      h2(class: "text-4xl font-extrabold mb-8") { "Written by" }
      div(class: "flex flex-col lg:flex-row gap-8") {
        div(class: "flex-[0_0_120px]") {
          img(class: "w-[120px] h-[120px] rounded-full", src: "/articles/images/kevin.png")
        }

        div(class: "prose") {
          h3(class: "!m-0") { "Kevin Renskers" }
          p(class: "text-gray") {
            "Freelance software developer with over 25 years of experience. Writes articles about Swift, Python, and TypeScript. Builds"
            a(href: "https://www.critical-notes.com") { "Critical Notes" }
            %", and maintains a bunch of"
            a(href: "/projects/") { "open source projects" }
            %"."
          }
          p(class: "text-gray") {
            "No AI was used in writing any of the content on this website."
          }
        }
      }
    }

    div(class: "mt-16") {
      h2(class: "text-4xl font-extrabold mb-8") { seeMoreArticlesTitle }

      div(class: "grid lg:grid-cols-2 gap-10") {
        seeMoreArticles.map { renderArticleForGrid(article: $0) }
      }

      p(class: "prose mt-8") {
        a(href: "/articles/") { "› See all articles" }
      }
    }

    div(class: "border-t border-light mt-8 pt-8") {
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
  }
}
