import Foundation
import MCP
#if canImport(Network)
import Network
#endif

public enum FastMCPError: Error, LocalizedError {
    case serverNotInitialized
    case invalidURL(String)
    case networkUnavailable
    case serverStartFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .serverNotInitialized:
            return "FastMCP server is not initialized"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkUnavailable:
            return "Network framework is not available on this platform"
        case .serverStartFailed(let reason):
            return "Failed to start server: \(reason)"
        }
    }
}

public final class SimpleFastMCP: @unchecked Sendable {
    public let name: String
    public let version: String
    private let server: Server
    private let toolRegistry: MCPToolRegistry
    
    public init(_ name: String, version: String = "1.0.0", toolRegistry: MCPToolRegistry = .shared) {
        self.name = name
        self.version = version
        self.toolRegistry = toolRegistry
        self.server = Server(
            name: name, 
            version: version,
            capabilities: Server.Capabilities(tools: Server.Capabilities.Tools())
        )
    }
    
    /// Configure MCP server with tool handlers from the registry
    private func configureToolHandlers() async {
        // Register tools/list handler to return available tools
        let toolRegistry = self.toolRegistry
        await server.withMethodHandler(ListTools.self) { _ in
            let toolDefs = toolRegistry.getAllTools()
            let tools = toolDefs.map { toolDef in
                Tool(
                    name: toolDef.name,
                    description: toolDef.description,
                    inputSchema: Self.convertJSONSchemaToValue(toolDef.inputSchema)
                )
            }
            
            return ListTools.Result(tools: tools)
        }
        
        // Register tools/call handler to execute tool calls
        await server.withMethodHandler(CallTool.self) { params in
            let toolName = params.name
            
            // Convert Value arguments to [String: Any]
            let arguments: [String: Any] = params.arguments?.compactMapValues { value in
                Self.convertValueToAny(value)
            } ?? [:]
            
            // Execute the tool through our registry
            let result = try await toolRegistry.callTool(named: toolName, with: arguments)
            
            // Convert result to MCP format
            let content = result.content.map { mcpContent -> Tool.Content in
                switch mcpContent {
                case .text(let text):
                    return .text(text)
                case .image(let data, let mimeType):
                    return .image(data: data, mimeType: mimeType ?? "image/png", metadata: nil)
                }
            }
            
            return CallTool.Result(content: content, isError: result.isError)
        }
    }
    
    /// Convert our JSONSchema enum to MCP Value format
    private static func convertJSONSchemaToValue(_ schema: JSONSchema) -> Value {
        switch schema {
        case .string(let value):
            return .object(["type": .string("string"), "const": .string(value)])
        case .number(let value):
            return .object(["type": .string("number"), "const": .double(value)])
        case .integer(let value):
            return .object(["type": .string("integer"), "const": .int(value)])
        case .boolean(let value):
            return .object(["type": .string("boolean"), "const": .bool(value)])
        case .array(let items):
            let itemValues = items.map { convertJSONSchemaToValue($0) }
            return .object([
                "type": .string("array"),
                "items": .array(itemValues)
            ])
        case .object(let properties):
            let propertyValues = properties.mapValues { convertJSONSchemaToValue($0) }
            return .object([
                "type": .string("object"), 
                "properties": .object(propertyValues)
            ])
        case .null:
            return .object(["type": .string("null")])
        }
    }
    
    /// Convert MCP Value to Any for our tool system
    private static func convertValueToAny(_ value: Value) -> Any? {
        switch value {
        case .string(let str):
            return str
        case .double(let num):
            return num
        case .int(let num):
            return num
        case .bool(let bool):
            return bool
        case .array(let array):
            return array.compactMap { convertValueToAny($0) }
        case .object(let obj):
            return obj.compactMapValues { convertValueToAny($0) }
        case .null, .data:
            return nil
        }
    }
    
    /// Run the MCP server with HTTP streaming transport
    /// - Parameters:
    ///   - host: Host to bind to (default: "127.0.0.1")
    ///   - port: Port to listen on (default: 8000)
    ///   - path: HTTP path for MCP endpoint (default: "/mcp")
    /// - Returns: After the server has started successfully
    public func run(host: String = "127.0.0.1", port: Int = 8000, path: String = "/mcp") async throws {
        #if canImport(Network)
        // Configure tool handlers before starting
        await configureToolHandlers()
        
        let transport = HTTPServerTransport(host: host, port: port, path: path)
        try await server.start(transport: transport)
        // Return immediately after server starts, don't wait for completion
        #else
        throw FastMCPError.networkUnavailable
        #endif
    }
    
    /// Run the MCP server with HTTP streaming transport and wait for completion
    /// - Parameters:
    ///   - host: Host to bind to (default: "127.0.0.1")  
    ///   - port: Port to listen on (default: 8000)
    ///   - path: HTTP path for MCP endpoint (default: "/mcp")
    /// - Note: This method blocks until the server is stopped
    public func runAndWait(host: String = "127.0.0.1", port: Int = 8000, path: String = "/mcp") async throws {
        #if canImport(Network)
        // Configure tool handlers before starting
        await configureToolHandlers()
        
        let transport = HTTPServerTransport(host: host, port: port, path: path)
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
        #else
        throw FastMCPError.networkUnavailable
        #endif
    }
    
    /// Run the MCP server with stdio transport (for command line usage)
    public func runStdio() async throws {
        // Configure tool handlers before starting
        await configureToolHandlers()
        
        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
    
    /// Access the underlying MCP server for advanced configuration
    public var mcpServer: Server {
        return server
    }
}

public final class SimpleFastMCPClient {
    private let client: MCP.Client
    
    public init(name: String = "FastMCP Client", version: String = "1.0.0") {
        self.client = MCP.Client(name: name, version: version)
    }
    
    public func connect(host: String, port: Int, path: String = "/mcp") async throws {
        let urlString = "http://\(host):\(port)\(path)"
        guard let endpoint = URL(string: urlString) else {
            throw FastMCPError.invalidURL(urlString)
        }
        
        let transport = HTTPClientTransport(endpoint: endpoint)
        _ = try await client.connect(transport: transport)
    }
    
    public func disconnect() async {
        await client.disconnect()
    }
    
    public func ping() async throws {
        try await client.ping()
    }
    
    /// Access the underlying MCP client for advanced usage
    public var mcpClient: MCP.Client {
        return client
    }
}
