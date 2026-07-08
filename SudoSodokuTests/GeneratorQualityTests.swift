import XCTest
@testable import SudoSodoku

final class GeneratorQualityTests: XCTestCase {

    // MARK: - Hidden singles beyond rows (regression for the row-only scan)

    func testHiddenSingleDetectedInColumn() {
        // Column 0 holds every digit except 5, so (0,0) is a hidden single
        // for 5 in that column. Row 0 has many possible homes for 5, so the
        // old row-only scan returned nil here and graded the board "stuck".
        var board = Array(repeating: 0, count: 81)
        let columnValues = [1, 2, 3, 4, 6, 7, 8, 9]
        for (offset, value) in columnValues.enumerated() {
            board[(offset + 1) * 9] = value
        }

        let move = SudokuGenerator.findHiddenSingle(board: board)
        XCTAssertEqual(move?.index, 0)
        XCTAssertEqual(move?.value, 5)
    }

    // MARK: - EASY quality gate

    func testEasyBoardIsSinglesSolvableWithBreadthAndSpreadClues() {
        let (puzzle, _, _) = SudokuGenerator.generatePuzzle(targetDifficulty: .easy)

        let analysis = SudokuGenerator.solveWithSingles(puzzle: puzzle)
        XCTAssertTrue(analysis.solved, "EASY must be finishable with singles alone")
        XCTAssertGreaterThanOrEqual(analysis.minChoices, 2,
                                    "EASY must never funnel the player into a single forced move")

        assertFloors(puzzle, box: 3, row: 2, column: 2, label: "EASY")
    }

    func testMediumBoardRespectsClueFloors() {
        let (puzzle, _, _) = SudokuGenerator.generatePuzzle(targetDifficulty: .medium)
        assertFloors(puzzle, box: 2, row: 1, column: 1, label: "MEDIUM")
    }

    // MARK: - Handcrafted qualities (aesthetic styles + technique identity)

    func testDigHolesHonorsEachSymmetryStyle() {
        let solved = SudokuGenerator.generateSolvedBoard()
        let noFloors = SudokuGenerator.ClueFloors(box: 0, row: 0, column: 0)

        for style in SudokuGenerator.SymmetryStyle.allCases where style != .free {
            let puzzle = SudokuGenerator.digHoles(
                solvedBoard: solved, targetClues: 32, floors: noFloors, symmetry: style
            )
            for index in 0..<81 {
                XCTAssertEqual(
                    puzzle[index] == 0, puzzle[style.partner(of: index)] == 0,
                    "\(style): hole pattern must mirror its own style at \(index)"
                )
            }
        }
    }

    func testSymmetryOrbitsAreInvolutions() {
        // Every style must pair cells symmetrically: partner(partner(i)) == i.
        for style in SudokuGenerator.SymmetryStyle.allCases {
            for index in 0..<81 {
                XCTAssertEqual(style.partner(of: style.partner(of: index)), index,
                               "\(style) is not an involution at \(index)")
            }
        }
    }

    func testHardIsDesignedAroundAnIntermediateAha() {
        let (puzzle, _, _) = SudokuGenerator.generatePuzzle(targetDifficulty: .hard)
        XCTAssertEqual(SudokuGenerator.techniqueTier(puzzle: puzzle), .intermediate,
                       "HARD must require intermediate techniques but never more")
        XCTAssertFalse(SudokuGenerator.solveWithSingles(puzzle: puzzle).solved,
                       "HARD must not fall to singles alone")
    }

    func testMasterResistsIntermediateTechniques() {
        let (puzzle, _, _) = SudokuGenerator.generatePuzzle(targetDifficulty: .master)
        XCTAssertEqual(SudokuGenerator.techniqueTier(puzzle: puzzle), .advanced)
    }

    func testMediumNeverDemandsAdvancedTechniques() {
        let (puzzle, _, _) = SudokuGenerator.generatePuzzle(targetDifficulty: .medium)
        XCTAssertNotEqual(SudokuGenerator.techniqueTier(puzzle: puzzle), .advanced)
    }

    // MARK: - digHoles floor mechanics (no generation loop)

    func testDigHolesNeverDropsBelowFloors() {
        let solved = SudokuGenerator.generateSolvedBoard()
        // Aggressive target: floors must win over the clue budget.
        let puzzle = SudokuGenerator.digHoles(
            solvedBoard: solved,
            targetClues: 20,
            floors: SudokuGenerator.ClueFloors(box: 3, row: 2, column: 2),
            symmetry: .rotational
        )
        assertFloors(puzzle, box: 3, row: 2, column: 2, label: "digHoles")
        XCTAssertEqual(SudokuGenerator.countSolutions(board: puzzle, limit: 2), 1)
    }

    // MARK: - Helpers

    private func assertFloors(
        _ puzzle: [Int], box: Int, row: Int, column: Int, label: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        for unit in 0..<9 {
            let rowClues = (0..<9).filter { puzzle[unit * 9 + $0] != 0 }.count
            XCTAssertGreaterThanOrEqual(rowClues, row, "\(label): row \(unit) too sparse", file: file, line: line)

            let colClues = (0..<9).filter { puzzle[$0 * 9 + unit] != 0 }.count
            XCTAssertGreaterThanOrEqual(colClues, column, "\(label): column \(unit) too sparse", file: file, line: line)

            let origin = (unit / 3) * 27 + (unit % 3) * 3
            let boxClues = (0..<9).filter { puzzle[origin + ($0 / 3) * 9 + $0 % 3] != 0 }.count
            XCTAssertGreaterThanOrEqual(boxClues, box, "\(label): box \(unit) too sparse", file: file, line: line)
        }
    }
}
