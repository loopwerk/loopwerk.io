import Foundation
import Moon
import Saga
import SagaImageReader
import SagaPathKit
import SwiftSoup

private let syntaxHighlighter: Moon = {
  do {
    return try Moon(additionalPlugins: ["prism-svelte.js"], bundle: Bundle.module)
  } catch {
    fatalError("Failed to initialize Moon: \(error)")
  }
}()

/// Some tags should automatically result on parent tags being added.
/// For example, all articles tagged with "django" should also be tagged with "python".
/// This tagHierarchy is used to automate this.
let tagHierarchy: TagTree = [
  "swift": ["saga"],
  "python": ["django", "uv"],
  "javascript": ["sveltekit"],
  "deployment": ["coolify"],
]

let tagAncestors = ancestorsMap(tagHierarchy)

func expandTags(item: Item<ArticleMetadata>) {
  var expanded = Set(item.metadata.tags)
  for tag in item.metadata.tags {
    if let ancestors = tagAncestors[tag] {
      expanded.formUnion(ancestors)
    }
  }
  item.metadata.expandedTags = Array(expanded)
}

func permalink(item: Item<ArticleMetadata>) {
  // Insert the publication year into the permalink.
  // If the `relativeDestination` was "articles/looking-for-django-cms/index.html", then it becomes "articles/2009/looking-for-django-cms/index.html"
  var components = item.relativeDestination.components
  components.insert("\(Calendar.current.component(.year, from: item.date))", at: 1)
  item.relativeDestination = Path(components: components)
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

/// An album's title from its folder name: "street-art" becomes "Street art"
func albumTitle(folder: String) -> String {
  let words = folder.replacingOccurrences(of: "-", with: " ")
  return words.prefix(1).uppercased() + words.dropFirst()
}

/// A photo's title doubles as its alt text: "Architecture photo taken on March 4, 2025".
/// Photos are processed before they're linked to their album, so the album title comes from the folder.
func photoTitle(photo: Item<ImageMetadata>) {
  let album = albumTitle(folder: photo.relativeSource.parent().lastComponent)
  photo.title = "\(album) photo taken on \(photo.date.formatted("MMMM d, yyyy"))"
}

/// Photos have no body of their own; the photo feed uses this as the entry content.
/// Feed readers resolve relative URLs inconsistently, so the src is absolute.
func photoFeedBody(photo: Item<ImageMetadata>) {
  let src = SiteMetadata.url.appendingPathComponent(photo.relativeSource.string).absoluteString
  photo.body = #"<img src="\#(src)" width="\#(photo.metadata.imageWidth)" height="\#(photo.metadata.imageHeight)" alt="\#(photo.title)">"#
}

/// Screenshots are found by filename: work/images/critical-notes-1.webp belongs to work/critical-notes.md
func workImages(item: Item<WorkProjectMetadata>) {
  let slug = item.relativeSource.lastComponentWithoutExtension
  let files = (try? FileManager.default.contentsOfDirectory(atPath: "\(SiteMetadata.projectRoot)/content/work/images")) ?? []
  let images = files.filter { $0.hasPrefix("\(slug)-") }.sorted()
  item.metadata.images = images.isEmpty ? nil : images
}

private let lastUpdatedDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "MMMM dd, yyyy"
  formatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
  return formatter
}()

/// Runs on both the rendered HTML and the markdown twin, hence the `markdown` flag for values that contain links
func replacePlaceholders(in text: String, item: AnyItem, markdown: Bool) -> String {
  func link(_ text: String, href: String) -> String {
    markdown ? "[\(text)](\(href))" : #"<a href="\#(href)">\#(text)</a>"#
  }

  let placeholders = [
    "{{ last_updated }}": lastUpdatedDateFormatter.string(from: item.lastModified),
    "{{ available }}": SiteMetadata.available ? ", and I'm currently \(link("available for hire", href: "/hire-me/"))" : "",
  ]

  return placeholders.reduce(text) { text, placeholder in
    text.replacingOccurrences(of: placeholder.key, with: placeholder.value)
  }
}

func fillPlaceholders(item: Item<PageMetadata>) {
  item.body = replacePlaceholders(in: item.body, item: item, markdown: false)
}
