import XCTest
@testable import FastMCPServer

// Test tools defined using the @MCPTool macro imported via FastMCPServer
@MCPTool(name: "server_calculator", description: "Calculator tool via server import")
struct ServerCalculatorTool {
    func execute() async throws -> Int {
        return 42
    }
}

@MCPTool(name: "server_greeting", description: "Greeting tool via server import")
struct ServerGreetingTool {
    func execute() async throws -> String {
        return "Hello from FastMCPServer!"
    }
}

final class MacroIntegrationTests: XCTestCase {
    
    func testMacroAvailabilityThroughFastMCPServer() {
        // Verify that @MCPTool macro is available when importing FastMCPServer
        let calculatorDef = ServerCalculatorTool.mcpToolDefinition
        let greetingDef = ServerGreetingTool.mcpToolDefinition
        
        XCTAssertEqual(calculatorDef.name, "server_calculator")
        XCTAssertEqual(calculatorDef.description, "Calculator tool via server import")
        
        XCTAssertEqual(greetingDef.name, "server_greeting")
        XCTAssertEqual(greetingDef.description, "Greeting tool via server import")
    }
    
    func testMCPToolProtocolAvailability() {
        // Verify that MCPToolProtocol is available
        XCTAssertTrue(ServerCalculatorTool.self is any MCPToolProtocol.Type)
        XCTAssertTrue(ServerGreetingTool.self is any MCPToolProtocol.Type)
    }
    
    func testToolExecution() async throws {
        // Test that tools can be executed through the protocol
        let calcResult = try await ServerCalculatorTool.callTool(with: [:])
        XCTAssertEqual(calcResult.content.count, 1)
        XCTAssertEqual(calcResult.content.first?.text, "42")
        XCTAssertFalse(calcResult.isError)
        
        let greetResult = try await ServerGreetingTool.callTool(with: [:])
        XCTAssertEqual(greetResult.content.count, 1)
        XCTAssertEqual(greetResult.content.first?.text, "Hello from FastMCPServer!")
        XCTAssertFalse(greetResult.isError)
    }
    
    func testMCPToolRegistryAvailability() {
        // Verify that MCPToolRegistry is available through FastMCPServer import
        let registry = MCPToolRegistry.shared
        
        // The registry should be accessible and functional
        // Note: Tools aren't auto-registered in our current implementation
        // but the registry interface should be available
        let allTools = registry.getAllTools()
        XCTAssertNotNil(allTools) // Should return an array (empty or not)
    }
    
    func testServerTypesAvailability() {
        // Verify that server types are still available
        let server = FastMCPServer("test", version: "1.0.0")
        XCTAssertNotNil(server)
        
        let client = FastMCPClient(name: "test", version: "1.0.0")
        XCTAssertNotNil(client)
    }
    
    func testJSONSchemaTypes() {
        // Verify that JSON schema types are available
        let stringSchema = JSONSchema.string("test")
        let _ = JSONSchema.object(["key": .string("value")])
        
        XCTAssertNotNil(stringSchema.stringValue)
        XCTAssertEqual(stringSchema.stringValue, "test")
        
        // Test that we can create complex schemas
        let toolSchema = JSONSchema.object([
            "type": .string("object"),
            "properties": .object([
                "input": .string("string")
            ]),
            "required": .array([.string("input")])
        ])
        
        if case .object(let schemaObject) = toolSchema {
            XCTAssertTrue(schemaObject.keys.contains("type"))
            XCTAssertTrue(schemaObject.keys.contains("properties"))
            XCTAssertTrue(schemaObject.keys.contains("required"))
        } else {
            XCTFail("Should be object schema")
        }
    }
}