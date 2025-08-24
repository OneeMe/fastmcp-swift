import Foundation
import MCP

public enum FastMCPError: Error, LocalizedError {
    case serverNotInitialized
    case invalidURL(String)
    
    public var errorDescription: String? {
        switch self {
        case .serverNotInitialized:
            return "FastMCP server is not initialized"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
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
    
    public func run(host: String = "127.0.0.1", port: Int = 8000, path: String = "/mcp") async throws {
        let urlString = "http://\(host):\(port)\(path)"
        guard let endpoint = URL(string: urlString) else {
            throw FastMCPError.invalidURL(urlString)
        }
        
        let transport = HTTPClientTransport(endpoint: endpoint)
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
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
}