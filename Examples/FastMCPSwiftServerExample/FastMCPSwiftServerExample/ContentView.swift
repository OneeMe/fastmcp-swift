//
// FastMCPSwiftServerExample
// Created by: onee on 8/24/25
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serverManager: FastMCPServerManager

    var body: some View {
        NavigationSplitView {
            List {
                Section("FastMCP Server Status") {
                    HStack {
                        Circle()
                            .fill(serverManager.isServerRunning ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(serverManager.serverStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .navigationTitle("FastMCP Example")
        } detail: {
            VStack(spacing: 20) {
                Text("FastMCP Swift Server Example")
                    .font(.title)
                    .padding()
                
                Text("Server Status: \(serverManager.serverStatus)")
                    .padding()
                
                if serverManager.isServerRunning {
                    Text("FastMCP HTTP streaming server is running on:")
                        .padding(.top)
                    Text("localhost:57890/mcp")
                        .font(.monospaced(.body)())
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("You can now connect MCP clients to this endpoint!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Text("HTTP streaming server failed to start")
                        .foregroundColor(.red)
                        .padding(.top)
                    Text("Check console for error details.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(FastMCPServerManager())
}
