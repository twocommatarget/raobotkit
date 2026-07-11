import SwiftUI

/// A horizontally scrolling ribbon for a game's own announcements / promos.
/// Driven by a TimelineView so the scroll is computed from wall-clock time each
/// frame (reliable on device). Optionally tappable (e.g. to request a review).
///
/// NOTE: intended for *first-party* messages — NOT third-party ad networks,
/// which are restricted in apps aimed at children.
public struct MarqueeRibbon: View {
    public var messages: [String]
    public var speed: Double
    public var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var textWidth: CGFloat = 0
    @State private var startDate = Date()

    public init(messages: [String], speed: Double = 45, onTap: (() -> Void)? = nil) {
        self.messages = messages
        self.speed = speed
        self.onTap = onTap
    }

    private var line: String {
        messages.joined(separator: "      ✦      ") + "      ✦      "
    }

    public var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
            .background(Color.accentColor)
            .overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
                    HStack(spacing: 0) {
                        marqueeText
                        marqueeText
                    }
                    .offset(x: offset(at: timeline.date))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { onTap?() }
            .onPreferenceChange(WidthKey.self) { width in
                if width > 0 { textWidth = width }
            }
            .accessibilityLabel(messages.joined(separator: ", "))
            .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }

    private func offset(at now: Date) -> CGFloat {
        guard textWidth > 0, !reduceMotion else { return 0 }
        let distance = CGFloat(now.timeIntervalSince(startDate)) * CGFloat(speed)
        return -distance.truncatingRemainder(dividingBy: textWidth)
    }

    private var marqueeText: some View {
        Text(line)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .fixedSize()
            .background(GeometryReader { geo in
                Color.clear.preference(key: WidthKey.self, value: geo.size.width)
            })
    }
}

private struct WidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
