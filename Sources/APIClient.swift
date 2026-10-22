import Foundation
import Security

struct ServerLogin: Codable { let url, username, password: String }
enum ClientError: LocalizedError {
    case invalidURL, authentication, server(Int), connection, format
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "请输入有效的HTTPS服务地址。"
        case .authentication: return "用户名或密码不正确。"
        case .server(let code): return "服务返回状态 \(code)，请稍后重试。"
        case .connection: return "连接失败，请核对HTTPS入口、网络和端口。"
        case .format: return "服务数据结构不匹配，请更新App或后台。"
        }
    }
}

final class RedirectGuard: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

final class APIClient {
    private let login: ServerLogin
    private let base: URL
    private let session: URLSession
    init(login: ServerLogin) throws {
        guard let url = URL(string: login.url.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme?.lowercased() == "https", url.host != nil, url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil else { throw ClientError.invalidURL }
        self.login = login; base = url
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20; configuration.timeoutIntervalForResource = 35
        configuration.urlCredentialStorage = nil; configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration, delegate: RedirectGuard(), delegateQueue: nil)
    }
    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        try await send(path, method: "GET", query: query, body: nil)
    }
    func post<T: Decodable>(_ path: String, values: [String:String] = [:]) async throws -> T {
        try await send(path, method: "POST", query: [], body: JSONSerialization.data(withJSONObject: values))
    }
    private func send<T: Decodable>(_ path: String, method: String, query: [URLQueryItem], body: Data?) async throws -> T {
        var components = URLComponents(url: base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        guard let url = components.url else { throw ClientError.invalidURL }
        var request = URLRequest(url: url); request.httpMethod = method
        request.setValue("Basic " + Data("\(login.username):\(login.password)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body { request.httpBody = body; request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch { throw ClientError.connection }
        guard let http = response as? HTTPURLResponse else { throw ClientError.connection }
        if http.statusCode == 401 || http.statusCode == 403 { throw ClientError.authentication }
        guard (200..<300).contains(http.statusCode) else { throw ClientError.server(http.statusCode) }
        guard data.count <= 2_000_000 else { throw ClientError.format }
        let decoder = JSONDecoder(); decoder.keyDecodingStrategy = .convertFromSnakeCase
        do { return try decoder.decode(T.self, from: data) } catch { throw ClientError.format }
    }
}

enum LoginVault {
    private static let service = "OrbitTrade.server-login"
    static func read() -> ServerLogin? {
        let query: [String:Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:service,
                                   kSecAttrAccount as String:"primary", kSecReturnData as String:true,
                                   kSecMatchLimit as String:kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(ServerLogin.self, from: data)
    }
    static func save(_ login: ServerLogin) throws {
        let data = try JSONEncoder().encode(login)
        let query: [String:Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:service, kSecAttrAccount as String:"primary"]
        let update = SecItemUpdate(query as CFDictionary, [kSecValueData as String:data] as CFDictionary)
        if update == errSecSuccess { return }
        guard update == errSecItemNotFound else { throw ClientError.format }
        var add = query; add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(add as CFDictionary,nil) == errSecSuccess else { throw ClientError.format }
    }
    static func delete() {
        SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"primary"] as CFDictionary)
    }
}
