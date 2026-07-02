import SwiftUI
import AppKit

struct StatusSummaryBar: View {
    @ObservedObject var store: AuraRuntimeStore
    @ObservedObject var engine: AuraEngine

    private var isCliActive: Bool {
        store.isBusy || engine.isRunning
    }

    private var formattedSync: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: store.lastSync, relativeTo: Date())
    }

    private var cliStatusText: String {
        isCliActive ? "CLI Active" : "CLI Idle"
    }

    private var cliStatusTint: Color {
        isCliActive ? Color.accentColor : Color.secondary
    }

    private var cliSourceName: String? {
        store.cliPath?.lastPathComponent
    }

    var body: some View {
        HStack(spacing: 10) {
            statusChip

            metricPill(icon: "shippingbox", value: "\(store.runningContainersCount)/\(store.totalContainersCount)", label: "Containers")
            metricPill(icon: "photo.on.rectangle", value: "\(store.images.count)", label: "Images")
            metricPill(icon: "network", value: "\(store.networks.count)", label: "Networks")

            if let cliSourceName {
                metricPill(icon: "terminal", value: cliSourceName, label: "CLI")
                    .help("CLI path: \(store.cliPath?.path ?? "Unknown")")
            }

            Spacer()

            Text("Updated \(formattedSync)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.42))
    }

    @ViewBuilder
    private var statusChip: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(cliStatusTint)
                .frame(width: 7, height: 7)
            Text(cliStatusText)
                .font(.caption.weight(.semibold))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 9)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cliStatusTint.opacity(0.13))
        )
        .foregroundStyle(cliStatusTint)
    }

    @ViewBuilder
    private func metricPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
