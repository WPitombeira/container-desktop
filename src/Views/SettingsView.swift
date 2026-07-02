import SwiftUI
import AppKit
import AuraMCPKit

struct SettingsView: View {
    @State private var autoRefresh = false
    @State private var selectedDefaultSection = AuraSection.dashboard.rawValue
    @StateObject private var onboardingStore = ContainerRuntimeOnboardingStore()
    @AppStorage("runtime.autoCheckForUpdates") private var autoCheckForUpdates = true
    @AppStorage("runtime.autoDownloadUpdates") private var autoDownloadUpdates = false
    @AppStorage("agents.mcpPackagePath") private var mcpPackagePath = AuraMCPConnectionDescriptor.defaultPackagePath()
    @State private var showInstallConfirmation = false
    @State private var changelogExpanded = false

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

            Section("Agents MCP") {
                mcpConnectionPanel
            }

            Section("Apple Container Runtime") {
                statusHeader
                if onboardingStore.isRefreshingRuntime || onboardingStore.isCheckingForUpdates {
                    ProgressView("Syncing runtime metadata")
                        .font(.caption)
                        .controlSize(.small)
                }
                runtimePathAndVersion

                if let statusMessage = onboardingStore.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button("Refresh runtime") {
                        Task { await onboardingStore.refreshRuntimeStatus() }
                    }
                    .disabled(onboardingStore.isRefreshingRuntime)

                    if onboardingStore.hasRuntimeCLI == false {
                        Button("Retry CLI discovery") {
                            Task { await onboardingStore.refreshRuntimeStatus() }
                        }
                        .disabled(onboardingStore.isRefreshingRuntime)
                    }
                }
            }

            Section("Updates") {
                Toggle("Auto-check for updates", isOn: $autoCheckForUpdates)
                Toggle("Auto-download updates", isOn: $autoDownloadUpdates)

                if let checked = onboardingStore.lastCheckedReleaseAt {
                    Text("Last checked: \(checked.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let latestTag = onboardingStore.latestTag {
                    LabeledContent("Latest release", value: latestTag)

                    if onboardingStore.installedVersion == nil {
                        Text("CLI not installed.")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    } else if onboardingStore.updateAvailable {
                        Text("Update available")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Your version: \(onboardingStore.installedVersion ?? "Not detected")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if onboardingStore.installedVersion != nil {
                        Text("CLI version is up to date.")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                } else {
                    Text("No release metadata loaded yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button("Check for updates") {
                        Task {
                            await onboardingStore.checkForUpdates(autoDownload: autoDownloadUpdates)
                        }
                    }
                    .disabled(onboardingStore.isCheckingForUpdates)

                    if onboardingStore.canInstallOrUpdate {
                        Button(onboardingStore.installActionLabel) {
                            showInstallConfirmation = true
                        }
                        .disabled(onboardingStore.isInstalling)
                        .buttonStyle(.borderedProminent)
                    }
                }

                if onboardingStore.isCheckingForUpdates {
                    Text(onboardingStore.updateMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if onboardingStore.hasChangelog {
                Section("Latest release changelog") {
                    DisclosureGroup(isExpanded: $changelogExpanded) {
                        ScrollView(.vertical) {
                            Text(onboardingStore.changelog)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 180)
                    } label: {
                        Text(onboardingStore.latestTag ?? "Apple Container")
                    }
                }
            }

            if let installPlan = onboardingStore.installPlan {
                Section("Install plan") {
                    Text(installPlan.asset.name)
                        .font(.caption)
                        .bold()
                    Text(installPlan.instructions.joined(separator: "\n"))
                        .font(.caption)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Button("Copy download URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(installPlan.downloadURL.absoluteString, forType: .string)
                        }
                        .buttonStyle(.bordered)

                        Button("Open download") {
                            NSWorkspace.shared.open(installPlan.downloadURL)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(16)
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            Task {
                await onboardingStore.refreshRuntimeStatus()
                if autoCheckForUpdates {
                    await onboardingStore.checkForUpdates(autoDownload: autoDownloadUpdates)
                }
            }
        }
        .onChange(of: autoCheckForUpdates) { _, shouldCheck in
            if shouldCheck {
                Task {
                    await onboardingStore.checkForUpdates(autoDownload: autoDownloadUpdates)
                }
            }
        }
        .onChange(of: autoDownloadUpdates) { _, autoDownload in
            if autoDownload, onboardingStore.updateAvailable {
                Task {
                    await onboardingStore.autoDownloadReleaseArtifactIfNeeded()
                }
            }
        }
        .alert(
            "Install Apple Container CLI",
            isPresented: $showInstallConfirmation
        ) {
            Button("Install", role: .destructive) {
                Task {
                    await onboardingStore.installLatestCLI()
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            if let latest = onboardingStore.latestRelease {
                Text("Install Apple Container \(latest.tagName)?")
            } else {
                Text("Please check for updates first to locate an installable release.")
            }
        }
    }

    @ViewBuilder
    private var statusHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: onboardingStore.hasRuntimeCLI ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .foregroundStyle(onboardingStore.hasRuntimeCLI ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("CLI runtime")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(onboardingStore.updateMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var runtimePathAndVersion: some View {
        if let cliPath = onboardingStore.cliPath {
            LabeledContent("Path", value: cliPath.path)
        } else {
            Text("Apple Container CLI was not found in standard locations.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if let installedVersion = onboardingStore.installedVersion {
            LabeledContent("Version", value: installedVersion)
        }
    }

    private var mcpDescriptor: AuraMCPConnectionDescriptor {
        AuraMCPConnectionDescriptor(packagePath: mcpPackagePath)
    }

    private var isMCPPackagePathValid: Bool {
        let packageFile = URL(fileURLWithPath: mcpPackagePath).appendingPathComponent("Package.swift")
        return FileManager.default.fileExists(atPath: packageFile.path)
    }

    private var mcpConnectionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
                Image(systemName: isMCPPackagePathValid ? "point.3.connected.trianglepath.dotted" : "exclamationmark.triangle.fill")
                    .foregroundStyle(isMCPPackagePathValid ? AuraTheme.success : AuraTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("MCP server")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    Text(isMCPPackagePathValid ? "Ready for local Agents" : "Package.swift was not found at this path")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
                Spacer()
                Text("stdio")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AuraTheme.accent.opacity(0.12), in: Capsule())
                    .foregroundStyle(AuraTheme.accent)
            }

            TextField("Package path", text: $mcpPackagePath)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            VStack(alignment: .leading, spacing: 7) {
                Text("Server command")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(mcpDescriptor.shellCommand)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Agent config")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView(.vertical) {
                    Text(mcpDescriptor.agentConfigJSON)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 170)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    copyToPasteboard(mcpDescriptor.agentConfigJSON)
                } label: {
                    Label("Copy config", systemImage: "doc.on.doc")
                }
                .buttonStyle(AuraCompactButtonStyle(prominent: true))

                Button {
                    copyToPasteboard(mcpDescriptor.shellCommand)
                } label: {
                    Label("Copy command", systemImage: "terminal")
                }
                .buttonStyle(AuraCompactButtonStyle())

                Button {
                    mcpPackagePath = AuraMCPConnectionDescriptor.defaultPackagePath()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(AuraCompactButtonStyle())

                Button {
                    NSWorkspace.shared.open(URL(fileURLWithPath: mcpPackagePath))
                } label: {
                    Label("Open", systemImage: "folder")
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            HStack(spacing: 8) {
                toolChip("Skills")
                toolChip("Compose")
                toolChip("Provisioning")
                toolChip("Standards")
            }
        }
    }

    private func toolChip(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.09), in: Capsule())
            .foregroundStyle(.secondary)
    }

    private func copyToPasteboard(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }
}
