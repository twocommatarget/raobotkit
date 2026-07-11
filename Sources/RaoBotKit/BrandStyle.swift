import SwiftUI

/// Shared RaoBot brand identity, reused across games. Sourced from raobot.ai.
public enum BrandStyle {
    public static let name = "RaoBot"
    public static let websiteURL = URL(string: "https://raobot.ai")!

    // Palette (from raobot.ai)
    public static let accent = Color(red: 0x25 / 255, green: 0x63 / 255, blue: 0xEB / 255) // #2563EB
    public static let accentLight = Color(red: 0xEF / 255, green: 0xF6 / 255, blue: 0xFF / 255) // #EFF6FF
    public static let ink = Color(red: 0x0F / 255, green: 0x17 / 255, blue: 0x2A / 255) // #0F172A
    public static let amber = Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x06 / 255) // #D97706
    public static let green = Color(red: 0x16 / 255, green: 0xA3 / 255, blue: 0x4A / 255) // #16A34A
    public static let red = Color(red: 0xDC / 255, green: 0x26 / 255, blue: 0x26 / 255) // #DC2626
    public static let background = Color(red: 0xF8 / 255, green: 0xFA / 255, blue: 0xFC / 255) // #F8FAFC
}

/// The RaoBot wordmark: "Rao" (ink) + "Bot" (accent), matching raobot.ai.
public struct RaoBotWordmark: View {
    public var size: CGFloat
    public var onDark: Bool

    public init(size: CGFloat = 15, onDark: Bool = false) {
        self.size = size
        self.onDark = onDark
    }

    public var body: some View {
        (Text("Rao").foregroundColor(onDark ? .white : BrandStyle.ink)
            + Text("Bot").foregroundColor(BrandStyle.accent))
            .font(.system(size: size, weight: .bold))
            .accessibilityLabel("RaoBot")
    }
}

/// A small "by RaoBot" credit line for home screens / footers.
public struct RaoBotCredit: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 5) {
            Text("by").font(.footnote).foregroundStyle(.secondary)
            RaoBotWordmark(size: 15)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("by RaoBot")
    }
}
