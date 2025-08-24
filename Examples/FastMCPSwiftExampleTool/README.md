# FastMCP Swift Example Tool

一个使用 FastMCPProtocol 实现 echo 工具的示例库。

## 概述

这个包演示了如何使用 FastMCPProtocol 创建可重用的 MCP 工具。它实现了一个简单的 echo 工具，可以将输入的消息原样返回，并添加时间戳和消息长度信息。

## 功能

- **EchoTool**: 实现 `ToolProvider` 协议的 echo 工具
- **工具注册**: 提供便利方法将工具注册到 FastMCP registry
- **完整测试**: 包含全面的单元测试

## 使用方法

### 基本使用

```swift
import FastMCPSwiftExampleTool
import FastMCPProtocol

// 创建 registry
let registry = DefaultFastMCPRegistry()

// 注册 echo 工具
FastMCPSwiftExampleTool.registerTools(with: registry)

// 获取并使用工具
if let echoTool = registry.getTool(named: "echo") {
    let result = try await echoTool.execute(with: ["message": "Hello, World!"])
    print(result)
}
```

### 直接创建工具

```swift
let echoTool = FastMCPSwiftExampleTool.createEchoTool()
let result = try await echoTool.execute(with: ["message": "Hello, FastMCP!"])
```

## Echo 工具

### 参数

- `message` (string, required): 要回显的消息

### 返回值

返回包含以下字段的字典：
- `echo`: 原始消息
- `timestamp`: ISO8601 格式的时间戳  
- `length`: 消息长度

### 示例

```swift
// 输入
["message": "Hello, FastMCP!"]

// 输出
[
    "echo": "Hello, FastMCP!",
    "timestamp": "2025-08-25T00:00:13Z",
    "length": 15
]
```

## 开发

### 构建

```bash
swift build
```

### 测试

```bash
swift test
```

### 运行特定测试

```bash
swift test --filter EchoToolTests.testEchoToolExecution
```

## 架构

这个库演示了 FastMCP Swift 的插件架构：

1. **工具实现**: `EchoTool` 实现 `ToolProvider` 协议
2. **Sendable 合规**: 所有组件都是线程安全的
3. **错误处理**: 定义了领域特定的错误类型
4. **注册系统**: 通过 registry 模式管理工具

## 集成

这个包可以作为其他 FastMCP 应用程序的依赖项：

```swift
dependencies: [
    .package(path: "path/to/FastMCPSwiftExampleTool")
]
```