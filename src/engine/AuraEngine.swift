import Foundation

/// AuraEngine: The core logic for the Aura macOS application.
/// This class handles the interaction with the `container` CLI and performs
/// the translation from Docker configurations to Apple Container commands.
@MainActor
public class AuraEngine: ObservableObject {
    
    @Published public var containerLogs: String = ""
    @Published public var isRunning: Bool = false
    @Published public var error: String? = nil
    @Published public var cliPath: String = ""
    @Published public var discoveredCLI: Bool = false

    private let stateStore = ContainerStateStore()
    private let converter = DockerConversionService()
    
    public init() {}
    
    // MARK: - Core Actions
    
    /// Executes a command via the 'container' CLI and captures output.
    public func runContainerCommand(_ arguments: [String]) {
        isRunning = true
        Task { @MainActor [weak self] in
            await self?.stateStore.refreshCLIPath()
            await self?.stateStore.run(arguments)
            guard let self else { return }
            self.discoveredCLI = self.stateStore.cliPath != nil
            self.cliPath = self.stateStore.cliPath?.path ?? ""
            self.isRunning = false

            if let output = self.stateStore.lastExecution {
                let line = output.combined
                self.containerLogs = self.containerLogs + "\n" + line
                if output.exitCode != 0 {
                    self.error = "Container command failed (\(output.exitCode))."
                } else {
                    self.error = nil
                }
            } else {
                self.error = self.stateStore.lastError
            }
        }
    }
    
    // MARK: - Docker to Apple Converter
    
    /// Translates a simplified Docker Compose dictionary into an Apple Container command.
    /// In a production app, this would use a YAML parser.
    public func convertDockerCompose(image: String, ports: [String], name: String) -> [String] {
        let service = ComposeServiceRow(name: name, image: image, ports: ports)
        return converter.convertComposeService(service).command
    }

    public func convertDockerRun(_ command: String) -> DockerConversionResult {
        do {
            return try converter.convertDockerRunCommand(command)
        } catch {
            return DockerConversionResult(command: [], warnings: [error.localizedDescription])
        }
    }
}
