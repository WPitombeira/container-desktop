import SwiftUI

struct NetworksView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AuraSectionHeader("Networks", subtitle: "\(filteredNetworks.count) local networks", systemImage: "network")
                Spacer()
                Button {
                    store.appendLog("Network creation is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Create", systemImage: "plus")
                }
                .buttonStyle(AuraCompactButtonStyle(prominent: true))

                Button {
                    store.appendLog("Network inspection is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Inspect", systemImage: "info.circle")
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            if filteredNetworks.isEmpty {
                AuraEmptyState(
                    title: searchText.isEmpty ? "No networks found" : "No networks match this search",
                    message: searchText.isEmpty ? "Local runtime networks will appear here after refresh." : "Try a different network name, driver, scope, or subnet detail.",
                    systemImage: "network"
                )
            } else {
                AuraSurface {
                    VStack(spacing: 0) {
                        header
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredNetworks) { network in
                                    row(network)
                                    if network.id != filteredNetworks.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .auraPage()
        .searchable(text: $searchText, prompt: "Search networks")
    }

    private var header: some View {
        HStack(spacing: 14) {
            tableLabel("Name")
            tableLabel("Driver", width: 120)
            tableLabel("Scope", width: 120)
            tableLabel("Details")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06))
    }

    private func row(_ network: AuraNetwork) -> some View {
        HStack(spacing: 14) {
            Text(network.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(network.driver)
                .font(.caption.monospaced())
                .frame(width: 120, alignment: .leading)

            Text(network.scope)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(network.subnet)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var filteredNetworks: [AuraNetwork] {
        store.filteredNetworks(searchText)
    }

    private func tableLabel(_ value: String, width: CGFloat? = nil) -> some View {
        Text(value.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}
