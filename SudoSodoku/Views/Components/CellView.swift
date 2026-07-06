import SwiftUI

struct CellView: View {
    let cell: SudokuCell
    let cellSize: CGFloat
    let isSelected: Bool
    let isRelated: Bool
    let highlightNumber: Int?
    /// Increments each time this cell receives a conflicting digit (see
    /// SudokuGame.conflictShakes); every increment plays one shake.
    let shakeTrigger: Int
    var onTap: () -> Void

    @State private var animateTrigger = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Rectangle().fill(bg).border(Color.white.opacity(0.1), width: 0.5)

            if cell.value == nil && !cell.notes.isEmpty {
                NoteGridView(notes: cell.notes, size: cellSize)
            }

            if let val = cell.value {
                Text("\(val)")
                    .font(.system(size: cellSize * 0.6, weight: cell.isGiven ? .bold : .regular, design: .monospaced))
                    .foregroundColor(txt)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .keyframeAnimator(initialValue: 0.0, trigger: shakeTrigger) { content, offset in
            content.offset(x: offset)
        } keyframes: { _ in
            // CRT-glitch jitter on conflict; collapses to a no-op (amplitude 0)
            // when Reduce Motion is on — the red text still marks the error.
            let amplitude: Double = reduceMotion ? 0 : cellSize * 0.08
            LinearKeyframe(-amplitude, duration: 0.05)
            LinearKeyframe(amplitude, duration: 0.05)
            LinearKeyframe(-amplitude * 0.5, duration: 0.05)
            LinearKeyframe(0.0, duration: 0.05)
        }
        .onTapGesture {
            if !reduceMotion {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = false }
                }
            }
            onTap()
        }
    }

    private var bg: Color {
        if isSelected { return Color.green.opacity(0.2) }
        if let value = cell.value, value == highlightNumber { return Color.green.opacity(0.4) }
        if isRelated { return Color.white.opacity(0.05) }
        return Color.clear
    }

    private var txt: Color {
        if cell.isGiven { return .white }
        if cell.isError { return .red }
        return .green
    }
}
