import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRemoveServerConfirmationShown = false
    @State private var isLanguageDropdownOpen = false
    @State private var isLanguageDropdownButtonHovered = false
    @State private var hoveredLanguageCode: String?
    @State private var hoveredReleaseID: TorrServerRelease.ID?
    private let settingsControlWidth: CGFloat = 174
    private let settingsControlHeight: CGFloat = 38

    private let portFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 65535
        return formatter
    }()

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            ZStack {
                AppTheme.appBackground

                if appState.server.status.isRunning {
                    WebPreview(
                        url: appState.serverURL,
                        reloadID: appState.webReloadID,
                        authEnabled: appState.settings.authEnabled,
                        username: appState.settings.username,
                        password: appState.passwordDraft
                    )
                } else {
                    placeholder
                }

                if let progressMessage = appState.progressMessage {
                    progressOverlay(progressMessage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 1080, minHeight: 680)
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.text)
        .task {
            appState.handleLaunch()
        }
        .alert(L.removeServerTitle, isPresented: $isRemoveServerConfirmationShown) {
            Button(L.cancel, role: .cancel) {}
            Button(L.remove, role: .destructive) {
                appState.removeServer()
            }
        } message: {
            Text(L.removeServerMessage)
        }
    }

    private func progressOverlay(_ message: String) -> some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(AppTheme.primary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(10)
            .frame(width: 300)
            .background(AppTheme.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.outline, lineWidth: 1))
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private var placeholder: some View {
        ZStack {
            AppTheme.appBackground

            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: AppIconProvider.image(size: NSSize(width: 76, height: 76)))
                        .resizable()
                        .frame(width: 76, height: 76)

                    Circle()
                        .fill(AppTheme.surface)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: appState.server.status.symbolName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.statusColor(appState.server.status))
                        )
                        .shadow(color: AppTheme.statusColor(appState.server.status).opacity(0.25), radius: 10)
                }

                Text(appState.server.status.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text(appState.serverURL.absoluteString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.textMuted)
                if appState.server.isInstalled {
                    Button(L.startServer, systemImage: "play.fill") {
                        Task { await appState.startServer() }
                    }
                    .disabled(appState.server.status.isBusy)
                    .buttonStyle(TechnicalButtonStyle(.primary))
                } else {
                    Button(L.install, systemImage: "arrow.down.circle") {
                        Task { await appState.installSelectedReleaseAndStart() }
                    }
                    .disabled(appState.releases.isEmpty || appState.server.status.isBusy)
                    .buttonStyle(TechnicalButtonStyle(.primary))
                }
            }
            .padding(40)
            .frame(width: 390)
            .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.surfaceHighest.opacity(0.75), lineWidth: 1))
            .shadow(color: .black.opacity(0.26), radius: 34, y: 18)
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(nsImage: AppIconProvider.image(size: NSSize(width: 42, height: 42)))
                    .resizable()
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("TorrServer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                    HStack(spacing: 7) {
                        StatusDot(color: AppTheme.statusColor(appState.server.status))
                        Text(appState.server.status.title)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                Spacer()
            }
            .padding(24)

            Divider()
                .overlay(AppTheme.outline.opacity(0.8))

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    serverPanel
                    versionsPanel
                    settingsPanel
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 22)
            }

            Divider()
                .overlay(AppTheme.outline.opacity(0.8))

            aboutPanel
                .padding(24)
        }
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(AppTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.outline.opacity(0.9))
                .frame(width: 1)
        }
    }

    private var serverPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            TechnicalSectionTitle(title: L.webUI, systemImage: "globe")

            HStack(spacing: 8) {
                StatusDot(color: AppTheme.statusColor(appState.server.status))
                Text(appState.server.status.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
            }

            Text(appState.serverURL.absoluteString)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.secondary)
                .textSelection(.enabled)

            Button(L.openInBrowser, systemImage: "safari") {
                appState.openInBrowser()
            }
            .disabled(!appState.server.status.isRunning)
            .buttonStyle(TechnicalButtonStyle(.secondary))
        }
    }

    private var versionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TechnicalSectionTitle(title: L.version, systemImage: "clock.arrow.circlepath")

                Spacer()

                Button("", systemImage: "arrow.clockwise") {
                    Task { await appState.loadReleases() }
                }
                .help(L.reloadVersions)
                .disabled(appState.isLoadingReleases)
                .buttonStyle(TechnicalButtonStyle(.icon))
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(appState.releases) { release in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(appState.selectedReleaseID == release.id ? AppTheme.primary : .clear)
                                .frame(width: 3)
                                .clipShape(Capsule())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(release.tag)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.text)

                                if release.isLatest {
                                    Text(L.latest)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(AppTheme.textMuted)
                                }
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(releaseRowBackground(release.id))
                        .contentShape(Rectangle())
                        .overlay {
                            ImmediateReleaseClickArea { clickCount in
                                appState.selectedReleaseID = release.id
                                guard clickCount >= 2 else { return }
                                guard appState.canInstallSelectedRelease else { return }
                                Task { await appState.installSelectedReleaseAndStart() }
                            }
                        }
                        .onHover { isHovered in
                            hoveredReleaseID = isHovered ? release.id : nil
                            isHovered ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                    }
                }
            }
            .background(AppTheme.backgroundEdge.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.outline, lineWidth: 1))
            .frame(height: 230)

            if let progressMessage = appState.progressMessage {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(AppTheme.primary)
                    Text(progressMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }

            Button(L.install, systemImage: "square.and.arrow.down") {
                Task { await appState.installSelectedReleaseAndStart() }
            }
            .disabled(!appState.canInstallSelectedRelease)
            .buttonStyle(TechnicalButtonStyle(.secondary))
        }
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            TechnicalSectionTitle(title: L.settings, systemImage: "gearshape")

            languageSettingsRow
                .zIndex(10)

            settingsRow(label: L.port) {
                TextField("8090", value: $appState.settings.port, formatter: portFormatter)
                    .technicalField()
                    .frame(width: settingsControlWidth, height: settingsControlHeight)
                    .onChange(of: appState.settings.port) { _ in
                        appState.markRestartRequired()
                    }
            }

            Toggle(L.authorization, isOn: $appState.settings.authEnabled)
                .onChange(of: appState.settings.authEnabled) { _ in
                    appState.markRestartRequired()
                }
                .tint(AppTheme.primary)

            settingsRow(label: L.username) {
                TextField(L.username, text: $appState.settings.username)
                    .technicalField()
                    .frame(width: settingsControlWidth, height: settingsControlHeight)
                    .disabled(!appState.settings.authEnabled)
                    .onChange(of: appState.settings.username) { _ in
                        appState.markRestartRequired()
                    }
            }

            settingsRow(label: L.password) {
                SecureField(L.password, text: $appState.passwordDraft)
                    .technicalField()
                    .frame(width: settingsControlWidth, height: settingsControlHeight)
                    .disabled(!appState.settings.authEnabled)
                    .onChange(of: appState.passwordDraft) { _ in
                        if appState.settings.authEnabled {
                            appState.settings.setPassword(appState.passwordDraft)
                        }
                        appState.markRestartRequired()
                    }
            }

            Toggle(L.launchAtLogin, isOn: Binding(
                get: { appState.settings.launchAtLogin },
                set: { appState.setLaunchAtLogin($0) }
            ))
            .tint(AppTheme.primary)

            HStack {
                if appState.server.status.isRunning {
                    Button(L.stopServer, systemImage: "stop.fill") {
                        appState.stopServer()
                    }
                    .buttonStyle(TechnicalButtonStyle(.secondary))
                } else {
                    Button(L.startServer, systemImage: "play.fill") {
                        Task { await appState.startServer() }
                    }
                    .disabled(!appState.server.isInstalled || appState.server.status.isBusy)
                    .buttonStyle(TechnicalButtonStyle(.primary))
                }

                if appState.restartRequired {
                    Button(L.restart, systemImage: "arrow.clockwise") {
                        Task { await appState.restartServer() }
                    }
                    .buttonStyle(TechnicalButtonStyle(.primary))
                }
            }

            Button(L.removeServer, systemImage: "trash") {
                isRemoveServerConfirmationShown = true
            }
            .disabled(!appState.server.isInstalled || appState.server.status.isBusy)
            .buttonStyle(TechnicalButtonStyle(.secondary))

            if appState.restartRequired {
                Label(L.restartRequired, systemImage: "exclamationmark.circle")
                    .foregroundStyle(AppTheme.secondary)
            }

            if let lastError = appState.lastError {
                Label(lastError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(AppTheme.error)
                    .textSelection(.enabled)
            }
        }
        .font(.system(size: 13))
    }

    private func settingsRow<Control: View>(label: String, @ViewBuilder control: () -> Control) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)

            control()
                .frame(width: settingsControlWidth, height: settingsControlHeight)
        }
    }

    private var languageSettingsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(L.languageLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: settingsControlHeight, alignment: .center)

            languageDropdown
                .frame(width: settingsControlWidth, alignment: .top)
        }
    }

    private var languageDropdown: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                isLanguageDropdownOpen.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedLanguageTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .rotationEffect(.degrees(isLanguageDropdownOpen ? 180 : 0))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(AppTheme.text)
            .padding(.horizontal, 12)
            .frame(width: settingsControlWidth, height: settingsControlHeight)
            .background(AppTheme.surface.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(languageDropdownBorder, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            isLanguageDropdownButtonHovered = isHovered
            isHovered ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
        }
        .overlay(alignment: .top) {
            if isLanguageDropdownOpen {
                VStack(spacing: 0) {
                    ForEach(languageOptions, id: \.code) { option in
                        Button {
                            appState.settings.languageCode = option.code
                            withAnimation(.easeInOut(duration: 0.12)) {
                                isLanguageDropdownOpen = false
                            }
                        } label: {
                            HStack {
                                Text(option.title)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                                if appState.settings.languageCode == option.code {
                                    Image(systemName: "check")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(AppTheme.primary)
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                            .padding(.horizontal, 12)
                            .frame(width: settingsControlWidth, height: 32)
                            .background(languageOptionBackground(option.code))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { isHovered in
                            hoveredLanguageCode = isHovered ? option.code : nil
                            isHovered ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                        }
                    }
                }
                .padding(.vertical, 4)
                .frame(width: settingsControlWidth)
                .background(AppTheme.surface.opacity(0.98), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.outline, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.32), radius: 18, y: 8)
                .offset(y: settingsControlHeight + 6)
                .zIndex(100)
            }
        }
        .frame(width: settingsControlWidth)
        .zIndex(100)
    }

    private func releaseRowBackground(_ releaseID: TorrServerRelease.ID) -> Color {
        if appState.selectedReleaseID == releaseID {
            return AppTheme.surfaceHigh
        }
        if hoveredReleaseID == releaseID {
            return AppTheme.surfaceHigh.opacity(0.58)
        }
        return .clear
    }

    private var languageDropdownBorder: Color {
        if isLanguageDropdownOpen || isLanguageDropdownButtonHovered {
            return AppTheme.primary.opacity(0.72)
        }
        return AppTheme.outline
    }

    private func languageOptionBackground(_ code: String) -> Color {
        if hoveredLanguageCode == code {
            return AppTheme.surfaceHighest
        }
        if appState.settings.languageCode == code {
            return AppTheme.surfaceHigh
        }
        return .clear
    }

    private var languageOptions: [(code: String, title: String)] {
        [
            ("system", L.languageSystem),
            ("bg", L.languageBulgarian),
            ("en", L.languageEnglish),
            ("fr", L.languageFrench),
            ("ro", L.languageRomanian),
            ("ru", L.languageRussian),
            ("uk", L.languageUkrainian)
        ]
    }

    private var selectedLanguageTitle: String {
        languageOptions.first { $0.code == appState.settings.languageCode }?.title ?? L.languageSystem
    }

    private var aboutPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            TechnicalSectionTitle(title: L.about, systemImage: "info.circle")

            Text(L.developer)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(AppTheme.textMuted)

            Link(
                "dancheskus/TorrServerMacInstaller",
                destination: URL(string: "https://github.com/dancheskus/TorrServerMacInstaller")!
            )
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.secondary)
            .onHover { isHovering in
                if isHovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}

private struct ImmediateReleaseClickArea: NSViewRepresentable {
    let onClick: (Int) -> Void

    func makeNSView(context: Context) -> ClickView {
        let view = ClickView()
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: ClickView, context: Context) {
        nsView.onClick = onClick
    }

    final class ClickView: NSView {
        var onClick: ((Int) -> Void)?

        override func mouseDown(with event: NSEvent) {
            onClick?(event.clickCount)
        }

        override func scrollWheel(with event: NSEvent) {
            nextResponder?.scrollWheel(with: event)
        }
    }
}
