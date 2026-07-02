import Foundation

public struct AuraMCPConnectionDescriptor: Equatable, Sendable {
    public let packagePath: String
    public let serverName: String

    public init(packagePath: String, serverName: String = "aura-container-desktop") {
        self.packagePath = packagePath
        self.serverName = serverName
    }

    public var command: String {
        "/usr/bin/swift"
    }

    public var arguments: [String] {
        ["run", "--package-path", packagePath, "AuraMCP"]
    }

    public var shellCommand: String {
        ([command] + arguments).map(Self.shellQuote).joined(separator: " ")
    }

    public var agentConfigJSON: String {
        let payload: [String: JSONValue] = [
            "mcpServers": .object([
                serverName: .object([
                    "command": .string(command),
                    "args": .array(arguments.map { .string($0) })
                ])
            ])
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(JSONValue.object(payload)),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return json
    }

    public static func defaultPackagePath(bundleURL: URL = Bundle.main.bundleURL) -> String {
        let fileManager = FileManager.default
        let current = URL(fileURLWithPath: fileManager.currentDirectoryPath).standardizedFileURL
        if fileManager.fileExists(atPath: current.appendingPathComponent("Package.swift").path) {
            return current.path
        }

        let bundleParent = bundleURL.deletingLastPathComponent()
        let candidates = [
            bundleParent,
            bundleParent.deletingLastPathComponent(),
            bundleParent.deletingLastPathComponent().deletingLastPathComponent()
        ]

        for candidate in candidates {
            if fileManager.fileExists(atPath: candidate.appendingPathComponent("Package.swift").path) {
                return candidate.standardizedFileURL.path
            }
        }

        return current.path
    }

    private static func shellQuote(_ value: String) -> String {
        if value.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "'\"\\$"))) == nil {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
