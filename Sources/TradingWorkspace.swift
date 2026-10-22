import SwiftUI
import WebKit
import UIKit

/// The same authenticated workspace as the website, including all editing and
/// research controls. Account credentials never enter page JavaScript.
struct TradingWorkspaceScreen: View {
    @EnvironmentObject var store: TradingStore
    @State private var loading = true
    @State private var pageError: String?
    @State private var reload = 0

    var body: some View {
        Group {
            if let login = store.workspaceLogin {
                VStack(spacing: 0) {
                    if loading { ProgressView().tint(OrbitTheme.cyan).padding(.vertical, 4) }
                    if let pageError {
                        HStack { Text(pageError).font(.caption); Spacer(); Button("重试") { reload += 1 } }
                            .padding(10).foregroundStyle(.orange)
                    }
                    AuthenticatedWorkspace(login: login, reload: reload, loading: $loading, error: $pageError)
                        .id(store.generation)
                }
            } else {
                VStack(spacing: 20) {
                    EmptyScreen(title: "连接工作台", message: "连接后可编辑持仓与现金，运行公司调研、仓位建议、复盘并追踪两类账户回报。")
                    Button("登录服务器") { store.showSettings = true }.buttonStyle(.borderedProminent).tint(OrbitTheme.cyan)
                }.padding(24)
            }
        }
        .background(OrbitTheme.background)
        .navigationTitle("交易观测站").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if store.workspaceLogin != nil { Button { reload += 1 } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("刷新工作台") }
                Button { store.showSettings = true } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("服务器与登录设置")
            }
        }
    }
}

struct AuthenticatedWorkspace: UIViewRepresentable {
    let login: ServerLogin
    let reload: Int
    @Binding var loading: Bool
    @Binding var error: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.processPool = WKProcessPool()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = UIColor(OrbitTheme.background)
        view.scrollView.backgroundColor = UIColor(OrbitTheme.background)
        view.allowsBackForwardNavigationGestures = true
        let refresh = UIRefreshControl()
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.pullRefresh(_:)), for: .valueChanged)
        view.scrollView.refreshControl = refresh
        context.coordinator.webView = view
        if let url = URL(string: login.url), url.scheme?.lowercased() == "https" {
            view.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        }
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.reload != reload {
            context.coordinator.reload = reload
            view.reload()
        }
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        view.stopLoading(); view.navigationDelegate = nil; view.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: AuthenticatedWorkspace
        var reload: Int
        weak var webView: WKWebView?
        init(_ parent: AuthenticatedWorkspace) { self.parent = parent; reload = parent.reload }
        @objc func pullRefresh(_ sender: UIRefreshControl) { webView?.reload(); sender.endRefreshing() }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.loading = true; parent.error = nil
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.loading = false }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
        private func failed(_ error: Error) {
            parent.loading = false
            if (error as NSError).code != NSURLErrorCancelled { parent.error = "工作台加载失败，请检查网络或登录设置。" }
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.loading = false; parent.error = "页面已暂停，点击重试可读取最新状态。"
        }
        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                     completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let space = challenge.protectionSpace
            if space.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                completionHandler(.performDefaultHandling, nil)
                return
            }
            guard let server = URL(string: parent.login.url),
                  space.authenticationMethod == NSURLAuthenticationMethodHTTPBasic,
                  space.protocol?.lowercased() == "https", space.host.lowercased() == server.host?.lowercased(),
                  space.port == (server.port ?? 443), challenge.previousFailureCount == 0 else {
                completionHandler(.cancelAuthenticationChallenge, nil); return
            }
            completionHandler(.useCredential, URLCredential(user: parent.login.username, password: parent.login.password, persistence: .forSession))
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url, let server = URL(string: parent.login.url) else { decisionHandler(.cancel); return }
            if WorkspacePolicy.permits(url, server: server) {
                if navigationAction.targetFrame == nil { webView.load(navigationAction.request); decisionHandler(.cancel) }
                else { decisionHandler(.allow) }
            } else {
                // Open an explicitly tapped evidence link outside the authenticated
                // workspace; do not attach a password or Authorization header.
                if navigationAction.navigationType == .linkActivated && url.scheme?.lowercased() == "https" && url.user == nil && url.password == nil {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
            }
        }
        private func presenter(_ webView: WKWebView) -> UIViewController? {
            var controller = webView.window?.rootViewController
            while let presented = controller?.presentedViewController { controller = presented }
            return controller
        }
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            guard let controller = presenter(webView), controller.presentedViewController == nil else { completionHandler(false); return }
            let alert = UIAlertController(title: "确认操作", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "确认", style: .default) { _ in completionHandler(true) })
            controller.present(alert, animated: true)
        }
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            guard let controller = presenter(webView), controller.presentedViewController == nil else { completionHandler(); return }
            let alert = UIAlertController(title: "工作台提示", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default) { _ in completionHandler() })
            controller.present(alert, animated: true)
        }
    }
}
