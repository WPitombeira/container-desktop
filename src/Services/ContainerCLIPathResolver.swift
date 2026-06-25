import Foundation

public final class ContainerCLIPathResolver {
    public typealias ExecutableChecker = @Sendable (URL) -> Bool

    private let additionalCandidates: [String]
    private let executableChecker: ExecutableChecker
    private let candidateDirectories: [String]

    public init(
        candidateDirectories: [String]? = nil,
        additionalCandidates: [String] = [
            "/usr/bin/container",
            "/usr/local/bin/container",
            "/opt/homebrew/bin/container",
            "/opt/local/bin/container"
        ],
        executableChecker: @escaping ExecutableChecker = { FileManager.default.isExecutableFile(atPath: $0.path) }
    ) {
        self.candidateDirectories = candidateDirectories ??
            (ProcessInfo.processInfo.environment["PATH"] ?? "")
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
        guard !candidateDirectories.isEmpty else { return [] }
        return candidateDirectories
            .map { ($0 as NSString).appendingPathComponent("container") }
    }
}
