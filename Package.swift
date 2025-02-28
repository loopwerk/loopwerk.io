// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v12),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "2.0.0"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup", "2.8.0"..."2.8.0"),
    .package(url: "https://github.com/twostraws/SwiftGD", branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "Loopwerk",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "SwiftSoup",
        "SwiftGD",
      ]
    ),
    .testTarget(
      name: "LoopwerkTests",
      dependencies: ["Loopwerk"]
    ),
  ]
)
