import Foundation

enum WorkspacePolicy {
    static func permits(_ target: URL, server: URL) -> Bool {
        target.scheme?.lowercased() == "https" && server.scheme?.lowercased() == "https"
        && target.host?.lowercased() == server.host?.lowercased()
        && (target.port ?? 443) == (server.port ?? 443)
        && target.user == nil && target.password == nil
    }
}
