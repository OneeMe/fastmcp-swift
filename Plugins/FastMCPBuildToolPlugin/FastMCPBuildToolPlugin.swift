import PackagePlugin
import Foundation

@main
struct FastMCPBuildToolPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let swiftTarget = target as? SourceModuleTarget else {
            return []
        }

        // Output file path inside plugin work directory
        let output = context.pluginWorkDirectory.appending("_FastMCP_Generated_Tools.swift")

        // Build arguments: we pass all source file paths to the tool
        var arguments: [String] = ["--output", output.string]
        for file in swiftTarget.sourceFiles(withSuffix: ".swift") {
            arguments.append(contentsOf: ["--source", file.path.string])
        }

        return [
            .buildCommand(
                displayName: "FastMCP: Generate tool registrations",
                executable: try context.tool(named: "fastmcp-gen").path,
                arguments: arguments,
                outputFiles: [output]
            )
        ]
    }
}


