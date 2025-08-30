import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct FastMCPMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MCPToolMacro.self,
    ]
}