import Foundation

/// A utility to help with the "Magic Converter" logic.
/// This will be expanded to use a real YAML parser in the next phase.
public struct DockerConfig {
    public let image: String
    public let ports: [String]
    public let name: String
    
    public init(image: String, ports: [String], name: String) {
        self.image = image
        self.ports = ports
        self.name = name
    }
}

public class ConversionService {
    private static let dockerConversionService = DockerConversionService()

    public static func convert(config: DockerConfig) -> [String] {
        let service = ComposeServiceRow(
            name: config.name,
            image: config.image,
            ports: config.ports
        )
        return dockerConversionService.convertComposeService(service).command
    }

    public static func convert(command: String) -> DockerConversionResult {
        (try? dockerConversionService.convertDockerRunCommand(command)) ??
            .init(command: [], warnings: ["Conversion failed."])
    }

    public static func convertForCLI(config: DockerConfig) -> [String] {
        convert(config: config)
    }
}
