import HTML

extension Node {
  /// Recursively checks whether this node tree contains a `<meta>` tag with the given
  /// `property` or `name` attribute.
  func containsMeta(_ property: String) -> Bool {
    switch self {
      case .element(let tag, let attributes, let child):
        if tag == "meta", attributes["property"] == property || attributes["name"] == property {
          return true
        }
        return child?.containsMeta(property) ?? false
      case .fragment(let children):
        return children.contains { $0.containsMeta(property) }
      default:
        return false
    }
  }
}
