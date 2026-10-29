// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v15),
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "3.10.0"),
    // .package(path: "../Saga/Saga/"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaUtils", from: "1.6.0"),
    .package(url: "https://github.com/twostraws/SwiftGD", branch: "main"),
    .package(url: "https://github.com/loopwerk/Moon", from: "1.2.3"),
    .package(url: "https://github.com/loopwerk/Bonsai", from: "1.1.0"),
    .package(url: "https://github.com/loopwerk/SwiftTailwind", from: "1.0.0"),
    .package(url: "https://github.com/loopwerk/SagaImageReader", from: "1.4.0"),
    .package(url: "https://github.com/swiftcsv/SwiftCSV", from: "0.8.0"),
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.0.0"),
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
        "SagaImageReader",
        "SwiftCSV",
        .product(name: "SwiftDotenv", package: "swift-dotenv"),
      ],
      exclude: [
        "Resources/background.pxd",
        "Resources/opengraph.pxd",
        "csv",
      ],
      resources: [
        .copy("Resources/prism-svelte.js"),
        .copy("Resources/background.png"),
        .copy("Resources/main.ttf"),
        .copy("Resources/title.ttf"),
      ]
    ),
  ]
)
