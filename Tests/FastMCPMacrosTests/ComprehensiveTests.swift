import XCTest
@testable import FastMCPMacros

@MCPTool(name: "math", description: "Mathematical operations")
struct MathTool {
    func execute() async throws -> Double {
        return 3.14159
    }
}

@MCPTool(name: "status", description: "System status check")  
struct StatusTool {
    func execute() async throws -> [String: Any] {
        return ["status": "healthy", "uptime": 12345]
    }
}

final class ComprehensiveTests: XCTestCase {
    
    func testMultipleToolDefinitions() {
        // Test that multiple tools can be defined and have correct definitions
        let mathDef = MathTool.mcpToolDefinition
        let statusDef = StatusTool.mcpToolDefinition
        
        XCTAssertEqual(mathDef.name, "math")
        XCTAssertEqual(mathDef.description, "Mathematical operations")
        
        XCTAssertEqual(statusDef.name, "status") 
        XCTAssertEqual(statusDef.description, "System status check")
        
        // Verify they have different names
        XCTAssertNotEqual(mathDef.name, statusDef.name)
    }
    
    func testToolExecutionWithDifferentReturnTypes() async throws {
        // Test numeric return type
        let mathResult = try await MathTool.callTool(with: [:])
        XCTAssertEqual(mathResult.content.count, 1)
        XCTAssertFalse(mathResult.isError)
        
        let mathText = mathResult.content.first?.text
        XCTAssertNotNil(mathText)
        XCTAssertTrue(mathText!.contains("3.14159"))
        
        // Test complex return type (dictionary)
        let statusResult = try await StatusTool.callTool(with: [:])
        XCTAssertEqual(statusResult.content.count, 1)
        XCTAssertFalse(statusResult.isError)
        
        let statusText = statusResult.content.first?.text
        XCTAssertNotNil(statusText)
        // The text should contain dictionary representation
        XCTAssertTrue(statusText!.contains("status") || statusText!.contains("uptime"))
    }
    
    func testSchemaConsistency() {
        // Test that all generated tools have consistent schema structure
        let mathSchema = MathTool.mcpToolDefinition.inputSchema
        let statusSchema = StatusTool.mcpToolDefinition.inputSchema
        
        // Both should be object schemas
        guard case .object(let mathObj) = mathSchema,
              case .object(let statusObj) = statusSchema else {
            XCTFail("All tools should have object schemas")
            return
        }
        
        // Both should have the same basic structure
        XCTAssertTrue(mathObj.keys.contains("type"))
        XCTAssertTrue(mathObj.keys.contains("properties"))
        XCTAssertTrue(mathObj.keys.contains("required"))
        
        XCTAssertTrue(statusObj.keys.contains("type"))
        XCTAssertTrue(statusObj.keys.contains("properties"))
        XCTAssertTrue(statusObj.keys.contains("required"))
    }
    
    func testMCPToolProtocolConformance() {
        // Verify that generated extensions properly conform to MCPToolProtocol
        XCTAssertTrue(MathTool.self is any MCPToolProtocol.Type)
        XCTAssertTrue(StatusTool.self is any MCPToolProtocol.Type)
        
        // Test that we can use them polymorphically
        let toolTypes: [any MCPToolProtocol.Type] = [MathTool.self, StatusTool.self]
        XCTAssertEqual(toolTypes.count, 2)
        
        let definitions = toolTypes.map { $0.mcpToolDefinition }
        XCTAssertEqual(definitions.count, 2)
        XCTAssertTrue(definitions.contains { $0.name == "math" })
        XCTAssertTrue(definitions.contains { $0.name == "status" })
    }
    
    func testErrorHandling() async {
        // Test that the generated callTool method properly handles errors
        // This is a basic test - in practice, you'd create a tool that throws
        
        do {
            _ = try await MathTool.callTool(with: [:])
            // Should succeed
        } catch {
            XCTFail("Tool execution should not throw for valid cases")
        }
    }
}