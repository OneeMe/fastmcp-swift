// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fastmcp-swift",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FastMCPSwift",
            targets: ["FastMCPSwift"]),
        .library(
            name: "FastMCPProtocol",
            targets: ["FastMCPProtocol"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "FastMCPProtocol"),
        .target(
            name: "FastMCPSwift",
            dependencies: [
                "FastMCPProtocol",
                .product(name: "MCP", package: "swift-sdk")
            ]),
        .testTarget(
            name: "FastMCPSwiftTests",
            dependencies: ["FastMCPSwift", "FastMCPProtocol"]
        ),
    ]
)
