import Foundation

public final class ContainerReleaseService {
    private let releaseURL: URL
    private let httpClient: ContainerReleaseHTTPClient
    private let parser: ContainerVersionParser
    private let decoder: JSONDecoder

    public init(
        releaseURL: URL = URL(string: "https://api.github.com/repos/apple/container/releases/latest")!,
        httpClient: ContainerReleaseHTTPClient = URLSessionContainerReleaseHTTPClient()
    ) {
        self.releaseURL = releaseURL
        self.httpClient = httpClient
        self.parser = ContainerVersionParser()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchLatestRelease() async throws -> AppleContainerRelease {
        var request = URLRequest(url: releaseURL)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("ContainerDesktop/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await httpClient.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ContainerReleaseServiceError.invalidResponseFormat("Response was not HTTP.")
        }
        guard (200...299).contains(http.statusCode) else {
            throw ContainerReleaseServiceError.requestFailed(statusCode: http.statusCode)
        }

        do {
            let payload = try decoder.decode(GitHubReleasePayload.self, from: data)
            return payload.asRelease()
        } catch {
            throw ContainerReleaseServiceError.invalidResponseFormat(error.localizedDescription)
        }
    }

    public func planUpdate(
        latestRelease: AppleContainerRelease,
        installedVersionText: String?
    ) -> ContainerReleaseUpdatePlan {
        let installed = installedVersionText.flatMap { parser.parse(from: $0) }

        guard let latestVersion = latestRelease.version else {
            return ContainerReleaseUpdatePlan(
                latestRelease: latestRelease,
                installedVersion: installed,
                decision: .releaseVersionUnknown
            )
        }

        guard let installedVersion = installed else {
            let installPlan = makeInstallPlan(from: latestRelease)
            return ContainerReleaseUpdatePlan(
                latestRelease: latestRelease,
                installedVersion: nil,
                decision: .unknownInstalledVersion(installPlan)
            )
        }

        if installedVersion == latestVersion {
            return ContainerReleaseUpdatePlan(
                latestRelease: latestRelease,
                installedVersion: installedVersion,
                decision: .upToDate
            )
        }

        if installedVersion > latestVersion {
            return ContainerReleaseUpdatePlan(
                latestRelease: latestRelease,
                installedVersion: installedVersion,
                decision: .installedAhead
            )
        }

        guard let installPlan = makeInstallPlan(from: latestRelease) else {
            return ContainerReleaseUpdatePlan(
                latestRelease: latestRelease,
                installedVersion: installedVersion,
                decision: .updateAvailableButNoInstaller
            )
        }

        return ContainerReleaseUpdatePlan(
            latestRelease: latestRelease,
            installedVersion: installedVersion,
            decision: .updateAvailable(installPlan)
        )
    }

    public func parseInstalledVersion(from output: String) -> ContainerReleaseVersion? {
        parser.parse(from: output)
    }

    private func makeInstallPlan(from release: AppleContainerRelease) -> ContainerReleaseInstallPlan? {
        guard let chosenAsset = preferredAsset(in: release.assets) else {
            return nil
        }

        let instructions = [
            "Download \(chosenAsset.name) from \(chosenAsset.downloadURL.absoluteString).",
            "Open the downloaded package and complete the installation through the Apple installer UI.",
            "Restart Container Desktop after installation if the app is not updated automatically."
        ]

        return ContainerReleaseInstallPlan(
            asset: chosenAsset,
            downloadURL: chosenAsset.downloadURL,
            instructions: instructions
        )
    }

    private func preferredAsset(in assets: [AppleContainerReleaseAsset]) -> AppleContainerReleaseAsset? {
        let namedAssets = assets.map { ($0, $0.name.lowercased()) }

        if let signedPackage = namedAssets.first(where: {
            $0.1.hasSuffix(".pkg") && $0.1.contains("installer-signed")
        })?.0 {
            return signedPackage
        }

        if let package = namedAssets.first(where: {
            $0.1.hasSuffix(".pkg") && !$0.1.contains("unsigned")
        })?.0 {
            return package
        }

        for fileExtension in ["pkg", "dmg", "zip", "xip"] {
            if let asset = namedAssets.first(where: { $0.1.hasSuffix(".\(fileExtension)") })?.0 {
                return asset
            }
        }

        return assets.first { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private struct GitHubReleasePayload: Decodable {
    let id: Int
    let tagName: String
    let name: String?
    let body: String?
    let publishedAt: Date?
    let htmlURL: URL
    let assets: [GitHubReleaseAssetPayload]

    struct GitHubReleaseAssetPayload: Decodable {
        let id: Int
        let name: String
        let state: String?
        let contentType: String?
        let size: Int?
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case state
            case size
            case contentType = "content_type"
            case browserDownloadURL = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case publishedAt = "published_at"
        case htmlURL = "html_url"
        case assets
    }

    func asRelease() -> AppleContainerRelease {
        .init(
            id: id,
            tagName: tagName,
            name: name ?? tagName,
            changelog: body ?? "",
            publishedAt: publishedAt,
            htmlURL: htmlURL,
            assets: assets.map {
                AppleContainerReleaseAsset(
                    id: $0.id,
                    name: $0.name,
                    state: $0.state,
                    contentType: $0.contentType,
                    sizeBytes: $0.size,
                    downloadURL: $0.browserDownloadURL
                )
            }
        )
    }
}
