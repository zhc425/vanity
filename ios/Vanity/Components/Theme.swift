import SwiftUI

/// 设计基调：遵循 Human Interface Guidelines，使用系统字体、系统语义色和材质，
/// 只保留一种品牌色（玫瑰木 AccentColor），让藏品照片成为界面上唯一的主角。
enum Palette {
    static let accent = Color.accentColor
    static let warning = Color.orange
    static let expired = Color.red
    static let fresh = Color.green
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let fill = Color(uiColor: .tertiarySystemFill)
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "自动"
        case .light: "浅色"
        case .dark: "深色"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension Expiry.Tone {
    var color: Color { self == .expired ? Palette.expired : Palette.warning }
    var symbol: String { self == .expired ? "exclamationmark.circle.fill" : "clock.fill" }
}

/// 列表行尾的到期状态：图标 + 文字，颜色只用来强调，不单独承载信息。
struct StatusLabel: View {
    let status: Expiry.Status?
    var body: some View {
        if let status {
            Label(status.label, systemImage: status.tone.symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(status.tone.color)
                .labelStyle(.titleAndIcon)
                .imageScale(.small)
        }
    }
}

/// 圆角缩略图，统一使用连续曲率圆角。
extension View {
    func continuousCorners(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - iOS 18 缩放转场（iOS 17 自动退回默认推入动画）

struct ZoomSource: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

struct ZoomDestination: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

extension View {
    func zoomSource(_ id: String, in namespace: Namespace.ID) -> some View { modifier(ZoomSource(id: id, namespace: namespace)) }
    func zoomDestination(_ id: String, in namespace: Namespace.ID) -> some View { modifier(ZoomDestination(id: id, namespace: namespace)) }
}
