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
                    .font(.subheadline.weight(.semibold))
                Text("Local container control")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            VStack(spacing: 0) {
                detailHeader
                StatusSummaryBar(store: store, engine: engine)
                Divider()
                selectedDetail
            }
            .frame(minWidth: 760)
        }
        .navigationSplitViewStyle(.automatic)
        .task {
            await store.refreshResources()
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
        .frame(minWidth: 230, idealWidth: 250)
        .scrollContentBackground(.automatic)
        .navigationTitle("Container Desktop")
    }

    private var detailHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(selection.rawValue)
                    .font(.system(size: 24, weight: .semibold))
                Text(sectionSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: refreshCurrentSection) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(AuraCompactButtonStyle())
            .keyboardShortcut("r", modifiers: .command)
            .help("Refresh resources")

            Button(action: checkCliConnection) {
                Label("Test CLI", systemImage: "terminal")
            }
            .buttonStyle(AuraCompactButtonStyle(prominent: true))
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .help("Run container --help")
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .background(.regularMaterial)
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

    private var sectionSubtitle: String {
        switch selection {
        case .dashboard:
            "Runtime overview, health, and recent activity"
        case .containers:
            "Inspect and control local containers"
        case .images:
            "Review images available to the local runtime"
        case .volumes:
            "Track persistent storage and reclaim policy"
        case .networks:
            "Inspect local container networking"
        case .converter:
            "Translate Docker commands for Apple Container"
        case .logs:
            "Audit runtime events and command output"
        case .settings:
            "Runtime, updates, and Agent MCP connection"
        }
    }
}
