import Foundation

@MainActor
final class AuraRuntimeStore: ObservableObject {
    @Published private(set) var containers: [AuraContainer] = []
    @Published private(set) var images: [AuraImage] = []
    @Published private(set) var volumes: [AuraVolume] = []
    @Published private(set) var networks: [AuraNetwork] = []
    @Published private(set) var logs: [AuraLogEntry] = []
    @Published private(set) var lastSync: Date = Date()
    @Published private(set) var cliPath: URL?
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var lastError: String?

    private let stateStore: ContainerStateStore

    init() {
        self.stateStore = ContainerStateStore()
        appendLog("Container Desktop runtime store initialized.")
    }

    init(stateStore: ContainerStateStore) {
        self.stateStore = stateStore
        appendLog("Container Desktop runtime store initialized.")
    }

    var runningContainersCount: Int {
        containers.filter { $0.status == .running }.count
    }

    var totalContainersCount: Int {
        containers.count
    }

    var filterText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
    }

    func refresh() {
        Task { await refreshResources() }
    }

    func refreshResources() async {
        isBusy = true
        defer { isBusy = false }

        await stateStore.refreshCLIPath()
        cliPath = stateStore.cliPath

        await stateStore.refreshCollections()
        containers = stateStore.containers.map(Self.container)
        images = stateStore.images.map(Self.image)
        volumes = stateStore.volumes.map(Self.volume)
        networks = stateStore.networks.map(Self.network)
        lastSync = Date()
        lastError = stateStore.lastError

        if let lastError {
            appendLog(lastError, level: .error)
        } else {
            appendLog("Refreshed container resources from local CLI.")
        }
    }

    func clearLogs() {
        logs.removeAll()
        appendLog("Log history cleared.")
    }

    func appendLog(_ message: String, level: AuraLogLevel = .info) {
        logs.insert(AuraLogEntry(timestamp: Date(), level: level, message: message), at: 0)
        if logs.count > 200 {
            logs.removeLast()
        }
    }

    func filteredContainers(_ query: String) -> [AuraContainer] {
        guard !query.isEmpty else { return containers }
        let lowered = query.lowercased()
        return containers.filter { item in
            "\(item.name) \(item.image) \(item.status.badgeLabel) \(item.ports.joined(separator: " "))"
                .lowercased()
                .contains(lowered)
        }
    }

    func filteredImages(_ query: String) -> [AuraImage] {
        guard !query.isEmpty else { return images }
        let lowered = query.lowercased()
        return images.filter { item in
            "\(item.name) \(item.tag) \(item.size) \(item.id)"
                .lowercased()
                .contains(lowered)
        }
    }

    func filteredVolumes(_ query: String) -> [AuraVolume] {
        guard !query.isEmpty else { return volumes }
        let lowered = query.lowercased()
        return volumes.filter { item in
            "\(item.name) \(item.mountPoint) \(item.reclaimPolicy) \(item.size)"
                .lowercased()
                .contains(lowered)
        }
    }

    func filteredNetworks(_ query: String) -> [AuraNetwork] {
        guard !query.isEmpty else { return networks }
        let lowered = query.lowercased()
        return networks.filter { item in
            "\(item.name) \(item.driver) \(item.scope) \(item.subnet)"
                .lowercased()
                .contains(lowered)
        }
    }

    func filteredLogs(_ query: String) -> [AuraLogEntry] {
        guard !query.isEmpty else { return logs }
        let lowered = query.lowercased()
        return logs.filter { entry in
            [entry.message, entry.level.rawValue].contains(where: { $0.lowercased().contains(lowered) })
        }
    }

    func startContainer(_ id: AuraContainer.ID) {
        Task { await runLifecycleCommand(["start", id], label: "Started container '\(displayName(for: id))'.") }
    }

    func stopContainer(_ id: AuraContainer.ID) {
        Task { await runLifecycleCommand(["stop", id], label: "Stopped container '\(displayName(for: id))'.") }
    }

    func removeCompletedContainers() {
        let ids = containers
            .filter { $0.status == .stopped || $0.status == .unhealthy }
            .map(\.id)

        guard !ids.isEmpty else {
            appendLog("No stopped or unhealthy containers to remove.")
            return
        }

        Task {
            for id in ids {
                await runLifecycleCommand(["rm", id], label: "Removed container '\(displayName(for: id))'.", refreshAfterCommand: false)
            }
            await refreshResources()
        }
    }

    private func runLifecycleCommand(
        _ arguments: [String],
        label: String,
        refreshAfterCommand: Bool = true
    ) async {
        isBusy = true
        defer { isBusy = false }

        await stateStore.run(arguments)
        if let output = stateStore.lastExecution, output.exitCode == 0 {
            appendLog(label)
        } else {
            let details = stateStore.lastExecution?.combined.trimmingCharacters(in: .whitespacesAndNewlines)
            appendLog(details?.isEmpty == false ? details! : (stateStore.lastError ?? "Container command failed."), level: .error)
        }

        if refreshAfterCommand {
            await refreshResources()
        }
    }

    private func displayName(for id: AuraContainer.ID) -> String {
        containers.first(where: { $0.id == id })?.name ?? id
    }

    private static func container(_ row: ContainerStateRow) -> AuraContainer {
        AuraContainer(
            id: row.id,
            name: row.name?.nilIfEmpty ?? row.id,
            image: row.image?.nilIfEmpty ?? "unknown image",
            status: AuraRuntimeStatus(containerState: row.state, statusText: row.status),
            ports: row.ports,
            cpu: 0,
            memory: "n/a",
            startedAt: Date()
        )
    }

    private static func image(_ row: ContainerImageRow) -> AuraImage {
        AuraImage(
            id: row.id,
            name: row.repository?.nilIfEmpty ?? row.digest?.nilIfEmpty ?? row.id,
            tag: row.tag?.nilIfEmpty ?? "latest",
            size: row.size?.nilIfEmpty ?? "n/a",
            createdAt: Date()
        )
    }

    private static func volume(_ row: ContainerVolumeRow) -> AuraVolume {
        AuraVolume(
            id: row.id,
            name: row.name?.nilIfEmpty ?? row.id,
            mountPoint: row.mountpoint?.nilIfEmpty ?? "n/a",
            reclaimPolicy: row.driver?.nilIfEmpty ?? row.scope?.nilIfEmpty ?? "local",
            size: "n/a"
        )
    }

    private static func network(_ row: ContainerNetworkRow) -> AuraNetwork {
        let detail = [
            row.isInternal.map { "internal=\($0)" },
            row.attachable.map { "attachable=\($0)" }
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        return AuraNetwork(
            id: row.id,
            name: row.name?.nilIfEmpty ?? row.id,
            driver: row.driver?.nilIfEmpty ?? "n/a",
            scope: row.scope?.nilIfEmpty ?? "local",
            subnet: detail.isEmpty ? "n/a" : detail
        )
    }
}

private extension AuraRuntimeStatus {
    init(containerState: String?, statusText: String?) {
        let combined = [containerState, statusText]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        if combined.contains("unhealthy") {
            self = .unhealthy
        } else if combined.contains("paused") {
            self = .paused
        } else if combined.contains("running") || combined.contains("up") {
            self = .running
        } else {
            self = .stopped
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }
        return value
    }
}
