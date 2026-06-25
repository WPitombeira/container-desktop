import SwiftUI

struct LogsView: View {
    @ObservedObject var store: AuraPlaceholderStore
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            if filteredLogs.isEmpty {
                Text("No logs match the current filter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                List(filteredLogs) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text(entry.level.rawValue)
                            .font(.caption2.monospaced())
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(levelStyle(for: entry.level).opacity(0.15))
                            .foregroundStyle(levelStyle(for: entry.level))
                            .clipShape(Capsule())
                        Text(timestamp(entry.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 98, alignment: .leading)
                        Text(entry.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search logs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear") {
                    store.clearLogs()
                }
            }
        }
        .navigationTitle("Logs")
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
