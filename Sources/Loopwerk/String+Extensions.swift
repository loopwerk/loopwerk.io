import SwiftSoup
import Foundation

extension String {
  func improveHTML() -> String {
    do {
      // Using SwiftSoup, we turn the HTML string into a proper document
      let doc = try SwiftSoup.parseBodyFragment(self)

      // Find all links with an href attribute
      let links = try doc.select("a[href]")
      for link in links {
        // If the href doesn't start with a slash or mailto:, it's an external link.
        // This is simplified but should work for most examples.
        // External links get target="_blank" and rel="nofollow"
        let href = try link.attr("href")
        if !href.starts(with: "/") && !href.starts(with: "mailto:") {
          try link.attr("target", "_blank")
          try link.attr("rel", "nofollow")
        }
      }

      // Add named anchors to headings
      let headings = try doc.select("h1, h2, h3")
      for heading in headings {
        let slug = try heading.text().slugified
        try heading.prepend("<a name=\"\(slug)\"></a>")
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

      return try doc.body()?.html() ?? self
    } catch {
      return self
    }
  }
}
