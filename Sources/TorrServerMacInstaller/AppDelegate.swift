import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState.shared
    private var statusItem: NSStatusItem?
    private var window: NSWindow?
    private var quitWarningPanel: NSPanel?
    private var quitWarningDeadline: Date?
    private var quitWarningDismissWorkItem: DispatchWorkItem?
    private var shouldQuitImmediately = false
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        setupStatusItem()
        if !launchedAsLoginItem {
            showMainWindow()
        }
        appState.handleLaunch()

        appState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)
    }

    private var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent else {
            return false
        }

        return event.eventID == kAEOpenApplication
            && event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldQuitImmediately {
            shouldQuitImmediately = false
            return terminateImmediately()
        }

        if let quitWarningDeadline, quitWarningDeadline > Date() {
            clearQuitWarning()
            return terminateImmediately()
        }

        showQuitWarning()
        return .terminateCancel
    }

    private func terminateImmediately() -> NSApplication.TerminateReply {
        clearQuitWarning()
        appState.server.stopBeforeQuit()
        return .terminateNow
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        updateStatusItem()
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        button.image = AppIconProvider.image(size: NSSize(width: 18, height: 18))
        button.imagePosition = .imageOnly
        button.title = ""
        statusItem?.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: L.openApp, action: #selector(openApp), keyEquivalent: ""))
        let openBrowser = NSMenuItem(title: L.openInBrowser, action: #selector(openBrowser), keyEquivalent: "")
        openBrowser.isEnabled = appState.server.status.isRunning
        menu.addItem(openBrowser)
        menu.addItem(.separator())

        let status = NSMenuItem(title: appState.server.status.title, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)

        if appState.server.isInstalled {
            if appState.server.status.isRunning {
                menu.addItem(NSMenuItem(title: L.stopServer, action: #selector(stopServer), keyEquivalent: ""))
            } else {
                let start = NSMenuItem(title: L.startServer, action: #selector(startServer), keyEquivalent: "")
                start.isEnabled = !appState.server.status.isBusy
                menu.addItem(start)
            }
        } else {
            let install = NSMenuItem(title: L.install, action: #selector(installLatest), keyEquivalent: "")
            install.isEnabled = appState.canInstallSelectedRelease
            menu.addItem(install)
        }

        let login = NSMenuItem(title: L.launchAtLogin, action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.state = appState.settings.launchAtLogin ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L.quit, action: #selector(quit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }
        return menu
    }

    @objc private func openApp() {
        showMainWindow()
    }

    @objc private func openBrowser() {
        appState.openInBrowser()
    }

    @objc private func startServer() {
        Task { await appState.startServer() }
    }

    @objc private func stopServer() {
        appState.stopServer()
    }

    @objc private func installLatest() {
        showMainWindow()
        Task { await appState.installSelectedReleaseAndStart() }
    }

    @objc private func toggleLaunchAtLogin() {
        appState.setLaunchAtLogin(!appState.settings.launchAtLogin)
    }

    @objc private func quit() {
        shouldQuitImmediately = true
        NSApplication.shared.terminate(nil)
    }

    private func showMainWindow() {
        if window == nil {
            let content = ContentView()
                .environmentObject(appState)
            let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 760)

            let newWindow = NSWindow(
                contentRect: screenFrame,
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "TorrServer"
            newWindow.contentView = NSHostingView(rootView: content)
            newWindow.backgroundColor = NSColor(red: 0.067, green: 0.075, blue: 0.098, alpha: 1)
            newWindow.appearance = NSAppearance(named: .darkAqua)
            newWindow.isReleasedWhenClosed = false
            window = newWindow
        }

        maximizeWindowToVisibleScreen()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func maximizeWindowToVisibleScreen() {
        guard let window else { return }
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        if let visibleFrame {
            window.setFrame(visibleFrame, display: true, animate: false)
        }
    }

    private func showQuitWarning() {
        quitWarningDeadline = Date().addingTimeInterval(4)
        quitWarningDismissWorkItem?.cancel()

        let panel = quitWarningPanel ?? makeQuitWarningPanel()
        let message = appState.server.status.isRunning
            ? L.quitAgainServerWillStop
            : L.quitAgain

        panel.contentView = NSHostingView(rootView: QuitWarningView(message: message))
        positionQuitWarningPanel(panel)
        panel.orderFrontRegardless()
        quitWarningPanel = panel

        let dismiss = DispatchWorkItem { [weak self] in
            self?.quitWarningPanel?.close()
            self?.quitWarningPanel = nil
            self?.quitWarningDeadline = nil
            self?.quitWarningDismissWorkItem = nil
        }
        quitWarningDismissWorkItem = dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: dismiss)
    }

    private func clearQuitWarning() {
        quitWarningPanel?.close()
        quitWarningPanel = nil
        quitWarningDeadline = nil
        quitWarningDismissWorkItem?.cancel()
        quitWarningDismissWorkItem = nil
    }

    private func makeQuitWarningPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 92),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func positionQuitWarningPanel(_ panel: NSPanel) {
        let targetFrame = window?.frame ?? NSScreen.main?.visibleFrame ?? .zero
        let panelSize = panel.frame.size
        let x = targetFrame.midX - panelSize.width / 2
        let y = targetFrame.minY + 36
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct QuitWarningView: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "power")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.quitTitle)
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(width: 430, height: 92)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
