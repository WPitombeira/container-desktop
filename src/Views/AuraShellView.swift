import SwiftUI

struct AuraShellView: View {
    @StateObject private var engine = AuraEngine()
    @StateObject private var store = AuraPlaceholderStore()
    @State private var selection: AuraSection = .dashboard

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                StatusSummaryBar(store: store, engine: engine)
                Divider()
                selectedDetail
            }
            .frame(minWidth: 640)
        }
        .navigationSplitViewStyle(.automatic)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: refreshCurrentSection) {
                    Label("Refresh", systemImage: "arrow.triangle.2.circlepath")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh resources for the selected section")
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: checkCliConnection) {
                    Label("Test Container CLI", systemImage: "terminal.fill")
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .help("Ping Container CLI")
            }
        }
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section("Operations") {
                ForEach([
                    AuraSection.dashboard,
                    .containers,
                    .images,
                    .volumes,
                    .networks,
                    .converter,
                    .logs
                ], id: \.id) { section in
                    Label(section.rawValue, systemImage: section.iconName)
                        .tag(section)
                }
            }

            Section("System") {
                Label(AuraSection.settings.rawValue, systemImage: AuraSection.settings.iconName)
                    .tag(AuraSection.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Aura")
    }

    @ViewBuilder
    private var selectedDetail: some View {
        switch selection {
        case .dashboard:
            DashboardView(engine: engine, store: store)
        case .containers:
            ContainersView(store: store)
        case .images:
            ImagesView(store: store)
        case .volumes:
            VolumesView(store: store)
        case .networks:
            NetworksView(store: store)
        case .converter:
            ConverterView(store: store)
        case .logs:
            LogsView(store: store)
        case .settings:
            SettingsView()
        }
    }

    private func refreshCurrentSection() {
        switch selection {
        case .dashboard, .containers, .images, .volumes, .networks, .converter, .logs, .settings:
            Task { @MainActor in
                store.refresh()
                engine.runContainerCommand(["--help"])
            }
        }
    }

    private func checkCliConnection() {
        Task { @MainActor in
            engine.runContainerCommand(["--help"])
        }
    }
}
