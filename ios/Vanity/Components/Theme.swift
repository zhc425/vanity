import CoreText
import SwiftUI
import UIKit

enum Palette {
    static let background = Color("Background")
    static let ink = Color("Ink")
    static let silver = Color("Silver")
    static let rule = Color("Rule")
    static let paper = Color("Paper")
    static let veil = Color("Veil")
    static let plum = Color("Plum")
    static let plumText = Color("PlumText")
    static let warning = Color("Warning")
    static let expired = Color("Expired")
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "跟随系统"
        case .light: "白天"
        case .dark: "夜间"
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

enum Typeface {
    /// 宋体优先，没有时退回系统衬线体
    private static let songti: String? = ["STSongti-SC-Regular", "STSong"].first { UIFont(name: $0, size: 12) != nil }

    static func serif(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        if let songti { return .custom(songti, size: size, relativeTo: style) }
        return .system(size: size, design: .serif)
    }

    static func script(_ size: CGFloat) -> Font { .custom("GreatVibes-Regular", fixedSize: size) }

    static func registerFonts() {
        guard let url = Bundle.main.url(forResource: "GreatVibes-Regular", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

struct VanityMark: View {
    var size: CGFloat = 30
    var body: some View {
        Text("Vanity")
            .font(Typeface.script(size))
            .foregroundStyle(Palette.ink)
            .accessibilityLabel("Vanity")
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Palette.plumText)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(Palette.plum, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundStyle(Palette.plum)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(Palette.veil, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.rule))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .background(Palette.paper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.rule))
    }
}

struct StatusBadge: View {
    let status: Expiry.Status?
    var body: some View {
        if let status {
            let color = status.tone == .expired ? Palette.expired : Palette.warning
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(status.label)
            }
            .font(.caption)
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
        }
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
