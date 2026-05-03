// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DCSettings",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7),
        .tvOS(.v14),
        .macOS(.v11),
        .visionOS("2.0")
    ],
    products: [
        .library(
            name: "DCSettings",
            targets: ["DCSettings"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DCSettings",
            dependencies: []),
        .testTarget(
            name: "DCSettingsTests",
            dependencies: ["DCSettings"]),
    ]
)
