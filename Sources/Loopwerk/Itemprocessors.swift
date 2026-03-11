import Foundation
import Moon
import SagaPathKit
import Saga
import SwiftGD
import SwiftSoup

private let syntaxHighlighter: Moon = {
  do {
    return try Moon(additionalPlugins: ["prism-svelte.js"], bundle: Bundle.module)
  } catch {
    fatalError("Failed to initialize Moon: \(error)")
  }
}()

func permalink(item: Item<ArticleMetadata>) {
  // Insert the publication year into the permalink.
  // If the `relativeDestination` was "articles/looking-for-django-cms/index.html", then it becomes "articles/2009/looking-for-django-cms/index.html"
  var components = item.relativeDestination.components
  components.insert("\(Calendar.current.component(.year, from: item.date))", at: 1)
  item.relativeDestination = Path(components: components)
}

func heroImage(item: Item<ArticleMetadata>) {
  // Check if a hero image exists for this article. If so, get its dimensions.
  let imageFilename = item.filenameWithoutExtension + "-1480w.webp"
  let heroesPath = Path(SiteMetadata.projectRoot) + "content/articles/heroes"
  let imagePath = heroesPath + imageFilename

  if imagePath.exists {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath.string)),
       let image = try? Image(data: data, as: .webp)
    {
      item.metadata.heroImage = HeroImage(
        path: "/articles/heroes/" + imageFilename,
        width: image.size.width,
        height: image.size.height
      )
    }
  }
}

func unescapeMarkVar<M>(item: Item<M>) {
  var html = item.body
    .replacingOccurrences(of: "&lt;mark&gt;", with: "<mark>")
    .replacingOccurrences(of: "&lt;/mark&gt;", with: "</mark>")
    .replacingOccurrences(of: "&lt;var&gt;", with: "<var>")
    .replacingOccurrences(of: "&lt;/var&gt;", with: "</var>")

  // Handle <mark title="...">
  if let markAttrRegex = try? NSRegularExpression(pattern: #"&lt;mark\s+title=&quot;([^&]*)&quot;&gt;"#) {
    html = markAttrRegex.stringByReplacingMatches(in: html, range: NSRange(html.startIndex..., in: html), withTemplate: #"<mark title="$1">"#)
  }

  item.body = html
}

func syntaxHighlight<M>(item: Item<M>) {
  item.body = syntaxHighlighter.highlightCodeBlocks(in: item.body)
}

/// Convert `<pre data-title="...">` to visible `<span class="code-title">` elements.
public func addCodeBlockTitles<M>(_ doc: Document, item: Item<M>) throws {
  let preElements = try doc.select("pre[data-title]")
  for pre in preElements {
    let title = try pre.attr("data-title")
    try pre.prepend("<span class=\"code-title\">\(title)</span>")
  }
}
