//
// FastMCPSwiftServerExample
// Created by: onee on 8/24/25
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
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
                
                Section("Items") {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
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
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button("Add Item") {
                    addItem()
                }
                .padding()
                
                Spacer()
            }
            .padding()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(FastMCPServerManager())
}
