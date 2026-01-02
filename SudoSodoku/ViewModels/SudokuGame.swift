import SwiftUI
import Combine

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

