import SwiftUI

struct LogsView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                AuraSectionHeader("Logs", subtitle: "\(filteredLogs.count) matching events", systemImage: "doc.text.magnifyingglass")
                Spacer()
                Button {
                    store.clearLogs()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            if filteredLogs.isEmpty {
                AuraEmptyState(
                    title: searchText.isEmpty ? "No logs yet" : "No logs match this search",
                    message: searchText.isEmpty ? "Runtime events and command warnings will appear here." : "Try a different command, level, or message fragment.",
                    systemImage: "doc.text.magnifyingglass"
                )
            } else {
                AuraSurface {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredLogs) { entry in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(entry.level.rawValue)
                                        .font(.caption2.monospaced().weight(.semibold))
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 7)
                                        .background(levelStyle(for: entry.level).opacity(0.15), in: Capsule())
                                        .foregroundStyle(levelStyle(for: entry.level))
                                    Text(timestamp(entry.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 92, alignment: .leading)
                                    Text(entry.message)
                                        .font(.caption)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)

                                if entry.id != filteredLogs.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
        .auraPage()
        .searchable(text: $searchText, prompt: "Search logs")
    }

    private var filteredLogs: [AuraLogEntry] {
        store.filteredLogs(searchText)
    }

    private func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func levelStyle(for level: AuraLogLevel) -> Color {
        switch level {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}
