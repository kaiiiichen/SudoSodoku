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


