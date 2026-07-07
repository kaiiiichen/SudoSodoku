import XCTest
@testable import SudoSodoku

final class UnitPulseTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    func testCompletingARowPublishesItsNineCells() {
        // Row 0 solution values are 1...9; indices 1-8 given, place at 0.
        let game = makeGame(givens: Dictionary(uniqueKeysWithValues: (1...8).map { ($0, $0 + 1) }))

        game.selectCell(at: 0)
        game.inputNumber(1)

        XCTAssertEqual(game.completedUnitPulse?.cells, Set(0..<9))
    }

    func testCompletingRowAndColumnPublishesTheirUnion() {
        // Row 0 (indices 1-8) and column 0 (indices 9,18,...72) both one short
        // of complete; placing at index 0 finishes both at once.
        var givens = Dictionary(uniqueKeysWithValues: (1...8).map { ($0, $0 + 1) })
        for row in 1...8 {
            givens[row * 9] = solutionValue(at: row * 9)
        }
        let game = makeGame(givens: givens)

        game.selectCell(at: 0)
        game.inputNumber(1)

        let rowCells = Set(0..<9)
        let colCells = Set((0..<9).map { $0 * 9 })
        XCTAssertEqual(game.completedUnitPulse?.cells, rowCells.union(colCells))
    }

    func testConflictingFillDoesNotPulse() {
        // Row 0 has indices 1-8 filled; placing a duplicate 2 at index 0
        // fills the row but with a conflict.
        let game = makeGame(givens: Dictionary(uniqueKeysWithValues: (1...8).map { ($0, $0 + 1) }))

        game.selectCell(at: 0)
        game.inputNumber(2)

        XCTAssertTrue(game.board[0].isError)
        XCTAssertNil(game.completedUnitPulse, "Conflicted units must not celebrate")
    }

    func testIncompleteUnitDoesNotPulse() {
        let game = makeGame(givens: [1: 2, 2: 3])
        game.selectCell(at: 0)
        game.inputNumber(1)
        XCTAssertNil(game.completedUnitPulse)
    }

    func testWinningMoveSkipsThePulse() {
        // Full valid board minus index 0: the final move is victory's moment,
        // not a unit celebration.
        var givens: [Int: Int] = [:]
        for index in 1..<81 { givens[index] = solutionValue(at: index) }
        let game = makeGame(givens: givens)

        game.selectCell(at: 0)
        game.inputNumber(solutionValue(at: 0))

        XCTAssertTrue(game.isSolved)
        XCTAssertNil(game.completedUnitPulse, "Victory owns the final move")
    }

    // MARK: - Fixtures

    private func solutionValue(at index: Int) -> Int {
        let row = index / 9
        let col = index % 9
        return (row * 3 + row / 3 + col) % 9 + 1
    }

    private func makeGame(givens: [Int: Int]) -> SudokuGame {
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
