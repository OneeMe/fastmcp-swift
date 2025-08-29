import Foundation
import FastMCPProtocol

/// Example usage patterns for the FastMCPSwiftExampleTool library
public enum Usage {
    
    /// Demonstrate basic tool usage
    public static func basicUsage() async throws {
        print("=== FastMCP Swift Example Tool - Basic Usage ===")
        
        // Create an echo tool directly
        let echoTool = EchoTool()
        print("Created echo tool: \(echoTool.toolName)")
        
        // Execute the tool
        let result = try await echoTool.execute(with: ["message": "Hello, FastMCP Swift!"])
        print("Echo result: \(result)")
        
        // Show parameter schema
        let schema = echoTool.getParameterSchema()
        print("Parameter schema: \(schema)")
    }
    
    /// Demonstrate registry usage
    public static func registryUsage() async throws {
        print("=== FastMCP Swift Example Tool - Registry Usage ===")
        
        // Create a registry
        let registry = DefaultFastMCPRegistry()
        print("Created registry")
        
        // Register the echo tool
        await FastMCPSwiftExampleTool.registerTools(with: registry)
        print("Registered tools")
        
        // List registered tools
        let tools = registry.getRegisteredTools()
        print("Available tools: \(tools.map { $0.toolName })")
        
        // Get and use the echo tool
        if let echoTool = registry.getTool(named: "echo") {
            let result = try await echoTool.execute(with: [
                "message": "Registry-based echo test"
            ])
            print("Registry echo result: \(result)")
        }
    }
    
    /// Demonstrate error handling
    public static func errorHandlingUsage() async {
        print("=== FastMCP Swift Example Tool - Error Handling ===")
        
        let echoTool = EchoTool()
        
        do {
            // This should fail due to missing message parameter
            _ = try await echoTool.execute(with: [:])
        } catch let error as EchoToolError {
            print("Caught expected error: \(error.localizedDescription)")
        } catch {
            print("Caught unexpected error: \(error)")
        }
        
        do {
            // This should fail due to wrong parameter type
            _ = try await echoTool.execute(with: ["message": 123])
        } catch let error as EchoToolError {
            print("Caught expected error: \(error.localizedDescription)")
        } catch {
            print("Caught unexpected error: \(error)")
        }
    }
}
