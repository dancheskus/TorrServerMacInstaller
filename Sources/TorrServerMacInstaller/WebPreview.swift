import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct WebPreview: NSViewRepresentable {
    let url: URL
    let reloadID: UUID
    let authEnabled: Bool
    let username: String
    let password: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.update(authEnabled: authEnabled, username: username, password: password)
        webView.load(URLRequest(url: url))
        context.coordinator.lastReloadID = reloadID
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(authEnabled: authEnabled, username: username, password: password)
        if webView.url != url || context.coordinator.lastReloadID != reloadID {
            webView.load(URLRequest(url: url))
            context.coordinator.lastReloadID = reloadID
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var lastReloadID: UUID?
        private var authEnabled = false
        private var username = ""
        private var password = ""

        func update(authEnabled: Bool, username: String, password: String) {
            self.authEnabled = authEnabled
            self.username = username
            self.password = password
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping @MainActor @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            let method = challenge.protectionSpace.authenticationMethod
            let supportsHTTPAuth = method == NSURLAuthenticationMethodHTTPBasic
                || method == NSURLAuthenticationMethodHTTPDigest
                || method == NSURLAuthenticationMethodDefault

            guard authEnabled,
                  supportsHTTPAuth,
                  challenge.previousFailureCount == 0,
                  !username.isEmpty,
                  !password.isEmpty else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            let credential = URLCredential(
                user: username,
                password: password,
                persistence: .forSession
            )
            completionHandler(.useCredential, credential)
        }

        @MainActor
        func webView(
            _ webView: WKWebView,
            runOpenPanelWith parameters: WKOpenPanelParameters,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping @MainActor @Sendable ([URL]?) -> Void
        ) {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = parameters.allowsMultipleSelection
            panel.canChooseDirectories = parameters.allowsDirectories
            panel.canChooseFiles = true
            panel.resolvesAliases = true
            panel.prompt = L.open

            if !parameters.allowsDirectories,
               let torrentType = UTType(filenameExtension: "torrent") {
                panel.allowedContentTypes = [torrentType]
            }

            panel.begin { response in
                completionHandler(response == .OK ? panel.urls : nil)
            }
        }
    }
}
