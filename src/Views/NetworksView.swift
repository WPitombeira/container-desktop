import SwiftUI

struct NetworksView: View {
    @ObservedObject var store: AuraPlaceholderStore
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
        .navigationTitle("Networks")
    }

    private var filteredNetworks: [AuraNetwork] {
        store.filteredNetworks(searchText)
    }
}
