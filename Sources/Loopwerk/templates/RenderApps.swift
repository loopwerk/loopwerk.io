import Saga
import HTML

func renderApps(context: ItemsRenderingContext<AppMetadata, SiteMetadata>) -> Node {
  baseLayout(section: .apps, title: "Apps", siteMetadata: context.siteMetadata) {
    article {
      div(class: "page_content") {
        p {
          "iOS apps I've worked on. I was either the only developer on the project, or the lead developer with more people on the team. Newest apps are shown first."
        }

        context.items.map { app in
          div(class: "app") {
            h2 { app.title }

            div(class: app.metadata.images.count > 1 ? "screenshots" : "screenshot") {
              app.metadata.images.map { src in
                %span { %img(src: "/apps/images/\(src)" )}
              }
            }

            app.body

            if let url = app.metadata.url {
              a(class: "appstorelink", href: url) { "App Store" }
            }
          }
        }
      }
    }
  }
}
