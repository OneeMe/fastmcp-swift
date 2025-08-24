//
// FastMCPSwiftServerExample
// Created by: onee on 8/24/25
//

import SwiftUI
import FastMCPServer

@main
struct FastMCPSwiftServerExampleApp: App {
    @StateObject private var serverManager = FastMCPServerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serverManager)
        }
    }
}

@MainActor
class FastMCPServerManager: ObservableObject {
    private let fastMCPServer = FastMCPServer("FastMCPSwiftServerExample", version: "1.0.0")
    @Published var isServerRunning = false
    @Published var serverStatus = "Not started"
    
    init() {
        startFastMCPServer()
    }
    
    private func startFastMCPServer() {
        Task {
            do {
                serverStatus = "Starting FastMCP HTTP streaming server on localhost:57890/mcp..."
                print(serverStatus)
                try await fastMCPServer.run(host: "127.0.0.1", port: 57890, path: "/mcp")
                isServerRunning = true
                serverStatus = "FastMCP server running on localhost:57890/mcp"
                print(serverStatus)
            } catch {
                serverStatus = "Failed to start FastMCP server: \(error.localizedDescription)"
                print(serverStatus)
                isServerRunning = false
            }
        }
    }
}
