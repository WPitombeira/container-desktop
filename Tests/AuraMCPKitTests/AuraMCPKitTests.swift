import XCTest
import AuraMCPKit

final class AuraMCPKitTests: XCTestCase {
    func testConnectionDescriptorBuildsAgentConfig() throws {
        let descriptor = AuraMCPConnectionDescriptor(packagePath: "/tmp/Container Desktop")

        XCTAssertEqual(descriptor.command, "/usr/bin/swift")
        XCTAssertEqual(descriptor.arguments, ["run", "--package-path", "/tmp/Container Desktop", "AuraMCP"])
        XCTAssertTrue(descriptor.shellCommand.contains("'/tmp/Container Desktop'"))
        XCTAssertTrue(descriptor.agentConfigJSON.contains("\"aura-container-desktop\""))
        XCTAssertTrue(descriptor.agentConfigJSON.contains("\"AuraMCP\""))
    }

    func testSkillInstallerWritesSkillMarkdown() throws {
        let temp = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let installer = AuraSkillInstaller(currentDirectory: temp)
        let output = try installer.install(arguments: [
            "name": .string("Docker Maintainer"),
            "description": .string("Provision containers consistently."),
            "instructions": .string("# Docker Maintainer\n\nUse compose projects."),
            "overwrite": .bool(false)
        ])

        let skillPath = temp.appendingPathComponent(".agents/skills/docker-maintainer/SKILL.md")
        let content = try String(contentsOf: skillPath, encoding: .utf8)
        XCTAssertTrue(output.contains(skillPath.path))
        XCTAssertTrue(content.contains("name: docker-maintainer"))
        XCTAssertTrue(content.contains("Use compose projects."))
    }

    func testComposeGeneratorSeparatesSecretsAndNamedVolumes() throws {
        let temp = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let provisioner = ComposeProjectProvisioner(currentDirectory: temp)
        let generated = try provisioner.generate(arguments: [
            "projectName": .string("Agent API"),
            "services": .array([
                .object([
                    "name": .string("api"),
                    "image": .string("ghcr.io/example/api:latest"),
                    "ports": .array([.string("8080:8080")]),
                    "volumes": .array([.string("api_data:/var/lib/api")]),
                    "environment": .object([
                        "MODE": .string("production"),
                        "API_TOKEN": .string("secret-token")
                    ]),
                    "healthcheck": .string("curl -fsS http://localhost:8080/health || exit 1")
                ])
            ])
        ])

        XCTAssertTrue(generated.composeYAML.contains("name: agent-api"))
        XCTAssertTrue(generated.composeYAML.contains("restart: unless-stopped"))
        XCTAssertTrue(generated.composeYAML.contains("API_TOKEN: \"${API_API_TOKEN:-}\""))
        XCTAssertTrue(generated.composeYAML.contains("api_data:"))
        XCTAssertTrue(generated.envExample.contains("API_MODE=production"))
        XCTAssertTrue(generated.envExample.contains("API_API_TOKEN="))
        XCTAssertFalse(generated.envExample.contains("secret-token"))
    }

    func testComposeProvisionWritesFilesWithoutStartingByDefault() async throws {
        let temp = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let provisioner = ComposeProjectProvisioner(currentDirectory: temp)
        let output = try await provisioner.provision(arguments: [
            "projectName": .string("Cache Stack"),
            "services": .array([
                .object([
                    "name": .string("redis"),
                    "image": .string("redis:7"),
                    "ports": .array([.string("6379:6379")])
                ])
            ])
        ])

        let projectDirectory = temp.appendingPathComponent("aura-containers/cache-stack")
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectDirectory.appendingPathComponent("compose.yaml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectDirectory.appendingPathComponent(".env.example").path))
        XCTAssertTrue(output.contains("Containers were not started"))
    }

    func testRegistryListsAndCallsStandardsTool() async {
        let registry = AuraMCPToolRegistry()
        XCTAssertTrue(registry.tools.contains { $0.name == "aura_container_standards" })

        let result = await registry.callTool(name: "aura_container_standards", arguments: [:])
        XCTAssertFalse(result.isError)
        XCTAssertTrue(result.content.first?.text.contains("Docker Compose projects") == true)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AuraMCPKitTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
