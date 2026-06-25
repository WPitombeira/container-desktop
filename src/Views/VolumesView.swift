import SwiftUI

struct VolumesView: View {
    @ObservedObject var store: AuraPlaceholderStore
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
                    store.appendLog("Volume create action is waiting for service wiring.")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Prune") {
                    store.appendLog("Volume prune action is waiting for service wiring.")
                }
            }
        }
        .navigationTitle("Volumes")
    }

    private var filteredVolumes: [AuraVolume] {
        store.filteredVolumes(searchText)
    }
}
