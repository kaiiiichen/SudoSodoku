import SwiftUI

struct BoardView: View {
    @ObservedObject var game: SudokuGame
    
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
                            onTap: {
                                game.selectCell(at: index)
                            }
                        )
                    }
                }
                .overlay(GridLinesOverlay(width: width))
                .border(Color.gray, width: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    func isRelated(index: Int) -> Bool {
        guard let s = game.selectedCellIndex, s < game.board.count && index < game.board.count else { return false }
        let sc = game.board[s]
        let cc = game.board[index]
        return cc.row == sc.row || cc.col == sc.col || (cc.row / 3 == sc.row / 3 && cc.col / 3 == sc.col / 3)
    }
    
    func getHighlightNumber() -> Int? {
        guard let idx = game.selectedCellIndex, idx < game.board.count, let val = game.board[idx].value else { return nil }
        return val
    }
}

struct CellView: View {
    let cell: SudokuCell
    let cellSize: CGFloat
    let isSelected: Bool
    let isRelated: Bool
    let highlightNumber: Int?
    var onTap: () -> Void
    
    @State private var animateTrigger = false
    
    var body: some View {
        ZStack {
            Rectangle().fill(bg).border(Color.white.opacity(0.1), width: 0.5)
            if isSelected { Rectangle().stroke(Color.green, lineWidth: 2).zIndex(10) }
            
            if cell.value == nil && !cell.notes.isEmpty {
                NoteGridView(notes: cell.notes, size: cellSize)
            }
            
            if let val = cell.value {
                Text("\(val)").font(.system(size: cellSize * 0.6, weight: cell.isGiven ? .bold : .regular, design: .monospaced)).foregroundColor(txt)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .onTapGesture {
            HapticManager.shared.lightImpact()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = true }
            onTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = false }
            }
        }
    }
    
    var bg: Color {
        if isSelected { return Color.green.opacity(0.2) }
        if let v = cell.value, v == highlightNumber { return Color.green.opacity(0.4) }
        if isRelated { return Color.white.opacity(0.05) }
        return Color.clear
    }
    
    var txt: Color {
        if cell.isGiven { return .white }
        if cell.isError { return .red }
        return .green
    }
}

