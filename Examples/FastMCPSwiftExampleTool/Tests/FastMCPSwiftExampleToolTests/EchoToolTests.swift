import XCTest
@testable import FastMCPSwiftExampleTool
@testable import FastMCPProtocol

final class EchoToolTests: XCTestCase {
    
    func testEchoToolInitialization() {
        let echoTool = EchoTool()
        XCTAssertEqual(echoTool.toolName, "echo")
        XCTAssertEqual(echoTool.toolDescription, "Echo back the input message")
    }
    
    func testEchoToolExecution() async throws {
        let echoTool = EchoTool()
        let parameters = ["message": "Hello, FastMCP!"]
        
        let result = try await echoTool.execute(with: parameters)
        
        guard let resultDict = result as? [String: Any] else {
            XCTFail("Result should be a dictionary")
            return
        }
        
        XCTAssertEqual(resultDict["echo"] as? String, "Hello, FastMCP!")
        XCTAssertEqual(resultDict["length"] as? Int, 15)
        XCTAssertNotNil(resultDict["timestamp"])
    }
    
    func testEchoToolMissingMessage() async {
        let echoTool = EchoTool()
        let parameters: [String: Any] = [:]
        
        do {
            _ = try await echoTool.execute(with: parameters)
            XCTFail("Should have thrown an error for missing message")
        } catch EchoToolError.missingMessage {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testEchoToolParameterSchema() {
        let echoTool = EchoTool()
        let schema = echoTool.getParameterSchema()
        
        XCTAssertEqual(schema["type"] as? String, "object")
        
        guard let properties = schema["properties"] as? [String: Any],
              let messageProperty = properties["message"] as? [String: Any] else {
            XCTFail("Schema should have properties with message")
            return
        }
        
        XCTAssertEqual(messageProperty["type"] as? String, "string")
        XCTAssertEqual(messageProperty["description"] as? String, "The message to echo back")
        
        guard let required = schema["required"] as? [String] else {
            XCTFail("Schema should have required array")
            return
        }
        
        XCTAssertTrue(required.contains("message"))
    }
    
    func testToolRegistration() {
        let registry = DefaultFastMCPRegistry()
        
        FastMCPSwiftExampleTool.registerTools(with: registry)
        
        let registeredTools = registry.getRegisteredTools()
        XCTAssertEqual(registeredTools.count, 1)
        
        let echoTool = registry.getTool(named: "echo")
        XCTAssertNotNil(echoTool)
        XCTAssertEqual(echoTool?.toolName, "echo")
    }
    
    func testCreateEchoTool() {
        let echoTool = FastMCPSwiftExampleTool.createEchoTool()
        XCTAssertEqual(echoTool.toolName, "echo")
        XCTAssertEqual(echoTool.toolDescription, "Echo back the input message")
    }
}