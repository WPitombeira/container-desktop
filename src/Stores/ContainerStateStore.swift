import Foundation

@MainActor
public final class ContainerStateStore: ObservableObject {
    @Published public private(set) var cliPath: URL?
    @Published public private(set) var isBusy: Bool = false
    @Published public private(set) var lastExecution: CLICommandOutput?
    @Published public private(set) var containers: [ContainerStateRow] = []
    @Published public private(set) var images: [ContainerImageRow] = []
    @Published public private(set) var volumes: [ContainerVolumeRow] = []
    @Published public private(set) var networks: [ContainerNetworkRow] = []
    @Published public private(set) var lastError: String?

    private let service: ContainerCLIService

    public init(service: ContainerCLIService = ContainerCLIService()) {
        self.service = service
    }

    public func refreshCLIPath() async {
        isBusy = true
        defer { isBusy = false }

        switch await service.discoverPath() {
        case .success(let url):
            cliPath = url
            lastError = nil
        case .failure(let error):
            cliPath = nil
            lastError = error.localizedDescription
        }
    }

    public func run(_ arguments: [String]) async {
        isBusy = true
        defer { isBusy = false }

        do {
            let output = try await service.execute(arguments)
            lastExecution = output
            lastError = output.exitCode == 0 ? nil : "Command failed with exit code \(output.exitCode)."
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func refreshCollections() async {
        isBusy = true
        defer { isBusy = false }

        do {
            async let containers = service.listContainers()
            async let images = service.listImages()
            async let volumes = service.listVolumes()
            async let networks = service.listNetworks()
            self.containers = try await containers
            self.images = try await images
            self.volumes = try await volumes
            self.networks = try await networks
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func clearLastExecution() {
        lastExecution = nil
        lastError = nil
    }
}
