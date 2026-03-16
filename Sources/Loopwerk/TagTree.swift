indirect enum TagTree: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
  case leaves([String])
  case branches([String: TagTree])
  
  init(arrayLiteral elements: String...) {
    self = .leaves(elements)
  }
  
  init(dictionaryLiteral elements: (String, TagTree)...) {
    self = .branches(Dictionary(uniqueKeysWithValues: elements))
  }
}

func ancestorsMap(_ tree: TagTree, ancestors: [String] = []) -> [String: [String]] {
  switch tree {
    case .leaves(let tags):
      var result: [String: [String]] = [:]
      for tag in tags {
        result[tag] = ancestors
      }
      return result
    case .branches(let dict):
      var result: [String: [String]] = [:]
      for (tag, children) in dict {
        if !ancestors.isEmpty {
          result[tag] = ancestors
        }
        let childResults = ancestorsMap(children, ancestors: ancestors + [tag])
        result.merge(childResults) { $1 }
      }
      return result
  }
}
