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
    dependencies: [
        .package(path: "../EngineCore")
    ],
    targets: [
        .target(
            name: "RenderCoreMetal",
            dependencies: [
                .product(name: "EngineCore", package: "EngineCore")
            ],
            resources: [
                .process("Shaders")
            ]
        ),
        .testTarget(
            name: "RenderCoreMetalTests",
            dependencies: [
                "RenderCoreMetal",
                .product(name: "EngineCore", package: "EngineCore")
            ]
        )
    ]
)
