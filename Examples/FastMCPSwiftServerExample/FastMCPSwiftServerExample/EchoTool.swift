//
// FastMCPSwiftServerExample
// Created by: onee on 8/30/25
//

import Foundation
import FastMCPServer  // This imports all macro functionality

// MARK: - Echo Tool Example

/// A simple echo tool that demonstrates the @MCPTool macro usage
/// This tool simply returns back any message it receives
@MCPTool(name: "echo", description: "Echo back a message with optional formatting")
struct EchoTool {
    let message: String
    let addTimestamp: Bool
    let prefix: String
    
    init(message: String = "Hello, FastMCP!", addTimestamp: Bool = false, prefix: String = "🔊") {
        self.message = message
        self.addTimestamp = addTimestamp
        self.prefix = prefix
    }
    
    func execute() async throws -> String {
        var result = "\(prefix) \(message)"
        
        if addTimestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            result += " (at \(formatter.string(from: Date())))"
        }
        
        return result
    }
}

// MARK: - Calculator Tool Example

/// A simple calculator tool showing numeric operations
@MCPTool(name: "calculator", description: "Perform basic mathematical calculations")
struct CalculatorTool {
    let operation: String
    let a: Double
    let b: Double
    
    init(operation: String = "add", a: Double = 10, b: Double = 5) {
        self.operation = operation.lowercased()
        self.a = a
        self.b = b
    }
    
    func execute() async throws -> String {
        let result: Double
        
        switch operation {
        case "add", "+":
            result = a + b
        case "subtract", "-":
            result = a - b
        case "multiply", "*":
            result = a * b
        case "divide", "/":
            guard b != 0 else {
                throw CalculatorError.divisionByZero
            }
            result = a / b
        case "power", "^":
            result = pow(a, b)
        default:
            throw CalculatorError.unsupportedOperation(operation)
        }
        
        return "Result: \(a) \(operation) \(b) = \(result)"
    }
}

enum CalculatorError: Error, LocalizedError {
    case divisionByZero
    case unsupportedOperation(String)
    
    var errorDescription: String? {
        switch self {
        case .divisionByZero:
            return "Cannot divide by zero"
        case .unsupportedOperation(let op):
            return "Unsupported operation: \(op). Supported: add, subtract, multiply, divide, power"
        }
    }
}

// MARK: - Weather Tool Example

/// A weather information tool (simulated data)
@MCPTool(name: "weather", description: "Get current weather information for a location")
struct WeatherTool {
    let location: String
    let includeDetails: Bool
    
    init(location: String = "San Francisco", includeDetails: Bool = true) {
        self.location = location
        self.includeDetails = includeDetails
    }
    
    func execute() async throws -> String {
        // Simulated weather data
        let temperature = Int.random(in: 15...30)
        let conditions = ["Sunny", "Partly Cloudy", "Cloudy", "Rainy"].randomElement()!
        let humidity = Int.random(in: 40...80)
        let windSpeed = Int.random(in: 5...25)
        
        var result = "Weather in \(location): \(temperature)°C, \(conditions)"
        
        if includeDetails {
            result += "\nHumidity: \(humidity)%"
            result += "\nWind: \(windSpeed) km/h"
            result += "\nLast updated: \(Date().formatted(.dateTime.hour().minute()))"
        }
        
        return result
    }
}
