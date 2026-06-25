import Foundation

public enum DockerConversionError: Error, LocalizedError, Sendable {
    case invalidInput(String)
    case unsupportedCommand

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .unsupportedCommand:
            return "Only docker run conversion is supported in this release."
        }
    }
}

public final class DockerConversionService {
    private let tokenizer = ShellArgumentTokenizer()

    public init() {}

    public func convertDockerRunCommand(_ input: String) throws -> DockerConversionResult {
        let tokens = try tokenizer.tokenize(input)
        if tokens.isEmpty { throw DockerConversionError.invalidInput("Empty command.") }
        
        var cursor = 0
        if tokens[0] != "docker" {
            throw DockerConversionError.unsupportedCommand
        }
        cursor += 1

        guard cursor < tokens.count else {
            throw DockerConversionError.invalidInput("Missing docker subcommand.")
        }

        let subcommand = tokens[cursor]
        cursor += 1
        guard subcommand == "run" else {
            throw DockerConversionError.unsupportedCommand
        }

        var arguments: [String] = ["run"]
        var image: String?
        var warnings: [String] = []
        var index = cursor
        var pendingCommand: [String] = []

        func parseValue(_ token: String) -> String {
            if token.hasPrefix("'") && token.hasSuffix("'") {
                return String(token.dropFirst().dropLast())
            }
            if token.hasPrefix("\"") && token.hasSuffix("\"") && token.count >= 2 {
                return String(token.dropFirst().dropLast())
            }
            return token
        }

        while index < tokens.count {
            let token = tokens[index]

            if token == "--rm" {
                arguments.append("--rm")
                index += 1
                continue
            }

            if token == "-d" || token == "--detach" {
                arguments.append("--detach")
                index += 1
                continue
            }

            if token == "--name" {
                guard index + 1 < tokens.count else {
                    warnings.append("Missing value for --name; dropped.")
                    break
                }
                arguments.append(contentsOf: ["--name", parseValue(tokens[index + 1])])
                index += 2
                continue
            }

            if token == "-p" || token == "--publish" {
                guard index + 1 < tokens.count else {
                    warnings.append("Missing value for publish flag; dropped.")
                    break
                }
                arguments.append(contentsOf: ["--publish", parseValue(tokens[index + 1])])
                index += 2
                continue
            }

            if token.hasPrefix("-p") && token.count > 2 {
                arguments.append(contentsOf: ["--publish", parseValue(String(token.dropFirst(2)))])
                index += 1
                continue
            }

            if token == "-v" || token == "--volume" {
                guard index + 1 < tokens.count else {
                    warnings.append("Missing value for volume flag; dropped.")
                    break
                }
                arguments.append(contentsOf: ["--volume", parseValue(tokens[index + 1])])
                index += 2
                continue
            }

            if token.hasPrefix("-v") && token.count > 2 {
                arguments.append(contentsOf: ["--volume", parseValue(String(token.dropFirst(2)))])
                index += 1
                continue
            }

            if token == "-e" || token == "--env" {
                guard index + 1 < tokens.count else {
                    warnings.append("Missing value for env flag; dropped.")
                    break
                }
                arguments.append(contentsOf: ["--env", parseValue(tokens[index + 1])])
                index += 2
                continue
            }

            if token.hasPrefix("-e") && token.count > 2 && token.firstIndex(of: "=") == nil {
                arguments.append(contentsOf: ["--env", parseValue(String(token.dropFirst(2)))])
                index += 1
                continue
            }

            if token == "--network" {
                guard index + 1 < tokens.count else {
                    warnings.append("Missing value for network flag; dropped.")
                    break
                }
                arguments.append(contentsOf: ["--network", parseValue(tokens[index + 1])])
                index += 2
                continue
            }

            if token.hasPrefix("-") {
                if token == "--" {
                    index += 1
                    pendingCommand.append(contentsOf: tokens[index...])
                    break
                }
                warnings.append("Ignored unsupported flag: \(token)")
                index += 1
                continue
            }

            if image == nil {
                image = token
                arguments.append(contentsOf: ["--image", parseValue(token)])
                index += 1
                continue
            }

            pendingCommand.append(token)
            if index + 1 < tokens.count {
                pendingCommand.append(contentsOf: tokens[(index + 1)...])
            }
            break
        }

        guard image != nil else {
            throw DockerConversionError.invalidInput("No image argument found.")
        }

        arguments.append(contentsOf: pendingCommand)
        return DockerConversionResult(command: arguments, warnings: warnings)
    }

    public func convertComposeService(_ service: ComposeServiceRow) -> DockerConversionResult {
        var arguments: [String] = ["run"]
        var warnings: [String] = []
        arguments.append(contentsOf: ["--name", service.name])
        arguments.append(contentsOf: ["--image", service.image])

        service.ports.forEach {
            arguments.append(contentsOf: ["--publish", $0])
        }
        service.volumes.forEach {
            arguments.append(contentsOf: ["--volume", $0])
        }
        service.env.forEach {
            arguments.append(contentsOf: ["--env", "\($0.key)=\($0.value)"])
        }

        if service.detach { arguments.append("--detach") }
        if service.remove { arguments.append("--rm") }
        if let network = service.network { arguments.append(contentsOf: ["--network", network]) }

        arguments.append(contentsOf: service.command)
        if service.ports.isEmpty && service.env.isEmpty && service.volumes.isEmpty {
            warnings.append("Compose service had no ports, env, or volumes.")
        }

        return DockerConversionResult(command: arguments, warnings: warnings)
    }
}
