import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var settings = SettingsStore()
    @Published var server = ServerProcessManager()
    @Published var releases: [TorrServerRelease] = []
    @Published var selectedReleaseID: TorrServerRelease.ID?
    @Published var passwordDraft = ""
    @Published var installMessage = ""
    @Published var isLoadingReleases = false
    @Published var restartRequired = false
    @Published var lastError: String?
    @Published var webReloadID = UUID()

    private let releaseService = ReleaseService()
    private let loginItemService = LoginItemService()
    private var cancellables: Set<AnyCancellable> = []
    private var didHandleLaunch = false

    var serverURL: URL {
        URL(string: "http://localhost:\(settings.port)")!
    }

    var selectedRelease: TorrServerRelease? {
        releases.first { $0.id == selectedReleaseID } ?? releases.first
    }

    var isSelectedReleaseInstalled: Bool {
        guard server.isInstalled,
              let selectedRelease,
              let installedVersion = settings.selectedVersion else {
            return false
        }
        return selectedRelease.tag == installedVersion
    }

    var canInstallSelectedRelease: Bool {
        selectedRelease != nil && !server.status.isBusy && !isSelectedReleaseInstalled
    }

    var progressMessage: String? {
        if server.status == .installing {
            return installMessage.isEmpty ? L.installingFallback : installMessage
        }
        if isLoadingReleases {
            return L.loadingVersions
        }
        if server.status == .starting {
            return L.startingServer
        }
        if server.status == .stopping {
            return L.stoppingServer
        }
        return nil
    }

    private init() {
        passwordDraft = settings.password()
        server.refreshInstalledState()

        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        server.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func handleLaunch() {
        guard !didHandleLaunch else { return }
        didHandleLaunch = true

        Task {
            if server.isInstalled {
                await startServer()
                await loadReleases()
            } else {
                await loadReleases()
                await autoInstallLatestIfNeeded()
            }
        }
    }

    func loadReleases() async {
        guard !isLoadingReleases else { return }
        isLoadingReleases = true
        lastError = nil

        do {
            let fetched = try await releaseService.fetchReleases()
            releases = fetched
            if selectedReleaseID == nil {
                selectedReleaseID = settings.selectedVersion ?? fetched.first?.id
            }
        } catch {
            lastError = error.localizedDescription
        }

        isLoadingReleases = false
    }

    func installSelectedReleaseAndStart() async {
        guard canInstallSelectedRelease, let release = selectedRelease else { return }
        await installReleaseAndStart(release, userInitiated: true)
    }

    func autoInstallLatestIfNeeded() async {
        guard !server.isInstalled,
              !settings.userRemovedServer,
              let latestRelease = releases.first else {
            return
        }

        selectedReleaseID = latestRelease.id
        await installReleaseAndStart(latestRelease, userInitiated: false)
    }

    private func installReleaseAndStart(_ release: TorrServerRelease, userInitiated: Bool) async {
        settings.selectedVersion = release.tag
        if userInitiated {
            settings.userRemovedServer = false
        }
        lastError = nil
        installMessage = L.preparingInstallation

        do {
            try await server.install(release) { [weak self] message in
                self?.installMessage = message
            }
            restartRequired = false
            await startServer()
        } catch {
            server.refreshInstalledState()
            lastError = error.localizedDescription
        }
    }

    func removeServer() {
        do {
            try server.removeServerFiles()
            settings.userRemovedServer = true
            restartRequired = false
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func startServer() async {
        if settings.authEnabled {
            settings.setPassword(passwordDraft)
        }
        await server.start(
            port: settings.port,
            authEnabled: settings.authEnabled,
            username: settings.username,
            password: passwordDraft
        )
        restartRequired = false
        if case .error(let message) = server.status {
            lastError = message
        } else if server.status.isRunning {
            webReloadID = UUID()
        }
    }

    func stopServer() {
        server.stop()
        restartRequired = false
    }

    func restartServer() async {
        stopServer()
        try? await Task.sleep(for: .milliseconds(400))
        await startServer()
    }

    func openInBrowser() {
        NSWorkspace.shared.open(serverURL)
    }

    func markRestartRequired() {
        if server.status.isRunning {
            restartRequired = true
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemService.setEnabled(enabled)
            settings.setLaunchAtLoginStoredValue(enabled)
            lastError = nil
        } catch {
            settings.setLaunchAtLoginStoredValue(!enabled)
            lastError = error.localizedDescription
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
