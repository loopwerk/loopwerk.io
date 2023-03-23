import SwiftSoup
import Foundation
import Parsley

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
      // Using SwiftSoup, we turn the HTML string into a proper document
      let doc = try SwiftSoup.parseBodyFragment(self)

      // Find all links with an href attribute
      let links = try doc.select("a[href]")
      for link in links {
        // External links get target="_blank" and rel="nofollow"
        let href = try link.attr("href")
        if href.starts(with: "http://") || href.starts(with: "https://") {
          try link.attr("target", "_blank")
          try link.attr("rel", "nofollow")
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

        if (tagName == "p") {
          if (text == "%TOC%") {
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

      // Search all code blocks and replace /*HLS [optional title]*/[content]/*HLE*/ with a highlight span
      let codeBlocks = try doc.select("code")
      for codeBlock in codeBlocks {
        var content = try codeBlock.html()

        let regex = try NSRegularExpression(pattern: #"(?s)/\*HLS(?:(?!\*/)\W)?((?:(?!/\*HLS).)*?)\*/(.*?)/\*HLE\*/"#)
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        content = regex.stringByReplacingMatches(in: content, options: [], range: range, withTemplate: #"<span class="highlight" title="$1">$2</span>"#)

        let regex2 = try NSRegularExpression(pattern: #"(?s)/\*TMS(?:(?!\*/)\W)?((?:(?!/\*TMS).)*?)\*/(.*?)/\*TME\*/"#)
        let range2 = NSRange(content.startIndex..<content.endIndex, in: content)
        content = regex2.stringByReplacingMatches(in: content, options: [], range: range2, withTemplate: #"<span class="template" title="$1">$2</span>"#)

        try codeBlock.html(content)
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
