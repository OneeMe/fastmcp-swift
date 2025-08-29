import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct RegisterToolMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Minimal peer: ensure types provide default init if not present is out of scope
        // Here we just emit a no-op marker to keep the macro simple.
        return []
    }
}

@main
struct FastMCPMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RegisterToolMacro.self,
    ]
}


