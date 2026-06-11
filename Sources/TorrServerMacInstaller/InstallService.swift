import Foundation

struct InstallService {
    func isInstalled() -> Bool {
        FileManager.default.isExecutableFile(atPath: AppPaths.serverBinary.path)
    }

    func install(_ release: TorrServerRelease, progress: @MainActor @escaping (String) -> Void) async throws {
        await progress(L.preparingFolders)
        try FileManager.default.createDirectory(at: AppPaths.binDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: AppPaths.dataDirectory, withIntermediateDirectories: true)

        await progress(L.downloading(release.tag))
        let (temporaryURL, response) = try await URLSession.shared.download(from: release.downloadURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw AppError(L.downloadError(release.tag))
        }

        await progress(L.installingServerBinary)
        if FileManager.default.fileExists(atPath: AppPaths.serverBinary.path) {
            try FileManager.default.removeItem(at: AppPaths.serverBinary)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: AppPaths.serverBinary)

        var permissions = try FileManager.default.attributesOfItem(atPath: AppPaths.serverBinary.path)
        permissions[.posixPermissions] = 0o755
        try FileManager.default.setAttributes(permissions, ofItemAtPath: AppPaths.serverBinary.path)
    }
}
