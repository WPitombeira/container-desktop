import Foundation
import XCTest
@testable import ContainerDesktop

final class ContainerCLIPathResolverTests: XCTestCase {
    func testDiscoverUsesInjectedCandidateDirectory() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let binary = tempDirectory.appendingPathComponent("container")
        let created = FileManager.default.createFile(
            atPath: binary.path,
            contents: Data(),
            attributes: [.posixPermissions: 0o755]
        )
        XCTAssertTrue(created)

        let resolver = ContainerCLIPathResolver(
            candidateDirectories: [tempDirectory.path],
            additionalCandidates: [],
            executableChecker: { FileManager.default.isExecutableFile(atPath: $0.path) }
        )

        switch await resolver.discover() {
        case .success(let url):
            XCTAssertEqual(url.path, binary.path)
        case .failure:
            XCTFail("Expected resolver to find injected container binary.")
        }
    }

    func testDiscoverReportsMissingCLI() async {
        let resolver = ContainerCLIPathResolver(
            candidateDirectories: [],
            additionalCandidates: [],
            executableChecker: { _ in false }
        )

        switch await resolver.discover() {
        case .success:
            XCTFail("Expected missing CLI failure.")
        case .failure(let error):
            XCTAssertEqual(error.localizedDescription, "Container CLI executable was not found.")
        }
    }
}
