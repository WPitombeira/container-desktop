import SwiftUI

struct VolumesView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AuraSectionHeader("Volumes", subtitle: "\(filteredVolumes.count) storage volumes", systemImage: "internaldrive")
                Spacer()
                Button {
                    store.appendLog("Volume creation is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Create", systemImage: "plus")
                }
                .buttonStyle(AuraCompactButtonStyle(prominent: true))

                Button {
                    store.appendLog("Volume pruning is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Prune", systemImage: "sparkles")
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            if filteredVolumes.isEmpty {
                AuraEmptyState(
                    title: searchText.isEmpty ? "No volumes found" : "No volumes match this search",
                    message: searchText.isEmpty ? "Named volumes will appear here when containers create persistent storage." : "Try a different volume name, mount point, or reclaim policy.",
                    systemImage: "internaldrive"
                )
            } else {
                AuraSurface {
                    VStack(spacing: 0) {
                        header
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredVolumes) { volume in
                                    row(volume)
                                    if volume.id != filteredVolumes.last?.id {
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
        .searchable(text: $searchText, prompt: "Search volumes")
    }

    private var header: some View {
        HStack(spacing: 14) {
            tableLabel("Name")
            tableLabel("Mount point")
            tableLabel("Policy", width: 120)
            tableLabel("Usage", width: 100)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06))
    }

    private func row(_ volume: AuraVolume) -> some View {
        HStack(spacing: 14) {
            Text(volume.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(volume.mountPoint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(volume.reclaimPolicy)
                .font(.caption)
                .frame(width: 120, alignment: .leading)

            Text(volume.size)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var filteredVolumes: [AuraVolume] {
        store.filteredVolumes(searchText)
    }

    private func tableLabel(_ value: String, width: CGFloat? = nil) -> some View {
        Text(value.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}
