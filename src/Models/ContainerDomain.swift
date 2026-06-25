import Foundation

public struct CLICommandOutput: Sendable {
    public struct StreamChunk: Sendable {
        public let stream: StreamType
        public let text: String

        public enum StreamType: String, Sendable {
            case standardOutput
            case standardError
        }
    }

    public let exitCode: Int
    public let stdout: String
    public let stderr: String
    public let executedAt: Date
    public let elapsed: TimeInterval
    public let arguments: [String]
    public let chunks: [StreamChunk]

    public init(
        exitCode: Int,
        stdout: String,
        stderr: String,
        executedAt: Date,
        elapsed: TimeInterval,
        arguments: [String],
        chunks: [StreamChunk]
    ) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.executedAt = executedAt
        self.elapsed = elapsed
        self.arguments = arguments
        self.chunks = chunks
    }

    public var combined: String {
        if stdout.isEmpty { return stderr }
        if stderr.isEmpty { return stdout }
        return "\(stdout)\n\(stderr)"
    }
}

public enum ContainerCLIError: Error, LocalizedError, Sendable {
    case cliNotFound
    case commandFailed(String)
    case commandArgumentsInvalid(String)
    case outputParseError(String)

    public var errorDescription: String? {
        switch self {
        case .cliNotFound:
            return "Container CLI executable was not found."
        case let .commandFailed(message), let .commandArgumentsInvalid(message), let .outputParseError(message):
            return message
        }
    }
}

public struct ContainerStateRow: Identifiable, Hashable, Sendable {
    public let id: String
    public let image: String?
    public let name: String?
    public let command: String?
    public let state: String?
    public let status: String?
    public let created: String?
    public let ports: [String]

    public init(
        id: String,
        image: String?,
        name: String?,
        command: String?,
        state: String?,
        status: String?,
        created: String?,
        ports: [String]
    ) {
        self.id = id
        self.image = image
        self.name = name
        self.command = command
        self.state = state
        self.status = status
        self.created = created
        self.ports = ports
    }
}

public struct ContainerImageRow: Identifiable, Hashable, Sendable {
    public let id: String
    public let repository: String?
    public let tag: String?
    public let digest: String?
    public let size: String?
    public let created: String?

    public init(
        id: String,
        repository: String?,
        tag: String?,
        digest: String?,
        size: String?,
        created: String?
    ) {
        self.id = id
        self.repository = repository
        self.tag = tag
        self.digest = digest
        self.size = size
        self.created = created
    }
}

public struct ContainerVolumeRow: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String?
    public let driver: String?
    public let scope: String?
    public let mountpoint: String?

    public init(
        id: String,
        name: String?,
        driver: String?,
        scope: String?,
        mountpoint: String?
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.mountpoint = mountpoint
    }
}

public struct ContainerNetworkRow: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String?
    public let driver: String?
    public let scope: String?
    public let internal: String?
    public let attachable: String?

    public init(
        id: String,
        name: String?,
        driver: String?,
        scope: String?,
        internal: String?,
        attachable: String?
    ) {
        self.id = id
        self.name = name
        self.driver = driver
        self.scope = scope
        self.internal = internal
        self.attachable = attachable
    }
}

public struct ComposeServiceRow: Sendable {
    public let name: String
    public let image: String
    public let ports: [String]
    public let volumes: [String]
    public let env: [String: String]
    public let network: String?
    public let command: [String]
    public let detach: Bool
    public let remove: Bool

    public init(
        name: String,
        image: String,
        ports: [String] = [],
        volumes: [String] = [],
        env: [String: String] = [:],
        network: String? = nil,
        command: [String] = [],
        detach: Bool = false,
        remove: Bool = false
    ) {
        self.name = name
        self.image = image
        self.ports = ports
        self.volumes = volumes
        self.env = env
        self.network = network
        self.command = command
        self.detach = detach
        self.remove = remove
    }
}

public struct DockerConversionResult: Sendable {
    public let command: [String]
    public let warnings: [String]

    public init(command: [String], warnings: [String]) {
        self.command = command
        self.warnings = warnings
    }
}
