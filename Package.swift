// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v12),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "2.3.0"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.8.2"),
    .package(url: "https://github.com/twostraws/SwiftGD", branch: "main"),
    .package(url: "https://github.com/loopwerk/Moon", from: "1.2.2"),
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
        "Moon",
      ],
      resources: [
        .copy("Resources/prism-svelte.js"),
      ]
    ),
    .testTarget(
      name: "LoopwerkTests",
      dependencies: ["Loopwerk"]
    ),
  ]
)
