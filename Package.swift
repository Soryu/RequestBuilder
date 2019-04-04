// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RequestBuilder",
    products: [
        .library(
            name: "RequestBuilder",
            targets: ["RequestBuilder"]),
    ],
    dependencies: [
        .package(url: "https://github.com/khanlou/Promise.git", from: "2.0.3"),
    ],
    targets: [
        .target(
            name: "RequestBuilder",
            dependencies: ["Promise"]),
        .testTarget(
            name: "RequestBuilderTests",
            dependencies: ["RequestBuilder"]),
    ]
)
