import XCTest
@testable import ContainerDesktop

final class ContainerReleasePlanTests: XCTestCase {
    func testUpdatePlanRequiresManualInstallAndNoSilentInstall() {
        let service = ContainerReleaseService(httpClient: mockClient())
        let latest = latestRelease()

        let plan = service.planUpdate(
            latestRelease: latest,
            installedVersionText: "container version 1.0.0"
        )

        guard case let .updateAvailable(installPlan) = plan.decision else {
            return XCTFail("Expected updateAvailable decision.")
        }

        XCTAssertEqual(plan.installedVersion?.description, "1.0.0")
        XCTAssertEqual(installPlan.asset.name, "container-2.0.0.pkg")
        XCTAssertFalse(installPlan.allowsSilentInstall)
        XCTAssertTrue(installPlan.requiresUserInitiatedInstall)
        XCTAssertFalse(installPlan.instructions.isEmpty)
        XCTAssertTrue(installPlan.instructions.first?.hasPrefix("Download container-2.0.0.pkg") ?? false)
    }

    func testUpdatePlanIsNoActionWhenUpToDate() {
        let service = ContainerReleaseService(httpClient: mockClient())
        let latest = latestRelease()

        let plan = service.planUpdate(
            latestRelease: latest,
            installedVersionText: "container version 2.0.0"
        )

        XCTAssertEqual(plan.decision, .upToDate)
        XCTAssertEqual(plan.installedVersion?.description, "2.0.0")
    }

    func testUpdatePlanAllowsAheadOfRelease() {
        let service = ContainerReleaseService(httpClient: mockClient())
        let latest = latestRelease()

        let plan = service.planUpdate(
            latestRelease: latest,
            installedVersionText: "container version 3.0.0"
        )

        XCTAssertEqual(plan.decision, .installedAhead)
        XCTAssertEqual(plan.installedVersion?.description, "3.0.0")
    }

    func testUpdatePlanUnknownInstalledVersionFallsBackToManualPlan() {
        let service = ContainerReleaseService(httpClient: mockClient())
        let latest = latestRelease()

        let plan = service.planUpdate(
            latestRelease: latest,
            installedVersionText: "unknown version output"
        )

        guard case let .unknownInstalledVersion(installPlan) = plan.decision else {
            return XCTFail("Expected unknownInstalledVersion decision.")
        }

        XCTAssertNotNil(installPlan)
        XCTAssertEqual(installPlan?.asset.name, "container-2.0.0.pkg")
    }

    private func latestRelease() -> AppleContainerRelease {
        AppleContainerRelease(
            id: 9921,
            tagName: "2.0.0",
            name: "Container Desktop 2.0.0",
            changelog: "- parser",
            publishedAt: nil,
            htmlURL: URL(string: "https://github.com/apple/container/releases/tag/2.0.0")!,
            assets: [
                AppleContainerReleaseAsset(
                    id: 301,
                    name: "container-2.0.0.pkg",
                    state: "uploaded",
                    contentType: "application/octet-stream",
                    sizeBytes: 145000000,
                    downloadURL: URL(string: "https://example.com/container-2.0.0.pkg")!
                )
            ]
        )
    }

    private func mockClient() -> ContainerReleaseHTTPClient {
        MockReleaseHTTPClient(payload: Data(), expectedURL: URL(string: "https://api.github.com/repos/apple/container/releases/latest")!)
    }
}

private struct MockReleaseHTTPClient: ContainerReleaseHTTPClient {
    let payload: Data
    let expectedURL: URL

    init(payload: Data, expectedURL: URL) {
        self.payload = payload
        self.expectedURL = expectedURL
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: expectedURL, statusCode: 200, httpVersion: nil, headerFields: [:])!
        return (payload, response)
    }
}
