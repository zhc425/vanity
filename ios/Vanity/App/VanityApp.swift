import SwiftUI

@main
struct VanityApp: App {
    @State private var store = CollectionStore()
    @AppStorage("vanity.appearance") private var appearance: AppearanceMode = .system

    init() {
        Typeface.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
                .tint(Palette.plum)
        }
    }
}

enum Route: Hashable {
    case category(CategoryID)
    case record(String)
}

struct RootView: View {
    @Environment(CollectionStore.self) private var store
    @State private var path: [Route] = []
    @State private var showIndex = false
    @State private var showSettings = false
    @Namespace private var zoom

    var body: some View {
        NavigationStack(path: $path) {
            CoverView(zoom: zoom, onOpen: { path.append(.category($0)) },
                      onIndex: { showIndex = true }, onSettings: { showSettings = true },
                      onRecord: { record in path = [.category(record.categoryId), .record(record.id)] })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let id):
                        CategoryView(category: id.info, zoom: zoom,
                                     onRecord: { path.append(.record($0)) },
                                     onIndex: { showIndex = true })
                            .zoomDestination("category-\(id.rawValue)", in: zoom)
                    case .record(let id):
                        RecordView(recordID: id, onDeleted: { if path.last == .record(id) { path.removeLast() } })
                            .zoomDestination("record-\(id)", in: zoom)
                    }
                }
        }
        .sheet(isPresented: $showIndex) {
            CategoryIndexView(current: currentCategory) { category in
                showIndex = false
                path = [.category(category)]
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .overlay(alignment: .bottom) { NoticeBanner() }
        .alert("提示", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
            Button("好") { store.saveError = nil }
        } message: {
            Text(store.saveError ?? "")
        }
    }

    private var currentCategory: CategoryID? {
        for route in path.reversed() {
            if case .category(let id) = route { return id }
        }
        return nil
    }
}

struct NoticeBanner: View {
    @Environment(CollectionStore.self) private var store

    var body: some View {
        if let notice = store.notice {
            HStack(spacing: 14) {
                Text(notice.text)
                    .font(.subheadline)
                    .foregroundStyle(Palette.plumText)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if notice.undo != nil {
                    Button("撤销") { store.performUndo() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.plumText)
                }
                Button {
                    store.dismissNotice()
                } label: {
                    Image(systemName: "xmark").font(.caption.weight(.semibold))
                }
                .foregroundStyle(Palette.plumText.opacity(0.75))
                .accessibilityLabel("关闭提示")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(Palette.plum, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(notice.id)
        }
    }
}
