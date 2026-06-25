import SwiftUI

struct DashboardView: View {
    @ObservedObject var engine: AuraEngine
    @ObservedObject var store: AuraPlaceholderStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    metricCard(title: "Running Containers", value: "\(store.runningContainersCount)")
                    metricCard(title: "Stopped Containers", value: "\(max(0, store.totalContainersCount - store.runningContainersCount))")
                    metricCard(title: "Images", value: "\(store.images.count)")
                    metricCard(title: "Networks", value: "\(store.networks.count)")
                }

                GroupBox("Live Output") {
                    if engine.containerLogs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No command output yet.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(8)
                    } else {
                        Text(engine.containerLogs)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
                .frame(height: 240)

                if let error = engine.error {
                    GroupBox("System Error") {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    @ViewBuilder
    private func metricCard(title: String, value: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.title2)
                    .bold()
                Text(title)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }
}
