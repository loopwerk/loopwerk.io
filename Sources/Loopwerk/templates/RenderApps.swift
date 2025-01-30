import HTML
import Saga

func renderApps(context: ItemsRenderingContext<AppMetadata>) -> Node {
  baseLayout(canocicalURL: "/apps/", section: .apps, title: "Apps") {
    p {
      "Web and iOS apps I've worked on since 2010. Older projects (many websites, mostly written with PHP) are not included because they're no longer online and I didn't keep screenshots."
    }

    context.items.map { app in
      div(class: "mt-12") {
        h2(class: "text-2xl font-bold mb-2") { app.title }

        div(class: "mb-4 flex flex-wrap screenshots\(app.metadata.roundOffImages ?? true ? " rounded" : "") break_\(app.metadata.breakImages ?? (app.metadata.images.count % 2 == 0 ? 2 : app.metadata.images.count))") {
          app.metadata.images.map { src in
            %span(class: "block") { %img(src: "/apps/images/\(src)") }
          }
        }

        Node.raw(app.body)

        if let url = app.metadata.url {
          div(class: "mt-4") {
            a(class: "orange app", href: url, rel: "nofollow", target: "_blank") {
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
