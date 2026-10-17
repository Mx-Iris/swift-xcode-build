// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("ExistentialAny"),
    .strictMemorySafety(),
]

let package = Package(
    name: "swift-xcode-build",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "XcodeBuild", targets: ["XcodeBuild"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", from: "1.0.2"),
    ],
    targets: [
        .target(
            name: "XcodeBuild",
            dependencies: [
                .product(name: "Subprocess", package: "swift-subprocess"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "XcodeBuildTests",
            dependencies: ["XcodeBuild"],
            swiftSettings: swiftSettings
        ),
    ]
)
