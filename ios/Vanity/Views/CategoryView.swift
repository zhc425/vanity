import SwiftUI

enum RecordSort: String, CaseIterable, Identifiable {
    case recent, expiry, usage, name
    var id: String { rawValue }
    var title: String {
        switch self {
        case .recent: "最近添加"
        case .expiry: "最先到期"
        case .usage: "使用最多"
        case .name: "名称"
        }
    }
    var icon: String {
        switch self {
        case .recent: "clock"
        case .expiry: "hourglass"
        case .usage: "chart.bar"
        case .name: "textformat"
        }
    }

    func sorted(_ records: [CollectionRecord]) -> [CollectionRecord] {
        let today = Day.today()
        switch self {
        case .recent:
            // 存储顺序本身就是新的在前
            return records
        case .expiry:
            return records.sorted {
                let a = $0.expiry(today: today).date ?? "9999-12-31"
                let b = $1.expiry(today: today).date ?? "9999-12-31"
                return a == b ? $0.name < $1.name : a < b
            }
        case .usage:
            return records.sorted { $0.useCount == $1.useCount ? $0.name < $1.name : $0.useCount > $1.useCount }
        case .name:
            return records.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
    }
}

struct CategoryView: View {
    let category: VanityCategory
    let zoom: Namespace.ID
    let onRecord: (String) -> Void

    @Environment(CollectionStore.self) private var store
    @AppStorage("vanity.sort") private var sort: RecordSort = .recent
    @State private var query = ""
    @State private var editor: EditorMode?
    @State private var usedTrigger = 0
    @State private var pendingDelete: CollectionRecord?

    private var allRecords: [CollectionRecord] { store.records(in: category.id) }
    private var visible: [CollectionRecord] { sort.sorted(allRecords.filter { $0.matches(query) }) }

    var body: some View {
        Group {
            if allRecords.isEmpty {
                ContentUnavailableView {
                    Label("还没有\(category.title)", systemImage: category.symbol)
                } description: {
                    Text("添加第一件\(category.title)，记录开封日期和使用次数。")
                } actions: {
                    Button("添加\(category.title)") { editor = .add(category.id) }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                }
                .background(Palette.groupedBackground)
            } else {
                list
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !allRecords.isEmpty {
                    Menu {
                        Picker("排序方式", selection: $sort) {
                            ForEach(RecordSort.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("排序方式：\(sort.title)")
                }
                Button { editor = .add(category.id) } label: { Image(systemName: "plus") }
                    .accessibilityLabel("添加\(category.title)")
            }
        }
        .sensoryFeedback(.increase, trigger: usedTrigger)
        .sheet(item: $editor) { mode in
            EditorView(mode: mode) { id in
                if case .add = mode { onRecord(id) }
            }
        }
        .confirmationDialog("删除「\(pendingDelete?.name ?? "")」？", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
            Button("删除藏品", role: .destructive) {
                if let record = pendingDelete { withAnimation { store.delete(id: record.id) } }
                pendingDelete = nil
            }
        } message: {
            Text("使用记录和照片会一起删除。")
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(visible) { record in
                    NavigationLink(value: Route.record(record.id)) {
                        RecordRow(record: record, zoom: zoom)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { logUse(record) } label: { Label("使用", systemImage: "plus") }
                            .tint(Palette.accent)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { pendingDelete = record } label: { Label("删除", systemImage: "trash") }
                        Button { editor = .edit(record) } label: { Label("编辑", systemImage: "pencil") }
                            .tint(.gray)
                    }
                    .contextMenu {
                        Button { logUse(record) } label: { Label("使用一次", systemImage: "plus.circle") }
                        Button { editor = .edit(record) } label: { Label("编辑", systemImage: "pencil") }
                        Button { editor = .opening(record) } label: {
                            Label(record.openedDate == nil ? "记录开封" : "修改开封日期", systemImage: "seal")
                        }
                        Divider()
                        Button(role: .destructive) { pendingDelete = record } label: { Label("删除", systemImage: "trash") }
                    } preview: {
                        RecordPreview(record: record, photo: store.photo(for: record))
                    }
                }
            } header: {
                Text("\(allRecords.count) 件，按\(sort.title)排列")
            } footer: {
                if visible.isEmpty {
                    Text("没有与「\(query)」匹配的\(category.title)。")
                } else {
                    Text("向右轻扫可快速记一次使用。")
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "在\(category.title)中搜索")
        .animation(.default, value: sort)
    }

    private func logUse(_ record: CollectionRecord) {
        withAnimation(.snappy) { store.logUse(id: record.id) }
        usedTrigger += 1
    }
}

/// 长按预览：大图 + 名称
struct RecordPreview: View {
    let record: CollectionRecord
    let photo: UIImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Rectangle().fill(Palette.fill)
                    Image(systemName: record.categoryId.info.symbol)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 300, height: 240)
            .clipped()
            VStack(alignment: .leading, spacing: 2) {
                Text(record.name).font(.headline)
                if !record.identity.isEmpty {
                    Text(record.identity).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 300)
    }
}
