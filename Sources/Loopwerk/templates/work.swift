import HTML
import Parsley
import Saga

func renderWork(context: ItemsRenderingContext<WorkProjectMetadata>) -> Node {
  let projectsByCategory = Dictionary(grouping: context.items, by: { $0.metadata.category })

  let toc = ul {
    WorkCategory.allCases.map { category in
      li { a(href: "#\(category.rawValue)") { category.title } }
    }
  }

  return baseHtml(title: "Work", canonicalPath: "/work/", section: .work, toc: toc) {
    h1 { "Work" }
  } content: {
    div(class: "prose mb-16") {
      p { "A selection of projects, from web applications and APIs to iOS apps and SDKs." }
      p {
        "If you are looking for a developer to work on your project,"
        a(href: "/hire-me/") { "check if I am available" }
        %"."
      }
    }

    WorkCategory.allCases.map { category in
      div(class: "mb-24") {
        h2(class: "font-title text-3xl font-bold mb-12", id: category.rawValue) { category.title }
        (projectsByCategory[category] ?? []).map(renderWorkProject)
      }
    }
  }
}

@NodeBuilder
private func renderWorkProject(project: Item<WorkProjectMetadata>) -> Node {
  div(class: project.metadata.category == .earlier ? "mb-10 prose" : "mb-16 prose") {
    h3(class: "text-xl font-bold mb-0!") { project.title }
    p(class: "text-textfg/60") { project.metadata.tech.joined(separator: ", ") }

    if let images = project.metadata.images {
      div(class: "mb-4 flex flex-wrap screenshots\(project.metadata.roundedImages ?? true ? " rounded" : "") break_\(project.metadata.breakImages ?? (images.count % 2 == 0 ? 2 : images.count))") {
        images.map { src in
          %span(class: "block") { %img(src: "/work/images/\(src)") }
        }
      }
    }

    Node.raw(project.body)

    if let from = project.metadata.from, let testimonial = project.metadata.testimonial {
      blockquote(class: "[&>p:first-child]:mb-0!") {
        Node.raw(try! Parsley.html(testimonial, options: [.smartQuotes]))
        p(class: "font-normal mt-2!") { "— " + from }
      }
    }

    if let url = project.metadata.url {
      p {
        a(class: "app", href: url, rel: "nofollow", target: "_blank") {
          if url.contains(".apple.com") {
            "App Store"
          } else if url.contains("github.com") {
            "GitHub"
          } else {
            "Visit website"
          }
        }
      }
    }
  }
}

func renderOpenSource(context: ItemsRenderingContext<OpenSourceProjectMetadata>) -> Node {
  let projectsByCategory = Dictionary(grouping: context.items, by: { $0.metadata.category })

  let toc = ul {
    ProjectCategory.allCases.map { category in
      li { a(href: "#\(category.title.slugified)") { category.title } }
    }
  }

  return baseHtml(title: "Open source", canonicalPath: "/open-source/", section: .openSource, toc: toc) {
    h1 { "Open source" }
  } content: {
    div(class: "prose mb-16") {
      p {
        "These are some of the more interesting open source projects I've created over the years. For teams using my open source projects in production, I offer"
        a(href: "/open-source/support/") { "commercial support and consulting" }
        %"."
      }
    }

    ProjectCategory.allCases.map { category in
      div(class: "mt-12") {
        h2(class: "font-title text-3xl font-bold mb-6", id: category.title.slugified) { category.title }
        (projectsByCategory[category] ?? []).map(renderOpenSourceProject)
      }
    }
  }
}

@NodeBuilder
private func renderOpenSourceProject(project: Item<OpenSourceProjectMetadata>) -> Node {
  div(class: "pb-10 lg:pb-8") {
    h3(class: "text-xl font-bold") {
      project.title
    }

    div(class: "[&_a]:underline") {
      Node.raw(project.body)
    }

    div(class: "mt-2 lg:mt-0 flex gap-1 md:gap-4 items-start md:items-center flex-col md:flex-row links") {
      div {
        a(class: "app", href: "https://github.com/\(project.metadata.repo)", rel: "nofollow", target: "_blank") {
          project.metadata.repo
        }
      }
      img(class: "print:hidden", src: "https://img.shields.io/github/stars/\(project.metadata.repo)?color=f5b031&labelColor=566b78")
    }
  }
}
