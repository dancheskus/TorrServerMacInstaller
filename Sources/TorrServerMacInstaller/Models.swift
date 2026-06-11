import Foundation

enum ServerStatus: Equatable {
    case notInstalled
    case stopped
    case starting
    case running(version: String?)
    case stopping
    case installing
    case error(String)

    var title: String {
        switch self {
        case .notInstalled:
            L.notInstalled
        case .stopped:
            L.stopped
        case .starting:
            L.starting
        case .running(let version):
            version.map { L.running($0) } ?? L.running
        case .stopping:
            L.stopping
        case .installing:
            L.installing
        case .error:
            L.error
        }
    }

    var symbolName: String {
        switch self {
        case .notInstalled:
            "arrow.down.circle"
        case .stopped:
            "stop.circle"
        case .starting, .installing:
            "hourglass"
        case .running:
            "play.circle.fill"
        case .stopping:
            "pause.circle"
        case .error:
            "exclamationmark.triangle"
        }
    }

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    var isBusy: Bool {
        switch self {
        case .starting, .stopping, .installing:
            true
        default:
            false
        }
    }
}

struct TorrServerRelease: Identifiable, Hashable {
    let id: String
    let tag: String
    let downloadURL: URL
    let isLatest: Bool
}

enum AppPaths {
    static let applicationSupport: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("TorrServerMacInstaller", isDirectory: true)
    }()

    static let binDirectory = applicationSupport.appendingPathComponent("bin", isDirectory: true)
    static let dataDirectory = applicationSupport.appendingPathComponent("data", isDirectory: true)
    static let logFile = dataDirectory.appendingPathComponent("torrserver.log")
    static let authFile = dataDirectory.appendingPathComponent("accs.db")

    static var serverBinaryName: String {
        #if arch(arm64)
        "TorrServer-darwin-arm64"
        #else
        "TorrServer-darwin-amd64"
        #endif
    }

    static let serverBinary = binDirectory.appendingPathComponent(serverBinaryName)
}
