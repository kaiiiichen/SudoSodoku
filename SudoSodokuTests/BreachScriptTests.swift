import XCTest
@testable import SudoSodoku

final class BreachScriptTests: XCTestCase {

    func testIntroLinesTargetTheRequestedDifficulty() {
        let lines = BreachScript.introLines(difficulty: .master)
        XCTAssertEqual(lines.first, "$ sudo breach --target=grid_9x9 --master")
        XCTAssertTrue(lines.dropFirst().allSatisfy { $0.hasSuffix(" OK") },
                      "Every intro step must report OK")
    }

    func testFinalLinesReportVerdictAndRealScore() {
        let lines = BreachScript.finalLines(score: 82, difficulty: .master)
        XCTAssertTrue(lines[0].hasSuffix(" PASS"))
        XCTAssertEqual(lines[1], "> difficulty_index: 82 [MASTER]")
    }

    func testDotLeaderPaddingAlignsStatusColumn() {
        let short = BreachScript.padded("> a", status: "OK")
        let long = BreachScript.padded("> generating entropy", status: "OK")
        // Same visual column: text + dots always spans lineWidth characters.
        XCTAssertEqual(short.count - " OK".count, BreachScript.lineWidth)
        XCTAssertEqual(long.count - " OK".count, BreachScript.lineWidth)
        XCTAssertTrue(BreachScript.padded(String(repeating: "x", count: 40), status: "OK").contains(".."),
                      "Overlong lines still keep a minimum dot leader")
    }
}
