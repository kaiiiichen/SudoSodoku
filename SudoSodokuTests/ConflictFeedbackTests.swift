import XCTest
@testable import SudoSodoku

final class ConflictFeedbackTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    func testConflictingPlacementIncrementsShakeCounter() {
        // Given 5 at index 1 (row 0); placing 5 at index 0 conflicts.
        let game = makeGame(givens: [1: 5])

        game.selectCell(at: 0)
        game.inputNumber(5)

        XCTAssertTrue(game.board[0].isError)
        XCTAssertEqual(game.conflictShakes[0], 1)
    }

    func testValidPlacementDoesNotShake() {
        let game = makeGame(givens: [1: 5])

        game.selectCell(at: 0)
        game.inputNumber(3)

        XCTAssertFalse(game.board[0].isError)
        XCTAssertNil(game.conflictShakes[0], "Valid placements must not register a shake")
    }

    func testRepeatedConflictShakesAgain() {
        let game = makeGame(givens: [1: 5])
        game.selectCell(at: 0)

        game.inputNumber(5)              // conflict #1
        game.inputNumber(5)              // toggle the value off
        XCTAssertEqual(game.conflictShakes[0], 1, "Removing the value must not shake")

        game.inputNumber(5)              // conflict #2
        XCTAssertEqual(game.conflictShakes[0], 2, "Each fresh conflict must shake again")
    }

    func testUndoDoesNotShake() {
        let game = makeGame(givens: [1: 5])
        game.selectCell(at: 0)
        game.inputNumber(5)
        XCTAssertEqual(game.conflictShakes[0], 1)

        game.undoLastMove()
        XCTAssertEqual(game.conflictShakes[0], 1, "Undo reverts the board silently")
    }

    // MARK: - Fixtures

    private func makeGame(givens: [Int: Int]) -> SudokuGame {
        var initial = Array(repeating: 0, count: 81)
        for (index, value) in givens { initial[index] = value }
        let solution = (0..<81).map { index -> Int in
            let row = index / 9
            let col = index % 9
            return (row * 3 + row / 3 + col) % 9 + 1
        }

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
