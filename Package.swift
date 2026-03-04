// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v12),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "2.16.0"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaUtils", from: "1.0.2"),
    .package(url: "https://github.com/twostraws/SwiftGD", branch: "main"),
    .package(url: "https://github.com/loopwerk/Moon", from: "1.2.3"),
    .package(url: "https://github.com/loopwerk/Bonsai", from: "1.1.0"),
    .package(url: "https://github.com/loopwerk/SwiftTailwind", from: "1.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "Loopwerk",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "SagaUtils",
        "SwiftGD",
        "Moon",
        "Bonsai",
        "SwiftTailwind",
      ],
      resources: [
        .copy("Resources/prism-svelte.js"),
      ]
    ),
  ]
)
