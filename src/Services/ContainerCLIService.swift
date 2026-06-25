import Foundation

public final class ContainerCLIService {
    private let resolver: ContainerCLIPathResolver
    private let runner: ContainerCommandRunning
    private let parser: ContainerOutputParser

    public init(
        resolver: ContainerCLIPathResolver = ContainerCLIPathResolver(),
        runner: ContainerCommandRunning = ContainerCommandRunner(),
        parser: ContainerOutputParser = ContainerOutputParser()
    ) {
        self.resolver = resolver
        self.runner = runner
        self.parser = parser
    }

    public func discoverPath() async -> Result<URL, ContainerCLIError> {
        await resolver.discover()
    }

    public func execute(
        _ arguments: [String],
        workingDirectory: URL? = nil
    ) async throws -> CLICommandOutput {
        let resolved = try await discoverPath().get()
        return try await runner.run(
            executablePath: resolved,
            arguments: arguments,
            workingDirectory: workingDirectory
        )
    }

    public func listContainers() async throws -> [ContainerStateRow] {
        do {
            let output = try await execute(["ps"])
            return parser.parseContainers(from: output.combined)
        } catch {
            throw error
        }
    }

    public func listImages() async throws -> [ContainerImageRow] {
        let output = try await execute(["images"])
        return parser.parseImages(from: output.combined)
    }

    public func listVolumes() async throws -> [ContainerVolumeRow] {
        let output = try await execute(["volume", "ls"])
        return parser.parseVolumes(from: output.combined)
    }

    public func listNetworks() async throws -> [ContainerNetworkRow] {
        let output = try await execute(["network", "ls"])
        return parser.parseNetworks(from: output.combined)
    }
}
