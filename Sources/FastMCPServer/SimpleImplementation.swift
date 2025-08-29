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
    
    public init(_ name: String, version: String = "1.0.0") {
        self.name = name
        self.version = version
        self.server = Server(name: name, version: version)
        
        Task {
            await setupToolHandlers()
        }
    }
    
    private func setupToolHandlers() async {
        // Register tools/list handler using the auto-discovered tools
        await server.withMethodHandler(ListTools.self) { [weak self] _ in
            let toolTypes = MCPToolTypeRegistry.shared.allToolTypes()
            let tools = toolTypes.map { toolType in
                let toolInstance = toolType.init()
                return Tool(
                    name: toolType.toolName,
                    description: (toolInstance as? ToolProvider)?.toolDescription ?? "Tool description",
                    inputSchema: self?.convertDictionaryToValue((toolInstance as? ToolProvider)?.getParameterSchema() ?? [:]) ?? .object([:])
                )
            }
            
            return ListTools.Result(tools: tools)
        }
        
        // Register tools/call handler using the auto-discovered tools
        await server.withMethodHandler(CallTool.self) { [weak self] request in
            guard let toolType = MCPToolTypeRegistry.shared.getToolType(named: request.name) else {
                return CallTool.Result(
                    content: [.text("Tool not found: \(request.name)")], 
                    isError: true
                )
            }
            
            guard let tool = toolType.init() as? ToolProvider else {
                return CallTool.Result(
                    content: [.text("Tool does not conform to ToolProvider: \(request.name)")], 
                    isError: true
                )
            }
            
            // Convert MCP Value arguments to [String: Any]
            let arguments: [String: Any]
            if let args = request.arguments {
                arguments = self?.convertValueObjectToDictionary(args) ?? [:]
            } else {
                arguments = [:]
            }
            
            do {
                let result = try await tool.execute(with: arguments)
                let resultText = self?.formatResult(result) ?? String(describing: result)
                return CallTool.Result(content: [.text(resultText)])
            } catch {
                return CallTool.Result(
                    content: [.text("Tool execution failed: \(error.localizedDescription)")],
                    isError: true
                )
            }
        }
    }
    
    private func convertDictionaryToValue(_ dictionary: [String: Any]) -> Value {
        var valueDict: [String: Value] = [:]
        for (key, value) in dictionary {
            valueDict[key] = convertAnyToValue(value)
        }
        return .object(valueDict)
    }
    
    private func convertAnyToValue(_ value: Any) -> Value {
        switch value {
        case is NSNull:
            return .null
        case let bool as Bool:
            return .bool(bool)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let string as String:
            return .string(string)
        case let data as Data:
            return .data(data)
        case let array as [Any]:
            return .array(array.map { convertAnyToValue($0) })
        case let dict as [String: Any]:
            var valueDict: [String: Value] = [:]
            for (k, v) in dict {
                valueDict[k] = convertAnyToValue(v)
            }
            return .object(valueDict)
        default:
            return .string(String(describing: value))
        }
    }
    
    private func convertValueObjectToDictionary(_ objectValue: [String: Value]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, val) in objectValue {
            result[key] = convertValueToAny(val)
        }
        return result
    }
    
    private func convertValueToAny(_ value: Value) -> Any {
        switch value {
        case .null:
            return NSNull()
        case .bool(let bool):
            return bool
        case .int(let int):
            return int
        case .double(let double):
            return double
        case .string(let string):
            return string
        case .data(_, let data):
            return data
        case .array(let array):
            return array.map { convertValueToAny($0) }
        case .object(let object):
            var result: [String: Any] = [:]
            for (key, val) in object {
                result[key] = convertValueToAny(val)
            }
            return result
        }
    }
    
    private func formatResult(_ result: Any) -> String {
        if let dict = result as? [String: Any] {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
                return String(data: jsonData, encoding: .utf8) ?? String(describing: result)
            } catch {
                return String(describing: result)
            }
        }
        return String(describing: result)
    }
    
    
    /// Run the MCP server with HTTP streaming transport
    /// - Parameters:
    ///   - host: Host to bind to (default: "127.0.0.1")
    ///   - port: Port to listen on (default: 8000)
    ///   - path: HTTP path for MCP endpoint (default: "/mcp")
    /// - Returns: After the server has started successfully
    public func run(host: String = "127.0.0.1", port: Int = 8000, path: String = "/mcp") async throws {
        #if canImport(Network)
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
        let transport = HTTPServerTransport(host: host, port: port, path: path)
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
        #else
        throw FastMCPError.networkUnavailable
        #endif
    }
    
    /// Run the MCP server with stdio transport (for command line usage)
    public func runStdio() async throws {
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
