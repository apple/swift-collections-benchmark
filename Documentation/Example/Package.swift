// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kalimba",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Kalimba",
            targets: ["Kalimba"]),
        .executable(name: "kalimba-benchmark", targets: ["kalimba-benchmark"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "0.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Kalimba",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ]),
        .testTarget(
            name: "KalimbaTests",
            dependencies: ["Kalimba"]),
        .target(
            name: "kalimba-benchmark",
            dependencies: [
                "Kalimba",
                .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark")
            ]
            //path: "Benchmarks/swift-collections-benchmark"
        ),
    ]
)
