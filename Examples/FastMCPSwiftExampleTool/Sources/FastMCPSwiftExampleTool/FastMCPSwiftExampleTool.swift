import Foundation
import FastMCPProtocol

/// FastMCP Swift Example Tool Library
/// Provides an echo tool implementation using FastMCPProtocol
public struct FastMCPSwiftExampleTool {
    
    /// Register the echo tool with a FastMCP registry
    /// - Parameter registry: The registry to register the tool with
    public static func registerTools(with registry: FastMCPRegistry) {
        let echoTool = EchoTool()
        registry.registerTool(echoTool)
    }
    
    /// Create an echo tool instance
    /// - Returns: A configured EchoTool instance
    public static func createEchoTool() -> EchoTool {
        return EchoTool()
    }
}