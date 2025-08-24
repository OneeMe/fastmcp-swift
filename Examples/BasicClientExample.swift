import Foundation
import FastMCPSwift

@main
struct BasicClientExample {
    static func main() async throws {
        let client = SimpleFastMCPClient(name: "Example Client", version: "1.0.0")
        
        do {
            print("Connecting to FastMCP server...")
            try await client.connect(host: "127.0.0.1", port: 8000, path: "/mcp")
            print("Connected successfully!")
            
            print("Sending ping...")
            try await client.ping()
            print("Ping successful!")
            
        } catch {
            print("Client error: \(error)")
        }
        
        await client.disconnect()
        print("Disconnected from server")
    }
}