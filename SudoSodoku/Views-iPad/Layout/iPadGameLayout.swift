import SwiftUI

/// iPad-specific game layout with horizontal arrangement
struct iPadGameLayout: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 30) {
                // Left side - Game Board
                VStack(spacing: 20) {
                    iPadTopBar(game: game)
                    
                    ZStack {
                        iPadBoardView(game: game)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width * 0.62)
                
                // Right side - Control Panel
                VStack(spacing: 15) {
                    iPadControlPanel(game: game)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.38)
                .padding(.trailing, 30)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
    }
}

/// iPad-optimized top bar
struct iPadTopBar: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: { /* Handle back action */ }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .padding(15)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("MODE: \(game.difficulty.rawValue)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(game.difficulty.color)
                Text("SCORE: \(game.currentScore)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if game.isArchived {
                Button(action: { game.toggleFavorite() }) {
                    ZStack {
                        if game.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "star")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(15)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

/// iPad-optimized board view
struct iPadBoardView: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        GeometryReader { geometry in
            if game.board.count < 81 {
                Color.clear
            } else {
                let boardSize = min(geometry.size.width, geometry.size.height) * 0.75
                let cellSize = boardSize / 9
                
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 2), count: 9),
                    spacing: 2
                ) {
                    ForEach(0..<81) { index in
                        iPadCellView(
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
                .overlay(GridLinesOverlay(width: boardSize))
                .border(Color.gray, width: 3)
            }
        }
    }
    
    private func isRelated(index: Int) -> Bool {
        guard let selectedIndex = game.selectedCellIndex else { return false }
        return selectedIndex / 9 == index / 9 || // Same row
               selectedIndex % 9 == index % 9 || // Same column
               (selectedIndex / 27 == index / 27 && selectedIndex % 9 / 3 == index % 9 / 3) // Same 3x3 box
    }
    
    private func getHighlightNumber() -> Int? {
        guard let selectedIndex = game.selectedCellIndex,
              let selectedValue = game.board[selectedIndex].value else { return nil }
        return selectedValue
    }
}

/// iPad-optimized cell view with larger touch targets
struct iPadCellView: View {
    let cell: SudokuCell
    let cellSize: CGFloat
    let isSelected: Bool
    let isRelated: Bool
    let highlightNumber: Int?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(cellBackgroundColor)
                    .frame(width: cellSize, height: cellSize)
                    .border(cellBorderColor, width: cellBorderWidth)
                
                if let value = cell.value {
                    Text("\(value)")
                        .font(.system(size: cellSize * 0.6, weight: .bold, design: .monospaced))
                        .foregroundColor(cellTextColor)
                } else if !cell.notes.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 2) {
                        ForEach(Array(cell.notes).sorted(), id: \.self) { note in
                            Text("\(note)")
                                .font(.system(size: cellSize * 0.2, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(cellSize * 0.1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
    
    private var cellBackgroundColor: Color {
        if isSelected {
            return Color.white.opacity(0.3)
        } else if isRelated {
            return Color.white.opacity(0.1)
        } else if cell.isError {
            return Color.red.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var cellTextColor: Color {
        if cell.isGiven {
            return .white
        } else if cell.isError {
            return .red
        } else {
            return .green
        }
    }
    
    private var cellBorderColor: Color {
        if isSelected {
            return .green
        } else {
            return .gray
        }
    }
    
    private var cellBorderWidth: CGFloat {
        isSelected ? 3 : 1
    }
}
