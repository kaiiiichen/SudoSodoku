import SwiftUI

/// Three-act victory sequence: matrix rain, typewriter "ACCESS GRANTED",
/// then the ELO ticker rolling to the new value (with a rank-up ceremony
/// when a tier boundary was crossed). Dismissed by tap, never by timer.
struct MatrixVictoryOverlay: View {
    let ratingGained: Int
    let newRating: Int
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var typedCount = 0
    @State private var displayedRating = 0
    @State private var showRating = false
    @State private var showHint = false

    private let title = "ACCESS GRANTED"

    private var oldRating: Int { newRating - max(0, ratingGained) }
    private var didRankUp: Bool { RankTier.tier(for: oldRating) != RankTier.tier(for: newRating) }
    private var newTier: RankTier { RankTier.tier(for: newRating) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            if !reduceMotion {
                MatrixRain().opacity(0.35)
            }

            VStack(spacing: 18) {
                Text(String(title.prefix(typedCount)))
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 18)
                    .frame(height: 46)

                if typedCount == title.count {
                    Text("SYSTEM COMPROMISED")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                if showRating {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Text("ELO:")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(displayedRating)")
                                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                .foregroundColor(.green)
                                .contentTransition(.numericText(value: Double(displayedRating)))
                            if ratingGained > 0 {
                                Text("+\(ratingGained)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.yellow)
                            }
                        }
                        if ratingGained == 0 {
                            Text("LOW DIFFICULTY // NO GAIN")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        if didRankUp {
                            Text(">> RANK_UP: \(newTier.title) <<")
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundColor(newTier.color)
                                .shadow(color: newTier.color, radius: 12)
                        }
                    }
                    .transition(.opacity)
                }

                if showHint {
                    Text("[TAP_TO_CONTINUE]")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.top, 14)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .task { await runSequence() }
    }

    private func runSequence() async {
        if reduceMotion {
            typedCount = title.count
            displayedRating = newRating
            showRating = true
            showHint = true
            return
        }

        for count in 1...title.count {
            typedCount = count
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
        }

        displayedRating = oldRating
        withAnimation(.easeIn(duration: 0.2)) { showRating = true }
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.9)) { displayedRating = newRating }
        try? await Task.sleep(for: .milliseconds(1100))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            showHint = true
        }
    }
}

/// Falling character columns drawn on a Canvas — far cheaper than stacks of
/// Text views. Deterministic per-column pseudo-randomness keeps it allocation
/// free across frames.
private struct MatrixRain: View {
    private static let glyphs = Array("0123456789ABCDEF<>[]{}$#")

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let columnWidth: CGFloat = 16
                let rowHeight: CGFloat = 16
                let columns = max(1, Int(size.width / columnWidth))
                let travel = Double(size.height) + 240

                for column in 0..<columns {
                    let speed = 70.0 + Double((column * 37) % 70)
                    let offset = Double((column * 131) % 997)
                    let headY = CGFloat((time * speed + offset).truncatingRemainder(dividingBy: travel)) - 120
                    let x = CGFloat(column) * columnWidth + columnWidth / 2

                    for row in 0..<14 {
                        let y = headY - CGFloat(row) * rowHeight
                        guard y > -20, y < size.height + 20 else { continue }
                        let glyphIndex = abs(column &* 31 &+ row &* 17 &+ Int(time * 9)) % Self.glyphs.count
                        let alpha = row == 0 ? 0.95 : max(0.05, 0.7 - Double(row) * 0.05)
                        context.draw(
                            Text(String(Self.glyphs[glyphIndex]))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.green.opacity(alpha)),
                            at: CGPoint(x: x, y: y)
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
