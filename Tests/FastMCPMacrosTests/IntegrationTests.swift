import XCTest
@testable import FastMCPMacros

// Test tools defined at module level (not inside test functions)
@MCPTool(name: "add", description: "Add two numbers")
struct AddTool {
    var a: Int = 5
    var b: Int = 3
    
    func execute() async throws -> Int {
        return a + b
    }
}

@MCPTool(name: "greet", description: "Generate a greeting")
struct GreetTool {
    func execute() async throws -> String {
        return "Hello, FastMCP!"
    }
}

@MCPTool(name: "schema_test", description: "Test schema generation")
struct SchemaTestTool {
    func execute() async throws -> String {
        return "test"
    }
}

// Test that demonstrates the complete @MCPTool workflow
final class IntegrationTests: XCTestCase {
    
    func testBasicToolRegistrationAndExecution() async throws {
        // Verify the tool definition
        let toolDef = AddTool.mcpToolDefinition
        
        XCTAssertEqual(toolDef.name, "add")
        XCTAssertEqual(toolDef.description, "Add two numbers")
        
        // Test tool execution through the protocol
        let result = try await AddTool.callTool(with: [:])
        XCTAssertEqual(result.content.count, 1)
        
        if let textContent = result.content.first?.text {
            XCTAssertTrue(textContent.contains("8"))  // 5 + 3 = 8
        } else {
            XCTFail("Expected text content")
        }
    }
    
    func testStringTool() async throws {
        let result = try await GreetTool.callTool(with: [:])
        XCTAssertEqual(result.content.count, 1)
        XCTAssertEqual(result.content.first?.text, "Hello, FastMCP!")
    }
    
    func testJSONSchemaGeneration() {
        let definition = SchemaTestTool.mcpToolDefinition
        XCTAssertEqual(definition.name, "schema_test")
        XCTAssertEqual(definition.description, "Test schema generation")
        
        // Verify the schema structure
        if case .object(let schemaObject) = definition.inputSchema {
            XCTAssertTrue(schemaObject.keys.contains("type"))
            XCTAssertTrue(schemaObject.keys.contains("properties"))
            XCTAssertTrue(schemaObject.keys.contains("required"))
        } else {
            XCTFail("Expected object schema")
        }
    }
}