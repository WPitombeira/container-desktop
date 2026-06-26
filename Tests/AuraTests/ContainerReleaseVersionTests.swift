import XCTest
@testable import ContainerDesktop

final class ContainerReleaseVersionTests: XCTestCase {
    func testComparesSemanticVersions() {
        let v1 = ContainerReleaseVersion(rawValue: "1.2.3")
        let v2 = ContainerReleaseVersion(rawValue: "1.2.4")
        let v3 = ContainerReleaseVersion(rawValue: "1.2.4-beta")
        let v4 = ContainerReleaseVersion(rawValue: "1.2.4-alpha")

        XCTAssertNotNil(v1)
        XCTAssertNotNil(v2)
        XCTAssertNotNil(v3)
        XCTAssertNotNil(v4)

        XCTAssertLessThan(v1!, v2!)
        XCTAssertLessThan(v3!, v2!)
        XCTAssertLessThan(v4!, v3!)
        XCTAssertEqual(v2!.description, "1.2.4")
    }

    func testParsesVersionFromInstalledOutput() {
        let parser = ContainerVersionParser()
        XCTAssertEqual(
            parser.parse(from: "container version 2.1.0 (build abc)"),
            ContainerReleaseVersion(rawValue: "2.1.0")
        )
        XCTAssertEqual(
            parser.parse(from: "v1.2.3-rc.1"),
            ContainerReleaseVersion(rawValue: "1.2.3-rc.1")
        )
        XCTAssertNil(parser.parse(from: "not-a-version"))
    }
}
