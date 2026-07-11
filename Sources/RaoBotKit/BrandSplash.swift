import SwiftUI

/// A reusable branded launch splash for RaoBot games: the game's wordmark
/// (a base part + an accent-colored part) with a "by RaoBot" credit.
public struct BrandSplash: View {
    public var emoji: String
    public var base: String
    public var accent: String
    public var accentColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    public init(emoji: String = "", base: String, accent: String, accentColor: Color = BrandStyle.green) {
        self.emoji = emoji
        self.base = base
        self.accent = accent
        self.accentColor = accentColor
    }

    public var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 14) {
                if !emoji.isEmpty {
                    Text(emoji).font(.system(size: 34))
                }
                (Text(base).foregroundColor(.primary) + Text(accent).foregroundColor(accentColor))
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                RaoBotCredit()
                    .padding(.top, 6)
            }
            .scaleEffect(reduceMotion ? 1 : (appear ? 1 : 0.92))
            .opacity(reduceMotion ? 1 : (appear ? 1 : 0))
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appear = true }
        }
    }
}

/// Wrap your app's root view in this to show `BrandSplash` on launch, then
/// auto-dismiss into the content.
///
///     WindowGroup {
///         BrandSplashHost(emoji: "🔍", base: "Word", accent: "sy") {
///             HomeView()
///         }
///     }
///
/// Set the `RBK_SKIP_SPLASH` environment variable (e.g. for UI-test screenshots)
/// to skip the splash.
public struct BrandSplashHost<Content: View>: View {
    public var emoji: String
    public var base: String
    public var accent: String
    public var accentColor: Color
    public var duration: Double
    @ViewBuilder public var content: () -> Content

    @State private var showSplash: Bool

    public init(
        emoji: String = "",
        base: String,
        accent: String,
        accentColor: Color = BrandStyle.green,
        duration: Double = 2.4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.emoji = emoji
        self.base = base
        self.accent = accent
        self.accentColor = accentColor
        self.duration = duration
        self.content = content
        _showSplash = State(initialValue: ProcessInfo.processInfo.environment["RBK_SKIP_SPLASH"] == nil)
    }

    public var body: some View {
        ZStack {
            content()
            if showSplash {
                BrandSplash(emoji: emoji, base: base, accent: accent, accentColor: accentColor)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard showSplash else { return }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            withAnimation(.easeInOut(duration: 0.4)) { showSplash = false }
        }
    }
}
