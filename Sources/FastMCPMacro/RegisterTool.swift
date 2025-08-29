import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Public macro declaration surface used by tool authors
@attached(peer)
public macro RegisterTool() = #externalMacro(module: "FastMCPMacroImpl", type: "RegisterToolMacro")


