import Foundation

@main struct ModelChecks {
    static func main() throws {
        let decoder = JSONDecoder();decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = try Data(contentsOf:URL(fileURLWithPath:"Tests/overview.json"))
        let overview = try decoder.decode(Overview.self,from:data)
        precondition(overview.user == "test-user")
        precondition(overview.recordedAssets == nil)
        precondition(overview.holdings.isEmpty)
        precondition(overview.reviewActions[0].spec.primaryMetric == "excess_return_5d")
        precondition(overview.reviewActions[0].status == "waiting_data")
        let value = try decoder.decode(JSONValue.self,from:Data(#"{"metric":null,"count":2,"verified":false}"#.utf8))
        precondition(value["metric"]?.text == "未知")
        precondition(value["verified"]?.text == "false")
        let origin = URL(string: "https://43.128.79.120")!
        precondition(WorkspacePolicy.permits(URL(string: "https://43.128.79.120/#operations")!, server: origin))
        precondition(!WorkspacePolicy.permits(URL(string: "http://43.128.79.120")!, server: origin))
        precondition(!WorkspacePolicy.permits(URL(string: "https://43.128.79.120:8443")!, server: origin))
        precondition(!WorkspacePolicy.permits(URL(string: "https://other.example.com")!, server: origin))
        precondition(!WorkspacePolicy.permits(URL(string: "https://u:p@43.128.79.120")!, server: origin))
        print("Mobile snake_case decoding and unknown-result handling passed")
    }
}
