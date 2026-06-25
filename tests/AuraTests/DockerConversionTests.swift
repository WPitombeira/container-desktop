import XCTest
@testable import Aura

final class DockerConversionTests: XCTestCase {
    private func hasPair(_ command: [String], _ flag: String, _ value: String) -> Bool {
        guard let index = command.firstIndex(of: flag) else { return false }
        return index + 1 < command.count && command[index + 1] == value
    }

    func testConvertsDockerRunFlags() throws {
        let result = try DockerConversionService().convertDockerRunCommand(
            "docker run -d --name web -p 8080:80 -v ./data:/data -e MODE=debug --rm --network host nginx:1.27"
        )

        XCTAssertTrue(result.command.contains("--detach"))
        XCTAssertTrue(result.command.contains("--rm"))
        XCTAssertTrue(hasPair(result.command, "--name", "web"))
        XCTAssertTrue(hasPair(result.command, "--publish", "8080:80"))
        XCTAssertTrue(hasPair(result.command, "--volume", "./data:/data"))
        XCTAssertTrue(hasPair(result.command, "--env", "MODE=debug"))
        XCTAssertTrue(hasPair(result.command, "--network", "host"))
        XCTAssertTrue(hasPair(result.command, "--image", "nginx:1.27"))
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func testReportsUnsupportedDockerSubcommand() {
        XCTAssertThrowsError(try DockerConversionService().convertDockerRunCommand("docker compose up")) { error in
            XCTAssertEqual(error.localizedDescription, DockerConversionError.unsupportedCommand.localizedDescription)
        }
    }

    func testConvertsComposeService() {
        let service = ComposeServiceRow(
            name: "api",
            image: "postgres:16",
            ports: ["5432:5432"],
            volumes: ["dbdata:/var/lib/postgresql/data"],
            env: ["POSTGRES_PASSWORD": "secret"],
            network: "bridge",
            command: ["postgres"],
            detach: true,
            remove: true
        )

        let result = DockerConversionService().convertComposeService(service)

        XCTAssertEqual(result.command.first, "run")
        XCTAssertTrue(hasPair(result.command, "--name", "api"))
        XCTAssertTrue(hasPair(result.command, "--image", "postgres:16"))
        XCTAssertTrue(hasPair(result.command, "--publish", "5432:5432"))
        XCTAssertTrue(hasPair(result.command, "--volume", "dbdata:/var/lib/postgresql/data"))
        XCTAssertTrue(hasPair(result.command, "--env", "POSTGRES_PASSWORD=secret"))
        XCTAssertTrue(hasPair(result.command, "--network", "bridge"))
        XCTAssertTrue(result.command.contains("--detach"))
        XCTAssertTrue(result.command.contains("--rm"))
        XCTAssertTrue(result.command.contains("postgres"))
    }
}
