import HTML
import Saga

func renderProjects(context: ItemsRenderingContext<ProjectMetadata>) -> Node {
  baseLayout(canocicalURL: "/projects/", section: .projects, title: "Open Source") {
    div(class: "prose") {
      h1 { "Open Source" }
      p {
        "These are some of the more interesting open source projects I've created over the years."
      }
    }

    ["Swift", "Python", "JavaScript", "Objective-C", "Other"].map { category -> Node in
      let projects = context.items.filter { $0.metadata.category == category }
      return renderCategory(category: category, projects: projects)
    }
  }
}

@NodeBuilder
private func renderCategory(category: String, projects: [Item<ProjectMetadata>]) -> Node {
  div(class: "mt-12") {
    h1(class: "font-title text-4xl font-bold mb-6") { category }

    projects
      .sorted { ($0.order, $0.title) < ($1.order, $1.title) }
      .map { project -> Node in
        return renderProject(project: project)
      }
  }
}

@NodeBuilder
private func renderProject(project: Item<ProjectMetadata>) -> Node {
  div(class: "pb-10 lg:pb-8") {
    h3(class: "text-xl font-bold") {
      project.title
    }

    div(class: "[&_a]:underline") {
      Node.raw(project.body)
    }

    div(class: "mt-2 lg:mt-0 flex gap-1 lg:gap-4 items-start lg:items-center flex-col lg:flex-row") {
      div {
        a(class: "orange app text-sm lg:text-base", href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
          project.metadata.repo
        }
      }
      img(src: "https://img.shields.io/github/stars/\(project.metadata.repo)?color=f5b031&labelColor=566b78")
    }
  }
}
