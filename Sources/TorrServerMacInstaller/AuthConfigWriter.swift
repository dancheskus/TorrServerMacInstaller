import Foundation

struct AuthConfigWriter {
    func writeAuthConfig(enabled: Bool, username: String, password: String) throws {
        try FileManager.default.createDirectory(at: AppPaths.dataDirectory, withIntermediateDirectories: true)

        if enabled {
            guard !username.isEmpty, !password.isEmpty else {
                throw AppError(L.authRequiredError)
            }

            let data = try JSONEncoder().encode([username: password])
            try data.write(to: AppPaths.authFile, options: .atomic)
        } else if FileManager.default.fileExists(atPath: AppPaths.authFile.path) {
            try FileManager.default.removeItem(at: AppPaths.authFile)
        }
    }
}
