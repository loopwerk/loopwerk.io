import Saga
import HTML

func renderApps(context: ItemsRenderingContext<AppMetadata>) -> Node {
  baseLayout(section: .apps, title: "Apps") {
    article {
      div(class: "page_content") {
        p {
          "Web and iOS apps I've worked on. Newest apps are shown first."
        }

        context.items.map { app in
          div(class: "app") {
            h2 { app.title }

            div(class: "screenshots\(app.metadata.roundOffImages ?? true ? " rounded" : "") break_\(app.metadata.breakImages ?? (app.metadata.images.count % 2 == 0 ? 2 : app.metadata.images.count))") {
              app.metadata.images.map { src in
                %span { %img(src: "/apps/images/\(src)" )}
              }
            }

            Node.raw(app.body)

            if let url = app.metadata.url {
              a(href: url, rel: "nofollow", target: "_blank") {
                if url.contains(".apple.com") {
                  "App Store"
                } else {
                  "Website"
                }
              }
            }
          }
        }
      }
    }
  }
}
