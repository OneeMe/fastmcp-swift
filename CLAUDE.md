# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
```bash
# Build the package
swift build

# Run all tests
swift test

# Build for release
swift build -c release

# Run a specific test class
swift test --filter SimpleTests

# Run a specific test method
swift test --filter SimpleTests.testSimpleFastMCPInitialization

# Build and test in one command
swift build && swift test
```

### Package Management
```bash
# Update dependencies to latest compatible versions
swift package update

# Generate Xcode project (for development)
swift package generate-xcodeproj

# Clean build artifacts
swift package clean
```

### Platform Requirements
- Swift 6.1+ (required for package tools version)
- iOS 16.0+, macOS 13.0+, visionOS 1.0+ (minimum deployment targets)
- Dependencies managed through Swift Package Manager
- Key dependency: `github.com/modelcontextprotocol/swift-sdk` v0.1.0+

## Architecture Overview

### Dual-Package Structure
This project implements a **two-package architecture** designed for modularity and future extensibility:

1. **FastMCPSwift** (Main Package): HTTP-only MCP server/client implementation
2. **FastMCPProtocol** (Protocol Package): Dependency injection framework for future plugin support

### Key Architectural Decisions

**HTTP-Only Transport**: This implementation deliberately supports only HTTP streaming transport (no stdio), designed for web deployments and cross-platform client-server architectures.

**Wrapper Pattern**: FastMCPSwift acts as a high-level wrapper around the official MCP Swift SDK (`github.com/modelcontextprotocol/swift-sdk`), providing simplified APIs while leveraging the robust underlying implementation.

**Protocol-Based DI**: The `FastMCPProtocol` package defines provider protocols (`ToolProvider`, `ResourceProvider`, `PromptProvider`) and a registry system, establishing the foundation for future plugin architecture.

### Core Components

**SimpleFastMCP**: The main server class that wraps the official MCP `Server` class. Creates HTTP transports and manages server lifecycle. Currently provides basic server startup without tool/resource registration (future enhancement).

**SimpleFastMCPClient**: Client wrapper around official MCP `Client` class. Handles HTTP transport setup and provides simplified connection/ping functionality.

**Provider Protocols**: Thread-safe (`Sendable`) protocols in `FastMCPProtocol` that define the interface for tools, resources, and prompts. Currently unused but designed for future integration.

**Registry System**: `DefaultFastMCPRegistry` provides thread-safe storage and lookup for providers using `NSLock`. Currently standalone but architected for future integration with `SimpleFastMCP`.

### Implementation Status

This is an **early-stage foundation** implementation providing the groundwork for a full FastMCP Swift implementation:

**Working Features:**
- ✅ Multi-platform package structure with proper Swift 6.1 support
- ✅ HTTP streaming transport integration (no stdio support by design)
- ✅ Basic server/client lifecycle management
- ✅ Protocol-based architecture with thread-safe provider interfaces
- ✅ Type aliases for clean public API (`FastMCPServer`, `FastMCPClient`)

**Architectural Foundation (Not Yet Integrated):**
- 🚧 Tool/resource/prompt registration protocols defined but not connected to server
- 🚧 Registry system implemented but standalone
- 🚧 Advanced client functionality (list tools/resources, call tools, etc.)
- 🚧 Error handling between provider layer and MCP SDK layer

### Future Integration Points

The architecture is designed for these future enhancements:
1. **Tool Registration**: Integrate `ToolProvider` with `SimpleFastMCP.server.withMethodHandler()`
2. **Resource Management**: Connect `ResourceProvider` with MCP resource handling
3. **Client Functionality**: Expand `SimpleFastMCPClient` with tool calling, resource reading
4. **Plugin System**: Enable runtime registration of providers through the registry

### Dependencies and External Integration

**MCP Swift SDK Dependency**: Critical dependency on `github.com/modelcontextprotocol/swift-sdk`. The wrapper closely follows the underlying SDK's async actor patterns and transport architecture.

**Sendable Compliance**: All provider protocols and key classes implement `Sendable` for thread-safety in Swift's structured concurrency model.

**Error Handling**: Custom `FastMCPError` enum provides domain-specific errors while allowing MCP SDK errors to bubble through.

## Code Organization Patterns

- **Type Aliases**: `FastMCPServer` and `FastMCPClient` provide cleaner public API names
- **Re-exports**: `@_exported import FastMCPProtocol` makes protocols available when importing main package
- **Separation of Concerns**: Clean boundary between transport layer (SimpleFastMCP/Client) and provider abstractions (FastMCPProtocol)

## Development Context

### Testing Strategy
The current test suite (`SimpleTests`) focuses on basic initialization and component instantiation. When expanding functionality, follow these patterns:
- Test classes should be `final` to avoid inheritance issues
- Use `@testable import` to access internal APIs when needed
- Focus on unit tests for provider protocols and integration tests for client-server communication

### Sendable Compliance Considerations
All provider protocols inherit from `Sendable` to ensure thread-safety in Swift's actor system. When implementing providers:
- Use `@Sendable` closures for async operations
- Store immutable state or protect mutable state with locks (like `DefaultFastMCPRegistry`)
- Be aware that the underlying MCP SDK uses actors, requiring `await` for most operations

### Error Handling Philosophy
The project uses a layered error approach:
- `FastMCPError` for domain-specific errors (URL validation, initialization)
- Allow MCP SDK errors to bubble up for protocol-level issues
- Provider protocols should throw domain-appropriate errors that get wrapped by the transport layer

## Xcode Project Support

The repository includes an example Xcode project at `Examples/FastMCPSwiftServerExample/` that demonstrates FastMCP Swift integration in a macOS app.

### Building the Xcode Project

```bash
# Navigate to the Xcode project directory
cd Examples/FastMCPSwiftServerExample/

# List available targets and schemes
xcodebuild -list

# Build for macOS
xcodebuild -project FastMCPSwiftServerExample.xcodeproj \
           -scheme FastMCPSwiftServerExample \
           -destination "platform=macOS" \
           build

# Build for visionOS Simulator
xcodebuild -project FastMCPSwiftServerExample.xcodeproj \
           -scheme FastMCPSwiftServerExample \
           -destination "platform=visionOS Simulator,name=Apple Vision Pro" \
           build

# Run tests (macOS only for UI/app tests)
xcodebuild -project FastMCPSwiftServerExample.xcodeproj \
           -scheme FastMCPSwiftServerExample \
           -destination "platform=macOS" \
           test

# Build for release (macOS)
xcodebuild -project FastMCPSwiftServerExample.xcodeproj \
           -scheme FastMCPSwiftServerExample \
           -destination "platform=macOS" \
           -configuration Release \
           build

# Build for release (visionOS Simulator)
xcodebuild -project FastMCPSwiftServerExample.xcodeproj \
           -scheme FastMCPSwiftServerExample \
           -destination "platform=visionOS Simulator,name=Apple Vision Pro" \
           -configuration Release \
           build
```

### Xcode Project Structure
- **Main Target**: `FastMCPSwiftServerExample` - Multi-platform app with FastMCPSwift integration
- **Test Targets**: `FastMCPSwiftServerExampleTests` (unit tests), `FastMCPSwiftServerExampleUITests` (UI tests)
- **Dependencies**: Automatically resolves FastMCP Swift packages and external dependencies via SPM
- **Supported Platforms**: 
  - macOS 14.0+ (primary platform, supports tests)
  - visionOS 1.0+ (via visionOS Simulator)

### Package Dependencies in Xcode
The Xcode project automatically resolves these packages:
- `fastmcp-swift` (local path dependency to parent directory)
- `FastMCPSwiftExampleTool` (local example tool library)  
- `mcp-swift-sdk` v0.10.1+ (official MCP Swift SDK)
- `swift-log`, `swift-system`, `EventSource` (transitive dependencies)

### Platform-Specific Notes
- **iOS Support**: Currently not configured in the Xcode project (iOS simulators not available in destinations)
- **visionOS**: Fully supported for both Debug and Release configurations
- **macOS**: Primary development and testing platform with full UI/unit test support
- **Cross-Platform**: FastMCP Swift packages support iOS 16+/macOS 13+/visionOS 1+ via Swift Package Manager

### Available Destinations
When using `xcodebuild -list`, you'll see:
- `{ platform:macOS, name:Any Mac }`
- `{ platform:visionOS Simulator, name:Apple Vision Pro }`
- `{ platform:visionOS Simulator, name:Apple Vision Pro 4K }`

Note: iOS destinations may show as "Ineligible" if iOS SDK versions are not installed.