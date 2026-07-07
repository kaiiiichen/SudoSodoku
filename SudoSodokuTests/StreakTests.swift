import XCTest
@testable import SudoSodoku

final class StreakTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    func testValidPlacementsGrowTheStreak() {
        let game = makeGame()
        for (offset, index) in [0, 20, 40].enumerated() {
            game.selectCell(at: index)
            game.inputNumber(solutionValue(at: index))
            XCTAssertEqual(game.streak, offset + 1)
        }
    }

    func testConflictResetsSilently() {
        let game = makeGame(givens: [1: 2])
        game.selectCell(at: 20)
        game.inputNumber(solutionValue(at: 20))
        XCTAssertEqual(game.streak, 1)

        game.selectCell(at: 0)
        game.inputNumber(2) // duplicate of the given in row 0
        XCTAssertEqual(game.streak, 0)
    }

    func testRemovalsNotesAndUndoLeaveStreakUntouched() {
        let game = makeGame()
        game.selectCell(at: 0)
        game.inputNumber(solutionValue(at: 0))
        XCTAssertEqual(game.streak, 1)

        game.inputNumber(solutionValue(at: 0))   // toggle off
        XCTAssertEqual(game.streak, 1, "Removing a value is neutral")

        game.isNoteMode = true
        game.selectCell(at: 30)
        game.inputNumber(4)
        XCTAssertEqual(game.streak, 1, "Pencil notes are neutral")
        game.isNoteMode = false

        game.undoLastMove()
        XCTAssertEqual(game.streak, 1, "Undo is neutral - no punishment")
    }

    func testReplayResetsStreak() {
        let game = makeGame()
        game.selectCell(at: 0)
        game.inputNumber(solutionValue(at: 0))
        XCTAssertEqual(game.streak, 1)

        game.replayCurrentGame()
        XCTAssertEqual(game.streak, 0)
    }

    // MARK: - Fixtures

    private func solutionValue(at index: Int) -> Int {
        let row = index / 9
        let col = index % 9
        return (row * 3 + row / 3 + col) % 9 + 1
    }

    private func makeGame(givens: [Int: Int] = [:]) -> SudokuGame {
        var initial = Array(repeating: 0, count: 81)
        for (index, value) in givens { initial[index] = value }
        let solution = (0..<81).map { solutionValue(at: $0) }

        let record = GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: initial,
            solution: solution,
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: Array(repeating: [], count: 81),
            isSolved: false,
            ratingChange: nil
        )
        fixtureIDs.append(record.id)

        let game = SudokuGame()
        game.loadFromRecord(record)
        return game
    }
}
