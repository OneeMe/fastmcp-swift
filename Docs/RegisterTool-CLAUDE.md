# FastMCP Tool Registration System Design

## Overview

This document outlines the design for a Swift macro-based tool registration system for FastMCP. The goal is to create a lightweight, declarative way to register MCP tools that only depends on `FastMCPProtocol` and uses Swift macros for automatic registration.

## Design Goals

1. **Lightweight Dependencies**: Tool registration should only require `FastMCPProtocol`, not the full `FastMCPSwift` package
2. **Declarative API**: Use Swift macros to provide a clean, declarative interface
3. **Automatic Discovery**: FastMCP server should automatically discover and register all annotated tools at startup
4. **Type Safety**: Leverage Swift's type system for compile-time validation
5. **Zero Runtime Overhead**: Registration metadata should be compile-time generated

## Architecture

### Core Components

#### 1. FastMCPProtocol Extensions
- `MCPTool` protocol: Base protocol for all MCP tools
- `ToolRegistry` class: Central registry for collecting and managing tools
- Registration metadata structures

#### 2. Swift Macros
- `@MCPTool`: Primary macro for tool registration
- `@MCPParameter`: Macro for parameter definition with schema validation
- `@MCPDescription`: Macro for adding descriptions and metadata

#### 3. Code Generation
- Automatic schema generation from Swift types
- Runtime registration code injection
- Metadata collection for tool discovery

## API Design

### Basic Tool Registration

```swift
import FastMCPProtocol

@MCPTool(name: "calculate", description: "Perform mathematical calculations")
struct CalculatorTool {
    @MCPParameter(description: "Mathematical expression to evaluate")
    var expression: String
    
    func execute() async throws -> String {
        // Implementation here
        return evaluateExpression(expression)
    }
}
```

### Advanced Tool with Custom Schema

```swift
@MCPTool(name: "weather", description: "Get weather information")
struct WeatherTool {
    @MCPParameter(description: "Location (city name or coordinates)")
    var location: String
    
    @MCPParameter(description: "Temperature units", optional: true, defaultValue: "celsius")
    var units: TemperatureUnit = .celsius
    
    @MCPParameter(description: "Include forecast", optional: true)
    var includeForecast: Bool = false
    
    func execute() async throws -> WeatherResponse {
        // Implementation here
        return try await fetchWeather(location: location, units: units, forecast: includeForecast)
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"
    case kelvin = "kelvin"
}
```

### Resource Registration

```swift
@MCPResource(uri: "file://documents", name: "Document Storage")
struct DocumentResource {
    func read(uri: String) async throws -> [ResourceContent] {
        // Implementation here
    }
    
    func subscribe(uri: String) async throws -> AsyncStream<ResourceUpdate> {
        // Implementation here
    }
}
```

### Prompt Registration

```swift
@MCPPrompt(name: "code-review", description: "Generate code review prompts")
struct CodeReviewPrompt {
    @MCPParameter(description: "Programming language")
    var language: String
    
    @MCPParameter(description: "Code complexity level", optional: true)
    var complexity: CodeComplexity = .medium
    
    func generate() async throws -> [PromptMessage] {
        // Implementation here
    }
}
```

## Macro Implementation Strategy

### 1. @MCPTool Macro

The `@MCPTool` macro will:
- Generate a conformance to `MCPToolProtocol`
- Extract parameter information from `@MCPParameter` annotated properties
- Generate JSON schema from Swift types
- Create registration code that adds the tool to the global registry

**Generated Code Structure:**
```swift
extension CalculatorTool: MCPToolProtocol {
    static var mcpToolDefinition: MCPToolDefinition {
        MCPToolDefinition(
            name: "calculate",
            description: "Perform mathematical calculations",
            inputSchema: .object([
                "properties": .object([
                    "expression": .object([
                        "type": .string("string"),
                        "description": .string("Mathematical expression to evaluate")
                    ])
                ]),
                "required": .array([.string("expression")])
            ])
        )
    }
    
    func callTool(with arguments: [String: Any]) async throws -> MCPToolResult {
        guard let expression = arguments["expression"] as? String else {
            throw MCPError.invalidParams("Missing required parameter: expression")
        }
        
        let tool = CalculatorTool(expression: expression)
        let result = try await tool.execute()
        return MCPToolResult(content: [.text(result)])
    }
}

// Auto-registration code
@_constructor
private func registerCalculatorTool() {
    MCPToolRegistry.shared.register(CalculatorTool.self)
}
```

### 2. Schema Generation

The macro system will automatically generate JSON schemas from Swift types:

```swift
// Swift Type -> JSON Schema Mapping
String -> {"type": "string"}
Int -> {"type": "integer"}
Double -> {"type": "number"}
Bool -> {"type": "boolean"}
[T] -> {"type": "array", "items": <T schema>}
Optional<T> -> <T schema> (not in required array)
Enum -> {"type": "string", "enum": [cases]}
```

### 3. Registration Discovery

Tools will be automatically discovered through:
1. **Compile-time registration**: Macros inject registration code
2. **Global registry**: Centralized `MCPToolRegistry` collects all tools
3. **Runtime access**: FastMCP server queries registry at startup

## Registry Implementation

### MCPToolRegistry

```swift
public final class MCPToolRegistry: @unchecked Sendable {
    public static let shared = MCPToolRegistry()
    
    private var tools: [String: any MCPToolProtocol.Type] = [:]
    private var resources: [String: any MCPResourceProtocol.Type] = [:]
    private var prompts: [String: any MCPPromptProtocol.Type] = [:]
    
    private let lock = NSLock()
    
    private init() {}
    
    public func register<T: MCPToolProtocol>(_ toolType: T.Type) {
        lock.withLock {
            tools[T.mcpToolDefinition.name] = toolType
        }
    }
    
    public func getAllTools() -> [MCPToolDefinition] {
        lock.withLock {
            return tools.values.map { $0.mcpToolDefinition }
        }
    }
    
    public func getTool(named name: String) -> (any MCPToolProtocol.Type)? {
        lock.withLock {
            return tools[name]
        }
    }
}
```

### FastMCP Integration

```swift
extension SimpleFastMCP {
    public func registerDiscoveredTools() async {
        let registry = MCPToolRegistry.shared
        
        // Register tool handlers
        await server.withMethodHandler(ListTools.self) { _ in
            let tools = registry.getAllTools()
            return .init(tools: tools)
        }
        
        await server.withMethodHandler(CallTool.self) { params in
            guard let toolType = registry.getTool(named: params.name) else {
                throw MCPError.methodNotFound("Tool not found: \(params.name)")
            }
            
            return try await toolType.callTool(with: params.arguments ?? [:])
        }
        
        // Similarly for resources and prompts...
    }
}
```

## Usage Flow

### 1. Tool Developer Perspective

```swift
// 1. Create a new Swift package/module
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/fastmcp-swift", from: "1.0.0")
]
targets: [
    .target(
        name: "MyMCPTools",
        dependencies: [
            .product(name: "FastMCPProtocol", package: "fastmcp-swift")
        ]
    )
]

// 2. Define tools using macros
// Sources/MyMCPTools/WeatherTool.swift
import FastMCPProtocol

@MCPTool(name: "weather", description: "Get weather information")
struct WeatherTool {
    @MCPParameter(description: "City name")
    var city: String
    
    func execute() async throws -> String {
        return "Weather for \(city): 25°C, Sunny"
    }
}
```

### 2. Server Integration

```swift
// FastMCP server automatically discovers and registers all tools
import FastMCPSwift
import MyMCPTools  // This triggers tool registration

let server = FastMCPServer("MyApp", version: "1.0.0")
await server.registerDiscoveredTools()  // Registers all @MCPTool annotated tools
try await server.run(host: "127.0.0.1", port: 57890, path: "/mcp")
```

## Implementation Plan

### Phase 1: Core Protocol & Registry
1. Define `MCPToolProtocol` and related protocols in `FastMCPProtocol`
2. Implement `MCPToolRegistry` with thread-safe registration
3. Create basic schema generation utilities

### Phase 2: Macro Development
1. Implement `@MCPTool` macro with basic functionality
2. Add `@MCPParameter` macro for parameter definition
3. Generate automatic schema from Swift types

### Phase 3: FastMCP Integration
1. Add tool discovery to `SimpleFastMCP`
2. Implement automatic handler registration
3. Add error handling and validation

### Phase 4: Advanced Features
1. Support for resources and prompts
2. Custom schema validation
3. Tool versioning and metadata

### Phase 5: Documentation & Examples
1. Comprehensive documentation
2. Example tool packages
3. Integration guides

## Benefits

1. **Developer Experience**: Simple, declarative API for tool registration
2. **Type Safety**: Compile-time validation of tool definitions
3. **Performance**: Zero runtime overhead for registration metadata
4. **Modularity**: Tools can be developed in separate packages
5. **Discoverability**: Automatic tool discovery without manual registration
6. **Maintainability**: Clean separation between tool logic and registration

## Considerations

1. **Swift Version**: Requires Swift 5.9+ for macro support
2. **Compilation**: Tools must be compiled into the final binary
3. **Dynamic Loading**: No support for runtime plugin loading (by design)
4. **Debugging**: Macro-generated code may be harder to debug

## Future Extensions

1. **Plugin System**: Dynamic tool loading from external packages
2. **Tool Validation**: Runtime validation of tool implementations
3. **Performance Monitoring**: Built-in metrics for tool performance
4. **Tool Documentation**: Auto-generated documentation from macro metadata