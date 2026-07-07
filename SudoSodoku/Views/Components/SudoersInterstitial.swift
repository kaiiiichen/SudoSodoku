import SwiftUI

/// One-shot gate for the classic sudoers joke shown before the first
/// MASTER game. Pure so the trigger logic is unit-testable.
enum SudoersJoke {
    static let seenKey = "hasSeenSudoersIncident"

    static func shouldShow(for difficulty: Difficulty, defaults: UserDefaults = .standard) -> Bool {
        difficulty == .master && !defaults.bool(forKey: seenKey)
    }

    static func markSeen(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: seenKey)
    }
}

/// The joke itself: the dreaded warning, a beat of silence, then the
/// typewriter punchline. Tap anywhere to skip; fires `onFinished` once.
struct SudoersInterstitial: View {
    let username: String
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showPunchline = false
    @State private var typedCount = 0
    @State private var finished = false

    private let punchline = "...just kidding. root access granted."

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(username) is not in the sudoers file.")
                .foregroundColor(.white)
            Text("This incident will be reported.")
                .foregroundColor(.red)
            Text(String(punchline.prefix(typedCount)))
                .foregroundColor(.green)
                .opacity(showPunchline ? 1 : 0)
        }
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .task { await run() }
    }

    private func run() async {
        if reduceMotion {
            showPunchline = true
            typedCount = punchline.count
            try? await Task.sleep(for: .seconds(2))
            finish()
            return
        }

        try? await Task.sleep(for: .milliseconds(1400))
        guard !Task.isCancelled, !finished else { return }
        showPunchline = true
        for count in 1...punchline.count {
            typedCount = count
            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled, !finished else { return }
        }
        try? await Task.sleep(for: .milliseconds(700))
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinished()
    }
}
