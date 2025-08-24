//
// FastMCPSwiftServerExample
// Created by: onee on 8/24/25
//

import SwiftUI
import SwiftData
import FastMCPSwift

@main
struct FastMCPSwiftServerExampleApp: App {
    @StateObject private var serverManager = FastMCPServerManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serverManager)
        }
        .modelContainer(sharedModelContainer)
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
                serverStatus = "Starting FastMCP HTTP streaming server on localhost:57890/mcp"
                print(serverStatus)
                try await fastMCPServer.run(host: "127.0.0.1", port: 57890, path: "/mcp")
                isServerRunning = true
                serverStatus = "FastMCP server running on localhost:57890/mcp"
                print(serverStatus)
            } catch {
                serverStatus = "Failed to start FastMCP server: \(error)"
                print(serverStatus)
                isServerRunning = false
            }
        }
    }
}
