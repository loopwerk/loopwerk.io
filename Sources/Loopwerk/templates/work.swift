import HTML
import Saga

func renderWork(context: ItemsRenderingContext<WorkProjectMetadata>) -> Node {
  baseHtml(title: "Work", canonicalPath: "/work/", section: .work) {
    div(class: "prose") {
      h1 { "Work" }
      p {
        "Web and iOS apps I've worked on since 2010. Older projects (many websites, mostly written with PHP) are not included because they're no longer online and I didn't keep screenshots."
      }
      p {
        "If you are looking for a developer to work on your project,"
        a(href: "/about/") { "check if I am available" }
        %"."
      }
    }

    context.items.map { app in
      div(class: "mt-12 prose") {
        h3(class: "text-2xl font-bold !mb-0") { app.title }

        div(class: "mb-4 flex flex-wrap screenshots\(app.metadata.roundOffImages ?? true ? " rounded" : "") break_\(app.metadata.breakImages ?? (app.metadata.images.count % 2 == 0 ? 2 : app.metadata.images.count))") {
          app.metadata.images.map { src in
            %span(class: "block") { %img(src: "/work/images/\(src)") }
          }
        }

        Node.raw(app.body)

        if let url = app.metadata.url {
          div(class: "mt-4") {
            a(class: "app", href: url, rel: "nofollow", target: "_blank") {
              if url.contains(".apple.com") {
                "App Store"
              } else {
                "Visit website"
              }
            }
          }
        }
      }
    }
  }
}

func renderOpenSource(context: ItemsRenderingContext<OpenSourceProjectMetadata>) -> Node {
  baseHtml(title: "Open Source", canonicalPath: "/open-source/", section: .openSource) {
    div(class: "prose") {
      h1 { "Open Source" }
      p {
        "These are some of the more interesting open source projects I've created over the years."
        "For teams using my open source projects in production, I offer"
        a(href: "/open-source/support/") {
          "commercial support and consulting"
        }
        %"."
      }
    }

    let projectsByCategory = Dictionary(grouping: context.items, by: { $0.metadata.category })

    ["Python", "Swift", "JavaScript", "Objective-C", "Other"].map { category -> Node in
      let projects = projectsByCategory[category] ?? []
      return renderCategory(category: category, projects: projects)
    }
  }
}

@NodeBuilder
private func renderCategory(category: String, projects: [Item<OpenSourceProjectMetadata>]) -> Node {
  div(class: "mt-12") {
    h1(class: "font-title text-3xl font-bold mb-6") { category == "JavaScript" ? "TypeScript / JavaScript" : category }

    projects
      .map { project -> Node in
        return renderProject(project: project)
      }
  }
}

@NodeBuilder
private func renderProject(project: Item<OpenSourceProjectMetadata>) -> Node {
  div(class: "pb-10 lg:pb-8") {
    h3(class: "text-xl font-bold") {
      project.title
    }

    div(class: "[&_a]:underline") {
      Node.raw(project.body)
    }

    div(class: "mt-2 lg:mt-0 flex gap-1 md:gap-4 items-start md:items-center flex-col md:flex-row") {
      div {
        a(class: "orange app", href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
          project.metadata.repo
        }
      }
      img(src: "https://img.shields.io/github/stars/\(project.metadata.repo)?color=f5b031&labelColor=566b78")
    }
  }
}
