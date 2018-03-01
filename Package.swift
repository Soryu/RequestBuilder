// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RequestBuilder",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "RequestBuilder",
            targets: ["RequestBuilder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/khanlou/Promise.git", .revision("2a4157075c390f447f412f52c8a18e298357d05f")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RequestBuilder",
            dependencies: ["Promise"]),
        .testTarget(
            name: "RequestBuilderTests",
            dependencies: ["RequestBuilder"]),
    ]
)
