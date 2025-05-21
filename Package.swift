// swift-tools-version:6.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import PackageDescription


// This package recognizes the conditional compilation flags listed below.
// To use enable them, uncomment the corresponding lines or define them
// from the package manager command line:
//
//     swift build -Xswiftc -DSOME_SETTING
var settings: [SwiftSetting]? = [
  .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
  name: "swift-collections-benchmark",
  platforms: [.macOS(.v15), .iOS(.v18), .watchOS(.v11), .tvOS(.v18), .visionOS(.v2)],
  products: [
    .library(name: "CollectionsBenchmark", targets: ["CollectionsBenchmark"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-system", from: "1.4.2"),
  ],
  targets: [
    .target(
      name: "CollectionsBenchmark",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SystemPackage", package: "swift-system"),
      ],
      path: "Sources/CollectionsBenchmark",
      swiftSettings: settings),
    .testTarget(
      name: "CollectionsBenchmarkTests",
      dependencies: ["CollectionsBenchmark"],
      swiftSettings: settings),
  ]
)
