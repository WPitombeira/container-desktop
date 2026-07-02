import Foundation

public final class AuraSkillInstaller {
    private let fileManager: FileManager
    private let currentDirectory: URL

    public init(
        fileManager: FileManager = .default,
        currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    ) {
        self.fileManager = fileManager
        self.currentDirectory = currentDirectory
    }

    public func install(arguments: [String: JSONValue]) throws -> String {
        let name = try arguments.requiredString("name")
        let description = try arguments.requiredString("description")
        let instructions = try arguments.requiredString("instructions")
        let overwrite = try arguments.optionalBool("overwrite")
        let targetDirectory = try arguments.optionalString("targetDirectory")

        let slug = Self.slugify(name)
        guard !slug.isEmpty else {
            throw AuraMCPToolError.invalidArgument("Skill name must contain at least one letter or number.")
        }

        let baseDirectory = targetDirectory.map { URL(fileURLWithPath: $0, relativeTo: currentDirectory).standardizedFileURL }
            ?? currentDirectory.appendingPathComponent(".agents/skills", isDirectory: true).standardizedFileURL
        let skillDirectory = baseDirectory.appendingPathComponent(slug, isDirectory: true).standardizedFileURL
        let skillFile = skillDirectory.appendingPathComponent("SKILL.md").standardizedFileURL

        guard isDescendant(skillDirectory, of: baseDirectory) else {
            throw AuraMCPToolError.invalidArgument("Skill target must stay inside the configured skills directory.")
        }

        if fileManager.fileExists(atPath: skillFile.path), overwrite == false {
            throw AuraMCPToolError.fileExists(skillFile.path)
        }

        try fileManager.createDirectory(at: skillDirectory, withIntermediateDirectories: true)
        try renderSkillMarkdown(name: slug, description: description, instructions: instructions)
            .write(to: skillFile, atomically: true, encoding: .utf8)

        return """
        Installed skill "\(slug)".
        Path: \(skillFile.path)
        """
    }

    public static func slugify(_ value: String) -> String {
        let lowered = value.lowercased()
        var output = ""
        var previousWasDash = false

        for scalar in lowered.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                output.unicodeScalars.append(scalar)
                previousWasDash = false
            } else if previousWasDash == false {
                output.append("-")
                previousWasDash = true
            }
        }

        return output.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func renderSkillMarkdown(name: String, description: String, instructions: String) -> String {
        """
        ---
        name: \(name)
        description: "\(Self.escapeFrontmatter(description))"
        ---

        \(instructions.trimmingCharacters(in: .whitespacesAndNewlines))
        """
    }

    private static func escapeFrontmatter(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }

    private func isDescendant(_ child: URL, of parent: URL) -> Bool {
        let childPath = child.standardizedFileURL.path
        let parentPath = parent.standardizedFileURL.path
        return childPath == parentPath || childPath.hasPrefix(parentPath + "/")
    }
}
