import AppKit
import SwiftUI

struct AuraShellView: View {
    @StateObject private var engine = AuraEngine()
    @StateObject private var store = AuraRuntimeStore()
    @State private var selection: AuraSection = .dashboard

    private let sidebarSections: [AuraSection] = [
        .dashboard,
        .containers,
        .images,
        .volumes,
        .networks,
        .converter,
        .logs
    ]

    private var appIcon: some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 17, height: 17)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            appIcon
            VStack(alignment: .leading, spacing: 2) {
                Text("Container Desktop")
                    .font(.headline)
                Text("Container management")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

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
        .task {
            await store.refreshResources()
        }
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
            Section {
                ForEach(sidebarSections, id: \.id) { section in
                    Label(section.rawValue, systemImage: section.iconName)
                        .tag(section)
                        .contentShape(Rectangle())
                }
            } header: {
                sidebarHeader
            }

            Section("System") {
                Label(AuraSection.settings.rawValue, systemImage: AuraSection.settings.iconName)
                    .tag(AuraSection.settings)
                    .contentShape(Rectangle())
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 230)
        .scrollContentBackground(.automatic)
        .navigationTitle("Container Desktop")
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
                await store.refreshResources()
            }
        }
    }

    private func checkCliConnection() {
        Task { @MainActor in
            engine.runContainerCommand(["--help"])
        }
    }
}
