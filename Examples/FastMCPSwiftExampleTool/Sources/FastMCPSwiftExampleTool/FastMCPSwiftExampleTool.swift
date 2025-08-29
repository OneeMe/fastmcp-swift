import Foundation
import FastMCPProtocol
// 由构建插件生成的 `_FastMCP_Generated_Tools.swift` 会在构建时参与编译，内含 `registerAllDiscoveredTools()`

/// FastMCP Swift Example Tool Library
/// Provides an echo tool implementation using FastMCPProtocol
public struct FastMCPSwiftExampleTool {
    
    /// 注册本模块中通过 @RegisterTool 标注的工具到给定的运行时注册表
    /// - Parameter registry: 运行时注册表（存放 ToolProvider 实例）
    public static func registerTools(with registry: FastMCPRegistry) {
        // 先调用由插件生成的类型注册函数（将类型写入 MCPToolTypeRegistry）
        registerAllDiscoveredTools()

        // 将类型注册表中的工具类型实例化并注册到运行时注册表
        for toolType in MCPToolTypeRegistry.shared.allToolTypes() {
            let instance = toolType.init()
            if let provider = instance as? ToolProvider {
                registry.registerTool(provider)
            }
        }
    }
    
    /// Create an echo tool instance
    /// - Returns: A configured EchoTool instance
    public static func createEchoTool() -> EchoTool {
        return EchoTool()
    }
}
