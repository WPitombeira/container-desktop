import SwiftUI

struct ContainersView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""
    @State private var selectedContainer: AuraContainer.ID?

    private var filtered: [AuraContainer] {
        store.filteredContainers(searchText)
            .sorted { $0.status.sortOrder < $1.status.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            resourceToolbar

            if filtered.isEmpty {
                AuraEmptyState(
                    title: searchText.isEmpty ? "No containers found" : "No containers match this search",
                    message: searchText.isEmpty ? "Refresh resources or create containers with the CLI to populate this view." : "Try a different container name, image, status, or port.",
                    systemImage: "shippingbox"
                )
            } else {
                AuraSurface {
                    VStack(spacing: 0) {
                        containerHeader
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filtered) { container in
                                    containerRow(container)
                                    if container.id != filtered.last?.id {
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
        .searchable(text: $searchText, prompt: "Search containers")
        .onAppear {
            if selectedContainer == nil, let first = filtered.first {
                selectedContainer = first.id
            }
        }
    }

    private var resourceToolbar: some View {
        HStack(spacing: 10) {
            AuraSectionHeader("Containers", subtitle: "\(filtered.count) shown • \(store.runningContainersCount) running", systemImage: "shippingbox")
            Spacer()
            Button {
                selectedContainer.map(store.startContainer)
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(AuraCompactButtonStyle(prominent: true))
            .disabled(selectedContainer == nil)

            Button {
                selectedContainer.map(store.stopContainer)
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(AuraCompactButtonStyle())
            .disabled(selectedContainer == nil)

            Button {
                store.removeCompletedContainers()
            } label: {
                Label("Remove stopped", systemImage: "trash")
            }
            .buttonStyle(AuraCompactButtonStyle())
        }
    }

    private var containerHeader: some View {
        HStack(spacing: 14) {
            tableLabel("Name", width: 220)
            tableLabel("Image")
            tableLabel("Status", width: 120)
            tableLabel("Ports", width: 160)
            tableLabel("CPU", width: 80)
            tableLabel("Memory", width: 90)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06))
    }

    private func containerRow(_ container: AuraContainer) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(container.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(shortID(container.id))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(width: 220, alignment: .leading)

            Text(container.image)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            AuraStatusBadge(status: container.status)
                .frame(width: 120, alignment: .leading)

            Text(container.ports.isEmpty ? "None" : container.ports.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(container.ports.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            Text("\(container.cpu, specifier: "%.2f")%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(container.memory)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(selectedContainer == container.id ? AuraTheme.accent.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedContainer = container.id
        }
    }

    private func tableLabel(_ value: String, width: CGFloat? = nil) -> some View {
        Text(value.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func shortID(_ id: String) -> String {
        String(id.prefix(12))
    }
}
