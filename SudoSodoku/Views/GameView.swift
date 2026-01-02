import SwiftUI

struct GameView: View {
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
                    Text("LOADING DATA...").font(.system(size: 16, design: .monospaced)).foregroundColor(.green)
                }
            } else {
                VStack(spacing: 10) {
                    // 顶部栏
                    HStack(spacing: 12) {
                        Button(action: { handleExitRequest(.back) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("MODE: \(game.difficulty.rawValue)").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(game.difficulty.color)
                            Text("SCORE: \(game.currentScore)").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if game.isArchived {
                            Button(action: { game.toggleFavorite() }) {
                                ZStack {
                                    if game.isFavorite {
                                        Image(systemName: "star.fill").foregroundColor(.yellow)
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.black).offset(y: 1)
                                    } else {
                                        Image(systemName: "star").foregroundColor(.white)
                                    }
                                }
                                .font(.system(size: 20)).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                            }
                        }
                        
                        Button(action: { game.toggleArchived() }) {
                            ZStack {
                                if game.isArchived {
                                    Image(systemName: "folder.fill").foregroundColor(.green)
                                    Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.black).offset(y: 1)
                                } else {
                                    Image(systemName: "folder").foregroundColor(.white)
                                }
                            }
                            .font(.system(size: 20)).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
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
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal).padding(.top, 10)
                    
                    Spacer()
                    BoardView(game: game).padding(.horizontal, 10)
                    
                    if game.isSolved {
                        VStack(spacing: 10) {
                            Text(">> SYSTEM HACKED <<").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.green).padding().background(Color.green.opacity(0.1)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
                            if let gained = game.ratingGained {
                                if gained > 0 {
                                    HStack { Image(systemName: "arrow.up.circle.fill"); Text("RATING INCREASED: +\(gained)").font(.system(size: 16, weight: .bold, design: .monospaced)) }.foregroundColor(.yellow)
                                } else {
                                    Text("LOW DIFFICULTY / NO GAIN").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Spacer()
                    }
                    ControlPanelView(game: game).padding(.bottom)
                }
            }
            
            if showVictoryAnimation { MatrixVictoryOverlay().zIndex(100) }
        }
        .navigationBarHidden(true)
        .onAppear {
            if game.board.isEmpty {
                game.onSolved = {
                    withAnimation { showVictoryAnimation = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation { showVictoryAnimation = false } }
                }
                if let rec = record {
                    game.loadFromRecord(rec)
                    if rec.isSolved { game.showSolution() }
                } else if let diff = difficulty {
                    game.generateGame(for: diff)
                }
            }
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
    
    func handleExitRequest(_ action: ExitAction) {
        if game.isSolved || game.isGenerating || game.isArchived || (record != nil && record!.isSolved) {
            pendingExitAction = action
            performPendingAction()
            return
        }
        pendingExitAction = action
        showSaveAlert = true
    }
    
    func performPendingAction() {
        guard let action = pendingExitAction else { return }
        switch action {
        case .back: dismiss()
        case .refresh:
            if let diff = difficulty { game.generateGame(for: diff) } else { game.replayCurrentGame() }
        }
        pendingExitAction = nil
    }
}

