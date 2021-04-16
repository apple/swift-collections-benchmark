// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Kalimba",
    products: [
        .library(
            name: "Kalimba",
            targets: ["Kalimba"]),
        .executable(name: "kalimba-benchmark", targets: ["kalimba-benchmark"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "Kalimba",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ]),
        .target(
            name: "kalimba-benchmark",
            dependencies: [
                "Kalimba",
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark")
            ]
        ),
    ]
)
