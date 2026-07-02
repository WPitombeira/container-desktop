import Foundation

public struct GeneratedComposeProject: Equatable, Sendable {
    public let projectName: String
    public let projectSlug: String
    public let composeYAML: String
    public let envExample: String
    public let readme: String
    public let gitignore: String

    public var renderedSummary: String {
        """
        # \(projectName)

        ## compose.yaml
        ```yaml
        \(composeYAML)
        ```

        ## .env.example
        ```dotenv
        \(envExample)
        ```

        ## README.md
        ```markdown
        \(readme)
        ```
        """
    }
}

public struct ComposeProjectProvisioner {
    public static let toolInputSchema: JSONValue = .object([
        "type": .string("object"),
        "properties": .object([
            "projectName": .object(["type": .string("string"), "description": .string("Human-readable project name.")]),
            "baseDirectory": .object(["type": .string("string"), "description": .string("Optional parent directory. Defaults to ./aura-containers.")]),
            "services": .object([
                "type": .string("array"),
                "description": .string("Compose service definitions."),
                "items": .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object(["type": .string("string")]),
                        "image": .object(["type": .string("string")]),
                        "ports": .object(["type": .string("array"), "items": .object(["type": .string("string")])]),
                        "volumes": .object(["type": .string("array"), "items": .object(["type": .string("string")])]),
                        "environment": .object(["type": .string("object")]),
                        "command": .object(["type": .string("array"), "items": .object(["type": .string("string")])]),
                        "healthcheck": .object(["type": .string("string")])
                    ]),
                    "required": .array([.string("name"), .string("image")])
                ])
            ]),
            "overwrite": .object(["type": .string("boolean"), "description": .string("Overwrite existing generated files when true.")]),
            "start": .object(["type": .string("boolean"), "description": .string("Run docker compose up -d after writing files.")])
        ]),
        "required": .array([.string("projectName"), .string("services")])
    ])

    public static let standardsMarkdown = """
    # Aura Container Standards

    - Prefer Docker Compose projects over one-off shell scripts for multi-step local services.
    - Keep runtime configuration in `.env` / `.env.example`; do not hard-code secrets in `compose.yaml`.
    - Use stable project, network, volume, and container names derived from the project slug.
    - Add `restart: unless-stopped` for long-lived services.
    - Add healthchecks for services that expose HTTP or database endpoints.
    - Prefer named volumes for durable data and bind mounts only for source/config files.
    - Keep generated projects small: `compose.yaml`, `.env.example`, `.gitignore`, and `README.md`.
    - Start containers only after an explicit `start: true` request.
    """

    private let fileManager: FileManager
    private let currentDirectory: URL
    private let commandRunner: ComposeCommandRunning

    public init(
        fileManager: FileManager = .default,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
        commandRunner: ComposeCommandRunning = ProcessComposeCommandRunner()
    ) {
        self.fileManager = fileManager
        self.currentDirectory = currentDirectory
        self.commandRunner = commandRunner
    }

    public func generate(arguments: [String: JSONValue]) throws -> GeneratedComposeProject {
        let request = try ComposeProjectRequest(arguments: arguments, currentDirectory: currentDirectory)
        return try generate(request: request)
    }

    public func provision(arguments: [String: JSONValue]) async throws -> String {
        let request = try ComposeProjectRequest(arguments: arguments, currentDirectory: currentDirectory)
        let generated = try generate(request: request)
        let projectDirectory = request.projectDirectory(slug: generated.projectSlug)

        try fileManager.createDirectory(at: projectDirectory, withIntermediateDirectories: true)
        try write(generated.composeYAML, to: projectDirectory.appendingPathComponent("compose.yaml"), overwrite: request.overwrite)
        try write(generated.envExample, to: projectDirectory.appendingPathComponent(".env.example"), overwrite: request.overwrite)
        try write(generated.readme, to: projectDirectory.appendingPathComponent("README.md"), overwrite: request.overwrite)
        try write(generated.gitignore, to: projectDirectory.appendingPathComponent(".gitignore"), overwrite: request.overwrite)

        var response = """
        Provisioned Compose project "\(generated.projectSlug)".
        Path: \(projectDirectory.path)
        Files: compose.yaml, .env.example, README.md, .gitignore
        """

        if request.start {
            let output = try await commandRunner.runComposeUp(in: projectDirectory)
            response += "\n\nStarted containers with docker compose up -d.\n\(output)"
        } else {
            response += "\n\nContainers were not started. Call again with start: true or run: docker compose up -d"
        }

        return response
    }

    private func generate(request: ComposeProjectRequest) throws -> GeneratedComposeProject {
        let slug = AuraSkillInstaller.slugify(request.projectName)
        guard !slug.isEmpty else {
            throw AuraMCPToolError.invalidArgument("projectName must contain at least one letter or number.")
        }
        guard request.services.isEmpty == false else {
            throw AuraMCPToolError.invalidArgument("At least one service is required.")
        }

        let envKeys = request.services.flatMap { service in
            service.environment.keys.map { EnvironmentKey(service: service.name, key: $0, value: service.environment[$0] ?? "") }
        }.sorted { $0.variable < $1.variable }

        return GeneratedComposeProject(
            projectName: request.projectName,
            projectSlug: slug,
            composeYAML: renderComposeYAML(slug: slug, services: request.services),
            envExample: renderEnvExample(keys: envKeys),
            readme: renderReadme(projectName: request.projectName, slug: slug, services: request.services),
            gitignore: ".env\n.DS_Store\n"
        )
    }

    private func renderComposeYAML(slug: String, services: [ComposeServiceRequest]) -> String {
        var lines: [String] = [
            "name: \(slug)",
            "",
            "services:"
        ]
        var namedVolumes: Set<String> = []

        for service in services {
            lines.append("  \(service.name):")
            lines.append("    image: \(service.image)")
            lines.append("    container_name: \(slug)-\(service.name)")
            lines.append("    restart: unless-stopped")

            if service.ports.isEmpty == false {
                lines.append("    ports:")
                service.ports.forEach { lines.append("      - \"\($0)\"") }
            }

            if service.environment.isEmpty == false {
                lines.append("    environment:")
                for key in service.environment.keys.sorted() {
                    let variable = EnvironmentKey(service: service.name, key: key, value: service.environment[key] ?? "")
                    lines.append("      \(key): \"${\(variable.variable):-\(variable.composeDefault)}\"")
                }
            }

            if service.volumes.isEmpty == false {
                lines.append("    volumes:")
                for volume in service.volumes {
                    lines.append("      - \(quote(volume))")
                    if let name = namedVolumeName(from: volume) {
                        namedVolumes.insert(name)
                    }
                }
            }

            if service.command.isEmpty == false {
                lines.append("    command:")
                service.command.forEach { lines.append("      - \(quote($0))") }
            }

            if let healthcheck = service.healthcheck {
                lines.append("    healthcheck:")
                lines.append("      test: [\"CMD-SHELL\", \"\(escapeYAMLDoubleQuoted(healthcheck))\"]")
                lines.append("      interval: 30s")
                lines.append("      timeout: 10s")
                lines.append("      retries: 3")
                lines.append("      start_period: 10s")
            }
        }

        lines.append("")
        lines.append("networks:")
        lines.append("  default:")
        lines.append("    name: \(slug)-net")

        if namedVolumes.isEmpty == false {
            lines.append("")
            lines.append("volumes:")
            for volume in namedVolumes.sorted() {
                lines.append("  \(volume):")
                lines.append("    name: \(slug)-\(volume)")
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func renderEnvExample(keys: [EnvironmentKey]) -> String {
        guard keys.isEmpty == false else {
            return "# No environment variables required yet.\n"
        }
        return keys.map { "\($0.variable)=\($0.exampleValue)" }.joined(separator: "\n") + "\n"
    }

    private func renderReadme(projectName: String, slug: String, services: [ComposeServiceRequest]) -> String {
        let serviceList = services.map { "- `\($0.name)`: `\($0.image)`" }.joined(separator: "\n")
        return """
        # \(projectName)

        Generated by Aura MCP.

        ## Services

        \(serviceList)

        ## Run

        ```bash
        cp .env.example .env
        docker compose up -d
        docker compose ps
        ```

        ## Stop

        ```bash
        docker compose down
        ```

        Project slug: `\(slug)`
        """
    }

    private func write(_ content: String, to url: URL, overwrite: Bool) throws {
        if fileManager.fileExists(atPath: url.path), overwrite == false {
            throw AuraMCPToolError.fileExists(url.path)
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func namedVolumeName(from volume: String) -> String? {
        guard let first = volume.split(separator: ":", maxSplits: 1).first else { return nil }
        let name = String(first)
        if name.hasPrefix(".") || name.hasPrefix("/") || name.contains("/") {
            return nil
        }
        return AuraSkillInstaller.slugify(name).replacingOccurrences(of: "-", with: "_")
    }

    private func quote(_ value: String) -> String {
        "\"\(escapeYAMLDoubleQuoted(value))\""
    }

    private func escapeYAMLDoubleQuoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

public protocol ComposeCommandRunning: Sendable {
    func runComposeUp(in directory: URL) async throws -> String
}

public struct ProcessComposeCommandRunner: ComposeCommandRunning {
    public init() {}

    public func runComposeUp(in directory: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["docker", "compose", "up", "-d"]
            process.currentDirectoryURL = directory

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { process in
                let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let combined = [stdoutText, stderrText].filter { $0.isEmpty == false }.joined(separator: "\n")

                if process.terminationStatus == 0 {
                    continuation.resume(returning: combined.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    continuation.resume(throwing: AuraMCPToolError.commandFailed(combined))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: AuraMCPToolError.commandFailed(error.localizedDescription))
            }
        }
    }
}

private struct ComposeProjectRequest: Sendable {
    let projectName: String
    let baseDirectory: URL
    let services: [ComposeServiceRequest]
    let overwrite: Bool
    let start: Bool

    init(arguments: [String: JSONValue], currentDirectory: URL) throws {
        projectName = try arguments.requiredString("projectName")
        overwrite = try arguments.optionalBool("overwrite")
        start = try arguments.optionalBool("start")

        if let base = try arguments.optionalString("baseDirectory") {
            baseDirectory = URL(fileURLWithPath: base, relativeTo: currentDirectory).standardizedFileURL
        } else {
            baseDirectory = currentDirectory.appendingPathComponent("aura-containers", isDirectory: true).standardizedFileURL
        }

        guard let servicesJSON = arguments["services"]?.arrayValue else {
            throw AuraMCPToolError.missingArgument("services")
        }
        services = try servicesJSON.map { try ComposeServiceRequest(json: $0) }
    }

    func projectDirectory(slug: String) -> URL {
        baseDirectory.appendingPathComponent(slug, isDirectory: true).standardizedFileURL
    }
}

private struct ComposeServiceRequest: Sendable {
    let name: String
    let image: String
    let ports: [String]
    let volumes: [String]
    let environment: [String: String]
    let command: [String]
    let healthcheck: String?

    init(json: JSONValue) throws {
        guard let object = json.objectValue else {
            throw AuraMCPToolError.invalidArgument("Each service must be an object.")
        }
        name = AuraSkillInstaller.slugify(try object.requiredString("name"))
        image = try object.requiredString("image")
        ports = try Self.stringArray(from: object["ports"], label: "ports")
        volumes = try Self.stringArray(from: object["volumes"], label: "volumes")
        environment = try Self.stringMap(from: object["environment"], label: "environment")
        command = try Self.stringArray(from: object["command"], label: "command")
        healthcheck = try object.optionalString("healthcheck")

        if name.isEmpty {
            throw AuraMCPToolError.invalidArgument("Service name must contain at least one letter or number.")
        }
    }

    private static func stringArray(from value: JSONValue?, label: String) throws -> [String] {
        guard let value, value != .null else { return [] }
        guard let array = value.arrayValue else {
            throw AuraMCPToolError.invalidArgument("Service \(label) must be an array of strings.")
        }
        return try array.map {
            guard let string = $0.stringValue else {
                throw AuraMCPToolError.invalidArgument("Service \(label) must be an array of strings.")
            }
            return string
        }
    }

    private static func stringMap(from value: JSONValue?, label: String) throws -> [String: String] {
        guard let value, value != .null else { return [:] }
        guard let object = value.objectValue else {
            throw AuraMCPToolError.invalidArgument("Service \(label) must be an object of string values.")
        }
        var result: [String: String] = [:]
        for (key, json) in object {
            guard let string = json.stringValue else {
                throw AuraMCPToolError.invalidArgument("Service \(label) value for \(key) must be a string.")
            }
            result[key] = string
        }
        return result
    }
}

private struct EnvironmentKey: Sendable {
    let service: String
    let key: String
    let value: String

    var variable: String {
        "\(service)_\(key)"
            .uppercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "_")
    }

    var isSecret: Bool {
        let upper = key.uppercased()
        return ["SECRET", "PASSWORD", "TOKEN", "API_KEY", "PRIVATE_KEY"].contains { upper.contains($0) }
    }

    var composeDefault: String {
        if isSecret { return "" }
        return value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    var exampleValue: String {
        isSecret ? "" : value
    }
}
