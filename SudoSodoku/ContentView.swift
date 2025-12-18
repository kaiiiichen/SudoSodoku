import SwiftUI
import Combine
import GameKit

// MARK: - 0. 基础设施 (Haptics & Styles)

class HapticManager {
    static let shared = HapticManager()
    func lightImpact() { let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred() }
    func mediumImpact() { let g = UIImpactFeedbackGenerator(style: .medium); g.impactOccurred() }
    func success() { let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success) }
    func error() { let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.error) }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { HapticManager.shared.lightImpact() }
            }
    }
}

// MARK: - 1. 数据模型与持久化

struct GameRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let startTime: Date
    var lastPlayedTime: Date
    let difficulty: String
    let difficultyIndex: Int
    let initialBoard: [Int]
    let solution: [Int]
    var playerBoard: [Int]
    var playerNotes: [[Int]]?
    var isSolved: Bool
    var ratingChange: Int?
    
    var isArchived: Bool = false
    var isFavorite: Bool = false
    
    var progress: Int {
        if isSolved { return 100 }
        let totalToFill = initialBoard.filter { $0 == 0 }.count
        if totalToFill == 0 { return 100 }
        var filledCount = 0
        for i in 0..<81 {
            if initialBoard[i] == 0 && playerBoard[i] != 0 {
                filledCount += 1
            }
        }
        return Int((Double(filledCount) / Double(totalToFill)) * 100)
    }
}

// MARK: - ELO Rating Manager
class RatingManager {
    static let shared = RatingManager()
    
    func calculateRatingChange(playerRating: Int, puzzleDifficultyIndex: Int) -> Int {
        let puzzleRating = 800.0 + (Double(puzzleDifficultyIndex) * 12.0)
        let exponent = (puzzleRating - Double(playerRating)) / 400.0
        let expectedScore = 1.0 / (1.0 + pow(10.0, exponent))
        let kFactor: Double = playerRating < 2000 ? 32.0 : (playerRating < 2400 ? 24.0 : 16.0)
        let change = kFactor * (1.0 - expectedScore)
        return max(1, Int(round(change)))
    }
    
    func getRankTitle(rating: Int) -> (title: String, color: Color) {
        switch rating {
        case ..<1200: return ("SCRIPT_KIDDIE", .gray)
        case 1200..<1400: return ("USER", .green)
        case 1400..<1600: return ("SUDOER", .cyan)
        case 1600..<1800: return ("SYS_ADMIN", .blue)
        case 1800..<2000: return ("KERNEL_HACKER", .purple)
        default: return ("THE_ARCHITECT", .orange)
        }
    }
}

// MARK: - Storage Manager
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    @Published var records: [GameRecord] = []
    @Published var userRating: Int = 1200
    
    private let currentFileName = "save_data_v4.json"
    private let legacyFileNames = ["save_data_v3.json", "save_data_v2.json", "save_data.json"]
    
    init() { loadData() }
    
    private func getFileURL(name: String) -> URL {
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            if !FileManager.default.fileExists(atPath: iCloudURL.path) {
                try? FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
            }
            return iCloudURL.appendingPathComponent(name)
        } else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        }
    }
    
    struct StorageContainer: Codable {
        let rating: Int
        let records: [GameRecord]
    }
    
    func saveGame(_ record: GameRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
        persist()
    }
    
    func toggleFavorite(for id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isFavorite.toggle()
            if records[index].isFavorite { records[index].isArchived = true }
            persist()
        }
    }
    
    func setArchived(for id: UUID, isArchived: Bool) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isArchived = isArchived
            if !isArchived { records[index].isFavorite = false }
            persist()
        }
    }
    
    func batchDelete(ids: Set<UUID>) {
        records.removeAll { ids.contains($0.id) }
        persist()
    }
    
    func batchFavorite(ids: Set<UUID>) {
        for i in 0..<records.count {
            if ids.contains(records[i].id) {
                records[i].isFavorite = true
                records[i].isArchived = true
            }
        }
        persist()
    }
    
    func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        persist()
    }
    
    func deleteRecord(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records.remove(at: index)
            persist()
        }
    }
    
    func updateUserRating(add points: Int) {
        userRating += points
        persist()
    }
    
    func loadData() {
        let currentURL = getFileURL(name: currentFileName)
        
        // 1. 尝试加载当前版本 (v4)
        if FileManager.default.fileExists(atPath: currentURL.path),
           let data = try? Data(contentsOf: currentURL),
           let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
            DispatchQueue.main.async {
                self.records = decoded.records.sorted(by: { $0.lastPlayedTime > $1.lastPlayedTime })
                self.userRating = decoded.rating
            }
            return
        }
        
        // 2. 迁移逻辑
        print("⚠️ Current save not found. Attempting migration...")
        for legacyName in legacyFileNames {
            let legacyURL = getFileURL(name: legacyName)
            if FileManager.default.fileExists(atPath: legacyURL.path) {
                print("✅ Found legacy save: \(legacyName)")
                if let data = try? Data(contentsOf: legacyURL),
                   let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
                    
                    DispatchQueue.main.async {
                        // [关键修复] 将所有迁移过来的旧记录强制标记为已存档
                        // 因为在旧版本中，只要在列表里就是“已保存”的
                        var migratedRecords = decoded.records
                        for i in 0..<migratedRecords.count {
                            migratedRecords[i].isArchived = true
                        }
                        
                        self.records = migratedRecords.sorted(by: { $0.lastPlayedTime > $1.lastPlayedTime })
                        self.userRating = decoded.rating
                        // 立即保存为 v4 格式，完成迁移
                        self.persist()
                        print("🚀 Migration successful. All legacy records marked as archived.")
                    }
                    return
                }
            }
        }
    }
    
    private func persist() {
        let container = StorageContainer(rating: userRating, records: records)
        if let data = try? JSONEncoder().encode(container) {
            try? data.write(to: getFileURL(name: currentFileName))
        }
    }
}

// MARK: - Game Center
class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    @Published var isAuthenticated = false
    @Published var playerName: String = "Guest"
    @Published var playerPhoto: Image?
    
    func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            if let vc = vc {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.playerName = localPlayer.displayName
                    localPlayer.loadPhoto(for: .small) { image, _ in
                        if let image = image { self.playerPhoto = Image(uiImage: image) }
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel & Game Logic

struct SudokuCell: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let col: Int
    var value: Int?
    var solutionValue: Int?
    var isGiven: Bool
    var isError: Bool = false
    var notes: Set<Int> = []
}

struct MoveHistory {
    let index: Int
    let oldCell: SudokuCell
    let newCell: SudokuCell
}

enum Difficulty: String, CaseIterable, Codable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    case master = "MASTER"
    
    var scoreRange: ClosedRange<Int> {
        switch self {
        case .easy: return 0...15
        case .medium: return 16...40
        case .hard: return 41...75
        case .master: return 76...100
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .master: return .red
        }
    }
}

class SudokuGame: ObservableObject {
    @Published var board: [SudokuCell] = []
    @Published var selectedCellIndex: Int?
    @Published var difficulty: Difficulty = .easy
    @Published var isSolved: Bool = false
    @Published var currentScore: Int = 0
    @Published var isGenerating: Bool = true
    @Published var ratingGained: Int? = nil
    
    @Published var isNoteMode: Bool = false
    
    @Published var isArchived: Bool = false
    @Published var isFavorite: Bool = false
    
    @Published var undoStack: [MoveHistory] = []
    @Published var redoStack: [MoveHistory] = []
    
    var onSolved: (() -> Void)?
    var currentRecordID: UUID?
    
    init() { }
    
    func discardCurrentRecord() {
        guard let recordID = currentRecordID else { return }
        if !isArchived {
            StorageManager.shared.deleteRecord(id: recordID)
        }
    }
    
    func generateGame(for difficulty: Difficulty) {
        self.difficulty = difficulty
        self.isGenerating = true
        self.selectedCellIndex = nil
        self.isSolved = false
        self.ratingGained = nil
        self.isArchived = false
        self.isFavorite = false
        self.isNoteMode = false
        self.undoStack = []
        self.redoStack = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            let (puzzle, solution, score) = SudokuGenerator.generatePuzzle(targetDifficulty: difficulty)
            let newRecordID = UUID()
            
            DispatchQueue.main.async {
                self.currentScore = score
                self.currentRecordID = newRecordID
                
                self.board = (0..<81).map { i in
                    let val = puzzle[i]
                    let sol = solution[i]
                    return SudokuCell(
                        row: i / 9,
                        col: i % 9,
                        value: val == 0 ? nil : val,
                        solutionValue: sol,
                        isGiven: val != 0
                    )
                }
                self.isGenerating = false
                self.saveCurrentState()
            }
        }
    }
    
    func loadFromRecord(_ record: GameRecord) {
        self.isGenerating = true
        self.currentRecordID = record.id
        self.difficulty = Difficulty(rawValue: record.difficulty) ?? .easy
        self.isSolved = record.isSolved
        self.currentScore = record.difficultyIndex
        self.ratingGained = record.ratingChange
        self.isArchived = record.isArchived
        self.isFavorite = record.isFavorite
        self.isNoteMode = false
        self.undoStack = []
        self.redoStack = []
        
        self.board = (0..<81).map { i in
            let initialVal = record.initialBoard[i]
            let playerVal = record.playerBoard[i]
            let solutionVal = record.solution[i]
            let displayValue = initialVal != 0 ? initialVal : (playerVal != 0 ? playerVal : nil)
            
            let notesArray = record.playerNotes?[i] ?? []
            let notes = Set(notesArray)
            
            return SudokuCell(
                row: i / 9,
                col: i % 9,
                value: displayValue,
                solutionValue: solutionVal,
                isGiven: initialVal != 0,
                notes: notes
            )
        }
        
        updateBoardErrors()
        self.isGenerating = false
    }
    
    func selectCell(at index: Int) {
        selectedCellIndex = index
    }
    
    func inputNumber(_ number: Int) {
        guard let index = selectedCellIndex else { return }
        if board[index].isGiven { return }
        
        let oldCell = board[index]
        
        if isNoteMode {
            if board[index].notes.contains(number) {
                board[index].notes.remove(number)
            } else {
                board[index].notes.insert(number)
            }
        } else {
            if board[index].value == number {
                board[index].value = nil
            } else {
                board[index].value = number
                board[index].notes = []
            }
            updateBoardErrors()
            checkVictory()
        }
        
        let newCell = board[index]
        
        if oldCell != newCell {
            undoStack.append(MoveHistory(index: index, oldCell: oldCell, newCell: newCell))
            redoStack.removeAll()
        }
        
        saveCurrentState()
    }
    
    func undoLastMove() {
        guard let lastMove = undoStack.popLast() else { return }
        redoStack.append(lastMove)
        board[lastMove.index] = lastMove.oldCell
        updateBoardErrors()
        saveCurrentState()
        HapticManager.shared.lightImpact()
    }
    
    func redoLastMove() {
        guard let nextMove = redoStack.popLast() else { return }
        undoStack.append(nextMove)
        board[nextMove.index] = nextMove.newCell
        updateBoardErrors()
        saveCurrentState()
        HapticManager.shared.lightImpact()
    }
    
    func clearSelectedCell() {
        guard let index = selectedCellIndex, !board[index].isGiven else { return }
        
        let oldCell = board[index]
        board[index].value = nil
        board[index].notes = []
        board[index].isError = false
        let newCell = board[index]
        
        if oldCell != newCell {
            undoStack.append(MoveHistory(index: index, oldCell: oldCell, newCell: newCell))
            redoStack.removeAll()
        }
        
        updateBoardErrors()
        saveCurrentState()
    }
    
    func toggleFavorite() {
        guard let id = currentRecordID else { return }
        isFavorite.toggle()
        if isFavorite { isArchived = true }
        StorageManager.shared.toggleFavorite(for: id)
        if let rec = StorageManager.shared.records.first(where: { $0.id == id }) {
            self.isArchived = rec.isArchived
        }
    }
    
    func toggleArchived() {
        guard let id = currentRecordID else { return }
        isArchived.toggle()
        StorageManager.shared.setArchived(for: id, isArchived: isArchived)
        if !isArchived { isFavorite = false }
    }
    
    func markAsArchived() {
        isArchived = true
        saveCurrentState()
    }
    
    func saveCurrentState() {
        guard let recordID = currentRecordID else { return }
        
        let initialBoardInts = board.map { $0.isGiven ? ($0.value ?? 0) : 0 }
        let solutionInts = board.map { $0.solutionValue ?? 0 }
        let playerBoardInts = board.map { $0.isGiven ? 0 : ($0.value ?? 0) }
        let notesData = board.map { Array($0.notes) }
        
        let record = GameRecord(
            id: recordID,
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: difficulty.rawValue,
            difficultyIndex: currentScore,
            initialBoard: initialBoardInts,
            solution: solutionInts,
            playerBoard: playerBoardInts,
            playerNotes: notesData,
            isSolved: isSolved,
            ratingChange: ratingGained,
            isArchived: isArchived,
            isFavorite: isFavorite
        )
        StorageManager.shared.saveGame(record)
    }
    
    func replayCurrentGame() {
        guard let recordID = currentRecordID else { return }
        guard let _ = StorageManager.shared.records.first(where: { $0.id == recordID }) else { return }
        
        for i in 0..<81 {
            if !board[i].isGiven {
                board[i].value = nil
                board[i].notes = []
                board[i].isError = false
            }
        }
        isSolved = false
        ratingGained = nil
        undoStack = []
        redoStack = []
        saveCurrentState()
    }
    
    func showSolution() {
        for i in 0..<81 {
            board[i].value = board[i].solutionValue
            board[i].notes = []
            board[i].isError = false
        }
        isSolved = true
        saveCurrentState()
    }
    
    private func isConflict(at index: Int, value: Int) -> Bool {
        let row = index / 9
        let col = index % 9
        
        for c in 0..<9 {
            let otherIndex = row * 9 + c
            if otherIndex != index, let otherVal = board[otherIndex].value, otherVal == value { return true }
        }
        for r in 0..<9 {
            let otherIndex = r * 9 + col
            if otherIndex != index, let otherVal = board[otherIndex].value, otherVal == value { return true }
        }
        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for r in 0..<3 {
            for c in 0..<3 {
                let otherIndex = (startRow + r) * 9 + (startCol + c)
                if otherIndex != index, let otherVal = board[otherIndex].value, otherVal == value { return true }
            }
        }
        return false
    }
    
    private func updateBoardErrors() {
        for i in 0..<81 {
            guard let val = board[i].value else {
                board[i].isError = false
                continue
            }
            if isConflict(at: i, value: val) {
                board[i].isError = true
            } else {
                board[i].isError = false
            }
        }
    }
    
    private func checkVictory() {
        let isFull = !board.contains { $0.value == nil }
        let hasError = board.contains { $0.isError }
        
        if isFull && !hasError && !isSolved {
            isSolved = true
            HapticManager.shared.success()
            let currentElo = StorageManager.shared.userRating
            let gained = RatingManager.shared.calculateRatingChange(playerRating: currentElo, puzzleDifficultyIndex: currentScore)
            self.ratingGained = gained
            StorageManager.shared.updateUserRating(add: gained)
            saveCurrentState()
            onSolved?()
        }
    }
}

// MARK: - Generator (保持不变)
struct SudokuGenerator {
    static let MAX_RAW_SCORE = 320.0
    static let MIN_RAW_SCORE = 30.0
    
    static func generatePuzzle(targetDifficulty: Difficulty) -> ([Int], [Int], Int) {
        var bestBoard: [Int] = []
        var bestScore = -1
        let solvedBoard = generateSolvedBoard()
        
        let maxAttempts = 40
        for _ in 0..<maxAttempts {
            let cluesToKeep: Int
            switch targetDifficulty {
            case .easy: cluesToKeep = Int.random(in: 36...50)
            case .medium: cluesToKeep = Int.random(in: 30...40)
            case .hard: cluesToKeep = Int.random(in: 24...32)
            case .master: cluesToKeep = Int.random(in: 20...25)
            }
            
            let puzzle = digHoles(solvedBoard: solvedBoard, targetClues: cluesToKeep)
            let rawScore = evaluateDifficulty(puzzle: puzzle)
            let normalizedScore = normalize(rawScore)
            
            if targetDifficulty.scoreRange.contains(normalizedScore) {
                return (puzzle, solvedBoard, normalizedScore)
            }
            
            let targetCenter = Double(targetDifficulty.scoreRange.lowerBound + targetDifficulty.scoreRange.upperBound) / 2.0
            let currentDist = abs(Double(normalizedScore) - targetCenter)
            let bestDist = bestScore == -1 ? Double.infinity : abs(Double(bestScore) - targetCenter)
            
            if bestBoard.isEmpty || currentDist < bestDist {
                bestBoard = puzzle
                bestScore = normalizedScore
            }
        }
        return (bestBoard, solvedBoard, bestScore)
    }
    
    static func normalize(_ raw: Int) -> Int {
        let percentage = (Double(raw) - MIN_RAW_SCORE) / (MAX_RAW_SCORE - MIN_RAW_SCORE)
        let score = Int(percentage * 100)
        return max(0, min(100, score))
    }
    
    static func evaluateDifficulty(puzzle: [Int]) -> Int {
        var tempBoard = puzzle
        var score = 0
        var emptyCells = tempBoard.filter { $0 == 0 }.count
        
        while emptyCells > 0 {
            var progressMade = false
            for i in 0..<81 {
                if tempBoard[i] == 0 {
                    let candidates = getCandidates(board: tempBoard, index: i)
                    if candidates.count == 1 {
                        tempBoard[i] = candidates[0]
                        score += 1
                        emptyCells -= 1
                        progressMade = true
                    }
                }
            }
            if progressMade { continue }
            if let move = findHiddenSingle(board: tempBoard) {
                tempBoard[move.index] = move.value
                score += 3
                emptyCells -= 1
                progressMade = true
            }
            if progressMade { continue }
            score += (emptyCells * 5)
            break
        }
        return score
    }
    
    static func getCandidates(board: [Int], index: Int) -> [Int] {
        var candidates: [Int] = []
        let row = index / 9
        let col = index % 9
        for num in 1...9 {
            if isValid(board, num, row, col) {
                candidates.append(num)
            }
        }
        return candidates
    }
    
    static func findHiddenSingle(board: [Int]) -> (index: Int, value: Int)? {
        for r in 0..<9 {
            var counts = Array(repeating: 0, count: 10)
            var positions = Array(repeating: -1, count: 10)
            for c in 0..<9 {
                let idx = r * 9 + c
                if board[idx] == 0 {
                    let candidates = getCandidates(board: board, index: idx)
                    for val in candidates {
                        counts[val] += 1
                        positions[val] = idx
                    }
                }
            }
            for val in 1...9 {
                if counts[val] == 1 && positions[val] != -1 {
                    return (positions[val], val)
                }
            }
        }
        return nil
    }

    static func generateSolvedBoard() -> [Int] {
        var board = Array(repeating: 0, count: 81)
        _ = solve(&board)
        return board
    }
    
    static func solve(_ board: inout [Int]) -> Bool {
        guard let index = board.firstIndex(of: 0) else { return true }
        let numbers = (1...9).shuffled()
        for num in numbers {
            if isValid(board, num, index / 9, index % 9) {
                board[index] = num
                if solve(&board) { return true }
                board[index] = 0
            }
        }
        return false
    }
    
    static func isValid(_ board: [Int], _ num: Int, _ row: Int, _ col: Int) -> Bool {
        for i in 0..<9 {
            if board[row * 9 + i] == num { return false }
            if board[i * 9 + col] == num { return false }
            let r = (row / 3) * 3 + i / 3
            let c = (col / 3) * 3 + i % 3
            if board[r * 9 + c] == num { return false }
        }
        return true
    }
    
    static func digHoles(solvedBoard: [Int], targetClues: Int) -> [Int] {
        var puzzle = solvedBoard
        var indices = Array(0..<81).shuffled()
        var holesToDig = 81 - targetClues
        for idx in indices {
            if holesToDig <= 0 { break }
            let backup = puzzle[idx]
            puzzle[idx] = 0
            if countSolutions(board: puzzle, limit: 2) == 1 {
                holesToDig -= 1
            } else {
                puzzle[idx] = backup
            }
        }
        return puzzle
    }
    
    static func countSolutions(board: [Int], limit: Int) -> Int {
        var copy = board
        var count = 0
        _solveCount(&copy, count: &count, limit: limit)
        return count
    }
    
    static func _solveCount(_ board: inout [Int], count: inout Int, limit: Int) {
        if count >= limit { return }
        guard let index = board.firstIndex(of: 0) else { count += 1; return }
        for num in 1...9 {
            if isValid(board, num, index / 9, index % 9) {
                board[index] = num
                _solveCount(&board, count: &count, limit: limit)
                board[index] = 0
            }
        }
    }
}

// MARK: - UI Views

struct ContentView: View {
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some View {
        NavigationStack {
            LandingView()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            GameCenterManager.shared.authenticateUser()
        }
    }
}

struct LandingView: View {
    @State private var cursorOpacity = 1.0
    @State private var glowStrength = 1.0
    @ObservedObject var gcManager = GameCenterManager.shared
    
    var body: some View {
        ZStack {
            TerminalBackground()
            
            VStack {
                HStack {
                    if gcManager.isAuthenticated {
                        if let photo = gcManager.playerPhoto {
                            photo.resizable().scaledToFit().frame(width: 30, height: 30).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill").font(.system(size: 30)).foregroundColor(.green)
                        }
                        Text("user: \(gcManager.playerName)").font(.system(size: 14, design: .monospaced)).foregroundColor(.green)
                    } else {
                        Image(systemName: "person.circle").font(.system(size: 30)).foregroundColor(.gray)
                        Text("user: guest").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: UserProfileView()) {
                        HStack { Text("WHOAMI"); Image(systemName: "person.text.rectangle") }
                            .font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            .padding(8).background(Color.green.opacity(0.1)).cornerRadius(8)
                    }
                }
                .padding(.top, 50).padding(.horizontal)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("root@ios:~$ ").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        Text("sudo sodoku").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
                    }
                    .padding(.bottom, 20)
                    
                    Text("sudo sodoku")
                        .font(.system(size: 54, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(glowStrength), radius: 15)
                        .shadow(color: .green.opacity(glowStrength * 0.6), radius: 40)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                glowStrength = 0.4
                            }
                        }
                    
                    Text("KERNEL_V0.5.0").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray).padding(.top, 5)
                }
                Spacer()
                
                NavigationLink(destination: ModeSelectionView()) {
                    HStack(spacing: 0) {
                        Text("./execute").font(.system(size: 24, weight: .bold, design: .monospaced))
                        Text("_").font(.system(size: 24, weight: .bold, design: .monospaced)).opacity(cursorOpacity)
                            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { cursorOpacity = 0.0 } }
                    }
                    .foregroundColor(.green).padding(.horizontal, 40).padding(.vertical, 20)
                    .background(Color.green.opacity(0.1)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
                }
                
                NavigationLink(destination: ArchiveView()) {
                    HStack { Image(systemName: "archivebox"); Text("cd /archives") }
                        .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray).padding()
                }
                Spacer()
            }
        }
    }
}

// 简单的矩阵雨特效 Overlay
struct MatrixVictoryOverlay: View {
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var matrixChars: [String] = []
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ<>?[]{}"
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack {
                ForEach(0..<10, id: \.self) { _ in
                    HStack {
                        ForEach(0..<15, id: \.self) { _ in
                            Text(String(characters.randomElement()!))
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color.green.opacity(Double.random(in: 0.2...0.8)))
                        }
                    }
                }
            }
            .opacity(0.3)
            
            VStack(spacing: 20) {
                Text("ACCESS GRANTED")
                    .font(.system(size: 40, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 20)
                    .scaleEffect(scale)
                
                Text("SYSTEM COMPROMISED")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 1.0; scale = 1.1 }
            withAnimation(.easeInOut(duration: 0.1).repeatForever()) { scale = 1.0 }
        }
    }
}

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
                            Button(action: {
                                game.toggleFavorite()
                            }) {
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
                        
                        Button(action: {
                            game.toggleArchived()
                        }) {
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
                        
                        // [修改点] 将原来的 Refresh 按钮替换为 Menu
                        Menu {
                            Button(role: .destructive, action: {
                                game.replayCurrentGame()
                            }) {
                                Label("RETRY (Clear)", systemImage: "eraser")
                            }
                            
                            Button(action: {
                                handleExitRequest(.refresh)
                            }) {
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
                game.markAsArchived() // 显式标记
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

// UserProfileView
struct UserProfileView: View {
    @ObservedObject var storage = StorageManager.shared
    var ratingInfo: (title: String, color: Color) { RatingManager.shared.getRankTitle(rating: storage.userRating) }
    var totalGames: Int { storage.records.count }
    var solvedGames: Int { storage.records.filter { $0.isSolved }.count }
    var totalDigitsFilled: Int {
        storage.records.reduce(0) { res, rec in
            res + rec.playerBoard.enumerated().filter { $0.element != 0 && rec.initialBoard[$0.offset] == 0 }.count
        }
    }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        ZStack {
                            Circle().stroke(ratingInfo.color, lineWidth: 4).frame(width: 120, height: 120).shadow(color: ratingInfo.color.opacity(0.5), radius: 10)
                            if let photo = GameCenterManager.shared.playerPhoto { photo.resizable().scaledToFit().clipShape(Circle()).frame(width: 100, height: 100) }
                            else { Image(systemName: "person.fill").font(.system(size: 50)).foregroundColor(ratingInfo.color) }
                        }
                        VStack(spacing: 5) {
                            Text(ratingInfo.title).font(.system(size: 24, weight: .heavy, design: .monospaced)).foregroundColor(ratingInfo.color)
                            Text("ELO RATING: \(storage.userRating)").font(.system(size: 16, design: .monospaced)).foregroundColor(.white)
                        }
                    }.padding(.top, 40)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatCard(title: "GAMES PLAYED", value: "\(totalGames)", icon: "gamecontroller")
                        StatCard(title: "PUZZLES SOLVED", value: "\(solvedGames)", icon: "checkmark.seal")
                        StatCard(title: "DIGITS FILLED", value: "\(totalDigitsFilled)", icon: "number.square.fill")
                        StatCard(title: "HIGHEST ELO", value: "\(storage.userRating)", icon: "chart.line.uptrend.xyaxis")
                    }.padding(.horizontal)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("SYSTEM_RANK_TABLE:").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        RankRow(range: "0-1199", title: "SCRIPT_KIDDIE", color: .gray)
                        RankRow(range: "1200-1399", title: "USER", color: .green)
                        RankRow(range: "1400-1599", title: "SUDOER", color: .cyan)
                        RankRow(range: "1600-1799", title: "SYS_ADMIN", color: .blue)
                        RankRow(range: "1800-1999", title: "KERNEL_HACKER", color: .purple)
                        RankRow(range: "2000+", title: "THE_ARCHITECT", color: .orange)
                    }.padding().background(Color.white.opacity(0.05)).cornerRadius(12).padding(.horizontal)
                    Spacer()
                }
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).foregroundColor(.green); Spacer() }
            Text(value).font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundColor(.white)
            Text(title).font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct RankRow: View {
    let range: String; let title: String; let color: Color
    var body: some View { HStack { Text(range).font(.system(size: 12, design: .monospaced)).foregroundColor(.gray).frame(width: 80, alignment: .leading); Text(title).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(color); Spacer() } }
}

struct ArchiveView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedRecordForAction: GameRecord?
    @State private var showActionSheet = false
    @State private var navigateToGame = false
    @State private var gameToLoad: GameRecord?
    @State private var filterMode: FilterMode = .all
    @State private var isEditMode: Bool = false
    @State private var selectedIds: Set<UUID> = []
    
    enum FilterMode { case all; case favorites }
    var filteredRecords: [GameRecord] { filterMode == .all ? storage.records : storage.records.filter { $0.isFavorite } }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading) {
                HStack {
                    Text(filterMode == .favorites ? "FAVORITES:" : "USER_LOGS:")
                        .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                    Spacer()
                    if isEditMode {
                        Button(action: { isEditMode = false; selectedIds.removeAll() }) { Text("DONE").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.green) }
                    }
                }.padding(.leading).padding(.trailing).padding(.top)
                
                if filteredRecords.isEmpty {
                    Spacer(); Text("NO_RECORDS_FOUND").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.5)).frame(maxWidth: .infinity); Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            HStack {
                                if isEditMode {
                                    Image(systemName: selectedIds.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedIds.contains(record.id) ? .green : .gray)
                                        .onTapGesture { if selectedIds.contains(record.id) { selectedIds.remove(record.id) } else { selectedIds.insert(record.id) } }
                                }
                                Button(action: {
                                    if isEditMode { if selectedIds.contains(record.id) { selectedIds.remove(record.id) } else { selectedIds.insert(record.id) } }
                                    else { handleRecordTap(record) }
                                }) { RecordRow(record: record) }
                            }
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain).refreshable { storage.loadData() }
                }
                
                if isEditMode {
                    HStack {
                        Button(action: { storage.batchDelete(ids: selectedIds); isEditMode = false; selectedIds.removeAll() }) {
                            VStack { Image(systemName: "trash"); Text("DELETE") }.foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: { storage.batchFavorite(ids: selectedIds); isEditMode = false; selectedIds.removeAll() }) {
                            VStack { Image(systemName: "star.fill"); Text("FAVORITE") }.foregroundColor(.yellow)
                        }
                    }.padding().background(Color.white.opacity(0.1))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { filterMode = .all }) { Label("Show All Logs", systemImage: "list.bullet") }
                        Button(action: { filterMode = .favorites }) { Label("Show Favorites", systemImage: "star.fill") }
                        Divider()
                        Button(action: { isEditMode.toggle() }) { Label("Batch Edit", systemImage: "checkmark.circle") }
                    } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)).foregroundColor(.green) }
                }
            }
            .navigationDestination(isPresented: $navigateToGame) { if let rec = gameToLoad { GameView(record: rec) } }
            .confirmationDialog("COMPLETED_TASK", isPresented: $showActionSheet) {
                Button("RESTART (sudo reboot)") { if var rec = selectedRecordForAction { rec.isSolved = false; gameToLoad = rec; navigateToGame = true } }
                Button("SHOW ANSWER (cat solution)") { if let rec = selectedRecordForAction { gameToLoad = rec; navigateToGame = true } }
                Button("CANCEL", role: .cancel) { }
            }
        }.navigationBarTitleDisplayMode(.inline).onAppear { storage.loadData() }
    }
    func handleRecordTap(_ record: GameRecord) {
        selectedRecordForAction = record
        if record.isSolved { showActionSheet = true } else { gameToLoad = record; navigateToGame = true }
    }
}

struct RecordRow: View {
    let record: GameRecord
    var dateFormatter: DateFormatter { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"; return f }
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if record.isFavorite { Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.yellow) }
                    Text(dateFormatter.string(from: record.lastPlayedTime)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
                }
                HStack {
                    Text(record.difficulty).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Difficulty(rawValue: record.difficulty)?.color ?? .gray)
                    if record.isSolved {
                        Text("[COMPLETED]").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        if let gain = record.ratingChange { Text("+\(gain) RP").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.yellow) }
                    } else {
                        Text("[IN_PROGRESS]").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    }
                }
            }
            Spacer()
            Text("\(record.progress)%").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(record.isSolved ? .green : .cyan).padding(.trailing, 10)
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(record.isSolved ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)).padding(.vertical, 4)
    }
}

struct ModeSelectionView: View {
    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading, spacing: 30) {
                Text("SELECT DIFFICULTY FLAGS:").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray).padding(.leading)
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            NavigationLink(destination: GameView(difficulty: diff)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("--\(diff.rawValue.lowercased())").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(diff.color)
                                        Text("DIFFICULTY_INDEX: \(diff.scoreRange.lowerBound)-\(diff.scoreRange.upperBound)").font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    Spacer(); Image(systemName: "chevron.right").foregroundColor(diff.color)
                                }
                                .padding().background(Color.black.opacity(0.5)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(diff.color.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}

struct TerminalBackground: View { var body: some View { Color(red: 0.05, green: 0.07, blue: 0.10).ignoresSafeArea() } }

struct BoardView: View {
    @ObservedObject var game: SudokuGame
    var body: some View {
        GeometryReader { geometry in
            if game.board.count < 81 { Color.clear } else {
                let width = geometry.size.width; let cellSize = width / 9
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: 0), count: 9), spacing: 0) {
                    ForEach(0..<81) { index in
                        // [关键修复] 将选中逻辑以 Closure 形式传给 CellView，避免手势冲突
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
                }.overlay(GridLinesOverlay(width: width)).border(Color.gray, width: 2)
            }
        }.aspectRatio(1, contentMode: .fit)
    }
    func isRelated(index: Int) -> Bool {
        guard let s = game.selectedCellIndex, s < game.board.count && index < game.board.count else { return false }
        let sc = game.board[s]; let cc = game.board[index]
        return cc.row == sc.row || cc.col == sc.col || (cc.row / 3 == sc.row / 3 && cc.col / 3 == sc.col / 3)
    }
    func getHighlightNumber() -> Int? { guard let idx = game.selectedCellIndex, idx < game.board.count, let val = game.board[idx].value else { return nil }; return val }
}

struct CellView: View {
    let cell: SudokuCell; let cellSize: CGFloat; let isSelected: Bool; let isRelated: Bool; let highlightNumber: Int?
    // [修复] 接收外部点击回调
    var onTap: () -> Void
    
    @State private var animateTrigger = false
    var body: some View {
        ZStack {
            Rectangle().fill(bg).border(Color.white.opacity(0.1), width: 0.5)
            if isSelected { Rectangle().stroke(Color.green, lineWidth: 2).zIndex(10) }
            
            // [新增] 笔记显示层：如果没有填数且有笔记，显示小网格
            if cell.value == nil && !cell.notes.isEmpty {
                NoteGridView(notes: cell.notes, size: cellSize)
            }
            
            if let val = cell.value { Text("\(val)").font(.system(size: cellSize * 0.6, weight: cell.isGiven ? .bold : .regular, design: .monospaced)).foregroundColor(txt) }
        }
        .frame(width: cellSize, height: cellSize).contentShape(Rectangle())
        .scaleEffect(animateTrigger ? 0.92 : 1.0)
        .onTapGesture {
            // [修复] 同时执行：1. 震动 2. 动画 3. 业务逻辑(选中)
            HapticManager.shared.lightImpact()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = true }
            onTap() // 执行传入的选中逻辑
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { animateTrigger = false } }
        }
    }
    var bg: Color { if isSelected { return Color.green.opacity(0.2) }; if let v = cell.value, v == highlightNumber { return Color.green.opacity(0.4) }; if isRelated { return Color.white.opacity(0.05) }; return Color.clear }
    var txt: Color { if cell.isGiven { return .white }; if cell.isError { return .red }; return .green }
}

// [新增] 笔记网格视图
struct NoteGridView: View {
    let notes: Set<Int>
    let size: CGFloat
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(size / 3), spacing: 0), count: 3), spacing: 0) {
            ForEach(1...9, id: \.self) { num in
                Text(notes.contains(num) ? "\(num)" : "")
                    .font(.system(size: size * 0.25, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6)) // 暗一点的绿色
                    .frame(height: size / 3)
            }
        }
    }
}

struct GridLinesOverlay: View {
    let width: CGFloat
    var body: some View {
        ZStack {
            HStack(spacing: 0) { Spacer(); Rectangle().frame(width: 2).foregroundColor(.white); Spacer(); Rectangle().frame(width: 2).foregroundColor(.white); Spacer() }
            VStack(spacing: 0) { Spacer(); Rectangle().frame(height: 2).foregroundColor(.white); Spacer(); Rectangle().frame(height: 2).foregroundColor(.white); Spacer() }
        }.allowsHitTesting(false)
    }
}

struct ControlPanelView: View {
    @ObservedObject var game: SudokuGame
    var body: some View {
        VStack(spacing: 20) { // Increased spacing for better visual separation
            // 1. Undo / Redo Row (Moved Up)
            HStack {
                Spacer()
                
                // Undo
                Button(action: {
                    game.undoLastMove()
                }) {
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
                
                // Redo
                Button(action: {
                    game.redoLastMove()
                }) {
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
                // Pencil (Left)
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
                
                // Del (Right)
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
                        Text("\(num)").font(.system(size: 24, weight: .bold, design: .monospaced)).frame(maxWidth: .infinity).frame(height: 55).background(Color.white.opacity(0.1)).foregroundColor(.white).cornerRadius(12)
                    }.buttonStyle(BouncyButtonStyle())
                }
            }.padding(.horizontal)
        }
    }
}
