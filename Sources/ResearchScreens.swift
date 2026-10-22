import SwiftUI

struct LibraryScreen: View {
    @EnvironmentObject var store: TradingStore
    @State private var companies: [LibraryCompany] = []
    @State private var query = ""
    @State private var error: String?
    func load() async {
        do { let data: LibraryCatalog? = try await store.client?.get("api/companies/library",query:[URLQueryItem(name:"q",value:query)]);companies = data?.companies ?? [];error = nil }
        catch { self.error = error.localizedDescription }
    }
    var body: some View {
        List {
            Section { Text("先读资料库，只补查变化与关键未知。入库不代表核验通过。").font(.caption).foregroundStyle(OrbitTheme.muted) }
            if let error { Text(error).foregroundStyle(.orange) }
            ForEach(companies) { company in
                NavigationLink { CompanyScreen(code:company.code) } label: {
                    HStack { VStack(alignment:.leading,spacing:5) { Text(company.name).font(.headline);Text(company.code).font(.system(.caption,design:.monospaced)).foregroundStyle(OrbitTheme.muted) };Spacer();Text("\(company.versions) 份资料").font(.caption).foregroundStyle(OrbitTheme.muted) }.padding(.vertical,4)
                }
            }
            if companies.isEmpty { Text("暂无匹配资料").foregroundStyle(OrbitTheme.muted) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("公司研究")
         .searchable(text:$query,prompt:"代码、名称或资料关键词").onSubmit(of:.search) { Task { await load() } }
         .task { await load() }.refreshable { await load() }
    }
}
struct CompanyScreen: View {
    let code: String
    @EnvironmentObject var store: TradingStore
    @State private var data: CompanyDossier?
    @State private var error: String?
    var body: some View {
        List {
            if let data {
                Section("结论") { Text(data.decisionCard.conclusion);DetailLine(title:"主要矛盾",value:data.decisionCard.principalContradiction);DetailLine(title:"风险 / 研究日期",value:"\(data.decisionCard.riskLevel) · \(data.decisionCard.reportDate ?? "未知")");Text(data.decisionCard.ageRequiresReview ? "旧研究需要复核。" : "使用前仍须检查最新研究门控。").font(.caption).foregroundStyle(.orange) }
                Section("下一项证据") { ForEach(data.decisionCard.nextEvidence,id:\.self) { Text($0).font(.subheadline) };if data.decisionCard.nextEvidence.isEmpty { Text("尚未记录").foregroundStyle(OrbitTheme.muted) } }
                Section("失效条件") { ForEach(data.decisionCard.invalidation,id:\.self) { Text($0).font(.subheadline) } }
                Section("资料与来源") { ForEach(data.documents) { doc in
                    DisclosureGroup("\(doc.title) · \(doc.sourceDate)") {
                        DetailLine(title:"原始引用",value:doc.sourceRef);DetailLine(title:"首次入库",value:doc.knownAt)
                        JSONDisclosure(title:"原始资料内容",value:doc.payload)
                    }
                } }
                Section { ForEach(data.limitations,id:\.self) { Text($0).font(.caption).foregroundStyle(OrbitTheme.muted) } }
            } else if let error { Text(error).foregroundStyle(.orange) }
            else { ProgressView("读取公司资料…") }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle(data?.name ?? code)
         .task { do { data = try await store.client?.get("api/companies/library/\(code)");if store.client == nil { error = "请先连接服务器" } } catch { self.error = error.localizedDescription } }
    }
}

struct ReviewScreen: View {
    @EnvironmentObject var store: TradingStore
    @State private var tasks: [ReviewTask] = []
    @State private var error: String?
    func load() async { do { let data: ReviewActionCatalog? = try await store.client?.get("api/review/actions");tasks = data?.items ?? [];error = nil } catch { self.error = error.localizedDescription } }
    var body: some View {
        List {
            Section {
                if let brief = store.overview?.review { Text(brief.headline);Text("\(brief.date) · v\(brief.version)\(brief.isCurrent ? "" : " · 历史复盘")").font(.caption).foregroundStyle(OrbitTheme.muted) }
                else { Text("尚未形成复盘结论").foregroundStyle(OrbitTheme.muted) }
                Text("先做实验并逐次记录结果；模块方针、提示词和长期记忆迭代留待另行决定。").font(.caption).foregroundStyle(OrbitTheme.muted)
            }
            Section("下一步验证 action") {
                ForEach(tasks.filter { $0.status != "superseded" }.prefix(3)) { task in taskLink(task) }
                if tasks.isEmpty { Text("暂无已登记的实验action").foregroundStyle(OrbitTheme.muted) }
            }
            if tasks.count>3 { Section { DisclosureGroup("其他验证与历史") { ForEach(tasks.dropFirst(3)) { task in taskLink(task) } } } }
            Section { NavigationLink("数据查询 Agent · 按需查证") { QueryScreen() } }
            if let error { Text(error).foregroundStyle(.orange) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("复盘与实验").task { await load() }.refreshable { await store.refresh();await load() }
    }
    func taskLink(_ task: ReviewTask) -> some View {
        NavigationLink { ReviewActionScreen(task:task) } label: {
            VStack(alignment:.leading,spacing:6) { Text(task.title).font(.subheadline.weight(.medium));Text(OrbitTheme.status(task.status)).font(.caption).foregroundStyle(OrbitTheme.cyan);Text(task.spec.nextCheck ?? "等待下一有效观察").font(.caption).lineLimit(2).foregroundStyle(OrbitTheme.muted) }.padding(.vertical,5)
        }
    }
}

struct ReviewActionScreen: View {
    let task: ReviewTask
    @EnvironmentObject var store: TradingStore
    @State private var history: [ResultObservation] = []
    @State private var showObservation = false
    @State private var showSpecification = false
    @State private var error: String?
    func load() async { do { let data: ResultHistory? = try await store.client?.get("api/review/actions/\(task.id)/results");history = data?.results ?? [] } catch { self.error = error.localizedDescription } }
    var body: some View {
        List {
            Section { Text(task.title).font(.headline);Text(OrbitTheme.status(task.status)).font(.caption).foregroundStyle(OrbitTheme.cyan);Text("本任务只验证实验，不改变生产规则或真实持仓。").font(.caption).foregroundStyle(OrbitTheme.muted) }
            Section("冻结的实验协议") { DetailLine(title:"基准",value:task.spec.baseline);DetailLine(title:"单一备选",value:task.spec.challenger);DetailLine(title:"主指标",value:task.spec.primaryMetric);DetailLine(title:"成立条件",value:task.spec.successCondition);DetailLine(title:"失败条件",value:task.spec.failureCondition);DetailLine(title:"下一检查",value:task.spec.nextCheck) }
            Section { JSONDisclosure(title:"当前结果与限制",value:task.latestResult)
                if task.status == "needs_specification" { Button("补齐协议，建立新版本") { showSpecification = true } }
                if task.status != "superseded" { Button("记录本次结果") { showObservation = true } }
            }
            Section("逐次结果") { ForEach(history) { result in
                DisclosureGroup("\(result.observationDate) · #\(result.id)") { DetailLine(title:"证据引用",value:result.sourceRef);DetailLine(title:"实际记录时间",value:result.recordedAt);JSONDisclosure(title:"观察内容",value:result.payload) }
            };if history.isEmpty { Text("尚无结果记录").foregroundStyle(OrbitTheme.muted) } }
            if let error { Text(error).foregroundStyle(.orange) }
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("验证action #\(task.id)").navigationBarTitleDisplayMode(.inline).task { await load() }
         .sheet(isPresented:$showObservation,onDismiss:{Task { await load();await store.refresh() }}) { ObservationForm(actionId:task.id) }
         .sheet(isPresented:$showSpecification,onDismiss:{Task { await load();await store.refresh() }}) { SpecificationForm(actionId:task.id) }
    }
}

struct ObservationForm: View {
    let actionId: Int
    @EnvironmentObject var store: TradingStore
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var source = ""
    @State private var status = "observation_recorded"
    @State private var requestId = UUID().uuidString
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        NavigationStack { Form {
            Section("本次观察") { TextField("测到了什么，或缺少什么数据",text:$note,axis:.vertical).lineLimit(4...8);TextField("证据引用或原始来源",text:$source).textInputAutocapitalization(.never);Picker("状态",selection:$status) {Text("记录观察").tag("observation_recorded");Text("仍需数据").tag("waiting_data");Text("暂停").tag("paused");Text("停止").tag("stopped")} }
            Section { Text("人工观察单独标记，不会自动宣称实验成功。").font(.caption).foregroundStyle(OrbitTheme.muted);Button(busy ? "保存中…" : "保存结果") { Task {
                guard let client = store.client else { error = "请先连接服务器";return }
                busy = true;defer { busy = false }
                do { let _: SuccessReply = try await client.post("api/review/actions/\(actionId)/observations",values:["note":note,"source_ref":source,"result_status":status,"request_id":requestId]);dismiss() } catch { self.error = error.localizedDescription }
            } }.disabled(busy || note.count<4 || note.count>1000 || source.count<4 || source.count>300) }
            if let error { Text(error).foregroundStyle(.orange) }
        }.navigationTitle("记录结果").toolbar { ToolbarItem(placement:.topBarTrailing) { Button("取消") { dismiss() } } } }
    }
}

struct SpecificationForm: View {
    let actionId: Int
    @EnvironmentObject var store: TradingStore
    @Environment(\.dismiss) private var dismiss
    @State private var baseline = ""
    @State private var challenger = ""
    @State private var metric = ""
    @State private var success = ""
    @State private var failure = ""
    @State private var next = ""
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        NavigationStack { Form {
            Section("单变量对照") {TextField("当前基准",text:$baseline,axis:.vertical);TextField("单一备选",text:$challenger,axis:.vertical);TextField("主指标与口径",text:$metric,axis:.vertical)}
            Section("预先约定") {TextField("成立条件",text:$success,axis:.vertical);TextField("失败条件",text:$failure,axis:.vertical);TextField("下次检查时间或触发",text:$next,axis:.vertical)}
            Section { Text("保存新协议版本后才开始新的观察，不把旧结果当作预注册样本。").font(.caption).foregroundStyle(OrbitTheme.muted);Button(busy ? "保存中…" : "冻结协议并等待样本") {Task {
                guard let client = store.client else { error = "请先连接服务器";return }
                busy = true;defer { busy = false }
                do { let _: SuccessReply = try await client.post("api/review/actions/\(actionId)/specification",values:["baseline":baseline,"challenger":challenger,"primary_metric":metric,"success_condition":success,"failure_condition":failure,"next_check":next]);dismiss() } catch { self.error = error.localizedDescription }
            }}.disabled(busy || baseline.count<4 || challenger.count<4 || metric.count<4 || success.count<8 || failure.count<8 || next.count<8) }
            if let error {Text(error).foregroundStyle(.orange)}
        }.navigationTitle("补齐实验协议").toolbar {ToolbarItem(placement:.topBarTrailing){Button("取消"){dismiss()}}} }
    }
}

struct QueryScreen: View {
    @EnvironmentObject var store: TradingStore
    @State private var question = ""
    @State private var answer: QueryReply?
    @State private var error: String?
    @State private var busy = false
    var body: some View {
        List {
            Section("按问题查询证据") { TextField("例如：哪些action还在等待样本？",text:$question,axis:.vertical).lineLimit(2...4);Button(busy ? "查询中…" : "只读查询") {Task {
                guard let client = store.client else {error = "请先连接服务器";return}
                busy = true;defer{busy = false}
                do {answer = try await client.post("api/review/query",values:["question":question]);error = nil} catch {self.error = error.localizedDescription;answer = nil}
            }}.disabled(busy || question.isEmpty || question.count>400);Text("最多一次查询规划、30行、12列、约12000字符。历史按需查询，不整库塞入上下文。").font(.caption).foregroundStyle(OrbitTheme.muted) }
            if let answer {
                Section(answer.purpose) {Text("返回\(answer.rows.count)行\(answer.truncated ? "，已截断，请缩小范围" : "")").font(.caption).foregroundStyle(OrbitTheme.muted)
                    ForEach(Array(answer.rows.enumerated()),id:\.offset) { item in
                        DisclosureGroup("记录 \(item.offset+1)") {ForEach(answer.columns,id:\.self) {column in DetailLine(title:column,value:item.element[column]?.text)}}
                    }
                }
                Section {DisclosureGroup("查询语句"){Text(answer.sql).font(.system(.caption,design:.monospaced)).textSelection(.enabled)}}
            }
            if let error {Text(error).foregroundStyle(.orange)}
        }.scrollContentBackground(.hidden).background(OrbitTheme.background).navigationTitle("数据查询")
    }
}
