import Saga

public extension Reader {
  static var parsleyMarkdownWithAttributesReader: Self {
    .parsleyMarkdownReader(markdownOptions: [.unsafe, .hardBreaks, .smartQuotes, .markdownAttributes])
  }
}
