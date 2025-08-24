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

public final class SimpleFastMCP {
    public let name: String
    public let version: String
    private let server: Server
    
    public init(_ name: String, version: String = "1.0.0") {
        self.name = name
        self.version = version
        self.server = Server(name: name, version: version)
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
