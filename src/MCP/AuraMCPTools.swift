import Foundation

public struct MCPToolDefinition: Codable, Equatable, Sendable {
    public let name: String
    public let description: String
    public let inputSchema: JSONValue
}

public struct MCPToolResult: Codable, Equatable, Sendable {
    public struct Content: Codable, Equatable, Sendable {
        public let type: String
        public let text: String
    }

    public let content: [Content]
    public let isError: Bool

    public static func text(_ value: String, isError: Bool = false) -> MCPToolResult {
        MCPToolResult(content: [.init(type: "text", text: value)], isError: isError)
    }
}

public enum AuraMCPToolError: Error, LocalizedError, Sendable {
    case missingArgument(String)
    case invalidArgument(String)
    case unsupportedTool(String)
    case fileExists(String)
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .missingArgument(name):
            return "Missing required argument: \(name)."
        case let .invalidArgument(message):
            return message
        case let .unsupportedTool(name):
            return "Unsupported MCP tool: \(name)."
        case let .fileExists(path):
            return "Refusing to overwrite existing file: \(path)."
        case let .commandFailed(message):
            return message
        }
    }
}

public final class AuraMCPToolRegistry {
    private let skillInstaller: AuraSkillInstaller
    private let composeProvisioner: ComposeProjectProvisioner

    public init(
        skillInstaller: AuraSkillInstaller = AuraSkillInstaller(),
        composeProvisioner: ComposeProjectProvisioner = ComposeProjectProvisioner()
    ) {
        self.skillInstaller = skillInstaller
        self.composeProvisioner = composeProvisioner
    }

    public var tools: [MCPToolDefinition] {
        [
            .init(
                name: "aura_install_skill",
                description: "Install or update a project-local Agent skill by writing a .agents/skills/<skill>/SKILL.md file.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object(["type": .string("string"), "description": .string("Skill name or slug.")]),
                        "description": .object(["type": .string("string"), "description": .string("Short skill description for frontmatter.")]),
                        "instructions": .object(["type": .string("string"), "description": .string("Markdown instructions for SKILL.md.")]),
                        "targetDirectory": .object(["type": .string("string"), "description": .string("Optional base skills directory. Defaults to .agents/skills in the current working directory.")]),
                        "overwrite": .object(["type": .string("boolean"), "description": .string("Overwrite an existing SKILL.md when true.")])
                    ]),
                    "required": .array([.string("name"), .string("description"), .string("instructions")])
                ])
            ),
            .init(
                name: "aura_generate_compose_project",
                description: "Generate Docker Compose project files as text without writing to disk.",
                inputSchema: ComposeProjectProvisioner.toolInputSchema
            ),
            .init(
                name: "aura_provision_compose_project",
                description: "Create a maintainable Docker Compose project and optionally run docker compose up -d.",
                inputSchema: ComposeProjectProvisioner.toolInputSchema
            ),
            .init(
                name: "aura_container_standards",
                description: "Return the Docker and Docker Compose standards Aura agents should follow.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([:])
                ])
            )
        ]
    }

    public func callTool(name: String, arguments: [String: JSONValue]) async -> MCPToolResult {
        do {
            switch name {
            case "aura_install_skill":
                let result = try skillInstaller.install(arguments: arguments)
                return .text(result)
            case "aura_generate_compose_project":
                let result = try composeProvisioner.generate(arguments: arguments)
                return .text(result.renderedSummary)
            case "aura_provision_compose_project":
                let result = try await composeProvisioner.provision(arguments: arguments)
                return .text(result)
            case "aura_container_standards":
                return .text(ComposeProjectProvisioner.standardsMarkdown)
            default:
                throw AuraMCPToolError.unsupportedTool(name)
            }
        } catch {
            return .text(error.localizedDescription, isError: true)
        }
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    func requiredString(_ key: String) throws -> String {
        guard let value = self[key] else { throw AuraMCPToolError.missingArgument(key) }
        guard let string = value.stringValue, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuraMCPToolError.invalidArgument("Argument \(key) must be a non-empty string.")
        }
        return string
    }

    func optionalString(_ key: String) throws -> String? {
        guard let value = self[key], value != .null else { return nil }
        guard let string = value.stringValue else {
            throw AuraMCPToolError.invalidArgument("Argument \(key) must be a string.")
        }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func optionalBool(_ key: String, default defaultValue: Bool = false) throws -> Bool {
        guard let value = self[key], value != .null else { return defaultValue }
        guard let bool = value.boolValue else {
            throw AuraMCPToolError.invalidArgument("Argument \(key) must be a boolean.")
        }
        return bool
    }
}
