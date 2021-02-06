// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Loopwerk",
  dependencies: [
    .package(path: "../Saga/"),
  ],
  targets: [
    .target(
      name: "Loopwerk",
      dependencies: ["Saga"]),
  ]
)
