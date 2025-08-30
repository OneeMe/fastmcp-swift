import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Import the macro implementation
#if canImport(FastMCPMacrosImplementation)
import FastMCPMacrosImplementation

final class MCPToolMacroTests: XCTestCase {
    func testBasicMCPToolMacro() throws {
        assertMacroExpansion(
            """
            @MCPTool(name: "test", description: "A test tool")
            struct TestTool {
                func execute() async throws -> String {
                    return "Hello, World!"
                }
            }
            """,
            expandedSource: """
            struct TestTool {
                func execute() async throws -> String {
                    return "Hello, World!"
                }
            }
            
            extension TestTool: MCPToolProtocol {
                static var mcpToolDefinition: MCPToolDefinition {
                    MCPToolDefinition(
                        name: "test",
                        description: "A test tool",
                        inputSchema: .object([
                            "type": .string("object"),
                            "properties": .object([:]),
                            "required": .array([])
                        ])
                    )
                }
                static func callTool(with arguments: [String: Any]) async throws -> MCPToolResult {
                    let tool = TestTool()
                    let result = try await tool.execute()
                    return MCPToolResult(content: [.text(String(describing: result))])
                }
            }
            
            @_constructor
            private func registerTestTool() {
                MCPToolRegistry.shared.register(TestTool.self)
            }
            """,
            macros: testMacros
        )
    }
    
    func testMCPToolWithoutExecuteMethod() throws {
        assertMacroExpansion(
            """
            @MCPTool(name: "invalid", description: "Invalid tool")
            struct InvalidTool {
                func doSomething() -> String {
                    return "invalid"
                }
            }
            """,
            expandedSource: """
            struct InvalidTool {
                func doSomething() -> String {
                    return "invalid"
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@MCPTool requires an 'execute' method", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}

let testMacros: [String: Macro.Type] = [
    "MCPTool": MCPToolMacro.self,
]
#endif