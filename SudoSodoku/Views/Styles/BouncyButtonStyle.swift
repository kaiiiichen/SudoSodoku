import SwiftUI

// Pure press animation; haptics come from the semantic vocabulary in
// HapticManager (placement, note toggle, warning) so key presses don't
// double-fire with the action's own feedback.
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}


