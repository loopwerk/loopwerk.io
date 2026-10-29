import Foundation
import HTML
import Saga

/// The work projects with `includeInCV: true`, which fill the CV's `{{ cv_projects }}` placeholder
func cvProjects(saga: Saga) -> [Item<WorkProjectMetadata>] {
  saga.allItems
    .compactMap { $0 as? Item<WorkProjectMetadata> }
    .filter { $0.metadata.includeInCV == true }
}

/// The standalone document WeasyPrint turns into the PDF. Paths are relative to /hire-me/cv/.
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
