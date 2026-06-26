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

    private var cliStatusIcon: String {
        isCliActive ? "bolt.fill" : "pause.fill"
    }

    private var cliStatusTint: Color {
        isCliActive ? Color.accentColor : Color.secondary
    }

    private var cliSourceName: String? {
        store.cliPath?.lastPathComponent
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                statusChip

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        metricPill(icon: "shippingbox", value: "\(store.runningContainersCount)/\(store.totalContainersCount)", label: "Containers")
                        metricPill(icon: "photo", value: "\(store.images.count)", label: "Images")

                        if let cliSourceName {
                            metricPill(icon: "terminal", value: cliSourceName, label: "CLI")
                                .help("CLI path: \(store.cliPath?.path ?? "Unknown")")
                        }
                    }
                    .padding(.horizontal, 2)
                }

                Text("Updated \(formattedSync)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private var statusChip: some View {
        Label(cliStatusText, systemImage: cliStatusIcon)
            .labelStyle(.titleAndIcon)
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(
                Capsule().fill(cliStatusTint.opacity(0.16))
            )
            .foregroundStyle(cliStatusTint)
    }

    @ViewBuilder
    private func metricPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption).bold()
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.thinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
