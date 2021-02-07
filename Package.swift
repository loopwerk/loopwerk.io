// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "Loopwerk",
  dependencies: [
    .package(name: "Saga", url: "https://github.com/loopwerk/Saga.git", .branch("test")),
  ],
  targets: [
    .target(
      name: "Loopwerk",
      dependencies: ["Saga"]),
  ]
)
