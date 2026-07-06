import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var game: SudokuGame
    
    var body: some View {
        VStack(spacing: 20) {
            // 1. Undo / Redo Row
            HStack {
                Spacer()
                
                Button(action: { game.undoLastMove() }) {
                    VStack {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 24))
                        Text("UNDO")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(game.undoStack.isEmpty ? .gray.opacity(0.5) : .cyan)
                }
                .disabled(game.undoStack.isEmpty)
                
                Spacer().frame(width: 24)
                
                Button(action: { game.redoLastMove() }) {
                    VStack {
                        Image(systemName: "arrow.uturn.forward.circle")
                            .font(.system(size: 24))
                        Text("REDO")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(game.redoStack.isEmpty ? .gray.opacity(0.5) : .cyan)
                }
                .disabled(game.redoStack.isEmpty)
            }
            .padding(.horizontal, 20)
            
            // 2. Pencil and Del Row
            HStack {
                Button(action: {
                    game.isNoteMode.toggle()
                    HapticManager.shared.noteModeToggled()
                }) {
                    VStack {
                        Image(systemName: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle")
                            .font(.system(size: 24))
                        Text(game.isNoteMode ? "PENCIL" : "NORMAL")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(game.isNoteMode ? .green : .gray)
                }
                
                Spacer()
                
                Button(action: { game.clearSelectedCell() }) {
                    VStack {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                        Text("DEL")
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            
            // 3. Numpad
            let hasSelection = game.selectedCellIndex != nil
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                ForEach(1...9, id: \.self) { num in
                    let exhausted = game.isExhausted(num)
                    Button(action: {
                        // With no cell selected the input would be silently
                        // swallowed; nudge instead so the tap never feels dead.
                        guard hasSelection else {
                            HapticManager.shared.warning()
                            return
                        }
                        game.inputNumber(num)
                    }) {
                        Text("\(num)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .strikethrough(exhausted, color: .gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.white.opacity(exhausted ? 0.04 : 0.1))
                            .foregroundColor(exhausted ? .gray.opacity(0.5) : .white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(.horizontal)
            .opacity(hasSelection ? 1.0 : 0.45)
            .animation(.easeInOut(duration: 0.15), value: hasSelection)
        }
    }
}


