import SwiftUI

struct DashboardView: View {
    @ObservedObject var engine: AuraEngine
    @ObservedObject var store: AuraRuntimeStore

    private var stoppedContainersCount: Int {
        max(0, store.totalContainersCount - store.runningContainersCount)
    }

    private var isLiveOutputEmpty: Bool {
        engine.containerLogs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overviewPanel
                metricsGrid

                HStack(alignment: .top, spacing: 16) {
                    recentActivity
                    liveOutput
                }
            }
            .auraPage()
        }
    }

    private var overviewPanel: some View {
        AuraSurface {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: store.cliPath == nil ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                            .foregroundStyle(store.cliPath == nil ? AuraTheme.warning : AuraTheme.success)
                        Text(store.cliPath == nil ? "Runtime needs attention" : "Runtime ready")
                            .font(.title3.weight(.semibold))
                    }

                    Text(store.cliPath?.path ?? "Apple Container CLI has not been discovered yet. Refresh runtime status before managing resources.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)

                    HStack(spacing: 10) {
                        Button {
                            Task { await store.refreshResources() }
                        } label: {
                            Label("Refresh resources", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(AuraCompactButtonStyle(prominent: true))

                        Button {
                            engine.runContainerCommand(["--help"])
                        } label: {
                            Label("Test CLI", systemImage: "terminal")
                        }
                        .buttonStyle(AuraCompactButtonStyle())
                    }
                    .padding(.top, 2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(store.filterText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(engine.isRunning || store.isBusy ? "Syncing" : "Idle")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(engine.isRunning || store.isBusy ? AuraTheme.accent : .primary)
                }
            }
            .padding(18)
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: metricColumns, spacing: 14) {
            AuraMetricCard(
                title: "Running containers",
                value: "\(store.runningContainersCount)",
                detail: "\(store.totalContainersCount) total containers",
                systemImage: "play.circle.fill",
                tint: AuraTheme.success
            )
            AuraMetricCard(
                title: "Stopped containers",
                value: "\(stoppedContainersCount)",
                detail: "Ready for cleanup or restart",
                systemImage: "stop.circle.fill",
                tint: .secondary
            )
            AuraMetricCard(
                title: "Images",
                value: "\(store.images.count)",
                detail: "Available locally",
                systemImage: "square.stack.3d.up.fill",
                tint: AuraTheme.accent
            )
            AuraMetricCard(
                title: "Volumes",
                value: "\(store.volumes.count)",
                detail: "Persistent storage",
                systemImage: "internaldrive.fill",
                tint: Color(red: 0.48, green: 0.46, blue: 0.92)
            )
            AuraMetricCard(
                title: "Networks",
                value: "\(store.networks.count)",
                detail: "Runtime network contexts",
                systemImage: "network",
                tint: Color(red: 0.0, green: 0.62, blue: 0.72)
            )
        }
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            AuraSectionHeader("Recent activity", subtitle: "Latest runtime events", systemImage: "clock.arrow.circlepath")

            AuraSurface {
                if store.logs.isEmpty {
                    compactEmpty(title: "No runtime events", message: "Refresh resources or run a command to populate activity.")
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.logs.prefix(6)) { entry in
                            HStack(alignment: .top, spacing: 10) {
                                Text(entry.level.rawValue)
                                    .font(.caption2.monospaced().weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(logColor(entry.level).opacity(0.14), in: Capsule())
                                    .foregroundStyle(logColor(entry.level))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.message)
                                        .font(.caption)
                                        .lineLimit(2)
                                    Text(time(entry.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)

                            if entry.id != store.logs.prefix(6).last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var liveOutput: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AuraSectionHeader("Command output", subtitle: "Latest process stream", systemImage: "terminal")
                Button("Clear") {
                    engine.containerLogs = ""
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            AuraSurface {
                ScrollView {
                    if isLiveOutputEmpty {
                        compactEmpty(title: "No command output", message: "Use Test CLI or a resource action to stream process output.")
                    } else {
                        Text(engine.containerLogs)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                    }
                }
                .frame(minHeight: 220, maxHeight: 320)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func compactEmpty(title: String, message: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding(18)
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 190, maximum: 260), spacing: 14)
        ]
    }

    private func logColor(_ level: AuraLogLevel) -> Color {
        switch level {
        case .info:
            AuraTheme.accent
        case .warning:
            AuraTheme.warning
        case .error:
            AuraTheme.danger
        }
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
