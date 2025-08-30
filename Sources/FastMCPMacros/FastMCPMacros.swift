@_exported import FastMCPProtocol

/// Macro for registering MCP tools
///
/// Apply this macro to a struct that implements a tool function.
/// The struct must have an `execute()` method that returns the tool's result.
///
/// Example:
/// ```swift
/// @MCPTool(name: "calculate", description: "Perform mathematical calculations")
/// struct CalculatorTool {
///     func execute() async throws -> String {
///         return "42"
///     }
/// }
/// ```
///
/// The macro will automatically:
/// 1. Generate MCPToolProtocol conformance
/// 2. Create tool definition with schema
/// 3. Provide static tool calling interface
@attached(extension, conformances: MCPToolProtocol, names: named(mcpToolDefinition), named(callTool))
public macro MCPTool(name: String, description: String) = #externalMacro(module: "FastMCPMacrosImplementation", type: "MCPToolMacro")