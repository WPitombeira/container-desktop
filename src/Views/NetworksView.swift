import SwiftUI

struct NetworksView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        List(filteredNetworks) { network in
            VStack(alignment: .leading, spacing: 2) {
                Text(network.name).bold()
                Text("Driver \(network.driver) • Scope \(network.scope)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Subnet \(network.subnet)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
        .searchable(text: $searchText, prompt: "Search networks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Create") {
                    store.appendLog("Network creation is not implemented yet; use the CLI command path for now.", level: .warning)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Inspect") {
                    store.appendLog("Network inspection is not implemented yet; use the CLI command path for now.", level: .warning)
                }
            }
        }
        .navigationTitle("Networks")
    }

    private var filteredNetworks: [AuraNetwork] {
        store.filteredNetworks(searchText)
    }
}
