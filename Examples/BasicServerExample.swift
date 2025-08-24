import Foundation
import FastMCPSwift

@main
struct BasicServerExample {
    static func main() async throws {
        let server = SimpleFastMCP("Basic Server Example", version: "1.0.0")
        
        print("Starting FastMCP server on http://127.0.0.1:8000/mcp")
        print("Server: \(server.name) v\(server.version)")
        
        do {
            try await server.run(host: "127.0.0.1", port: 8000, path: "/mcp")
        } catch {
            print("Server error: \(error)")
        }
    }
}