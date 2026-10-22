import Foundation

struct Overview: Decodable {
    let serverTime: String
    let user: String
    let accountKnown: Bool
    let cash: Double?
    let recordedMarketValue: Double
    let recordedAssets: Double?
    let holdings: [Holding]
    let monitor: MonitorSummary
    let decision: DecisionSummary?
    let review: ReviewBrief?
    let reviewActions: [ReviewTask]
    let companyCount: Int
    let portfolioNotice: String
}
struct Holding: Decodable, Identifiable {
    var id: String { code }
    let code, name: String
    let shares, recordedPrice, costBasis, recordedMarketValue: Double
    let updatedAt, hypothesis, invalidation: String
}
struct MonitorSummary: Decodable {
    let status: String
    let heartbeatAt: String?
    let activeAlertCount: Int
    let alerts: [MarketAlert]
    let notificationConfigured: Bool
}
struct MarketAlert: Decodable, Identifiable {
    let id: Int
    let title, severity, symbol, date: String
    let detail: JSONValue
    let lastSeen: String
    let acknowledged: Bool
    let deliveryStatus: String
}
struct MonitorPayload: Decodable { let status: String; let alerts: [MarketAlert] }
struct DecisionSummary: Decodable { let runId: Int; let date, status, summary: String; let isCurrent: Bool }
struct ReviewBrief: Decodable { let date, headline: String; let version: Int; let isCurrent: Bool }
struct ReviewTask: Decodable, Identifiable {
    let id: Int
    let tradeDate, kind, experimentKey, title, targetStage, status: String
    let `protocol`: ExperimentProtocol
    let latestResult: JSONValue
    let sourceRunId: Int
    var spec: ExperimentProtocol { `protocol` }
}
struct ExperimentProtocol: Decodable {
    let baseline, challenger, primaryMetric, successCondition, failureCondition, nextCheck: String?
}
struct LibraryCatalog: Decodable { let companies: [LibraryCompany] }
struct LibraryCompany: Decodable, Identifiable {
    var id: String { code }; let code, name, updatedAt: String; let versions: Int
}
struct CompanyDossier: Decodable {
    let code, name: String
    let decisionCard: CompanyCard
    let documents: [CompanyDocument]
    let limitations: [String]
}
struct CompanyCard: Decodable {
    let conclusion, principalContradiction, riskLevel: String
    let nextEvidence, invalidation: [String]
    let reportDate: String?
    let ageRequiresReview: Bool
}
struct CompanyDocument: Decodable, Identifiable {
    let id: Int; let kind, title, sourceRef, sourceDate, knownAt: String; let payload: JSONValue
}
struct ResultHistory: Decodable { let results: [ResultObservation] }
struct ReviewActionCatalog: Decodable { let items: [ReviewTask] }
struct ResultObservation: Decodable, Identifiable {
    let id: Int; let observationDate, recordedAt, sourceRef: String; let payload: JSONValue
}
struct SuccessReply: Decodable { let success: Bool }
struct AcknowledgeReply: Decodable { let status: String }
struct QueryReply: Decodable { let purpose, sql: String; let columns: [String]; let rows: [[String: JSONValue]]; let truncated: Bool }

enum JSONValue: Codable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Double), bool(Bool), null
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
    var text: String {
        if case .string(let value) = self { return value }
        if case .null = self { return "未知" }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return String(data: (try? encoder.encode(self)) ?? Data(), encoding: .utf8) ?? "未知"
    }
    subscript(key: String) -> JSONValue? { if case .object(let values) = self { return values[key] }; return nil }
}
