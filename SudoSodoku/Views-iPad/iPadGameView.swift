import SwiftUI

/// iPad-optimized game view
struct iPadGameView: View {
    @StateObject var game = SudokuGame()
    @Environment(\.dismiss) var dismiss
    
    var difficulty: Difficulty?
    var record: GameRecord?
    
    @State private var showSaveAlert = false
    @State private var pendingExitAction: ExitAction? = nil
    @State private var showVictoryAnimation = false
    
    enum ExitAction {
        case back
        case refresh
    }
    
    var body: some View {
        ZStack {
            TerminalBackground()
                .onTapGesture {
                    game.selectedCellIndex = nil
                }
            
            if game.isGenerating {
                VStack(spacing: 20) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .green)).scaleEffect(2)
                    Text("LOADING DATA...").font(.system(size: 20, design: .monospaced)).foregroundColor(.green)
                }
            } else {
                VStack(spacing: 15) {
                    // Top bar - iPad optimized
                    HStack(spacing: 15) {
                        Button(action: { handleExitRequest(.back) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold)).foregroundColor(.white).padding(15).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("MODE: \(game.difficulty.rawValue)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(game.difficulty.color)
                            Text("SCORE: \(game.currentScore)").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if game.isArchived {
                            Button(action: { game.toggleFavorite() }) {
                                ZStack {
                                    if game.isFavorite {
                                        Image(systemName: "star.fill").foregroundColor(.yellow)
                                        Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.black).offset(y: 1)
                                    } else {
                                        Image(systemName: "star").foregroundColor(.white)
                                    }
                                }
                                .font(.system(size: 24)).padding(15).background(Color.white.opacity(0.1)).clipShape(Circle())
                            }
                        }
                        
                        Button(action: { game.toggleArchived() }) {
                            ZStack {
                                if game.isArchived {
                                    Image(systemName: "folder.fill").foregroundColor(.green)
                                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.black).offset(y: 1)
                                } else {
                                    Image(systemName: "folder").foregroundColor(.white)
                                }
                            }
                            .font(.system(size: 24)).padding(15).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        
                        Menu {
                            Button(role: .destructive, action: { game.replayCurrentGame() }) {
                                Label("RETRY (Clear)", systemImage: "eraser")
                            }
                            
                            Button(action: { handleExitRequest(.refresh) }) {
                                Label("NEW TARGET (New Game)", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(15)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 30).padding(.top, 15)
                    
                    Spacer()
                    
                    // Board - iPad optimized with proper spacing
                    BoardView(game: game).padding(.horizontal, 30)
                    
                    if game.isSolved {
                        VStack(spacing: 10) {
                            Text(">> SYSTEM HACKED <<").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(.green).padding().background(Color.green.opacity(0.1)).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.green, lineWidth: 2))
                            if let gained = game.ratingGained {
                                if gained > 0 {
                                    HStack { Image(systemName: "arrow.up.circle.fill"); Text("RATING INCREASED: +\(gained)").font(.system(size: 18, weight: .bold, design: .monospaced)) }.foregroundColor(.yellow)
                                } else {
                                    Text("LOW DIFFICULTY / NO GAIN").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Spacer()
                    }
                    
                    // Control Panel - iPad optimized
                    ControlPanelView(game: game).padding(.bottom, 20)
                }
            }
            
            if showVictoryAnimation { MatrixVictoryOverlay().zIndex(100) }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadGameIfNeeded()
            // Initialize GameCenter authentication
            GameCenterManager.shared.authenticateUser()
        }
        .alert("SAVE_PROGRESS?", isPresented: $showSaveAlert) {
            Button("KEEP (Save)", role: .none) {
                game.markAsArchived()
                performPendingAction()
            }
            Button("DISCARD (Delete)", role: .destructive) { game.discardCurrentRecord(); performPendingAction() }
            Button("CANCEL", role: .cancel) { pendingExitAction = nil }
        } message: { Text("Do you want to save this session to your archives?") }
    }
    
    // MARK: - Private Methods
    
    private func loadGameIfNeeded() {
        if let record = record {
            game.loadFromRecord(record)
        } else if let difficulty = difficulty {
            game.generateGame(for: difficulty)
        }
    }
    
    private func handleExitRequest(_ action: ExitAction) {
        if game.isSolved || game.isGenerating || game.isArchived || (record != nil && record!.isSolved) {
            pendingExitAction = action
            performPendingAction()
            return
        }
        pendingExitAction = action
        showSaveAlert = true
    }
    
    private func performPendingAction() {
        guard let action = pendingExitAction else { return }
        switch action {
        case .back:
            dismiss()
        case .refresh:
            if let difficulty = difficulty {
                game.generateGame(for: difficulty)
            }
        }
        pendingExitAction = nil
    }
}
