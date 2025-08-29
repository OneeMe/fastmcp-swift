# FastMCP Swift

A Swift implementation of FastMCP, providing an ergonomic wrapper around the official MCP Swift SDK.

## Overview

FastMCP Swift brings the Model Context Protocol to the Swift ecosystem, supporting iOS, macOS, and visionOS platforms. It consists of two main packages:

- **FastMCPServer**: High-level wrapper around the MCP Swift SDK with HTTP streaming transport
- **FastMCPProtocol**: Protocol-based system for modular tool registration (framework for future expansion)

## Features

- 🚀 **Simple API**: Swift-native API inspired by FastMCP Python
- 📱 **Multi-platform**: Support for iOS 16+, macOS 13+, and visionOS 1+  
- 🔌 **HTTP Streaming**: Built-in HTTP transport for web deployments
- 🧩 **Extensible**: Protocol-based architecture for future plugin support
- ⚡ **Type Safety**: Full Swift type safety and modern async/await support
- 📦 **Lightweight**: Minimal wrapper around the official MCP Swift SDK

## Installation

Add FastMCP Swift to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/fastmcp-swift", from: "1.0.0")
]
```

Then import the modules:

```swift
import FastMCPServer
import FastMCPProtocol // For plugin development
```

## Quick Start

### Basic Server

```swift
import FastMCPServer

@main
struct MyServer {
    static func main() async throws {
        let server = SimpleFastMCP("My Server", version: "1.0.0")
        
        print("Starting server on http://127.0.0.1:8000/mcp")
        try await server.run(host: "127.0.0.1", port: 8000, path: "/mcp")
    }
}
```

### Client Usage

```swift
import FastMCPServer

@main
struct MyClient {
    static func main() async throws {
        let client = SimpleFastMCPClient(name: "My Client", version: "1.0.0")
        
        try await client.connect(host: "127.0.0.1", port: 8000, path: "/mcp")
        try await client.ping()
        await client.disconnect()
    }
}
```

### Plugin Development (Future Enhancement)

The `FastMCPProtocol` package provides a foundation for building reusable MCP components:

```swift
import FastMCPProtocol

// Protocol-based tool providers for future expansion
final class MathPlugin: ToolProvider {
    let toolName = "multiply"
    let toolDescription = "Multiply two numbers"
    
    func execute(with parameters: [String: Any]) async throws -> Any {
        guard let x = parameters["x"] as? Double,
              let y = parameters["y"] as? Double else {
            throw PluginError.invalidParameters
        }
        return ["result": x * y]
    }
    
    func getParameterSchema() -> [String: Any] {
        return [
            "type": "object",
            "properties": [
                "x": ["type": "number"],
                "y": ["type": "number"]  
            ],
            "required": ["x", "y"]
        ]
    }
}

// Future: Tool registration will be integrated with SimpleFastMCP
```

## API Reference

### SimpleFastMCP Class

The main server class for creating MCP servers.

```swift
public final class SimpleFastMCP {
    public init(_ name: String, version: String = "1.0.0")
    
    public func run(
        host: String = "127.0.0.1", 
        port: Int = 8000, 
        path: String = "/mcp"
    ) async throws
}
```

### SimpleFastMCPClient Class

For connecting to MCP servers.

```swift
public final class SimpleFastMCPClient {
    public init(name: String = "FastMCP Client", version: String = "1.0.0")
    
    public func connect(host: String, port: Int, path: String = "/mcp") async throws
    public func disconnect() async
    public func ping() async throws
}
```

### Protocol System

For creating reusable plugins:

```swift
public protocol ToolProvider {
    var toolName: String { get }
    var toolDescription: String { get }
    func execute(with parameters: [String: Any]) async throws -> Any
    func getParameterSchema() -> [String: Any]
}

public protocol ResourceProvider {
    var resourceURI: String { get }
    var resourceDescription: String { get }
    func getResource() async throws -> Any
}

public protocol PromptProvider {
    var promptName: String { get }
    var promptDescription: String { get } 
    func generatePrompt(with parameters: [String: Any]) async throws -> String
}
```

## Transport Support

FastMCP Swift currently supports HTTP streaming transport only, designed for web deployments and client-server architectures. The HTTP transport provides:

- Efficient streaming communication
- Web-compatible deployment
- Cross-platform client support
- Standard HTTP error handling

## Platform Support

- **iOS**: 16.0+
- **macOS**: 13.0+
- **visionOS**: 1.0+

## Examples

The `Examples/` directory contains:

- `BasicServerExample.swift`: Basic server startup and HTTP transport
- `BasicClientExample.swift`: Client connecting and ping functionality

## Current Status

This is an early implementation providing the foundation for FastMCP Swift. The current version includes:

✅ **Working Features:**
- HTTP streaming transport 
- Basic server and client setup
- Multi-platform support (iOS/macOS/visionOS)
- Integration with official MCP Swift SDK
- Protocol-based architecture for future expansion

🚧 **Future Enhancements:**
- Tool registration and execution
- Resource management
- Prompt handling
- Advanced client functionality
- Full FastMCP Python API parity

## Building and Testing

```bash
# Build the package
swift build

# Run tests  
swift test

# Build for specific platform
swift build -c release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License. See LICENSE for details.

## Related Projects

- [FastMCP Python](https://github.com/jlowin/fastmcp) - Original Python implementation
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) - Official MCP Swift SDK
- [Model Context Protocol](https://modelcontextprotocol.io) - MCP specification