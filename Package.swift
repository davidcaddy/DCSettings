// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DCSettings",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
        .macOS(.v10_15)
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
