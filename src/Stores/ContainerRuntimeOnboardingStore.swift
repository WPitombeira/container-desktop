import AppKit
import Foundation

public enum AppleContainerOnboardingError: Error, LocalizedError, Sendable {
    case releaseMetadataInvalid
    case installerAssetMissing
    case downloadFailed
    case installerOpenFailed

    public var errorDescription: String? {
        switch self {
        case .releaseMetadataInvalid:
            return "Release metadata from GitHub was invalid."
        case .installerAssetMissing:
            return "The latest Apple Container release does not include an installable package."
        case .downloadFailed:
            return "The Apple Container installer could not be downloaded."
        case .installerOpenFailed:
            return "The Apple Container installer could not be opened."
        }
    }
}

public protocol AppleContainerReleaseProviding {
    func latestRelease() async throws -> AppleContainerRelease
    func updatePlan(latestRelease: AppleContainerRelease, installedVersionText: String?) -> ContainerReleaseUpdatePlan
    func installedVersion(from output: String) -> ContainerReleaseVersion?
}

extension ContainerReleaseService: AppleContainerReleaseProviding {
    public func latestRelease() async throws -> AppleContainerRelease {
        try await fetchLatestRelease()
    }

    public func updatePlan(
        latestRelease: AppleContainerRelease,
        installedVersionText: String?
    ) -> ContainerReleaseUpdatePlan {
        planUpdate(latestRelease: latestRelease, installedVersionText: installedVersionText)
    }

    public func installedVersion(from output: String) -> ContainerReleaseVersion? {
        parseInstalledVersion(from: output)
    }
}

public protocol AppleContainerInstallProviding {
    var supportsAutomaticDownload: Bool { get }
    func prepareInstallPlan(for release: AppleContainerRelease) async throws -> ContainerReleaseInstallPlan
    func downloadReleaseArtifact(using plan: ContainerReleaseInstallPlan) async throws -> URL
    func openInstaller(at url: URL) async throws
}

public final class AppleContainerInstallerService: AppleContainerInstallProviding {
    public let supportsAutomaticDownload = true

    private let session: URLSession

    public init(
        session: URLSession = .shared
    ) {
        self.session = session
    }

    public func prepareInstallPlan(for release: AppleContainerRelease) async throws -> ContainerReleaseInstallPlan {
        guard let asset = preferredInstallerAsset(in: release.assets) else {
            throw AppleContainerOnboardingError.installerAssetMissing
        }

        return ContainerReleaseInstallPlan(
            asset: asset,
            downloadURL: asset.downloadURL,
            instructions: [
                "Download the signed Apple Container installer package.",
                "Open the package with macOS Installer.",
                "Approve the macOS installer prompts to complete installation.",
                "Refresh Container Desktop after the installer finishes."
            ]
        )
    }

    public func downloadReleaseArtifact(using plan: ContainerReleaseInstallPlan) async throws -> URL {
        let destinationDirectory = try downloadsDirectory()
        let destination = destinationDirectory.appendingPathComponent(plan.asset.name)

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: destination.path) {
            return destination
        }

        do {
            let (temporaryURL, _) = try await session.download(from: plan.downloadURL)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: temporaryURL, to: destination)
            return destination
        } catch {
            throw AppleContainerOnboardingError.downloadFailed
        }
    }

    @MainActor
    public func openInstaller(at url: URL) async throws {
        guard NSWorkspace.shared.open(url) else {
            throw AppleContainerOnboardingError.installerOpenFailed
        }
    }

    private func downloadsDirectory() throws -> URL {
        let fileManager = FileManager.default
        let base = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base
            .appendingPathComponent("ContainerDesktop", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)

        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func preferredInstallerAsset(in assets: [AppleContainerReleaseAsset]) -> AppleContainerReleaseAsset? {
        let lowercasedAssets = assets.map { ($0, $0.name.lowercased()) }

        if let signedPackage = lowercasedAssets.first(where: {
            $0.1.hasSuffix(".pkg") && $0.1.contains("installer-signed")
        })?.0 {
            return signedPackage
        }

        if let package = lowercasedAssets.first(where: {
            $0.1.hasSuffix(".pkg") && !$0.1.contains("unsigned")
        })?.0 {
            return package
        }

        return lowercasedAssets.first(where: { $0.1.hasSuffix(".pkg") })?.0
    }
}

@MainActor
public final class ContainerRuntimeOnboardingStore: ObservableObject {
    @Published public private(set) var cliPath: URL?
    @Published public private(set) var installedVersion: String?
    @Published public private(set) var latestRelease: AppleContainerRelease?
    @Published public private(set) var updatePlan: ContainerReleaseUpdatePlan?
    @Published public private(set) var lastCheckedAt: Date?
    @Published public private(set) var lastCheckedReleaseAt: Date?
    @Published public private(set) var isRefreshingRuntime = false
    @Published public private(set) var isCheckingForUpdates = false
    @Published public private(set) var isInstalling = false
    @Published public private(set) var isAutoDownloading = false
    @Published public private(set) var downloadedArtifactURL: URL?
    @Published public private(set) var installPlan: ContainerReleaseInstallPlan?
    @Published public private(set) var statusMessage: String?
    @Published public private(set) var lastError: String?

    private let cliService: ContainerCLIService
    private let releaseService: AppleContainerReleaseProviding
    private let installer: AppleContainerInstallProviding

    public init(
        cliService: ContainerCLIService = ContainerCLIService(),
        releaseService: AppleContainerReleaseProviding = ContainerReleaseService(),
        installer: AppleContainerInstallProviding = AppleContainerInstallerService()
    ) {
        self.cliService = cliService
        self.releaseService = releaseService
        self.installer = installer
    }

    public var hasRuntimeCLI: Bool {
        cliPath != nil
    }

    public var changelog: String {
        latestRelease?.changelog.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    public var hasChangelog: Bool {
        !changelog.isEmpty
    }

    public var latestTag: String? {
        latestRelease?.tagName
    }

    public var canInstallOrUpdate: Bool {
        guard installPlan != nil else { return false }

        switch updatePlan?.decision {
        case .unknownInstalledVersion, .updateAvailable:
            return true
        default:
            return !hasRuntimeCLI
        }
    }

    public var installActionLabel: String {
        hasRuntimeCLI ? "Install update" : "Install Apple Container"
    }

    public var updateAvailable: Bool {
        if case .updateAvailable = updatePlan?.decision {
            return true
        }
        return false
    }

    public var updateMessage: String {
        switch updatePlan?.decision {
        case .upToDate:
            return "Apple Container is up to date."
        case .installedAhead:
            return "Installed Apple Container is newer than the latest GitHub release."
        case .unknownInstalledVersion:
            return "Apple Container is available to install."
        case .releaseVersionUnknown:
            return "Latest release version could not be parsed."
        case .updateAvailable:
            if let installedVersion, let latestTag {
                return "Update available: \(installedVersion) -> \(latestTag)"
            }
            return "Apple Container update available."
        case .updateAvailableButNoInstaller:
            return "Update available, but no installable package was found."
        case nil:
            if hasRuntimeCLI {
                return "Runtime discovered; release check not run yet."
            }
            return "Apple Container is not installed."
        }
    }

    public func refreshRuntimeStatus() async {
        isRefreshingRuntime = true
        defer { isRefreshingRuntime = false }
        lastError = nil
        lastCheckedAt = Date()

        switch await cliService.discoverPath() {
        case .success(let path):
            cliPath = path
            installedVersion = await detectCLIVersion()
            statusMessage = installedVersion.map { "CLI ready: \($0)" } ?? "CLI found, but version could not be parsed."
        case .failure(let error):
            cliPath = nil
            installedVersion = nil
            statusMessage = "Apple Container CLI was not found."
            lastError = error.localizedDescription
        }
    }

    public func checkForUpdates(autoDownload: Bool = false) async {
        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }
        lastError = nil

        do {
            let release = try await releaseService.latestRelease()
            latestRelease = release
            lastCheckedReleaseAt = Date()

            let plan = releaseService.updatePlan(
                latestRelease: release,
                installedVersionText: installedVersion
            )
            updatePlan = plan
            installPlan = await resolvedInstallPlan(for: release, from: plan)
            statusMessage = updateMessage

            if autoDownload, installer.supportsAutomaticDownload, canInstallOrUpdate {
                await autoDownloadReleaseArtifactIfNeeded()
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func installLatestCLI() async {
        isInstalling = true
        defer { isInstalling = false }
        lastError = nil

        guard let plan = installPlan else {
            lastError = "Check for updates first to locate an installable release."
            return
        }

        do {
            let artifactURL = try await installer.downloadReleaseArtifact(using: plan)
            downloadedArtifactURL = artifactURL
            try await installer.openInstaller(at: artifactURL)
            statusMessage = "Opened \(artifactURL.lastPathComponent) in macOS Installer."
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func autoDownloadReleaseArtifactIfNeeded() async {
        guard installer.supportsAutomaticDownload, let plan = installPlan else {
            downloadedArtifactURL = nil
            return
        }

        isAutoDownloading = true
        defer { isAutoDownloading = false }

        do {
            downloadedArtifactURL = try await installer.downloadReleaseArtifact(using: plan)
            statusMessage = "Downloaded installer: \(downloadedArtifactURL?.lastPathComponent ?? plan.asset.name)"
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func resolvedInstallPlan(
        for release: AppleContainerRelease,
        from updatePlan: ContainerReleaseUpdatePlan
    ) async -> ContainerReleaseInstallPlan? {
        switch updatePlan.decision {
        case let .unknownInstalledVersion(plan):
            if let plan {
                return plan
            }
            return try? await installer.prepareInstallPlan(for: release)
        case let .updateAvailable(plan):
            return plan
        case .upToDate, .installedAhead, .releaseVersionUnknown, .updateAvailableButNoInstaller:
            return nil
        }
    }

    private func detectCLIVersion() async -> String? {
        do {
            let output = try await cliService.execute(["--version"])
            return releaseService.installedVersion(from: output.combined)?.description
        } catch {
            return nil
        }
    }
}
