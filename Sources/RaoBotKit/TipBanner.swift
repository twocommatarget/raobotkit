import SwiftUI
import Combine

/// A compact banner that shows ONE short message at a time and rotates through
/// the list every `interval` seconds. The message is always **fully visible**
/// (single line, auto-shrinks to fit — never clipped), so it replaces the older
/// scrolling `MarqueeRibbon`, which stalls under Reduce Motion and clips text.
///
/// Rotation is driven by a run-loop timer (reliable on device, even while
/// scrolling). With Reduce Motion on, the text swaps instantly instead of
/// cross-fading — so it still works, just without the animation.
public struct TipBanner: View {
    public var messages: [String]
    public var interval: Double
    public var onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    public init(messages: [String], interval: Double = 4.5, onTap: (() -> Void)? = nil) {
        self.messages = messages
        self.interval = interval
        self.onTap = onTap
        self.timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    }

    private var current: String {
        messages.isEmpty ? "" : messages[index % messages.count]
    }

    public var body: some View {
        ZStack {
            Color.accentColor
            Text(current)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .id(index)                       // new identity per message → transition
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { onTap?() }
        .onReceive(timer) { _ in
            guard messages.count > 1 else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) {
                index += 1
            }
        }
        .accessibilityElement()
        .accessibilityLabel(current)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
    }
}
