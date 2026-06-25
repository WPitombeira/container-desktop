import XCTest
@testable import Aura

final class ContainerOutputParserTests: XCTestCase {
    func testParsesJSONContainerRows() {
        let json = """
        [
          {
            "id": "c1",
            "Image": "nginx:1.27",
            "Name": "web",
            "Ports": "8080:80",
            "State": "running",
            "Status": "Up 2 minutes",
            "Created": "2m ago"
          }
        ]
        """

        let containers = ContainerOutputParser().parseContainers(from: json)

        XCTAssertEqual(containers.count, 1)
        XCTAssertEqual(containers.first?.id, "c1")
        XCTAssertEqual(containers.first?.name, "web")
        XCTAssertEqual(containers.first?.image, "nginx:1.27")
        XCTAssertEqual(containers.first?.ports, ["8080:80"])
    }

    func testParsesPipeDelimitedContainerRows() {
        let table = """
        CONTAINER ID | IMAGE | CREATED | STATUS | PORTS | NAME
        -------------------------------------------------------
        c1 | nginx:1.27 | 2m ago | Up | 80/tcp | web
        """

        let containers = ContainerOutputParser().parseContainers(from: table)

        XCTAssertEqual(containers.count, 1)
        XCTAssertEqual(containers.first?.id, "c1")
        XCTAssertEqual(containers.first?.name, "web")
        XCTAssertEqual(containers.first?.image, "nginx:1.27")
    }

    func testParsesImagesVolumesAndNetworks() {
        let parser = ContainerOutputParser()

        XCTAssertEqual(parser.parseImages(from: #"{"images":[{"id":"i1","repository":"nginx","tag":"latest","size":"180MB"}]}"#).first?.repository, "nginx")
        XCTAssertEqual(parser.parseVolumes(from: #"{"volumes":[{"name":"data","driver":"local","mountpoint":"/tmp/data"}]}"#).first?.name, "data")
        XCTAssertEqual(parser.parseNetworks(from: #"{"networks":[{"name":"bridge","driver":"bridge","scope":"local"}]}"#).first?.name, "bridge")
    }
}
