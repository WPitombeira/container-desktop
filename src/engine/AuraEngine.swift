import Foundation

/// AuraEngine: The core logic for the Aura macOS application.
/// This class handles the interaction with the `container` CLI and performs
/// the translation from Docker configurations to Apple Container commands.
public class AuraEngine: ObservableObject {
    
    @Published public var containerLogs: String = ""
    @Published public var isRunning: Bool = false
    @Published public var error: String? = nil
    
    public init() {}
    
    // MARK: - Core Actions
    
    /// Executes a command via the 'container' CLI and captures output.
    public func runContainerCommand(_ arguments: [String]) {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/container") // Standard path for CLI tools
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            self.isRunning = true
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.containerLogs += output
                }
            }
            
            process.waitUntilExit()
            DispatchQueue.main.async {
                self.isRunning = false
                if process.terminationStatus != 0 {
                    self.error = "Container exited with error code: \(process.terminationStatus)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to run container: \(error.localizedDescription)"
                self.isRunning = false
            }
        }
    }
    
    // MARK: - Docker to Apple Converter
    
    /// Translates a simplified Docker Compose dictionary into an Apple Container command.
    /// In a production app, this would use a YAML parser.
    public func convertDockerCompose(image: String, ports: [String], name: String) -> [String] {
        var args = ["run", "--image", image]
        
        for port in ports {
            args.append(contentsOf: ["--port", port])
        }
        
        args.append(name)
        return args
    }
}
