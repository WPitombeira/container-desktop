import SwiftUI

struct SettingsView: View {
    @State private var autoRefresh = false
    @State private var selectedDefaultSection = AuraSection.dashboard.rawValue

    var body: some View {
        Form {
            Section("General") {
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
                Text("Container execution, conversion, CLI discovery, and resource refresh are service-backed. Some advanced lifecycle actions still fall back to the command-line workflow.")
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
