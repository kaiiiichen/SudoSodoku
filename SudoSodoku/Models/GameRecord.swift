import Foundation

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
    
    // Logical quality metrics
    var undoCount: Int = 0                  // Number of undos
    
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
    
    // Calculate logical efficiency score (based on undo count)
    var logicalEfficiency: Int {
        let baseScore = 1000
        let undoPenalty = undoCount * 10        // 10 points deducted per undo
        
        return max(0, baseScore - undoPenalty)
    }
    
    // Logical quality level
    var logicalQuality: String {
        switch logicalEfficiency {
        case 950...: return "PERFECT"
        case 850..<950: return "EXCELLENT"
        case 700..<850: return "GOOD"
        case 500..<700: return "FAIR"
        default: return "NEEDS_IMPROVEMENT"
        }
    }

    func restartedCopy() -> GameRecord {
        var restarted = self
        restarted.lastPlayedTime = Date()
        restarted.playerBoard = Array(repeating: 0, count: 81)
        restarted.playerNotes = Array(repeating: [], count: 81)
        restarted.isSolved = false
        restarted.ratingChange = nil
        restarted.undoCount = 0
        return restarted
    }
}

