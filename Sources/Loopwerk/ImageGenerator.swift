import Foundation
import Saga
import SwiftGD

class ImageGenerator {
  private let background: Image
  private let fontSize: Double
  private let titleFontPath: String
  private let bodyFontPath: String

  init?(rootPath: String) {
    guard let backgroundImage = Image(url: URL(fileURLWithPath: "\(rootPath)/ImageGenerator/background.png")) else {
      print("Failed to load background image.")
      return nil
    }
    background = backgroundImage
    titleFontPath = "\(rootPath)/ImageGenerator/title.ttf"
    bodyFontPath = "\(rootPath)/ImageGenerator/main.ttf"
    fontSize = 58
  }

  func generate(article: Item<ArticleMetadata>, outputPath: String) {
    guard let image = background.cloned() else { return }

    let wrappedText = article.title.splitByLineWidth(width: 26)

    // Draw the title on the image
    var offsetY = 160
    for line in wrappedText {
      image.renderText(line, from: Point(x: 90, y: offsetY), fontList: [titleFontPath], color: Color.white, size: fontSize)
      offsetY += Int(fontSize) + 26
    }

    // Draw the date on the image
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM dd, yyyy"
    let date = dateFormatter.string(from: article.date)
    image.renderText(date, from: Point(x: 90, y: 540), fontList: [bodyFontPath], color: Color.white, size: 20)

    // Draw the tags on the image
    let tags = article.metadata.tags.sorted().map { "#\($0)" }.joined(separator: ", ")
    image.renderText(tags, from: Point(x: 90, y: 580), fontList: [bodyFontPath], color: Color.white, size: 20)

    // Save the image as a PNG
    image.write(to: URL(fileURLWithPath: outputPath))
  }
}

extension String {
  /// A simple helper method to break text into lines
  func splitByLineWidth(width: Int) -> [String] {
    return components(separatedBy: .whitespaces).reduce([String]()) { acc, word in
      var acc = acc
      if let last = acc.last, (last + " " + word).count <= width {
        acc[acc.count - 1] = last + " " + word
      } else {
        acc.append(word)
      }
      return acc
    }
  }
}
