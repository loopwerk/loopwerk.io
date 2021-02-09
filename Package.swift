// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Loopwerk",
  platforms: [
    .macOS(.v10_15)
  ],
  dependencies: [
    .package(name: "Saga", url: "https://github.com/loopwerk/Saga.git", .branch("Parsley")),
    .package(url: "https://github.com/pvieito/PythonKit.git", from: "0.1.0"),
  ],
  targets: [
    .target(
      name: "Loopwerk",
      dependencies: ["Saga", "PythonKit"]),
  ]
)
