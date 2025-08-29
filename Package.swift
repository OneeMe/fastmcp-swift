// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

// 定义要排除的文件和目录列表
let excludedFiles = [
    "AGENTS.md",
    "buildServer.json",
    "CLAUDE.md",
    "Docs",
    "Examples",
    "node_modules",
    "package-lock.json",
    "package.json",
    "Tests"
]

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
            name: "FastMCPMacro",
            targets: ["FastMCPMacro"]),
        .plugin(
            name: "FastMCPBuildToolPlugin",
            targets: ["FastMCPBuildToolPlugin"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.1.0"),
        // SwiftSyntax for macro and plugin scanning (match your Swift toolchain)
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        .target(
            name: "FastMCPProtocol",
            exclude: excludedFiles),
        .target(
            name: "FastMCPServer",
            dependencies: [
                "FastMCPProtocol",
                .product(name: "MCP", package: "swift-sdk")
            ],
            exclude: excludedFiles),
        // Macro implementation target for tooling (hosted by compiler)
        .macro(
            name: "FastMCPMacroImpl",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        // Macro declaration target (exposed to tool authors)
        .target(
            name: "FastMCPMacro",
            dependencies: [
                "FastMCPProtocol",
                "FastMCPMacroImpl"
            ],
            exclude: excludedFiles
        ),
        // Executable tool used by the build plugin
        .executableTarget(
            name: "fastmcp-gen",
            path: "Tools/FastMCPGenerator",
            sources: ["main.swift"]
        ),
        // Build tool plugin that scans source and emits the registration file
        .plugin(
            name: "FastMCPBuildToolPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "fastmcp-gen")
            ]
        ),
        .testTarget(
            name: "FastMCPServerTests",
            dependencies: ["FastMCPServer", "FastMCPProtocol"            ],
            exclude: excludedFiles
        ),
    ]
)
