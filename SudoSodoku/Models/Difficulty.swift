import SwiftUI

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

