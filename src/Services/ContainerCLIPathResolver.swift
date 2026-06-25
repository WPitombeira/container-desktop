import Foundation

public final class ContainerCLIPathResolver {
    public typealias ExecutableChecker = @Sendable (URL) -> Bool

    private let fileManager: FileManager
    private let environmentPaths: [String]
    private let additionalCandidates: [String]
    private let executableChecker: ExecutableChecker

    public init(
        fileManager: FileManager = .default,
        environmentPaths: [String]? = nil,
        additionalCandidates: [String] = [
            "/usr/bin/container",
            "/usr/local/bin/container",
            "/opt/homebrew/bin/container",
            "/opt/local/bin/container"
        ],
        executableChecker: @escaping ExecutableChecker = { FileManager.default.isExecutableFile(atPath: $0.path) }
    ) {
        self.fileManager = fileManager
        self.environmentPaths = environmentPaths
            ?? fileManager.currentDirectoryPath
                .split(separator: ":")
                .map(String.init)
        self.additionalCandidates = additionalCandidates
        self.executableChecker = executableChecker
    }

    public func discover() async -> Result<URL, ContainerCLIError> {
        let candidates = deduplicatedCandidatePaths()

        for path in candidates where !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            if executableChecker(url) {
                return .success(url)
            }
        }

        for path in envBinaryCandidates() where !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            if executableChecker(url) {
                return .success(url)
            }
        }

        return .failure(.cliNotFound)
    }

    private func deduplicatedCandidatePaths() -> [String] {
        var unique: [String] = []
        for candidate in additionalCandidates {
            if !unique.contains(candidate) {
                unique.append(candidate)
            }
        }
        return unique
    }

    private func envBinaryCandidates() -> [String] {
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        guard let envPaths = pathValues(from: pathEnv) else { return [] }
        return envPaths
            .map { ($0 as NSString).appendingPathComponent("container") }
    }

    private func pathValues(from value: String) -> [String]? {
        guard !value.isEmpty else { return nil }
        return value
            .split(separator: ":")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
}
