import Saga
import HTML

func renderProjects(context: ItemsRenderingContext<ProjectMetadata>) -> Node {
  baseLayout(section: .projects, title: "Open Source") {
    article {
      div(class: "page_content opensource") {
        p {
          "These are some of the more interesting open source projects I’ve created (or contributed to) over the years."
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
  div(class: "projects") {
    h1 { category }

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
    h3 {
      project.title
      if project.involvement != .author {
        span(class: "involvement") {
          project.involvement.rawValue
        }
      }
    }

    p {
      project.metadata.text
    }

    div(class: "footer") {
      div {
        a(href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
          project.metadata.repo
        }
      }
      div {
        img(src: "https://img.shields.io/github/stars/\(project.metadata.repo)?color=f5b031&labelColor=566b78")
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
