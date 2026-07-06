import SwiftUI

/// The lines of the fake breach log shown while a puzzle generates.
/// Pure so the script itself is unit-testable.
enum BreachScript {
    static let lineWidth = 30

    static func introLines(difficulty: Difficulty) -> [String] {
        [
            "$ sudo breach --target=grid_9x9 --\(difficulty.rawValue.lowercased())",
            padded("> requesting root access", status: "OK"),
            padded("> generating entropy", status: "OK"),
            padded("> digging holes", status: "OK"),
        ]
    }

    static func finalLines(score: Int, difficulty: Difficulty) -> [String] {
        [
            padded("> uniqueness check", status: "PASS"),
            "> difficulty_index: \(score) [\(difficulty.rawValue)]",
        ]
    }

    /// Dot-leader padding: `> generating entropy.......... OK`
    static func padded(_ text: String, status: String) -> String {
        let dots = max(2, lineWidth - text.count)
        return text + String(repeating: ".", count: dots) + " " + status
    }
}

/// Typewriter breach log that doubles as the loading screen: intro lines
/// reveal while the generator works, the verdict lines land once it finishes,
/// then `onFinished` hands the screen back to the board.
struct BreachLogView: View {
    let difficulty: Difficulty
    let isGenerating: Bool
    let finalScore: Int
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealedCount = 0
    @State private var cursorVisible = true

    private var introLines: [String] { BreachScript.introLines(difficulty: difficulty) }
    private var allLines: [String] {
        isGenerating
            ? introLines
            : introLines + BreachScript.finalLines(score: finalScore, difficulty: difficulty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(allLines.prefix(revealedCount).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color(for: line))
            }
            if revealedCount < allLines.count || isGenerating {
                Text("_")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .opacity(cursorVisible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
        .onAppear {
            if reduceMotion {
                revealedCount = allLines.count
            } else {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    cursorVisible = false
                }
            }
        }
        .task(id: isGenerating) { await run() }
    }

    private func color(for line: String) -> Color {
        if line.hasSuffix("PASS") { return .green }
        if line.hasPrefix("$") { return .white }
        return .green.opacity(0.75)
    }

    private func run() async {
        if reduceMotion {
            revealedCount = allLines.count
            if !isGenerating { onFinished() }
            return
        }

        while revealedCount < allLines.count {
            try? await Task.sleep(for: .milliseconds(revealedCount == 0 ? 50 : 170))
            guard !Task.isCancelled else { return }
            revealedCount = min(revealedCount + 1, allLines.count)
        }

        // Verdict lines are on screen; hold a beat, then hand back the board.
        if !isGenerating {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}
