import SwiftUI

/// A soft gradient backdrop used across screens. Adapts to light/dark mode.
public struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.10, green: 0.13, blue: 0.20), Color(red: 0.06, green: 0.08, blue: 0.12)]
                : [Color(red: 0.86, green: 0.93, blue: 1.0), Color(red: 0.91, green: 0.98, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
