import SwiftUI

struct VolumesView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        List(filteredVolumes) { volume in
            VStack(alignment: .leading, spacing: 2) {
                Text(volume.name).bold()
                Text("Mount: \(volume.mountPoint)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("Usage \(volume.size)").font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Text("Policy \(volume.reclaimPolicy)").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
        .searchable(text: $searchText, prompt: "Search volumes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Create") {
                    store.appendLog("Volume creation is not implemented yet; use the CLI command path for now.", level: .warning)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Prune") {
                    store.appendLog("Volume pruning is not implemented yet; use the CLI command path for now.", level: .warning)
                }
            }
        }
        .navigationTitle("Volumes")
    }

    private var filteredVolumes: [AuraVolume] {
        store.filteredVolumes(searchText)
    }
}
