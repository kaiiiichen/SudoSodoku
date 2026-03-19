import SwiftUI

/// iPad-optimized game view
struct iPadGameView: View {
    @StateObject private var game: SudokuGame
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

    init(game: SudokuGame = SudokuGame(), difficulty: Difficulty? = nil, record: GameRecord? = nil) {
        _game = StateObject(wrappedValue: game)
        self.difficulty = difficulty
        self.record = record
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
                GeometryReader { geometry in
                    let isLandscape = geometry.size.width > geometry.size.height

                    VStack(spacing: isLandscape ? 18 : 14) {
                        topBar(isCompact: !isLandscape)
                            .padding(.horizontal, isLandscape ? 36 : 24)
                            .padding(.top, isLandscape ? 20 : 16)

                        Group {
                            if isLandscape {
                                landscapeWorkspace(in: geometry.size)
                            } else {
                                portraitWorkspace(in: geometry.size)
                            }
                        }
                        .padding(.horizontal, isLandscape ? 36 : 24)
                        .padding(.bottom, isLandscape ? 28 : 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isLandscape)
                }
            }
            
            if showVictoryAnimation { MatrixVictoryOverlay().zIndex(100) }
        }
        .navigationBarHidden(true)
        .onAppear {
            configureVictoryAnimation()
            loadGameIfNeeded()
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

    @ViewBuilder
    private func topBar(isCompact: Bool) -> some View {
        if isCompact {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    backButton

                    VStack(alignment: .leading, spacing: 4) {
                        Text("MODE: \(game.difficulty.rawValue)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(game.difficulty.color)
                        Text("SCORE: \(game.currentScore)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    if game.isArchived {
                        favoriteButton
                    }
                    archiveButton
                    overflowMenu
                }
            }
            .padding(18)
            .background(topBarBackground)
        } else {
            HStack(spacing: 15) {
                backButton

                VStack(alignment: .leading, spacing: 4) {
                    Text("MODE: \(game.difficulty.rawValue)")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(game.difficulty.color)
                    Text("SCORE: \(game.currentScore)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                if game.isArchived {
                    favoriteButton
                }
                archiveButton
                overflowMenu
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(topBarBackground)
        }
    }

    private var topBarBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color.black.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var backButton: some View {
        Button(action: { handleExitRequest(.back) }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(15)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }

    private var favoriteButton: some View {
        Button(action: { game.toggleFavorite() }) {
            ZStack {
                if game.isFavorite {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.black).offset(y: 1)
                } else {
                    Image(systemName: "star").foregroundColor(.white)
                }
            }
            .font(.system(size: 24))
            .padding(15)
            .background(Color.white.opacity(0.1))
            .clipShape(Circle())
        }
    }

    private var archiveButton: some View {
        Button(action: { game.toggleArchived() }) {
            ZStack {
                if game.isArchived {
                    Image(systemName: "folder.fill").foregroundColor(.green)
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(.black).offset(y: 1)
                } else {
                    Image(systemName: "folder").foregroundColor(.white)
                }
            }
            .font(.system(size: 24))
            .padding(15)
            .background(Color.white.opacity(0.1))
            .clipShape(Circle())
        }
    }

    private var overflowMenu: some View {
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
    
    private func loadGameIfNeeded() {
        guard game.board.isEmpty else { return }
        if let record = record {
            game.loadFromRecord(record)
            if record.isSolved {
                game.showSolution()
            }
        } else if let difficulty = difficulty {
            game.generateGame(for: difficulty)
        }
    }

    private func configureVictoryAnimation() {
        game.onSolved = {
            withAnimation { showVictoryAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showVictoryAnimation = false }
            }
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
            } else {
                game.replayCurrentGame()
            }
        }
        pendingExitAction = nil
    }

    @ViewBuilder
    private func landscapeWorkspace(in size: CGSize) -> some View {
        HStack(alignment: .top, spacing: 28) {
            boardColumn(
                boardWidth: min(size.width * 0.60, size.height * 0.94),
                summaryInline: true
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            iPadControlPanel(game: game)
                .frame(width: min(max(size.width * 0.32, 320), 400))
        }
    }

    @ViewBuilder
    private func portraitWorkspace(in size: CGSize) -> some View {
        VStack(spacing: 22) {
            boardColumn(
                boardWidth: min(size.width - 48, size.height * 0.42),
                summaryInline: false
            )

            iPadControlPanel(game: game, isCompact: true, availableWidth: size.width - 48)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func boardColumn(boardWidth: CGFloat, summaryInline: Bool) -> some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)

            BoardView(game: game)
                .frame(width: max(boardWidth, 280))
                .shadow(color: Color.green.opacity(summaryInline ? 0.08 : 0.05), radius: summaryInline ? 18 : 10)

            if game.isSolved {
                victorySummary
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var victorySummary: some View {
        VStack(spacing: 10) {
            Text(">> SYSTEM HACKED <<")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.green, lineWidth: 2))

            if let gained = game.ratingGained {
                if gained > 0 {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("RATING INCREASED: +\(gained)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.yellow)
                } else {
                    Text("LOW DIFFICULTY / NO GAIN")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 8)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
