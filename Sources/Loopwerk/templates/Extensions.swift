import Foundation
import Saga

extension Date {
  func formatted(_ format: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }
}

extension String {
  var numberOfWords: Int {
    let characterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
    let components = self.components(separatedBy: characterSet)
    return components.filter { !$0.isEmpty }.count
  }

  // This is a sloppy implementation but sadly `NSAttributedString(data:options:documentAttributes:)`
  // is not available in CoreFoundation, and as such can't run on Linux (blocking CI builds).
  var withoutHtmlTags: String {
    return self
      .replacingOccurrences(of: "(?m)<pre><span></span><code>[\\s\\S]+?</code></pre>", with: "", options: .regularExpression, range: nil)
      .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// See https://jinja2docs.readthedocs.io/en/stable/templates.html#truncate
  func truncate(length: Int = 255, killWords: Bool = false, end: String = "...", leeway: Int = 5) -> String {
    if self.count <= length + leeway {
      return self
    }

    if killWords {
      return self.prefix(length - end.count) + end
    }

    return self.prefix(length - end.count).split(separator: " ").dropLast().joined(separator: " ") + end
  }
}

extension Item where M == ArticleMetadata {
  var summary: String {
    if let summary = metadata.summary {
      return summary
    }
    return String(body.withoutHtmlTags.truncate())
  }
}
