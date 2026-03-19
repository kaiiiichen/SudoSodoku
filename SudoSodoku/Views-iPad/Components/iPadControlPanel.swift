import SwiftUI

/// iPad-optimized control panel with larger buttons
struct iPadControlPanel: View {
    @ObservedObject var game: SudokuGame
    let isCompact: Bool
    let availableWidth: CGFloat?

    init(game: SudokuGame, isCompact: Bool = false, availableWidth: CGFloat? = nil) {
        self.game = game
        self.isCompact = isCompact
        self.availableWidth = availableWidth
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(spacing: 14) {
                buttonRow {
                    iPadControlButton(
                        title: "UNDO",
                        icon: "arrow.uturn.backward.circle",
                        tint: .cyan,
                        isActive: !game.undoStack.isEmpty,
                        isEnabled: !game.undoStack.isEmpty
                    ) {
                        game.undoLastMove()
                    }

                    iPadControlButton(
                        title: "REDO",
                        icon: "arrow.uturn.forward.circle",
                        tint: .cyan,
                        isActive: !game.redoStack.isEmpty,
                        isEnabled: !game.redoStack.isEmpty
                    ) {
                        game.redoLastMove()
                    }
                }

                buttonRow {
                    iPadControlButton(
                        title: game.isNoteMode ? "PENCIL" : "NORMAL",
                        icon: game.isNoteMode ? "pencil.circle.fill" : "pencil.circle",
                        tint: .green,
                        isActive: game.isNoteMode
                    ) {
                        game.isNoteMode.toggle()
                        HapticManager.shared.lightImpact()
                    }
                    
                    iPadControlButton(
                        title: "DEL",
                        icon: "trash",
                        tint: .gray,
                        isActive: false
                    ) {
                        game.clearSelectedCell()
                    }
                }
            }

            VStack(spacing: 15) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: numberGridColumns), spacing: 14) {
                    ForEach(1...9, id: \.self) { number in
                        iPadNumberButton(number: number, isCompact: isCompact) {
                            game.inputNumber(number)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.all, isCompact ? 18 : 20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isCompact ? 0.12 : 0.18), radius: isCompact ? 12 : 18, y: 6)
    }

    private var numberGridColumns: Int {
        if !isCompact { return 3 }
        if let availableWidth, availableWidth < 560 { return 4 }
        return 5
    }

    @ViewBuilder
    private func buttonRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if isCompact {
            HStack(spacing: 12) {
                content()
            }
        } else {
            HStack(spacing: 15) {
                content()
            }
        }
    }
}

/// iPad-optimized number button
private struct iPadNumberButton: View {
    let number: Int
    let isCompact: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 16 : 36)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.14), Color.white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: isCompact ? 56 : 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 16 : 36)
                            .stroke(Color.green, lineWidth: 2)
                    )

                Text("\(number)")
                    .font(.system(size: isCompact ? 24 : 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .contentShape(Rectangle())
        .buttonStyle(BouncyButtonStyle())
    }
}

/// iPad-optimized control button
private struct iPadControlButton: View {
    let title: String
    let icon: String
    let tint: Color
    let isActive: Bool
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(foregroundColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.72)
    }

    private var foregroundColor: Color {
        guard isEnabled else { return .gray.opacity(0.45) }
        return isActive ? tint : .gray
    }

    private var backgroundColor: Color {
        guard isEnabled else { return Color.white.opacity(0.04) }
        return isActive ? tint.opacity(0.18) : Color.white.opacity(0.08)
    }

    private var borderColor: Color {
        guard isEnabled else { return Color.gray.opacity(0.2) }
        return isActive ? tint : Color.gray.opacity(0.4)
    }
}
