// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga", from: "0.19.0"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "0.4.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "0.4.0"),
    .package(url: "https://github.com/pvieito/PythonKit", from: "0.1.0"),
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.3.2"),
  ],
  targets: [
    .target(
      name: "Loopwerk",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "PythonKit",
        "SwiftSoup",
      ]),
  ]
)
