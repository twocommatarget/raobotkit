#if canImport(UIKit)
import UIKit
#endif

/// Light haptic feedback for positive game events (success only — kid-friendly).
public enum Haptics {
    public static func found() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    public static func win() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
