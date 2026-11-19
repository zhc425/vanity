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
    let onIndex: () -> Void

    @Environment(CollectionStore.self) private var store
    @AppStorage("vanity.sort") private var sort: RecordSort = .recent
    @State private var query = ""
    @State private var editor: EditorMode?
    @State private var usedTrigger = 0

    private var allRecords: [CollectionRecord] { store.records(in: category.id) }
    private var visible: [CollectionRecord] { sort.sorted(allRecords.filter { $0.matches(query) }) }

    var body: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 18, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            Section {
                if allRecords.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else if visible.isEmpty {
                    Text("没有找到「\(query)」")
                        .font(.subheadline)
                        .foregroundStyle(Palette.silver)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 30)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(visible) { record in
                        row(record)
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 16))
                            .listRowBackground(Palette.background)
                            .listRowSeparatorTint(Palette.rule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { store.delete(id: record.id) } label: { Label("删除", systemImage: "trash") }
                                Button { editor = .edit(record) } label: { Label("编辑", systemImage: "pencil") }
                                    .tint(Palette.silver)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button { logUse(record) } label: { Label("记一次使用", systemImage: "plus") }
                                    .tint(Palette.plum)
                            }
                            .contextMenu {
                                Button { logUse(record) } label: { Label("记一次使用", systemImage: "plus.circle") }
                                Button { editor = .edit(record) } label: { Label("编辑藏品", systemImage: "pencil") }
                                Button { editor = .opening(record) } label: { Label(record.openedDate == nil ? "记录开封" : "修改开封记录", systemImage: "seal") }
                                Divider()
                                Button(role: .destructive) { store.delete(id: record.id) } label: { Label("删除", systemImage: "trash") }
                            }
                    }
                }
            } header: {
                if !allRecords.isEmpty {
                    HStack {
                        Text("藏品").font(Typeface.serif(22)).foregroundStyle(Palette.ink)
                        Spacer()
                        Menu {
                            Picker("排序", selection: $sort) {
                                ForEach(RecordSort.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                            }
                        } label: {
                            Label(sort.title, systemImage: "arrow.up.arrow.down")
                                .font(.footnote)
                                .foregroundStyle(Palette.plum)
                        }
                    }
                    .textCase(nil)
                    .padding(.bottom, 4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Palette.background.ignoresSafeArea())
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索名称、品牌或色号")
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { VanityMark(size: 28) }
            ToolbarItem(placement: .topBarTrailing) {
                Button("全部分类", action: onIndex).font(.subheadline)
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sensoryFeedback(.success, trigger: usedTrigger)
        .sheet(item: $editor) { mode in
            EditorView(mode: mode) { id in
                if case .add = mode { onRecord(id) }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(category.title)
                    .font(Typeface.serif(44, relativeTo: .largeTitle))
                    .foregroundStyle(Palette.ink)
                HStack(spacing: 8) {
                    Text(category.subtitle).font(Typeface.serif(16))
                    Text("\(allRecords.count) 件").font(.footnote.monospacedDigit())
                }
                .foregroundStyle(Palette.silver)
                Button {
                    editor = .add(category.id)
                } label: {
                    Label("添加藏品", systemImage: "plus")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            Spacer(minLength: 0)
            Image(category.cover)
                .resizable()
                .scaledToFill()
                .frame(width: 128, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityLabel(category.alt)
        }
        .buttonStyle(.borderless)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(Palette.plum)
            Text("还没有\(category.title)")
                .font(Typeface.serif(19))
                .foregroundStyle(Palette.ink)
            Text("添加第一件藏品，记录使用次数和到期日")
                .font(.footnote)
                .foregroundStyle(Palette.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.rule))
        .padding(.horizontal, 20)
    }

    private func row(_ record: CollectionRecord) -> some View {
        let expiry = record.expiry()
        return HStack(alignment: .center, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                RecordArtwork(record: record)
                    .frame(width: 58, height: 58)
                    .zoomSource("record-\(record.id)", in: zoom)
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.name)
                        .font(Typeface.serif(19))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                    if !record.identity.isEmpty {
                        Text(record.identity)
                            .font(.footnote)
                            .foregroundStyle(Palette.silver)
                            .lineLimit(1)
                    }
                    HStack(spacing: 12) {
                        Text("使用 \(record.useCount) 次")
                        Text("到期 \(Day.display(expiry.date))")
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.ink.opacity(0.8))
                    StatusBadge(status: expiry.status)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { onRecord(record.id) }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onRecord(record.id) }

            Button {
                logUse(record)
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 40, height: 40)
                    .background(Palette.veil, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.rule))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Palette.plum)
            .accessibilityLabel("记一次使用：\(record.name)")
        }
    }

    private func logUse(_ record: CollectionRecord) {
        store.logUse(id: record.id)
        usedTrigger += 1
    }
}
