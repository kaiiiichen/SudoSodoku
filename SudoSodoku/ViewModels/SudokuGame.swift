import Combine
import SwiftUI

class SudokuGame: ObservableObject {
    @Published var board: [SudokuCell] = []
    @Published var selectedCellIndex: Int?
    @Published var difficulty: Difficulty = .easy
    @Published var isSolved: Bool = false
    @Published var currentScore: Int = 0
    @Published var isGenerating: Bool = true
    @Published var ratingGained: Int?

    @Published var isNoteMode: Bool = false
    @Published var isArchived: Bool = false
    @Published var isFavorite: Bool = false
    @Published var undoStack: [MoveHistory] = []
    @Published var redoStack: [MoveHistory] = []

    // Per-cell shake counters; a cell shakes each time its counter increments.
    // Monotonically increasing on purpose: resetting to zero would itself be a
    // change and replay stale shakes on fresh boards.
    @Published private(set) var conflictShakes: [Int: Int] = [:]

    var onSolved: (() -> Void)?
    var currentRecordID: UUID?

    private var currentUndoCount: Int = 0
    private var sessionStartTime: Date?

    // MARK: - Play clock
    // Accumulated active play time; the running segment is open while
    // activeSegmentStart is non-nil (paused in background / after solving).
    private var accumulatedPlayTime: TimeInterval = 0
    private var activeSegmentStart: Date?

    func playDuration(at date: Date = Date()) -> TimeInterval {
        guard let start = activeSegmentStart else { return accumulatedPlayTime }
        return accumulatedPlayTime + max(0, date.timeIntervalSince(start))
    }

    func pauseClock(at date: Date = Date()) {
        guard let start = activeSegmentStart else { return }
        accumulatedPlayTime += max(0, date.timeIntervalSince(start))
        activeSegmentStart = nil
    }

    func resumeClock(at date: Date = Date()) {
        guard !isSolved, !isGenerating, activeSegmentStart == nil else { return }
        activeSegmentStart = date
    }

    private func resetClock(to accumulated: TimeInterval, running: Bool, at date: Date = Date()) {
        accumulatedPlayTime = accumulated
        activeSegmentStart = running ? date : nil
    }

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
        self.currentUndoCount = 0
        self.sessionStartTime = Date()

        DispatchQueue.global(qos: .userInitiated).async {
            let (puzzle, solution, score) = SudokuGenerator.generatePuzzle(targetDifficulty: difficulty)
            let newRecordID = UUID()

            DispatchQueue.main.async {
                self.currentScore = score
                self.currentRecordID = newRecordID
                self.board = (0..<81).map { index in
                    let value = puzzle[index]
                    let solutionValue = solution[index]
                    return SudokuCell(
                        row: index / 9,
                        col: index % 9,
                        value: value == 0 ? nil : value,
                        solutionValue: solutionValue,
                        isGiven: value != 0
                    )
                }
                self.isGenerating = false
                self.resetClock(to: 0, running: true)
                self.saveCurrentState()
            }
        }
    }

    func loadFromRecord(_ record: GameRecord) {
        isGenerating = true
        currentRecordID = record.id
        sessionStartTime = record.startTime
        difficulty = Difficulty(rawValue: record.difficulty) ?? .easy
        isSolved = record.isSolved
        currentScore = record.difficultyIndex
        ratingGained = record.ratingChange
        isArchived = record.isArchived
        isFavorite = record.isFavorite
        isNoteMode = false
        undoStack = []
        redoStack = []
        currentUndoCount = record.undoCount

        board = (0..<81).map { index in
            let initialValue = record.initialBoard[index]
            let playerValue = record.playerBoard[index]
            let solutionValue = record.solution[index]
            let displayValue = initialValue != 0 ? initialValue : (playerValue != 0 ? playerValue : nil)
            let notes = Set(record.playerNotes?[index] ?? [])

            return SudokuCell(
                row: index / 9,
                col: index % 9,
                value: displayValue,
                solutionValue: solutionValue,
                isGiven: initialValue != 0,
                notes: notes
            )
        }

        updateBoardErrors()
        isGenerating = false
        resetClock(to: record.playDuration, running: !record.isSolved)
    }

    func selectCell(at index: Int) {
        selectedCellIndex = index
    }

    func inputNumber(_ number: Int) {
        guard let index = selectedCellIndex, !board[index].isGiven else { return }

        let oldCell = board[index]
        var peerChanges: [CellChange] = []

        if isNoteMode {
            if board[index].notes.contains(number) {
                board[index].notes.remove(number)
            } else {
                board[index].notes.insert(number)
            }
            HapticManager.shared.noteToggled()
        } else {
            if board[index].value == number {
                board[index].value = nil
                updateBoardErrors()
                HapticManager.shared.digitRemoved()
            } else {
                board[index].value = number
                board[index].notes = []
                peerChanges = clearPeerNotes(of: number, around: index)
                updateBoardErrors()
                if board[index].isError {
                    conflictShakes[index, default: 0] += 1
                    HapticManager.shared.conflictDetected()
                } else {
                    HapticManager.shared.digitPlaced()
                }
            }
            checkVictory()
        }

        let newCell = board[index]
        var changes = peerChanges
        if oldCell != newCell {
            changes.insert(CellChange(index: index, oldCell: oldCell, newCell: newCell), at: 0)
        }
        if !changes.isEmpty {
            undoStack.append(MoveHistory(changes: changes))
            redoStack.removeAll()
        }

        saveCurrentState()
    }

    /// Placing a number removes it from the pencil notes of every peer
    /// (same row, column, or box). Returns the changes for undo history.
    private func clearPeerNotes(of number: Int, around index: Int) -> [CellChange] {
        var changes: [CellChange] = []
        for peer in peerIndices(of: index)
        where board[peer].value == nil && board[peer].notes.contains(number) {
            let oldCell = board[peer]
            board[peer].notes.remove(number)
            changes.append(CellChange(index: peer, oldCell: oldCell, newCell: board[peer]))
        }
        return changes
    }

    private func peerIndices(of index: Int) -> [Int] {
        let row = index / 9
        let col = index % 9
        var peers = Set<Int>()
        for i in 0..<9 {
            peers.insert(row * 9 + i)
            peers.insert(i * 9 + col)
            let boxIndex = ((row / 3) * 3 + i / 3) * 9 + (col / 3) * 3 + i % 3
            peers.insert(boxIndex)
        }
        peers.remove(index)
        return Array(peers)
    }

    // MARK: - Digit availability

    func placedCount(of number: Int) -> Int {
        board.filter { $0.value == number }.count
    }

    /// A digit is exhausted once all nine instances are on the board.
    /// Derived from board state, so undo/clear revives the numpad key.
    func isExhausted(_ number: Int) -> Bool {
        placedCount(of: number) >= 9
    }

    func undoLastMove() {
        guard let lastMove = undoStack.popLast() else { return }
        redoStack.append(lastMove)
        for change in lastMove.changes {
            board[change.index] = change.oldCell
        }
        updateBoardErrors()
        currentUndoCount += 1
        saveCurrentState()
        HapticManager.shared.moveReverted()
    }

    func redoLastMove() {
        guard let nextMove = redoStack.popLast() else { return }
        undoStack.append(nextMove)
        for change in nextMove.changes {
            board[change.index] = change.newCell
        }
        updateBoardErrors()
        saveCurrentState()
        HapticManager.shared.moveReverted()
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
            HapticManager.shared.digitRemoved()
        }

        updateBoardErrors()
        saveCurrentState()
    }

    func toggleFavorite() {
        guard let id = currentRecordID else { return }
        StorageManager.shared.toggleFavorite(for: id)
        syncRecordFlags(from: id)
    }

    func toggleArchived() {
        guard let id = currentRecordID else { return }
        StorageManager.shared.setArchived(for: id, isArchived: !isArchived)
        syncRecordFlags(from: id)
    }

    func markAsArchived() {
        isArchived = true
        saveCurrentState()
    }

    func saveCurrentState() {
        guard let recordID = currentRecordID else { return }

        let record = GameRecord(
            id: recordID,
            startTime: sessionStartTime ?? Date(),
            lastPlayedTime: Date(),
            difficulty: difficulty.rawValue,
            difficultyIndex: currentScore,
            initialBoard: board.map { $0.isGiven ? ($0.value ?? 0) : 0 },
            solution: board.map { $0.solutionValue ?? 0 },
            playerBoard: board.map { $0.isGiven ? 0 : ($0.value ?? 0) },
            playerNotes: board.map { Array($0.notes) },
            isSolved: isSolved,
            ratingChange: ratingGained,
            isArchived: isArchived,
            isFavorite: isFavorite,
            undoCount: currentUndoCount,
            playDuration: playDuration()
        )
        StorageManager.shared.saveGame(record)
    }

    func replayCurrentGame() {
        guard currentRecordID != nil else { return }

        for index in board.indices where !board[index].isGiven {
            board[index].value = nil
            board[index].notes = []
            board[index].isError = false
        }

        isSolved = false
        ratingGained = nil
        undoStack = []
        redoStack = []
        currentUndoCount = 0
        sessionStartTime = Date()
        resetClock(to: 0, running: true)
        saveCurrentState()
    }

    func showSolution() {
        for index in board.indices {
            board[index].value = board[index].solutionValue
            board[index].notes = []
            board[index].isError = false
        }
        isSolved = true
        pauseClock()
        saveCurrentState()
    }

    private func syncRecordFlags(from id: UUID) {
        guard let record = StorageManager.shared.records.first(where: { $0.id == id }) else { return }
        isFavorite = record.isFavorite
        isArchived = record.isArchived
    }

    private func isConflict(at index: Int, value: Int) -> Bool {
        let row = index / 9
        let col = index % 9

        for column in 0..<9 {
            let otherIndex = row * 9 + column
            if otherIndex != index, board[otherIndex].value == value { return true }
        }

        for rowIndex in 0..<9 {
            let otherIndex = rowIndex * 9 + col
            if otherIndex != index, board[otherIndex].value == value { return true }
        }

        let startRow = (row / 3) * 3
        let startCol = (col / 3) * 3
        for rowOffset in 0..<3 {
            for columnOffset in 0..<3 {
                let otherIndex = (startRow + rowOffset) * 9 + (startCol + columnOffset)
                if otherIndex != index, board[otherIndex].value == value { return true }
            }
        }

        return false
    }

    private func updateBoardErrors() {
        for index in board.indices {
            guard let value = board[index].value else {
                board[index].isError = false
                continue
            }
            board[index].isError = isConflict(at: index, value: value)
        }
    }

    private func checkVictory() {
        let isFull = !board.contains { $0.value == nil }
        let hasError = board.contains { $0.isError }

        guard isFull, !hasError, !isSolved else { return }

        isSolved = true
        pauseClock()
        HapticManager.shared.victory()

        let currentElo = StorageManager.shared.userRating
        let gained = RatingManager.shared.calculateRatingChange(
            playerRating: currentElo,
            puzzleDifficultyIndex: currentScore
        )
        ratingGained = gained

        if gained > 0 {
            StorageManager.shared.updateUserRating(add: gained)
            GameCenterManager.shared.submitRating(StorageManager.shared.userRating)
        }

        // Clock is already frozen, so this is the final solve time.
        GameCenterManager.shared.submitCompletionTime(playDuration(), difficulty: difficulty.rawValue)
        saveCurrentState()
        onSolved?()
    }
}
