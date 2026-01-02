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
                    HapticManager.shared.lightImpact()
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 8) {
                ForEach(1...9, id: \.self) { num in
                    Button(action: { game.inputNumber(num) }) {
                        Text("\(num)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

