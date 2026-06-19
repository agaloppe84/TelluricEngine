// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "RenderCoreMetal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RenderCoreMetal",
            targets: ["RenderCoreMetal"]
        )
    ],
    targets: [
        .target(
            name: "RenderCoreMetal"
        ),
        .testTarget(
            name: "RenderCoreMetalTests",
            dependencies: ["RenderCoreMetal"]
        )
    ]
)

