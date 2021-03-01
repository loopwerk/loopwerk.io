import Saga
import HTML

func renderProjects(context: ItemsRenderingContext<ProjectMetadata, SiteMetadata>) -> Node {
  baseLayout(section: .projects, title: "Open Source", siteMetadata: context.siteMetadata) {
    article {
      div(class: "page_content opensource") {
        p {
          "These are some of the more interesting open source projects I’ve created over the years. If you use one or more of these projects, please consider"
          a(href: "https://www.buymeacoffee.com/loopwerk", rel: "nofollow", target: "_blank") { "buying me a coffee" }
          %"."
        }

        ["Swift", "JavaScript", "Objective-C", "Python", "Other"].map { category -> Node in
          let projects = context.items.filter { $0.metadata.category == category }
          return renderCategory(category: category, projects: projects)
        }
      }
    }
  }
}

@NodeBuilder
private func renderCategory(category: String, projects: [Item<ProjectMetadata>]) -> Node {
  div(class: "lineheader") {
    div(class: "line") {}
    h1 { category }
  }

  div(class: "projects") {
    projects
      .filter { $0.metadata.parent == nil }
      .sorted { ($0.order, $0.title) < ($1.order, $1.title) }
      .map { project -> Node in
        let subProjects = projects.filter { $0.metadata.parent == project.title }
        return renderProject(project: project, subProjects: subProjects)
      }
  }
}

@NodeBuilder
private func renderProject(project: Item<ProjectMetadata>, subProjects: [Item<ProjectMetadata>]) -> Node {
  div(class: "project") {
//    if let image = project.metadata.image {
//      a(class: "contains_image", href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
//        img(height: "640", src: image, width: "1280")
//      }
//    }

    h3 { project.title }
    p {
      project.metadata.text
      br()
      a(href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
        project.metadata.repo
      }
    }

    if !subProjects.isEmpty {
      div(class: "subprojects") {
        h2 {
          "\(project.title) projects"
        }
        subProjects
          .sorted { ($0.order, $0.title) < ($1.order, $1.title) }
          .map {
            renderProject(project: $0, subProjects: [])
          }
      }
    }
  }
}
