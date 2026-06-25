import Foundation

@MainActor
final class AuraPlaceholderStore: ObservableObject {
    @Published var containers: [AuraContainer]
    @Published var images: [AuraImage]
    @Published var volumes: [AuraVolume]
    @Published var networks: [AuraNetwork]
    @Published var logs: [AuraLogEntry]
    @Published var lastSync: Date

    init(
        now: Date = Date(),
        containers: [AuraContainer]? = nil,
        images: [AuraImage]? = nil,
        volumes: [AuraVolume]? = nil,
        networks: [AuraNetwork]? = nil,
        logs: [AuraLogEntry]? = nil,
        lastSync: Date? = nil
    ) {
        self.containers = containers ?? [
            AuraContainer(
                name: "api-core",
                image: "node:22-alpine",
                status: .running,
                ports: ["8080:8080"],
                cpu: 0.24,
                memory: "178 MB",
                startedAt: now.addingTimeInterval(-3_600)
            ),
            AuraContainer(
                name: "worker-queue",
                image: "redis:7",
                status: .running,
                ports: ["6379:6379"],
                cpu: 0.06,
                memory: "64 MB",
                startedAt: now.addingTimeInterval(-7_200)
            ),
            AuraContainer(
                name: "web-proxy",
                image: "nginx:1.27",
                status: .stopped,
                ports: ["80:8080", "443:8443"],
                cpu: 0.00,
                memory: "0 MB",
                startedAt: now.addingTimeInterval(-180_000)
            )
        ]
        self.images = images ?? [
            AuraImage(name: "nginx", tag: "1.27", size: "186 MB", createdAt: now.addingTimeInterval(-14_000)),
            AuraImage(name: "redis", tag: "7", size: "112 MB", createdAt: now.addingTimeInterval(-30_000)),
            AuraImage(name: "node", tag: "22-alpine", size: "145 MB", createdAt: now.addingTimeInterval(-40_000))
        ]
        self.volumes = volumes ?? [
            AuraVolume(name: "aura-cache", mountPoint: "/var/lib/aura/cache", reclaimPolicy: "local", size: "2.1 GB"),
            AuraVolume(name: "postgres-data", mountPoint: "/var/lib/postgres/data", reclaimPolicy: "local", size: "7.4 GB"),
            AuraVolume(name: "mq-spool", mountPoint: "/var/lib/rabbitmq/mnesia", reclaimPolicy: "local", size: "1.8 GB")
        ]
        self.networks = networks ?? [
            AuraNetwork(name: "aura-bridge", driver: "bridge", scope: "local", subnet: "172.20.0.0/16"),
            AuraNetwork(name: "backend", driver: "bridge", scope: "local", subnet: "172.30.0.0/16"),
            AuraNetwork(name: "public", driver: "bridge", scope: "local", subnet: "10.10.0.0/24")
        ]
        self.logs = logs ?? [
            AuraLogEntry(timestamp: now.addingTimeInterval(-180), level: .info, message: "Container CLI bridge initialized."),
            AuraLogEntry(timestamp: now.addingTimeInterval(-110), level: .info, message: "Refreshed local resource inventory."),
            AuraLogEntry(timestamp: now.addingTimeInterval(-40), level: .warning, message: "web-proxy is stopped; command line profile requires restart.")
        ]
        self.lastSync = lastSync ?? now
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
        lastSync = Date()
        if let first = containers.first(where: { $0.status == .stopped }) {
            updateContainerStatus(first.id, to: .running, memory: first.memory, cpu: first.cpu)
        } else if let running = containers.last(where: { $0.status == .running }) {
            updateContainerStatus(running.id, to: .paused, memory: running.memory, cpu: running.cpu)
        }
        appendLog("Resource inventory refreshed from local bridge.")
    }

    func clearLogs() {
        logs.removeAll()
        appendLog("Log history cleared.")
    }

    func appendLog(_ message: String, level: AuraLogLevel = .info) {
        logs.insert(AuraLogEntry(timestamp: Date(), level: level, message: message), at: 0)
        if logs.count > 100 {
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
            "\(item.name) \(item.tag) \(item.size)"
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

    private func updateContainerStatus(_ id: UUID, to status: AuraRuntimeStatus, memory: String, cpu: Double) {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            return
        }
        containers[index] = AuraContainer(
            name: containers[index].name,
            image: containers[index].image,
            status: status,
            ports: containers[index].ports,
            cpu: cpu,
            memory: memory,
            startedAt: containers[index].startedAt
        )
    }

    func startContainer(_ id: AuraContainer.ID) {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            return
        }
        let target = containers[index]
        containers[index] = AuraContainer(
            name: target.name,
            image: target.image,
            status: .running,
            ports: target.ports,
            cpu: max(target.cpu, 0.01),
            memory: target.memory == "0 MB" ? "8 MB" : target.memory,
            startedAt: Date()
        )
        appendLog("Started container '\(target.name)'.")
    }

    func stopContainer(_ id: AuraContainer.ID) {
        guard let index = containers.firstIndex(where: { $0.id == id }) else {
            return
        }
        let target = containers[index]
        containers[index] = AuraContainer(
            name: target.name,
            image: target.image,
            status: .stopped,
            ports: target.ports,
            cpu: 0,
            memory: "0 MB",
            startedAt: target.startedAt
        )
        appendLog("Stopped container '\(target.name)'.")
    }

    func removeCompletedContainers() {
        let before = containers.count
        containers.removeAll { $0.status == .stopped || $0.status == .unhealthy }
        let removed = before - containers.count
        appendLog(removed > 0 ? "Removed \(removed) finished containers." : "No containers to remove.")
    }
}
