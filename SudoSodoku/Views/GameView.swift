import Combine
import SwiftUI

struct GameView: View {
    @StateObject private var game: SudokuGame
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    private let difficulty: Difficulty?
    private let record: GameRecord?

    @State private var showSaveAlert = false
    @State private var pendingExitAction: ExitAction?
    @State private var showVictoryAnimation = false

    @AppStorage("showPlayTimer") private var showPlayTimer = true
    @State private var clockNow = Date()
    @State private var showBreachLog = false
    @State private var showSudoersJoke = false

    @ObservedObject private var achievements = AchievementManager.shared
    @State private var toastText: String?
    @State private var pendingToast: String?
    private let clockTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum ExitAction {
        case back
        case refresh
    }

    init(difficulty: Difficulty) {
        _game = StateObject(wrappedValue: SudokuGame())
        self.difficulty = difficulty
        self.record = nil
    }

    init(record: GameRecord) {
        _game = StateObject(wrappedValue: SudokuGame())
        self.difficulty = nil
        self.record = record
    }

    var body: some View {
        ZStack {
            TerminalBackground()
                .onTapGesture { game.selectedCellIndex = nil }

            if showSudoersJoke {
                SudoersInterstitial(
                    username: GameCenterManager.shared.isAuthenticated
                        ? GameCenterManager.shared.playerName.lowercased()
                        : "user",
                    onFinished: {
                        SudoersJoke.markSeen()
                        AchievementManager.shared.unlockIncidentReported()
                        withAnimation(.easeOut(duration: 0.2)) { showSudoersJoke = false }
                        if let difficulty {
                            showBreachLog = true
                            game.generateGame(for: difficulty)
                        }
                    }
                )
            } else if game.isGenerating || showBreachLog {
                BreachLogView(
                    difficulty: game.difficulty,
                    isGenerating: game.isGenerating,
                    finalScore: game.currentScore,
                    onFinished: { withAnimation(.easeOut(duration: 0.2)) { showBreachLog = false } }
                )
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Button(action: { handleExitRequest(.back) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white).padding(10).background(Color.white.opacity(0.1)).clipShape(Circle())
                        }

                        VStack(alignment: .leading) {
                            Text("MODE: \(game.difficulty.rawValue)").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(game.difficulty.color)
                            Text("SCORE: \(game.currentScore)").font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                            if showPlayTimer {
                                Text("T+\(DateFormatting.playClock(game.playDuration(at: clockNow)))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.8))
                            }
                            if game.streak >= 5 {
                                Text("streak: \(game.streak) ▲")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.cyan.opacity(0.9))
                            }
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
                            Button(action: { showPlayTimer.toggle() }) {
                                Label(showPlayTimer ? "HIDE TIMER" : "SHOW TIMER", systemImage: "stopwatch")
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
                            if game.playDuration() > 0 {
                                Text("TIME: \(DateFormatting.playClock(game.playDuration()))")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Spacer()
                    }
                    ControlPanelView(game: game).padding(.bottom)
                }
            }

            if showVictoryAnimation {
                MatrixVictoryOverlay(
                    ratingGained: game.ratingGained ?? 0,
                    newRating: StorageManager.shared.userRating,
                    onDismiss: { withAnimation(.easeOut(duration: 0.25)) { showVictoryAnimation = false } }
                )
                .zIndex(100)
            }

            if let toastText {
                Text(toastText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.6), lineWidth: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
                    .transition(.opacity)
                    .zIndex(50)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: achievements.justUnlocked) { _, unlocked in
            guard let first = unlocked.first else { return }
            let suffix = unlocked.count > 1 ? " +\(unlocked.count - 1)" : ""
            pendingToast = ">> ACHIEVEMENT: \(first.title)\(suffix)"
            if !showVictoryAnimation { presentToast() }
        }
        .onChange(of: showVictoryAnimation) { _, showing in
            if !showing { presentToast() }
        }
        .onReceive(clockTicker) { clockNow = $0 }
        .onChange(of: game.isGenerating) { _, generating in
            if generating { showBreachLog = true }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background, .inactive:
                game.pauseClock()
                if !game.board.isEmpty { game.saveCurrentState() }
            case .active:
                game.resumeClock()
            @unknown default:
                break
            }
        }
        .onAppear {
            guard game.board.isEmpty else { return }

            game.onSolved = {
                withAnimation { showVictoryAnimation = true }
            }

            if let record {
                game.loadFromRecord(record)
                if record.isSolved { game.showSolution() }
            } else if let difficulty {
                if SudoersJoke.shouldShow(for: difficulty) {
                    showSudoersJoke = true
                } else {
                    showBreachLog = true
                    game.generateGame(for: difficulty)
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

    private func presentToast() {
        guard let text = pendingToast else { return }
        pendingToast = nil
        withAnimation(.easeIn(duration: 0.2)) { toastText = text }
        Task {
            try? await Task.sleep(for: .seconds(2.6))
            withAnimation(.easeOut(duration: 0.3)) { toastText = nil }
        }
    }

    private func handleExitRequest(_ action: ExitAction) {
        if game.isSolved || game.isGenerating || game.isArchived || (record?.isSolved == true) {
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
            if let difficulty {
                game.generateGame(for: difficulty)
            } else {
                game.replayCurrentGame()
            }
        }
        pendingExitAction = nil
    }
}
