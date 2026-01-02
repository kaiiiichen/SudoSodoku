import SwiftUI

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


