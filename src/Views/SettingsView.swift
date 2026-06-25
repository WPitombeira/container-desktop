import SwiftUI

struct SettingsView: View {
    @State private var usePlaceholderData = true
    @State private var autoRefresh = false
    @State private var selectedDefaultSection = AuraSection.dashboard.rawValue

    var body: some View {
        Form {
            Section("General") {
                Toggle("Use placeholder data while core services connect", isOn: $usePlaceholderData)
                Toggle("Auto-refresh resource list", isOn: $autoRefresh)
            }

            Section("Default start section") {
                Picker("Open on", selection: $selectedDefaultSection) {
                    ForEach(AuraSection.allCases) { section in
                        Text(section.rawValue).tag(section.rawValue)
                    }
                }
            }

            Section("Runtime Notes") {
                Text("Container execution, conversion, and daemon discovery remain service-backed and will replace these placeholders when the engine layer is ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: 560)
    }
}
