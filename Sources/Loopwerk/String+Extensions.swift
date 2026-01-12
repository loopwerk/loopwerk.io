import Foundation
import Parsley
import SwiftSoup

func tagnameToSpacing(_ tag: String) -> String {
  switch tag {
    case "h1":
      return ""
    case "h2":
      return "  "
    case "h3":
      return "    "
    default:
      return ""
  }
}

extension String {
  func improveHTML() -> String {
    do {
      // Unescape <mark> and <var> tags that were escaped by the markdown parser
      var html = self
        .replacingOccurrences(of: "&lt;mark&gt;", with: "<mark>")
        .replacingOccurrences(of: "&lt;/mark&gt;", with: "</mark>")
        .replacingOccurrences(of: "&lt;var&gt;", with: "<var>")
        .replacingOccurrences(of: "&lt;/var&gt;", with: "</var>")

      // Handle <mark title="...">
      let markAttrRegex = try NSRegularExpression(pattern: #"&lt;mark\s+title=&quot;([^&]*)&quot;&gt;"#)
      html = markAttrRegex.stringByReplacingMatches(in: html, range: NSRange(html.startIndex..., in: html), withTemplate: #"<mark title="$1">"#)

      // Using SwiftSoup, we turn the HTML string into a proper document
      let doc = try SwiftSoup.parseBodyFragment(html)

      // Find all links with an href attribute
      let links = try doc.select("a[href]")
      for link in links {
        // External links get target="_blank" and rel="nofollow"
        let href = try link.attr("href")
        if href.starts(with: "http://") || href.starts(with: "https://") {
          try _ = link.attr("target", "_blank")
          try _ = link.attr("rel", "nofollow")
        }
      }

      var toc: [String] = []
      var hasSeenTocTemplate = false

      // Add named anchors to headings
      // Generate the Table of Contents
      let headings = try doc.select("p, h1, h2, h3")
      for heading in headings {
        let tagName = heading.tagName()
        let text = try heading.text()

        if tagName == "p" {
          if text == "%TOC%" {
            hasSeenTocTemplate = true
          }
          continue
        }

        let slug = text.slugified
        try heading.prepend("<a name=\"\(slug)\"></a>")

        if hasSeenTocTemplate {
          toc.append("\(tagnameToSpacing(tagName))- [\(text)](#\(slug))")
        }
      }

      // Convert data-title attributes on pre elements into spans
      let preElements = try doc.select("pre[data-title]")
      for pre in preElements {
        let title = try pre.attr("data-title")
        try pre.prepend("<span class=\"code-title\">\(title)</span>")
      }

      // Convert blockquotes with [!TYPE] syntax to <aside class="type">
      let alertRegex = try NSRegularExpression(pattern: #"^\[!([A-Z]+)\]\s*(?:<br\s*/?>)?\s*"#)
      let blockquotes = try doc.select("blockquote")
      for blockquote in blockquotes {
        // Get the first paragraph to check for alert syntax
        if let firstP = try blockquote.select("p").first() {
          let text = try firstP.html()
          if let match = alertRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let typeRange = Range(match.range(at: 1), in: text) {
            let alertType = String(text[typeRange]).lowercased()

            // Remove the [!TYPE] marker and any following <br> from the first paragraph
            let cleanedText = alertRegex.stringByReplacingMatches(
              in: text,
              range: NSRange(text.startIndex..., in: text),
              withTemplate: ""
            )
            try firstP.html(cleanedText)

            // Create aside element and replace blockquote
            let aside = try doc.createElement("aside")
            try aside.addClass(alertType)
            let title = String(text[typeRange])
            try aside.html("<span class='title'>\(title)</span>" + blockquote.html())
            try blockquote.replaceWith(aside)
          }
        }
      }

      let result = try doc.body()?.html() ?? self
      let tocString = toc.joined(separator: "\n")
      let tocHtml = try Parsley.html(tocString)
      return result.replacingOccurrences(of: "<p>%TOC%</p>", with: tocHtml)
    } catch {
      return self
    }
  }
}
