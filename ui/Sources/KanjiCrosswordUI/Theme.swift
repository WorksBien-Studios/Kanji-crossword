import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Visual tokens for the paper-magazine look: ink on paper, indigo actions,
/// highlighter-yellow selection, vermilion stamps. Every colour has a light and
/// a dark value so the board stays legible in both appearances.
enum KanjiTheme {
    static let canvas = Color.adaptive(light: 0xF5F6F3, dark: 0x10151D)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x19202B)
    static let fill = Color.adaptive(light: 0xEDF0F2, dark: 0x222B38)
    static let bar = Color.adaptive(light: 0xFAFBF9, dark: 0x141A23)
    static let ink = Color.adaptive(light: 0x161D2B, dark: 0xEEF1F5)
    static let inkSecondary = Color.adaptive(light: 0x48546A, dark: 0xB2BCC9)
    static let line = Color.adaptive(light: 0xC6CDD5, dark: 0x3A4557)
    static let accent = Color.adaptive(light: 0x1F4B7A, dark: 0x3A73B5)
    static let accentText = Color.adaptive(light: 0x1F4B7A, dark: 0x9DC3F2)
    static let mark = Color.adaptive(light: 0xF7D75A, dark: 0x7A6410)
    static let related = Color.adaptive(light: 0xDCE8F6, dark: 0x243A57)
    static let starter = Color.adaptive(light: 0xE3E7EB, dark: 0x2C3644)
    static let stamp = Color.adaptive(light: 0xB93A22, dark: 0xF08A74)
    static let stampTint = Color.adaptive(light: 0xF8E1DB, dark: 0x4A2A24)
    static let success = Color.adaptive(light: 0x2A7350, dark: 0x7CCBA1)
    static let successTint = Color.adaptive(light: 0xDDEFE5, dark: 0x1F3A2D)

    /// Serif design falls back to the system Mincho for kanji, giving the
    /// printed-puzzle feel without bundling a font.
    static func kanjiFont(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    static func adaptive(light: UInt32, dark: UInt32) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(kanjiHex: dark)
                : UIColor(kanjiHex: light)
        })
        #else
        return Color(hex: light)
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(kanjiHex hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

// MARK: - Button styles

/// Full-width indigo call to action, 56pt tall.
struct KanjiPrimaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, compact: compact)
    }

    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let compact: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(compact ? .body.bold() : .title3.bold())
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: compact ? 48 : 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(KanjiTheme.accent)
                )
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
        }
    }
}

/// Outlined secondary action.
struct KanjiSecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, compact: compact)
    }

    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let compact: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(compact ? .body.bold() : .title3.bold())
                .foregroundStyle(KanjiTheme.accentText)
                .frame(maxWidth: .infinity, minHeight: compact ? 48 : 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(KanjiTheme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(KanjiTheme.accent, lineWidth: 2)
                )
                .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
        }
    }
}

/// A raised paper tile holding one kanji. Tiles whose kanji is already on the
/// board are dashed and dimmed so the remaining choices stand out.
struct KanjiTileButtonStyle: ButtonStyle {
    var used = false
    var height: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, used: used, height: height)
    }

    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let used: Bool
        let height: CGFloat
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(KanjiTheme.kanjiFont(size: height * 0.52))
                .foregroundStyle(KanjiTheme.ink)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(KanjiTheme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            KanjiTheme.inkSecondary,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: used ? [5, 4] : []
                            )
                        )
                )
                .offset(y: configuration.isPressed ? 2 : 0)
                .opacity(isEnabled ? (used ? 0.45 : 1) : 0.35)
        }
    }
}

/// Icon over a text label. The label is always visible: no icon-only controls.
struct KanjiActionButtonStyle: ButtonStyle {
    var bordered = false

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, bordered: bordered)
    }

    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let bordered: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.footnote.bold())
                .foregroundStyle(KanjiTheme.accentText)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(bordered ? KanjiTheme.card : Color.clear)
                )
                .overlay {
                    if bordered {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(KanjiTheme.line, lineWidth: 2)
                    }
                }
                .opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.4)
        }
    }
}

/// Vermilion hanko-style ring: solid double ring when finished, dashed when in
/// progress.
struct StampMark: View {
    enum Kind { case complete, inProgress }

    var kind: Kind = .complete
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    KanjiTheme.stamp,
                    style: StrokeStyle(
                        lineWidth: max(2, size * 0.11),
                        dash: kind == .inProgress ? [4, 3] : []
                    )
                )
            if kind == .complete {
                Circle()
                    .strokeBorder(KanjiTheme.stamp, lineWidth: max(1.5, size * 0.07))
                    .padding(size * 0.2)
                    .opacity(0.7)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Rounded card surface used by home, records and results.
struct KanjiCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(KanjiTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(KanjiTheme.line, lineWidth: 1)
            )
    }
}
