import SwiftUI

/// 首页：品类相册网格 + 需要留意的藏品，参考「照片」App 的相簿页。
struct LibraryView: View {
    @Environment(CollectionStore.self) private var store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var path: [Route] = []
    @State private var query = ""
    @State private var editor: EditorMode?
    @Namespace private var zoom

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: sizeClass == .regular ? 200 : 150), spacing: 14)]
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    overview
                } else {
                    SearchResults(query: query, zoom: zoom) { path.append(.record($0)) }
                }
            }
            .navigationTitle("藏品")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "名称、品牌、色号")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { addMenu }
            }
            .routeDestinations(path: $path, zoom: zoom)
        }
        .sheet(item: $editor) { mode in
            EditorView(mode: mode) { id in path.append(.record(id)) }
        }
        .onAppear(perform: openDemoScreen)
    }

    private func openDemoScreen() {
        guard DemoData.isEnabled, path.isEmpty else { return }
        switch DemoData.screen {
        case "category": path = [.category(.lipstick)]
        case "record": path = [.category(.lipstick), .record(DemoData.featuredID)]
        case "editor": editor = .edit(store.record(id: DemoData.featuredID) ?? DemoData.records()[0])
        default: break
        }
    }

    private var addMenu: some View {
        Menu {
            Section("添加到") {
                ForEach(VanityCategory.all) { category in
                    Button { editor = .add(category.id) } label: {
                        Label(category.title, systemImage: category.symbol)
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("添加藏品")
    }

    private var overview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if store.records.isEmpty {
                    welcome
                } else {
                    summary
                }
                attention
                VStack(alignment: .leading, spacing: 12) {
                    Text("分类")
                        .font(.title3.weight(.semibold))
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(VanityCategory.all) { category in
                            NavigationLink(value: Route.category(category.id)) {
                                CategoryTile(category: category, count: store.records(in: category.id).count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 100)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.groupedBackground)
    }

    /// 一句话概览，而不是一排大数字。
    private var summary: some View {
        let count = store.records.count
        let uses = store.records.reduce(0) { $0 + $1.useCount }
        let opened = store.records.filter { $0.openedDate != nil }.count
        return Text("共 \(count) 件，\(opened) 件已开封，累计使用 \(uses) 次。")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("把梳妆台收进口袋")
                .font(.title2.weight(.bold))
            Text("记下每件化妆品的开封日期和使用次数，到期前 Vanity 会提醒你。从下面任意一个分类开始。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                editor = .add(.lipstick)
            } label: {
                Label("添加第一件藏品", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var attention: some View {
        let items = Array(store.expiringSoon.prefix(3))
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("需要留意")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    if store.expiringSoon.count > items.count {
                        Text("另有 \(store.expiringSoon.count - items.count) 件")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                VStack(spacing: 0) {
                    ForEach(items) { record in
                        NavigationLink(value: Route.record(record.id)) {
                            RecordRow(record: record, zoom: zoom, compact: true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if record.id != items.last?.id {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                .background(Palette.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

/// 品类卡片：产品照片 + 名称 + 件数，类似「照片」的相簿。
struct CategoryTile: View {
    let category: VanityCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { CategoryArtwork(category: category) }
                .continuousCorners(16)
            VStack(alignment: .leading, spacing: 1) {
                Text(category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(count == 0 ? "暂无藏品" : "\(count) 件")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.title)，\(count) 件")
        .accessibilityAddTraits(.isButton)
    }
}

/// 全部藏品中的搜索结果
struct SearchResults: View {
    let query: String
    let zoom: Namespace.ID
    let onOpen: (String) -> Void
    @Environment(CollectionStore.self) private var store

    var body: some View {
        let results = store.records.filter { $0.matches(query) }
        if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List(results) { record in
                NavigationLink(value: Route.record(record.id)) {
                    RecordRow(record: record, zoom: zoom, showsCategory: true)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
