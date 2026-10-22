import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var store: TradingStore
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack { VStack(alignment:.leading,spacing:8) { Text("ORBIT / OBSERVATORY").font(.system(size:10,design:.monospaced)).tracking(2).foregroundStyle(OrbitTheme.cyan);Text("今日观测").font(.largeTitle.weight(.light)) }; Spacer();Image(systemName:"circle.hexagongrid").font(.title).foregroundStyle(OrbitTheme.cyan) }
                if let error = store.error { Text(error + "；下方如有记录，仅为上次成功读取。").font(.caption).foregroundStyle(.orange) }
                if let data = store.overview {
                    OrbitPanel { VStack(alignment:.leading,spacing:14) {
                        Text("录入资产 · 非实时净值").font(.caption).foregroundStyle(OrbitTheme.muted)
                        Text(OrbitTheme.money(data.recordedAssets)).font(.system(size:36,weight:.light,design:.monospaced)).minimumScaleFactor(0.6).lineLimit(1)
                        HStack { Text("现金 \(OrbitTheme.money(data.cash))");Spacer();Text("持仓 \(data.holdings.count) 只") }.font(.caption).foregroundStyle(OrbitTheme.muted)
                    } }
                    NavigationLink { AlertsScreen() } label: {
                        OrbitPanel { HStack { Image(systemName:data.monitor.activeAlertCount>0 ? "exclamationmark.circle" : "dot.radiowaves.left.and.right").foregroundStyle(data.monitor.activeAlertCount>0 ? Color.orange : OrbitTheme.cyan);VStack(alignment:.leading,spacing:5){Text("持仓预警").font(.headline);Text("\(data.monitor.activeAlertCount) 项待核对 · \(OrbitTheme.status(data.monitor.status))").font(.caption).foregroundStyle(OrbitTheme.muted)};Spacer();Image(systemName:"chevron.right").font(.caption).foregroundStyle(OrbitTheme.muted) } }
                    }.buttonStyle(.plain)
                    OrbitPanel { VStack(alignment:.leading,spacing:12) {
                        Text("决策摘要").font(.caption).foregroundStyle(OrbitTheme.cyan)
                        if let decision = data.decision {
                            Text(decision.summary).font(.subheadline).lineLimit(4)
                            Text("\(decision.date) · \(OrbitTheme.status(decision.status))\(decision.isCurrent ? "" : " · 历史记录，需更新")").font(.caption2).foregroundStyle(OrbitTheme.muted)
                            NavigationLink("查看依据与门控") { DecisionScreen(decision:decision) }.font(.caption).foregroundStyle(OrbitTheme.cyan)
                        } else { Text("尚未形成调仓判断").font(.subheadline) }
                    } }
                    Text(data.portfolioNotice).font(.caption2).foregroundStyle(OrbitTheme.muted)
                } else {
                    EmptyScreen(title:"等待连接",message:"连接你的交易服务器后，持仓、预警与研究记录会显示在这里。")
                    Button("连接服务器") { store.showSettings = true }.buttonStyle(.borderedProminent).tint(OrbitTheme.cyan).foregroundStyle(OrbitTheme.background)
                }
            }.padding(20)
        }.background(OrbitTheme.background).refreshable { await store.refresh() }
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button { store.showSettings = true } label:{Image(systemName:"slider.horizontal.3")} } }
    }
}

struct HoldingsScreen: View {
    @EnvironmentObject var store: TradingStore
    var body: some View {
        List {
            Section { ForEach(store.overview?.holdings ?? []) { holding in
                NavigationLink { HoldingDetailScreen(holding:holding) } label: {
                    HStack { VStack(alignment:.leading,spacing:5) { Text(holding.name).font(.headline);Text(holding.code).font(.system(.caption,design:.monospaced)).foregroundStyle(OrbitTheme.muted) };Spacer();VStack(alignment:.trailing,spacing:5) { Text(OrbitTheme.money(holding.recordedMarketValue)).font(.system(.subheadline,design:.monospaced));Text("\(holding.shares.formatted()) 股").font(.caption).foregroundStyle(OrbitTheme.muted) } }.padding(.vertical,5)
                }
            } } footer: { Text("录入市值非实时净值。点击持仓查看投资假设、失效条件与记录时间。") }
            if (store.overview?.holdings ?? []).isEmpty { Text("暂无已录入持仓").foregroundStyle(OrbitTheme.muted) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("持仓").refreshable { await store.refresh() }
    }
}
struct HoldingDetailScreen: View {
    let holding: Holding
    var body: some View {
        List {
            Section("记录") { DetailLine(title:"证券",value:holding.code);DetailLine(title:"股数",value:holding.shares.formatted());DetailLine(title:"录入价格 / 成本",value:"\(OrbitTheme.money(holding.recordedPrice)) / \(OrbitTheme.money(holding.costBasis))");DetailLine(title:"最近记录",value:holding.updatedAt) }
            Section("原有判断") { DetailLine(title:"持仓假设",value:holding.hypothesis);DetailLine(title:"失效 / 调仓条件",value:holding.invalidation) }
            Section { NavigationLink("公司资料与证据") { CompanyScreen(code:holding.code) } }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle(holding.name)
    }
}

struct DecisionScreen: View {
    let decision: DecisionSummary
    @EnvironmentObject var store: TradingStore
    @State private var details: JSONValue?
    @State private var error: String?
    var body: some View {
        List {
            Section { Text(decision.summary);DetailLine(title:"日期与状态",value:"\(decision.date) · \(OrbitTheme.status(decision.status))");Text(decision.isCurrent ? "按当前研究日期记录；仍须本人核对。" : "这是历史记录，不能当作今日指令。").font(.caption).foregroundStyle(.orange) }
            if let details { Section { JSONDisclosure(title:"程序门控、风险与持仓判断",value:details) } }
            if let error { Text(error).foregroundStyle(.orange) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("判断依据")
         .task { do { details = try await store.client?.get("api/mobile/decisions/\(decision.runId)") } catch { self.error = error.localizedDescription } }
    }
}

struct AlertsScreen: View {
    @EnvironmentObject var store: TradingStore
    @State private var alerts: [MarketAlert] = []
    @State private var error: String?
    func load() async { do { let data: MonitorPayload? = try await store.client?.get("api/monitor");alerts = data?.alerts ?? [] } catch { self.error = error.localizedDescription } }
    var body: some View {
        List {
            Section { Text("后台提醒继续由Server酱发送。App打开时可查看与确认预警；没有提醒不代表没有风险。").font(.caption).foregroundStyle(OrbitTheme.muted) }
            if let error { Text(error).foregroundStyle(.orange) }
            ForEach(alerts) { alert in
                DisclosureGroup {
                    Text(alert.detail["action"]?.text ?? "请人工核对").font(.subheadline)
                    DetailLine(title:"记录时间",value:alert.lastSeen)
                    DetailLine(title:"通知",value:alert.deliveryStatus == "delivered" ? "通知通道已接收" : "请核对通道状态")
                    if !alert.acknowledged { Button("已知悉") { Task { do { let _: AcknowledgeReply? = try await store.client?.post("api/monitor/alerts/\(alert.id)/acknowledge");await load();await store.refresh() } catch { self.error = error.localizedDescription } } } }
                } label: { Label(alert.title,systemImage:alert.acknowledged ? "checkmark.circle" : "exclamationmark.circle").font(.subheadline).foregroundStyle(alert.severity == "critical" ? Color.pink : Color.primary) }
            }
            if alerts.isEmpty { Text("暂无已记录预警").foregroundStyle(OrbitTheme.muted) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("持仓预警").task { await load() }.refreshable { await load() }
    }
}

struct SettingsScreen: View {
    @EnvironmentObject var store: TradingStore
    @Environment(\.dismiss) private var dismiss
    @State private var url = LoginVault.read()?.url ?? "https://43.128.79.120"
    @State private var user = LoginVault.read()?.username ?? "admin"
    @State private var password = LoginVault.read()?.password ?? ""
    @State private var saving = false
    var body: some View {
        NavigationStack {
            Form {
                Section("连接交易服务器") {
                    TextField("HTTPS地址",text:$url).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("用户名",text:$user).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField("登录密码",text:$password)
                    Button(saving ? "正在连接…" : "验证并保存") { Task { saving = true;defer { saving = false };if await store.connect(ServerLogin(url:url,username:user,password:password)) { dismiss() } } }.disabled(saving || user.isEmpty || password.isEmpty)
                    if let error = store.error { Text(error).font(.caption).foregroundStyle(.orange) }
                } footer: { Text("登录凭据保存在本机钥匙串。HTTPS入口需先配置完成；地址中的IP不代表服务器已有有效证书。") }
                Section("个人设备版") { Text("v0.1.0 · 个人研究辅助");Text("普通Apple ID通过个人签名安装，需定期续签。后台通知使用现有Server酱，App不在后台持续轮询。").font(.caption).foregroundStyle(OrbitTheme.muted) }
                if store.client != nil { Section { Button("退出并清除本机凭据",role:.destructive) { store.disconnect();password = "";dismiss() } } }
            }.navigationTitle("设置").toolbar { ToolbarItem(placement:.topBarTrailing) { Button("完成") { dismiss() } } }
        }
    }
}
