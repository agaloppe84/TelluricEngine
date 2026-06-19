// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AudioRuntime",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AudioRuntime",
            targets: ["AudioRuntime"]
        )
    ],
    targets: [
        .target(
            name: "AudioRuntime"
        ),
        .testTarget(
            name: "AudioRuntimeTests",
            dependencies: ["AudioRuntime"]
        )
    ]
)

