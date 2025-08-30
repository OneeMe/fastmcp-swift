// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "fastmcp-swift",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FastMCPServer",
            targets: ["FastMCPServer"]),
        .library(
            name: "FastMCPProtocol",
            targets: ["FastMCPProtocol"]),
        .library(
            name: "FastMCPMacros",
            targets: ["FastMCPMacros"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.1.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "FastMCPProtocol"),
        .target(
            name: "FastMCPServer",
            dependencies: [
                "FastMCPProtocol",
                "FastMCPMacros",
                .product(name: "MCP", package: "swift-sdk")
            ]),
        .macro(
            name: "FastMCPMacrosImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "FastMCPMacros",
            dependencies: [
                "FastMCPMacrosImplementation",
                "FastMCPProtocol"
            ]
        ),
        .testTarget(
            name: "FastMCPServerTests",
            dependencies: ["FastMCPServer", "FastMCPProtocol"]
        ),
        .testTarget(
            name: "FastMCPMacrosTests",
            dependencies: [
                "FastMCPMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
