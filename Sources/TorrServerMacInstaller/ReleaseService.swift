import Foundation

struct ReleaseService {
    private let releasesURL = URL(string: "https://api.github.com/repos/YouROK/TorrServer/releases")!

    func fetchReleases() async throws -> [TorrServerRelease] {
        let (data, response) = try await URLSession.shared.data(from: releasesURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppError(L.releasesLoadError)
        }

        let githubReleases = try JSONDecoder().decode([GitHubRelease].self, from: data)
        let matrixReleases = githubReleases.filter { $0.tagName.localizedCaseInsensitiveContains("MatriX") }
        guard let latestTag = matrixReleases.first?.tagName else { return [] }

        return matrixReleases.compactMap { release in
            guard let asset = release.assets.first(where: { $0.name == AppPaths.serverBinaryName }) else {
                return nil
            }

            return TorrServerRelease(
                id: release.tagName,
                tag: release.tagName,
                downloadURL: asset.browserDownloadURL,
                isLatest: release.tagName == latestTag
            )
        }
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case assets
    }
}

private struct GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

struct AppError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
