import Foundation
import Darwin

@MainActor
final class ServerProcessManager: ObservableObject {
    @Published private(set) var status: ServerStatus = .notInstalled

    private var process: Process?
    private let installService = InstallService()
    private let authWriter = AuthConfigWriter()

    var isInstalled: Bool {
        installService.isInstalled()
    }

    func refreshInstalledState() {
        if process?.isRunning == true {
            return
        }
        status = isInstalled ? .stopped : .notInstalled
    }

    func start(port: Int, authEnabled: Bool, username: String, password: String) async {
        guard !status.isBusy else { return }
        guard !status.isRunning else { return }
        guard isInstalled else {
            status = .notInstalled
            return
        }
        guard (1...65535).contains(port) else {
            status = .error(L.portRangeError)
            return
        }

        status = .starting

        do {
            terminateRunningServerProcesses()
            try authWriter.writeAuthConfig(enabled: authEnabled, username: username, password: password)
            try FileManager.default.createDirectory(at: AppPaths.dataDirectory, withIntermediateDirectories: true)

            let newProcess = Process()
            newProcess.executableURL = AppPaths.serverBinary
            var arguments = [
                "-d", AppPaths.dataDirectory.path,
                "-l", AppPaths.logFile.path,
                "-p", String(port)
            ]
            if authEnabled {
                arguments.append("-a")
            }
            newProcess.arguments = arguments
            newProcess.currentDirectoryURL = AppPaths.dataDirectory
            newProcess.standardOutput = FileHandle.nullDevice
            newProcess.standardError = FileHandle.nullDevice
            newProcess.terminationHandler = { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    if self.status.isRunning || self.status == .starting {
                        self.status = self.isInstalled ? .stopped : .notInstalled
                    }
                }
            }

            try newProcess.run()
            process = newProcess
            if let version = await waitForVersion(port: port, process: newProcess) {
                status = .running(version: version)
            } else if newProcess.isRunning {
                status = .running(version: nil)
            } else {
                process = nil
                status = .error(L.serverStartFailed)
            }
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    func stop() {
        guard let process, process.isRunning else {
            self.process = nil
            terminateRunningServerProcesses()
            refreshInstalledState()
            return
        }

        status = .stopping
        process.terminate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self, weak process] in
            guard let self else { return }
            if process?.isRunning == true {
                process?.interrupt()
            }
            self.process = nil
            self.terminateRunningServerProcesses()
            self.refreshInstalledState()
        }
    }

    func stopBeforeQuit() {
        guard let process, process.isRunning else {
            self.process = nil
            terminateRunningServerProcesses()
            refreshInstalledState()
            return
        }

        status = .stopping
        process.terminate()

        for _ in 0..<20 where process.isRunning {
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
        }

        self.process = nil
        terminateRunningServerProcesses()
        refreshInstalledState()
    }

    func install(_ release: TorrServerRelease, progress: @MainActor @escaping (String) -> Void) async throws {
        stopBeforeQuit()
        status = .installing
        try await installService.install(release, progress: progress)
        status = .stopped
    }

    func removeServerFiles() throws {
        stopBeforeQuit()
        let binaryNames = ["TorrServer-darwin-arm64", "TorrServer-darwin-amd64"]
        for binaryName in binaryNames {
            let binaryURL = AppPaths.binDirectory.appendingPathComponent(binaryName)
            if FileManager.default.fileExists(atPath: binaryURL.path) {
                try FileManager.default.removeItem(at: binaryURL)
            }
        }
        status = .notInstalled
    }

    private func waitForVersion(port: Int, process: Process) async -> String? {
        let url = URL(string: "http://localhost:\(port)/echo")!

        for _ in 0..<20 {
            guard process.isRunning else { return nil }

            do {
                let request = URLRequest(url: url, timeoutInterval: 0.6)
                let (data, _) = try await URLSession.shared.data(for: request)
                if let version = String(data: data, encoding: .utf8), !version.isEmpty {
                    return version
                }
            } catch {
                try? await Task.sleep(for: .milliseconds(300))
            }
        }

        return nil
    }

    private func terminateRunningServerProcesses() {
        unloadLegacyLaunchAgent()

        let pids = runningServerProcessIDs()
        guard !pids.isEmpty else { return }

        for pid in pids {
            kill(pid, SIGTERM)
        }

        for _ in 0..<20 {
            let remainingPIDs = pids.filter { isProcessRunning($0) }
            if remainingPIDs.isEmpty {
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        for pid in pids where isProcessRunning(pid) {
            kill(pid, SIGKILL)
        }
    }

    private func runningServerProcessIDs() -> [pid_t] {
        let ps = Process()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-axo", "pid=,args="]

        let pipe = Pipe()
        ps.standardOutput = pipe
        ps.standardError = FileHandle.nullDevice

        do {
            try ps.run()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        ps.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        let currentPID = ProcessInfo.processInfo.processIdentifier
        return output
            .split(separator: "\n")
            .compactMap { line -> pid_t? in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = trimmedLine.split(maxSplits: 1, whereSeparator: \.isWhitespace)
                guard parts.count == 2,
                      let pid = pid_t(String(parts[0])),
                      pid != currentPID,
                      isTorrServerCommand(String(parts[1])) else {
                    return nil
                }
                return pid
            }
    }

    private func isTorrServerCommand(_ arguments: String) -> Bool {
        let knownBinaryPaths = [
            AppPaths.binDirectory.appendingPathComponent("TorrServer-darwin-arm64").path,
            AppPaths.binDirectory.appendingPathComponent("TorrServer-darwin-amd64").path,
            "/Users/Shared/TorrServer/TorrServer"
        ]

        if knownBinaryPaths.contains(where: { arguments == $0 || arguments.hasPrefix($0 + " ") }) {
            return true
        }

        let knownBinaryNames = [
            "TorrServer-darwin-arm64",
            "TorrServer-darwin-amd64",
            "TorrServer"
        ]

        return knownBinaryNames.contains { binaryName in
            arguments == binaryName
                || arguments.hasPrefix(binaryName + " ")
                || arguments.contains("/\(binaryName) ")
        }
    }

    private func isProcessRunning(_ pid: pid_t) -> Bool {
        kill(pid, 0) == 0
    }

    private func unloadLegacyLaunchAgent() {
        let plistPath = "/Library/LaunchAgents/torrserver.plist"
        guard FileManager.default.fileExists(atPath: plistPath) else { return }

        runLaunchctl(arguments: ["bootout", "gui/\(getuid())", plistPath])
        runLaunchctl(arguments: ["remove", "TorrServer"])
    }

    private func runLaunchctl(arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
