import Foundation

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