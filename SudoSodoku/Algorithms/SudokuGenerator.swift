import Foundation

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


