import SwiftUI

struct StatusSummaryBar: View {
    @ObservedObject var store: AuraRuntimeStore
    @ObservedObject var engine: AuraEngine

    private var formattedSync: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: store.lastSync, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 16) {
            Label(
                store.isBusy || engine.isRunning ? "CLI Active" : "CLI Idle",
                systemImage: store.isBusy || engine.isRunning ? "bolt.fill" : "pause.fill"
            )
            .labelStyle(.titleAndIcon)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule().fill(store.isBusy || engine.isRunning ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(store.isBusy || engine.isRunning ? Color.accentColor : Color.secondary)

            Divider().frame(height: 16)

            Text("Containers: \(store.runningContainersCount)/\(store.totalContainersCount)")
                .font(.caption)

            Divider().frame(height: 16)

            Text("Images: \(store.images.count)")
                .font(.caption)

            if let cliPath = store.cliPath {
                Divider().frame(height: 16)
                Text(cliPath.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Resources \(formattedSync)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
    }
}
