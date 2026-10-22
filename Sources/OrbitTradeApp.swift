import SwiftUI

@MainActor final class TradingStore: ObservableObject {
    @Published var overview: Overview?
    @Published var error: String?
    @Published var loading = false
    @Published var showSettings = false
    @Published var generation = 0
    private(set) var client: APIClient?
    init() { if let login = LoginVault.read() { client = try? APIClient(login: login) } }
    func refresh() async {
        guard let client, !loading else { return }
        loading = true; defer { loading = false }
        do { overview = try await client.get("api/mobile/overview"); error = nil }
        catch { if !Task.isCancelled { self.error = error.localizedDescription } }
    }
    func connect(_ login: ServerLogin) async -> Bool {
        do {
            let api = try APIClient(login: login)
            let value: Overview = try await api.get("api/mobile/overview")
            try LoginVault.save(login)
            client = api; overview = value; error = nil; generation += 1
            return true
        } catch { self.error = error.localizedDescription; return false }
    }
    func disconnect() { LoginVault.delete(); client = nil; overview = nil; generation += 1 }
}

@main struct OrbitTradeApp: App {
    @StateObject private var store = TradingStore()
    @State private var showCover = true
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            Group {
                if showCover {
                    CoverScreen {
                        showCover = false
                        if store.client == nil { store.showSettings = true }
                    }
                } else {
                    TabView {
                        NavigationStack { HomeScreen() }.tabItem { Label("今日",systemImage:"circle.hexagongrid") }
                        NavigationStack { HoldingsScreen() }.tabItem { Label("持仓",systemImage:"chart.pie") }
                        NavigationStack { LibraryScreen() }.tabItem { Label("研究",systemImage:"square.stack.3d.up") }
                        NavigationStack { ReviewScreen() }.tabItem { Label("复盘",systemImage:"scope") }
                    }.tint(OrbitTheme.cyan)
                }
            }
            .environmentObject(store).preferredColorScheme(.dark)
            .sheet(isPresented:$store.showSettings) { SettingsScreen().environmentObject(store) }
            .task(id:"\(phase)-\(store.generation)-\(showCover)") {
                guard phase == .active, !showCover else { return }
                while !Task.isCancelled {
                    await store.refresh()
                    do { try await Task.sleep(nanoseconds:30_000_000_000) } catch { break }
                }
            }
        }
    }
}
