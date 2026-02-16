import SwiftUI

/// iPad-optimized control panel with larger buttons
struct iPadControlPanel: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 20) {
            // Number selection buttons
            VStack(spacing: 15) {
                Text("NUMBER_SELECTION")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(1...9, id: \.self) { number in
                        iPadNumberButton(number: number) {
                            game.inputNumber(number)
                        }
                    }
                }
            }
            
            // Control buttons
            VStack(spacing: 15) {
                Text("CONTROLS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                HStack(spacing: 15) {
                    iPadControlButton(
                        title: "NOTE_MODE",
                        icon: "pencil",
                        isActive: game.isNoteMode
                    ) {
                        game.isNoteMode.toggle()
                    }
                    
                    iPadControlButton(
                        title: "UNDO",
                        icon: "arrow.counterclockwise",
                        isActive: false
                    ) {
                        game.undoLastMove()
                    }
                    
                    iPadControlButton(
                        title: "REDO",
                        icon: "arrow.clockwise",
                        isActive: false
                    ) {
                        game.redoLastMove()
                    }
                }
                
                HStack(spacing: 15) {
                    iPadControlButton(
                        title: "CLEAR",
                        icon: "xmark.circle",
                        isActive: false
                    ) {
                        game.clearSelectedCell()
                    }
                    
                    iPadControlButton(
                        title: "SOLUTION",
                        icon: "eye.circle",
                        isActive: false
                    ) {
                        game.showSolution()
                    }
                }
            }
            
            Spacer()
        }
        .padding(.all, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
}

/// iPad-optimized number button
private struct iPadNumberButton: View {
    let number: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.green, lineWidth: 2)
                    )
                
                Text("\(number)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Handle tap animation
            }
        }
    }
}

/// iPad-optimized control button
private struct iPadControlButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isActive ? .green : .gray)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? .green : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive ? Color.green : Color.gray, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
