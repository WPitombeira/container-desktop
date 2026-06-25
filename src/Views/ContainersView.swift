import SwiftUI

struct ContainersView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""
    @State private var selectedContainer: AuraContainer.ID?

    private var filtered: [AuraContainer] {
        let items = store.filteredContainers(searchText)
        return items.sorted { $0.status.sortOrder < $1.status.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedContainer) {
                ForEach(filtered) { container in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(container.name).bold()
                            Spacer()
                            Text(container.status.badgeLabel)
                                .font(.caption)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(
                                    Capsule().fill(statusColor(for: container.status).opacity(0.18))
                                )
                                .foregroundStyle(statusColor(for: container.status))
                        }
                        Text(container.image).font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("Ports: \(container.ports.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("CPU \(container.cpu, specifier: "%.2f%%")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(container.id)
                    .padding(.vertical, 2)
                }
            }
            .searchable(text: $searchText, prompt: "Search containers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Start") {
                        selectedContainer.map(store.startContainer)
                    }
                    .disabled(selectedContainer == nil)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Stop") {
                        selectedContainer.map(store.stopContainer)
                    }
                    .disabled(selectedContainer == nil)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Remove Stopped") {
                        store.removeCompletedContainers()
                    }
                }
            }
            .onAppear {
                if selectedContainer == nil, let first = filtered.first {
                    selectedContainer = first.id
                }
            }
        }
        .navigationTitle("Containers")
    }

    private func statusColor(for status: AuraRuntimeStatus) -> Color {
        switch status {
        case .running:
            return .green
        case .paused:
            return .yellow
        case .unhealthy:
            return .red
        case .stopped:
            return .secondary
        }
    }
}
