import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var port: Int {
        didSet { defaults.set(port, forKey: Keys.port) }
    }

    @Published var authEnabled: Bool {
        didSet { defaults.set(authEnabled, forKey: Keys.authEnabled) }
    }

    @Published var username: String {
        didSet { defaults.set(username, forKey: Keys.username) }
    }

    @Published var selectedVersion: String? {
        didSet { defaults.set(selectedVersion, forKey: Keys.selectedVersion) }
    }

    @Published var languageCode: String {
        didSet { defaults.set(languageCode, forKey: Keys.languageCode) }
    }

    @Published var launchAtLogin: Bool

    @Published var userRemovedServer: Bool {
        didSet { defaults.set(userRemovedServer, forKey: Keys.userRemovedServer) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedPort = defaults.integer(forKey: Keys.port)
        self.port = savedPort == 0 ? 8090 : savedPort
        self.authEnabled = defaults.bool(forKey: Keys.authEnabled)
        self.username = defaults.string(forKey: Keys.username) ?? ""
        self.selectedVersion = defaults.string(forKey: Keys.selectedVersion)
        self.languageCode = defaults.string(forKey: Keys.languageCode) ?? "system"
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.userRemovedServer = defaults.bool(forKey: Keys.userRemovedServer)
    }

    func password() -> String {
        defaults.string(forKey: Keys.password) ?? ""
    }

    func setPassword(_ password: String) {
        defaults.set(password, forKey: Keys.password)
    }

    func setLaunchAtLoginStoredValue(_ enabled: Bool) {
        launchAtLogin = enabled
        defaults.set(enabled, forKey: Keys.launchAtLogin)
    }

    private enum Keys {
        static let port = "port"
        static let authEnabled = "authEnabled"
        static let username = "username"
        static let password = "password"
        static let selectedVersion = "selectedVersion"
        static let languageCode = "languageCode"
        static let launchAtLogin = "launchAtLogin"
        static let userRemovedServer = "userRemovedServer"
    }
}
