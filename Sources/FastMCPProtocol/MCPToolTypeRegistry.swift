import Foundation

/// Lightweight protocol for macro-based registration
/// Tool types are registered by type (not instance) and must provide a default initializer
public protocol MCPTool: Sendable {
    init()
    static var toolName: String { get }
}

/// Thread-safe registry that stores tool types discovered via build plugin
public final class MCPToolTypeRegistry: @unchecked Sendable {
    public static let shared = MCPToolTypeRegistry()

    private let lock = NSLock()
    private var toolTypes: [String: MCPTool.Type] = [:]

    private init() {}

    /// Register a tool type discovered at build time
    public func register(_ toolType: MCPTool.Type) {
        let name = toolType.toolName
        lock.withLock {
            toolTypes[name] = toolType
        }
    }

    /// Get a tool type by name
    public func getToolType(named name: String) -> MCPTool.Type? {
        lock.withLock {
            toolTypes[name]
        }
    }

    /// List all registered tool types
    public func allToolTypes() -> [MCPTool.Type] {
        lock.withLock {
            Array(toolTypes.values)
        }
    }
}


