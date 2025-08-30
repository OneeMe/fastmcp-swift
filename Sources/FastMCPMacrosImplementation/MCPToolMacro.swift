import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Macro implementation for @MCPTool
public struct MCPToolMacro: MemberMacro, ExtensionMacro {
    
    // MARK: - MemberMacro Implementation
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Only generate the auto-registration function for top-level types
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              let structName = structDecl.name.text.nilIfEmpty else {
            throw MCPToolMacroError.unsupportedDeclaration
        }
        
        // Skip registration function generation for local types (inside test functions)
        // This is a simplified approach - in real implementation you'd check the context
        return []
    }
    
    // MARK: - ExtensionMacro Implementation
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        // Extract tool name and description from macro arguments
        guard case let .argumentList(arguments) = node.arguments else {
            throw MCPToolMacroError.missingArguments
        }
        
        var toolName: String?
        var toolDescription: String?
        
        for argument in arguments {
            if let label = argument.label?.text {
                switch label {
                case "name":
                    toolName = extractStringLiteral(from: argument.expression)
                case "description":
                    toolDescription = extractStringLiteral(from: argument.expression)
                default:
                    break
                }
            }
        }
        
        guard let name = toolName, let description = toolDescription else {
            throw MCPToolMacroError.missingRequiredArguments
        }
        
        // Extract struct name
        guard let structDecl = declaration.as(StructDeclSyntax.self),
              let structName = structDecl.name.text.nilIfEmpty else {
            throw MCPToolMacroError.unsupportedDeclaration
        }
        
        // Extract execute method to ensure it exists
        let hasExecuteMethod = structDecl.memberBlock.members.contains { member in
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                return funcDecl.name.text == "execute"
            }
            return false
        }
        
        guard hasExecuteMethod else {
            throw MCPToolMacroError.missingExecuteMethod
        }
        
        // Generate MCPToolProtocol conformance extension
        let conformanceExtension = try ExtensionDeclSyntax("extension \(type): MCPToolProtocol") {
            // Generate mcpToolDefinition property
            DeclSyntax("""
            static var mcpToolDefinition: MCPToolDefinition {
                MCPToolDefinition(
                    name: "\(raw: name)",
                    description: "\(raw: description)",
                    inputSchema: .object([
                        "type": .string("object"),
                        "properties": .object([:]),
                        "required": .array([])
                    ])
                )
            }
            """)
            
            // Generate callTool method
            DeclSyntax("""
            static func callTool(with arguments: [String: Any]) async throws -> MCPToolResult {
                let tool = \(type)()
                let result = try await tool.execute()
                return MCPToolResult(content: [.text(String(describing: result))])
            }
            """)
        }
        
        return [conformanceExtension]
    }
}

// Helper function to extract string literals from expressions
private func extractStringLiteral(from expr: ExprSyntax) -> String? {
    if let stringLiteral = expr.as(StringLiteralExprSyntax.self) {
        return stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
    }
    return nil
}

// Custom extension to safely get text from identifiers
private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// Error types for macro expansion
enum MCPToolMacroError: Error, CustomStringConvertible {
    case missingArguments
    case missingRequiredArguments
    case unsupportedDeclaration
    case missingExecuteMethod
    
    var description: String {
        switch self {
        case .missingArguments:
            return "@MCPTool requires arguments"
        case .missingRequiredArguments:
            return "@MCPTool requires 'name' and 'description' arguments"
        case .unsupportedDeclaration:
            return "@MCPTool can only be applied to structs"
        case .missingExecuteMethod:
            return "@MCPTool requires an 'execute' method"
        }
    }
}