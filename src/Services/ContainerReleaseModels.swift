import Foundation

public struct AppleContainerReleaseAsset: Identifiable, Sendable, Equatable {
    public let id: Int
    public let name: String
    public let state: String?
    public let contentType: String?
    public let sizeBytes: Int?
    public let downloadURL: URL
}

public struct AppleContainerRelease: Identifiable, Sendable, Equatable {
    public let id: Int
    public let tagName: String
    public let name: String
    public let changelog: String
    public let publishedAt: Date?
    public let htmlURL: URL
    public let assets: [AppleContainerReleaseAsset]

    public var version: ContainerReleaseVersion? {
        ContainerReleaseVersion(rawValue: tagName)
    }

    public var normalizedTag: String {
        tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }
}

public struct ContainerReleaseInstallPlan: Sendable, Equatable {
    public let asset: AppleContainerReleaseAsset
    public let downloadURL: URL
    public let instructions: [String]
    public let allowsSilentInstall: Bool = false

    public var requiresUserInitiatedInstall: Bool { true }

    public var releaseTitle: String {
        asset.name
    }
}

public enum ContainerReleaseUpdateDecision: Sendable, Equatable {
    case upToDate
    case installedAhead
    case unknownInstalledVersion(ContainerReleaseInstallPlan?)
    case releaseVersionUnknown
    case updateAvailable(ContainerReleaseInstallPlan)
    case updateAvailableButNoInstaller
}

public struct ContainerReleaseUpdatePlan: Sendable, Equatable {
    public let latestRelease: AppleContainerRelease
    public let installedVersion: ContainerReleaseVersion?
    public let decision: ContainerReleaseUpdateDecision
}

public enum ContainerReleaseServiceError: Error, LocalizedError, Sendable {
    case requestFailed(statusCode: Int)
    case invalidResponseFormat(String)

    public var errorDescription: String? {
        switch self {
        case let .requestFailed(statusCode):
            return "GitHub release endpoint returned status code \(statusCode)."
        case let .invalidResponseFormat(message):
            return "Failed to parse Container release metadata: \(message)"
        }
    }
}

public protocol ContainerReleaseHTTPClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public final class URLSessionContainerReleaseHTTPClient: ContainerReleaseHTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
