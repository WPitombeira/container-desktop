import XCTest
@testable import ContainerDesktop

private struct MockReleaseHTTPClient: ContainerReleaseHTTPClient {
    let payload: Data
    let statusCode: Int
    let expectedURL: URL

    init(payload: Data, expectedURL: URL, statusCode: Int = 200) {
        self.payload = payload
        self.statusCode = statusCode
        self.expectedURL = expectedURL
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        XCTAssertEqual(request.url, expectedURL)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: [:]
        )!
        return (payload, response)
    }
}

final class ContainerReleaseParsingTests: XCTestCase {
    func testParsesGitHubLatestReleaseResponse() async throws {
        let fixture = #"""
        {
            "id": 9921,
            "tag_name": "v2.0.1",
            "name": "Container Desktop 2.0.1",
            "body": "## Changes\n- Add release parser primitives",
            "published_at": "2026-06-20T12:00:00Z",
            "html_url": "https://github.com/apple/container/releases/tag/v2.0.1",
            "assets": [
                {
                    "id": 301,
                    "name": "container-2.0.1.pkg",
                    "state": "uploaded",
                    "content_type": "application/octet-stream",
                    "size": 145000000,
                    "browser_download_url": "https://github.com/apple/container/releases/download/v2.0.1/container-2.0.1.pkg"
                },
                {
                    "id": 302,
                    "name": "release-notes.txt",
                    "state": "uploaded",
                    "content_type": "text/plain",
                    "size": 2048,
                    "browser_download_url": "https://github.com/apple/container/releases/download/v2.0.1/release-notes.txt"
                }
            ]
        }
        """#

        let data = fixture.data(using: .utf8)!
        let endpoint = URL(string: "https://api.github.com/repos/apple/container/releases/latest")!
        let service = ContainerReleaseService(
            releaseURL: endpoint,
            httpClient: MockReleaseHTTPClient(payload: data, expectedURL: endpoint)
        )

        let release = try await service.fetchLatestRelease()

        XCTAssertEqual(release.id, 9921)
        XCTAssertEqual(release.tagName, "v2.0.1")
        XCTAssertEqual(release.version, ContainerReleaseVersion(rawValue: "2.0.1"))
        XCTAssertEqual(release.assets.count, 2)
        XCTAssertEqual(
            release.assets.first?.name,
            "container-2.0.1.pkg"
        )
        XCTAssertEqual(
            release.assets.first?.downloadURL.absoluteString,
            "https://github.com/apple/container/releases/download/v2.0.1/container-2.0.1.pkg"
        )
        XCTAssertTrue(release.changelog.contains("Add release parser primitives"))
        XCTAssertEqual(
            release.htmlURL.absoluteString,
            "https://github.com/apple/container/releases/tag/v2.0.1"
        )
    }
}
