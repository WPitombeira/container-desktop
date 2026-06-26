import SwiftUI

struct DashboardView: View {
    @ObservedObject var engine: AuraEngine
    @ObservedObject var store: AuraRuntimeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(columns: metricColumns, spacing: 12) {
                    metricCard(title: "Running Containers", value: "\(store.runningContainersCount)")
                    metricCard(title: "Stopped Containers", value: "\(max(0, store.totalContainersCount - store.runningContainersCount))")
                    metricCard(title: "Images", value: "\(store.images.count)")
                    metricCard(title: "Networks", value: "\(store.networks.count)")
                }
                .frame(maxWidth: .infinity)

                GroupBox("Live Output") {
                    ScrollView {
                        if isLiveOutputEmpty {
                            Text("No command output yet.")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                        } else {
                            Text(engine.containerLogs)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                    }
                    .frame(minHeight: 210)
                }
                .frame(maxWidth: .infinity)

                if let error = engine.error {
                    GroupBox("System Error") {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear output") {
                    engine.containerLogs = ""
                }
            }
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
        .frame(maxWidth: .infinity, minHeight: 86)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 172, maximum: 260), spacing: 12),
        ]
    }

    private var isLiveOutputEmpty: Bool {
        engine.containerLogs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
