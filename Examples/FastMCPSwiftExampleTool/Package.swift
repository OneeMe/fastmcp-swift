// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FastMCPSwiftExampleTool",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "FastMCPSwiftExampleTool",
            targets: ["FastMCPSwiftExampleTool"]
        ),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "FastMCPSwiftExampleTool",
            dependencies: [
                .product(name: "FastMCPProtocol", package: "fastmcp-swift"),
                .product(name: "FastMCPMacro", package: "fastmcp-swift"),
            ]
        ,
        plugins: [
            .plugin(name: "FastMCPBuildToolPlugin", package: "fastmcp-swift")
        ]
        ),
        .testTarget(
            name: "FastMCPSwiftExampleToolTests",
            dependencies: ["FastMCPSwiftExampleTool"]
        ),
    ]
)
