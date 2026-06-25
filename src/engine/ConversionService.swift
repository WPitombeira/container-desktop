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
    public static func convert(config: DockerConfig) -> [String] {
        var args = ["run", "--image", config.image]
        for port in config.ports {
            args.append(contentsOf: ["--port", port])
        }
        args.append(config.name)
        return args
    }
}
