import SwiftUI

struct BoardView: View {
    @ObservedObject var game: SudokuGame
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulseCells: Set<Int> = []
    @State private var pulseOpacity: Double = 0

    var body: some View {
        GeometryReader { geometry in
            if game.board.count < 81 {
                Color.clear
            } else {
                let width = geometry.size.width
                let cellSize = width / 9
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 9), spacing: 0) {
                    ForEach(0..<81) { index in
                        CellView(
                            cell: game.board[index],
                            cellSize: cellSize,
                            isSelected: game.selectedCellIndex == index,
                            isRelated: isRelated(index: index),
                            highlightNumber: getHighlightNumber(),
                            shakeTrigger: game.conflictShakes[index] ?? 0,
                            onTap: { game.selectCell(at: index) }
                        )
                    }
                }
                .overlay(GridLinesOverlay(width: width))
                .overlay(unitPulse(cellSize: cellSize))
                .overlay(selectionFrame(cellSize: cellSize))
                .border(Color.gray, width: 2)
                .sensoryFeedback(.selection, trigger: game.selectedCellIndex)
                .onChange(of: game.completedUnitPulse) { _, pulse in
                    guard let pulse, !reduceMotion else { return }
                    pulseCells = pulse.cells
                    pulseOpacity = 0.32
                    withAnimation(.easeOut(duration: 0.5)) { pulseOpacity = 0 }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Phosphor flash over a just-completed row/column/box: a brief green
    /// glow that decays over half a second. Skipped entirely under Reduce
    /// Motion (the medium haptic still marks the moment).
    @ViewBuilder
    private func unitPulse(cellSize: CGFloat) -> some View {
        if pulseOpacity > 0 {
            ZStack {
                ForEach(Array(pulseCells), id: \.self) { index in
                    Rectangle()
                        .fill(Color.green.opacity(pulseOpacity))
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: (CGFloat(index % 9) + 0.5) * cellSize,
                            y: (CGFloat(index / 9) + 0.5) * cellSize
                        )
                }
            }
            .allowsHitTesting(false)
        }
    }

    /// One shared selection rectangle that glides between cells instead of
    /// jumping (per-cell strokes can only appear/disappear). Instant under
    /// Reduce Motion.
    @ViewBuilder
    private func selectionFrame(cellSize: CGFloat) -> some View {
        Group {
            if let index = game.selectedCellIndex {
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: cellSize, height: cellSize)
                    .position(
                        x: (CGFloat(index % 9) + 0.5) * cellSize,
                        y: (CGFloat(index / 9) + 0.5) * cellSize
                    )
            }
        }
        .allowsHitTesting(false)
        .animation(
            reduceMotion ? nil : .spring(response: 0.2, dampingFraction: 0.8),
            value: game.selectedCellIndex
        )
    }

    private func isRelated(index: Int) -> Bool {
        guard let selected = game.selectedCellIndex,
              selected < game.board.count,
              index < game.board.count else { return false }
        let selectedCell = game.board[selected]
        let currentCell = game.board[index]
        return currentCell.row == selectedCell.row
            || currentCell.col == selectedCell.col
            || (currentCell.row / 3 == selectedCell.row / 3 && currentCell.col / 3 == selectedCell.col / 3)
    }

    private func getHighlightNumber() -> Int? {
        guard let index = game.selectedCellIndex,
              index < game.board.count,
              let value = game.board[index].value else { return nil }
        return value
    }
}
