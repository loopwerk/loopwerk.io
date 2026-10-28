import Foundation
import HTML
import Saga

/// The work projects with `includeInCV: true`, which fill the CV's `{{ cv_projects }}` placeholder
func cvProjects(saga: Saga) -> [Item<WorkProjectMetadata>] {
  saga.allItems
    .compactMap { $0 as? Item<WorkProjectMetadata> }
    .filter { $0.metadata.includeInCV == true }
}

/// The CV page. The PDF version at /about/KevinRenskers.pdf is generated from the same markdown file.
func renderCV(context: ItemRenderingContext<PageMetadata>) -> Node {
  return baseHtml(title: "CV", canonicalPath: context.item.url, section: .cv, hasMarkdownTwin: true, asideContent: aboutAsideContent()) {
    article(class: "prose [&_h3+p]:-mt-4 [&_h3+p]:text-sm [&_h3+p]:text-textfg/70 [&_h4]:mb-0 [&_h4+p]:mt-1") {
      div(class: "print:hidden text-sm mb-8 links") {
        a(href: "/about/KevinRenskers.pdf", target: "_blank") { "Download as PDF" }
      }

      div(class: "-mb-4") {
        h1(class: "mb-0!") { context.item.title }
      }

      Node.raw(context.item.body)
    }
  }
}

/// The standalone document WeasyPrint turns into the PDF. Paths are relative to /about/cv/.
func renderCVDocument(item: Item<PageMetadata>) -> Node {
  // Everything before the first section heading (location, tagline, contact details) goes next to the photo
  let headerEnd = item.body.range(of: "<h2")?.lowerBound ?? item.body.endIndex

  return [
    .documentType("html"),
    html(lang: "en-US") {
      head {
        meta(charset: "utf-8")
        title { "\(item.title) CV" }
        meta(content: SiteMetadata.author, name: "author")
        link(href: "cv-pdf.css", rel: "stylesheet")
      }
      body {
        header {
          img(alt: "A photo of Kevin", src: "kevin-cv.jpg")
          div {
            h1 { item.title }
            Node.raw(String(item.body[..<headerEnd]))
          }
        }
        Node.raw(String(item.body[headerEnd...]))
      }
    },
  ]
}
