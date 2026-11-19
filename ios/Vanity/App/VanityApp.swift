import SwiftUI

@main
struct VanityApp: App {
    @State private var store = DemoData.isEnabled ? DemoData.makeStore() : CollectionStore()
    @AppStorage("vanity.appearance") private var appearance: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(appearance.colorScheme)
        }
    }
}

enum Route: Hashable {
    case category(CategoryID)
    case record(String)
    case history(String)
}

enum AppTab: Hashable {
    case library, expiring, settings
}

struct RootView: View {
    @Environment(CollectionStore.self) private var store
    @State private var tab: AppTab = .library

    var body: some View {
        TabView(selection: $tab) {
            LibraryView()
                .tabItem { Label("藏品", systemImage: "square.grid.2x2.fill") }
                .tag(AppTab.library)

            ExpiringView()
                .tabItem { Label("到期", systemImage: "hourglass") }
                .badge(store.expiringSoon.count)
                .tag(AppTab.expiring)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .overlay(alignment: .bottom) {
            NoticeToast()
                .padding(.bottom, 60)
        }
        .onAppear {
            switch DemoData.screen {
            case "expiring": tab = .expiring
            case "settings": tab = .settings
            default: break
            }
        }
        .alert("无法保存", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
            Button("好") { store.saveError = nil }
        } message: {
            Text(store.saveError ?? "")
        }
    }
}

/// 共用的导航目的地，让每个标签页的 NavigationStack 都能打开品类、藏品与使用记录。
struct RouteDestinations: ViewModifier {
    @Binding var path: [Route]
    let zoom: Namespace.ID

    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .category(let id):
                CategoryView(category: id.info, zoom: zoom) { path.append(.record($0)) }
            case .record(let id):
                RecordView(recordID: id, onDeleted: { pop(.record(id)) }, onHistory: { path.append(.history(id)) })
                    .zoomDestination("record-\(id)", in: zoom)
            case .history(let id):
                UseHistoryView(recordID: id)
            }
        }
    }

    private func pop(_ route: Route) {
        if let index = path.lastIndex(of: route) { path.removeSubrange(index...) }
    }
}

extension View {
    func routeDestinations(path: Binding<[Route]>, zoom: Namespace.ID) -> some View {
        modifier(RouteDestinations(path: path, zoom: zoom))
    }
}

/// 系统风格的轻提示：材质胶囊，悬浮在标签栏上方。
struct NoticeToast: View {
    @Environment(CollectionStore.self) private var store

    var body: some View {
        if let notice = store.notice {
            HStack(spacing: 12) {
                Image(systemName: notice.undo == nil ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                    .foregroundStyle(Palette.accent)
                    .imageScale(.large)
                Text(notice.text)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                if notice.undo != nil {
                    Button("撤销") { store.performUndo() }
                        .font(.subheadline.weight(.semibold))
                        .padding(.leading, 4)
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, notice.undo == nil ? 18 : 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.separator.opacity(0.4), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
            .padding(.horizontal, 24)
            .onTapGesture { store.dismissNotice() }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(notice.id)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
