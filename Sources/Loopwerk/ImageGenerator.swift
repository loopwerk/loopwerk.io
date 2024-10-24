import SwiftGD
import Foundation

class ImageGenerator {
  private let background: Image
  private let fontSize: Double
  private let fontPath: String
  
  init?(rootPath: String) {
    guard let backgroundImage = Image(url: URL(fileURLWithPath: "\(rootPath)/ImageGenerator/background.png")) else {
      print("Failed to load background image.")
      return nil
    }
    self.background = backgroundImage
    self.fontPath = "\(rootPath)/ImageGenerator/Roboto-Regular.ttf"
    self.fontSize = 60
  }
  
  func generate(title: String, outputPath: String) {
    let wrappedText = title.splitByLineWidth(width: 24)
    
    // Draw the text on the image
    var offsetY: Int = 100
    for line in wrappedText {
      background.renderText(line, from: Point(x: 36, y: offsetY), fontList: [self.fontPath], color: Color.white, size: self.fontSize)
      offsetY += Int(fontSize) + 20
    }
    
    // Save the image as a PNG
    background.write(to: URL(fileURLWithPath: outputPath))
  }
}

extension String {
  // A simple helper method to break text into lines
  func splitByLineWidth(width: Int) -> [String] {
    return self.components(separatedBy: .whitespaces).reduce([String]()) { acc, word in
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
