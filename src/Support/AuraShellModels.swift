import Foundation

struct AuraContainer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let image: String
    let status: AuraRuntimeStatus
    let ports: [String]
    let cpu: Double
    let memory: String
    let startedAt: Date
}

struct AuraImage: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let tag: String
    let size: String
    let createdAt: Date
}

struct AuraVolume: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let mountPoint: String
    let reclaimPolicy: String
    let size: String
}

struct AuraNetwork: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let driver: String
    let scope: String
    let subnet: String
}

struct AuraLogEntry: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let level: AuraLogLevel
    let message: String
}

enum AuraRuntimeStatus: String, CaseIterable, Codable {
    case running = "Running"
    case stopped = "Stopped"
    case paused = "Paused"
    case unhealthy = "Unhealthy"
}

enum AuraLogLevel: String, CaseIterable, Codable {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

extension AuraRuntimeStatus {
    var sortOrder: Int {
        switch self {
        case .running:
            return 0
        case .paused:
            return 1
        case .unhealthy:
            return 2
        case .stopped:
            return 3
        }
    }

    var badgeLabel: String {
        rawValue
    }
}
