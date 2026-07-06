import CoreHaptics
import UIKit

/// Semantic haptic vocabulary for the whole app. Views and the view model
/// express intent (digitPlaced, conflictDetected, ...) and never touch
/// concrete generators, so the game's feel is tuned in this one file.
final class HapticManager {
    static let shared = HapticManager()

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private var hapticEngine: CHHapticEngine?

    // MARK: - Board interactions

    /// Mechanical key press: a value snaps into a cell.
    func digitPlaced() {
        rigidGenerator.impactOccurred()
    }

    /// A value leaves the board (toggle-off or DEL).
    func digitRemoved() {
        lightGenerator.impactOccurred()
    }

    /// Pencil note toggled on/off — softer than a real placement.
    func noteToggled() {
        lightGenerator.impactOccurred(intensity: 0.6)
    }

    /// The placed digit conflicts with a peer.
    func conflictDetected() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// A row, column, or box was just completed (reserved for #16).
    func unitCompleted() {
        mediumGenerator.impactOccurred()
    }

    // MARK: - Controls

    /// Note mode switched — feels like a mode selector click.
    func noteModeToggled() {
        selectionGenerator.selectionChanged()
    }

    /// Undo or redo applied.
    func moveReverted() {
        lightGenerator.impactOccurred()
    }

    /// Input ignored (e.g. no cell selected) — nudge, not punish.
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    // MARK: - Victory

    /// Three ascending ticks followed by a soft rumble. Falls back to the
    /// plain success notification when custom haptics are unavailable
    /// (simulator, older devices, engine failure).
    func victory() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = victoryEngine() else {
            success()
            return
        }
        do {
            var events: [CHHapticEvent] = []
            for (step, time) in [0.0, 0.1, 0.2].enumerated() {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 + Float(step) * 0.15),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6 + Float(step) * 0.1),
                    ],
                    relativeTime: time
                ))
            }
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: 0.32,
                duration: 0.45
            ))
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            success()
        }
    }

    private func victoryEngine() -> CHHapticEngine? {
        if let hapticEngine { return hapticEngine }
        guard let engine = try? CHHapticEngine() else { return nil }
        engine.playsHapticsOnly = true
        // The engine starts itself when a player starts and shuts down when idle.
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in
            self?.hapticEngine = nil
        }
        hapticEngine = engine
        return engine
    }
}
