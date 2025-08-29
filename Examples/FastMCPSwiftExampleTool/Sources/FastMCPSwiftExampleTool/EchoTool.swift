import Foundation
import FastMCPProtocol
import FastMCPMacro

/// An echo tool that returns the input message back to the user
@RegisterTool
public final class EchoTool: MCPTool, ToolProvider, @unchecked Sendable {
    public static let toolName: String = "echo"
    public var toolName: String { EchoTool.toolName }
    public let toolDescription = "Echo back the input message"
    
    public init() {}
    
    public func execute(with parameters: [String: Any]) async throws -> Any {
        guard let message = parameters["message"] as? String else {
            throw EchoToolError.missingMessage
        }
        
        return [
            "echo": message,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "length": message.count
        ]
    }
    
    public func getParameterSchema() -> [String: Any] {
        return [
            "type": "object",
            "properties": [
                "message": [
                    "type": "string",
                    "description": "The message to echo back"
                ]
            ],
            "required": ["message"]
        ]
    }
}

public enum EchoToolError: Error, LocalizedError {
    case missingMessage
    
    public var errorDescription: String? {
        switch self {
        case .missingMessage:
            return "Missing required parameter: message"
        }
    }
}
