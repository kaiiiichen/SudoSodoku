import Foundation

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


