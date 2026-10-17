// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MinimalPackage",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "MinimalLibrary", targets: ["MinimalLibrary"]),
    ],
    targets: [
        .target(name: "MinimalLibrary"),
        .testTarget(name: "MinimalLibraryTests", dependencies: ["MinimalLibrary"]),
    ]
)
