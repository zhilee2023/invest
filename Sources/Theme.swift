import SwiftUI

enum OrbitTheme {
    static let background = Color(red:7/255.0,green:11/255.0,blue:18/255.0)
    static let panel = Color(red:14/255.0,green:24/255.0,blue:37/255.0)
    static let cyan = Color(red:140/255.0,green:232/255.0,blue:234/255.0)
    static let line = Color(red:40/255.0,green:60/255.0,blue:79/255.0)
    static let muted = Color(red:143/255.0,green:163/255.0,blue:182/255.0)
    static func money(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return value.formatted(.number.precision(.fractionLength(2)))
    }
    static func status(_ value: String) -> String {
        ["needs_specification":"待补协议","waiting_data":"等待样本","observing":"观察中",
         "paused":"已暂停","stopped":"已停止","superseded":"协议已更新",
         "monitoring":"盘中监控","outside_session":"休市等待","market_closed":"今日休市",
         "calendar_missing":"日历待更新","degraded":"行情有缺口","heartbeat_stale":"心跳过期",
         "completed":"已完成","blocked":"门控阻断","failed":"运行失败","not_started":"尚未启动"] [value] ?? value
    }
}

struct OrbitPanel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.frame(maxWidth:.infinity,alignment:.leading).padding(20)
        .background(OrbitTheme.panel,in:RoundedRectangle(cornerRadius:20))
        .overlay(RoundedRectangle(cornerRadius:20).stroke(OrbitTheme.line,lineWidth:0.8)) }
}
struct DetailLine: View {
    let title: String; let value: String?
    var body: some View { VStack(alignment:.leading,spacing:6) {
        Text(title).font(.caption).foregroundStyle(OrbitTheme.muted)
        Text((value?.isEmpty == false ? value : nil) ?? "待补充").font(.subheadline).textSelection(.enabled)
    }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,7) }
}
struct JSONDisclosure: View {
    let title: String; let value: JSONValue
    var body: some View { DisclosureGroup(title) {
        Text(String(value.text.prefix(6000))).font(.system(.caption,design:.monospaced))
            .frame(maxWidth:.infinity,alignment:.leading).textSelection(.enabled).padding(.vertical,8)
    }.font(.subheadline).tint(OrbitTheme.cyan) }
}
struct EmptyScreen: View {
    let title: String; let message: String
    var body: some View { ContentUnavailableView(title,systemImage:"circle.dotted",description:Text(message)) }
}
