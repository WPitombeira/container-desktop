import XCTest
@testable import Aura

final class CLIResultModelTests: XCTestCase {
    func testCombinedOutputPrefersAvailableStreams() {
        let stdoutOnly = CLICommandOutput(
            exitCode: 0,
            stdout: "ok",
            stderr: "",
            executedAt: Date(),
            elapsed: 0.1,
            arguments: ["ps"],
            chunks: []
        )
        XCTAssertEqual(stdoutOnly.combined, "ok")

        let both = CLICommandOutput(
            exitCode: 1,
            stdout: "out",
            stderr: "err",
            executedAt: Date(),
            elapsed: 0.1,
            arguments: ["bad"],
            chunks: []
        )
        XCTAssertEqual(both.combined, "out\nerr")
    }

    func testCLIErrorDescriptionsAreUserFacing() {
        XCTAssertEqual(
            ContainerCLIError.commandArgumentsInvalid("bad args").localizedDescription,
            "bad args"
        )
        XCTAssertEqual(
            ContainerCLIError.cliNotFound.localizedDescription,
            "Container CLI executable was not found."
        )
    }
}
