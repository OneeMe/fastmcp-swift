import Foundation

// MARK: - MCP Tool Protocol System

/// Schema representation for JSON Schema
public enum JSONSchema: Codable, Sendable {
    case string(String)
    case number(Double)
    case integer(Int)
    case boolean(Bool)
    case array([JSONSchema])
    case object([String: JSONSchema])
    case null
    
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
}

/// MCP Tool Definition
public struct MCPToolDefinition: Sendable {
    public let name: String
    public let description: String
    public let inputSchema: JSONSchema
    
    public init(name: String, description: String, inputSchema: JSONSchema) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

/// MCP Tool Result
public struct MCPToolResult: Sendable {
    public let content: [MCPContent]
    public let isError: Bool
    
    public init(content: [MCPContent], isError: Bool = false) {
        self.content = content
        self.isError = isError
    }
}

/// MCP Content types
public enum MCPContent: Sendable {
    case text(String)
    case image(String, String?) // data, mimeType
    
    public var text: String? {
        if case .text(let value) = self { return value }
        return nil
    }
}

/// Core MCP Tool Protocol
public protocol MCPToolProtocol: Sendable {
    static var mcpToolDefinition: MCPToolDefinition { get }
    static func callTool(with arguments: [String: Any]) async throws -> MCPToolResult
}

/// Error types for MCP operations
public enum MCPError: Error, Sendable {
    case invalidParams(String)
    case methodNotFound(String)
    case internalError(String)
    case invalidRequest(String)
}

// MARK: - MCP Tool Registry

/// Global registry for MCP tools
public final class MCPToolRegistry: @unchecked Sendable {
    public static let shared = MCPToolRegistry()
    
    private var tools: [String: any MCPToolProtocol.Type] = [:]
    private var resources: [String: any ResourceProvider] = [:]
    private var prompts: [String: any PromptProvider] = [:]
    
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
    
    public func callTool(named name: String, with arguments: [String: Any]) async throws -> MCPToolResult {
        guard let toolType = getTool(named: name) else {
            throw MCPError.methodNotFound("Tool not found: \(name)")
        }
        return try await toolType.callTool(with: arguments)
    }
}

// MARK: - Legacy Provider Protocols (Deprecated)

public protocol ToolProvider: Sendable {
    var toolName: String { get }
    var toolDescription: String { get }
    func execute(with parameters: [String: Any]) async throws -> Any
    func getParameterSchema() -> [String: Any]
}

public protocol ResourceProvider: Sendable {
    var resourceURI: String { get }
    var resourceDescription: String { get }
    func getResource() async throws -> Any
    func supportsTemplate() -> Bool
    func getTemplateParameters() -> [String: Any]
}

public protocol PromptProvider: Sendable {
    var promptName: String { get }
    var promptDescription: String { get }
    func generatePrompt(with parameters: [String: Any]) async throws -> String
    func getParameterSchema() -> [String: Any]
}

public protocol FastMCPRegistry {
    func registerTool(_ tool: ToolProvider)
    func registerResource(_ resource: ResourceProvider)
    func registerPrompt(_ prompt: PromptProvider)
    
    func getRegisteredTools() -> [ToolProvider]
    func getRegisteredResources() -> [ResourceProvider]
    func getRegisteredPrompts() -> [PromptProvider]
    
    func getTool(named name: String) -> ToolProvider?
    func getResource(for uri: String) -> ResourceProvider?
    func getPrompt(named name: String) -> PromptProvider?
}

public final class DefaultFastMCPRegistry: FastMCPRegistry {
    private var tools: [String: ToolProvider] = [:]
    private var resources: [String: ResourceProvider] = [:]
    private var prompts: [String: PromptProvider] = [:]
    
    private let lock = NSLock()
    
    public init() {}
    
    public func registerTool(_ tool: ToolProvider) {
        lock.withLock {
            tools[tool.toolName] = tool
        }
    }
    
    public func registerResource(_ resource: ResourceProvider) {
        lock.withLock {
            resources[resource.resourceURI] = resource
        }
    }
    
    public func registerPrompt(_ prompt: PromptProvider) {
        lock.withLock {
            prompts[prompt.promptName] = prompt
        }
    }
    
    public func getRegisteredTools() -> [ToolProvider] {
        lock.withLock {
            Array(tools.values)
        }
    }
    
    public func getRegisteredResources() -> [ResourceProvider] {
        lock.withLock {
            Array(resources.values)
        }
    }
    
    public func getRegisteredPrompts() -> [PromptProvider] {
        lock.withLock {
            Array(prompts.values)
        }
    }
    
    public func getTool(named name: String) -> ToolProvider? {
        lock.withLock {
            tools[name]
        }
    }
    
    public func getResource(for uri: String) -> ResourceProvider? {
        lock.withLock {
            resources[uri]
        }
    }
    
    public func getPrompt(named name: String) -> PromptProvider? {
        lock.withLock {
            prompts[name]
        }
    }
}