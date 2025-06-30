import Foundation
import SwiftGD
import Saga

class ImageGenerator {
  private let background: Image
  private let fontSize: Double
  private let fontPath: String

  init?(rootPath: String) {
    guard let backgroundImage = Image(url: URL(fileURLWithPath: "\(rootPath)/ImageGenerator/background.png")) else {
      print("Failed to load background image.")
      return nil
    }
    background = backgroundImage
    fontPath = "\(rootPath)/ImageGenerator/Roboto-Regular.ttf"
    fontSize = 54
  }

  func generate(article: Item<ArticleMetadata>, outputPath: String) {
    let wrappedText = article.title.splitByLineWidth(width: 25)

    // Draw the title on the image
    var offsetY = 160
    for line in wrappedText {
      background.renderText(line, from: Point(x: 90, y: offsetY), fontList: [fontPath], color: Color.white, size: fontSize)
      offsetY += Int(fontSize) + 24
    }

    // Draw the date on the image
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMMM dd, yyyy"
    let date = dateFormatter.string(from: article.date)
    background.renderText(date, from: Point(x: 90, y: 540), fontList: [fontPath], color: Color.white, size: 20)

    // Draw the tags on the image
    let tags = article.metadata.tags.map { "#\($0)" }.joined(separator: ", ")
    background.renderText(tags, from: Point(x: 90, y: 580), fontList: [fontPath], color: Color.white, size: 20)
    
    // Save the image as a PNG
    background.write(to: URL(fileURLWithPath: outputPath))
  }
}

extension String {
  // A simple helper method to break text into lines
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
