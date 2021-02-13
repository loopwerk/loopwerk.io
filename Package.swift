// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    .package(url: "https://github.com/loopwerk/Saga.git", from: "0.18.0"),
    .package(url: "https://github.com/loopwerk/SagaParsleyMarkdownReader", from: "0.4.0"),
    .package(url: "https://github.com/loopwerk/SagaSwimRenderer", from: "0.4.0"),
    .package(url: "https://github.com/pvieito/PythonKit.git", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "Loopwerk",
      dependencies: [
        "Saga",
        "SagaParsleyMarkdownReader",
        "SagaSwimRenderer",
        "PythonKit",
      ]),
  ]
)
