import XCTest
@testable import SudoSodoku

final class LeaderboardConstantsTests: XCTestCase {

    func testLeaderboardIDsMatchAppStoreConnectConfiguration() {
        XCTAssertEqual(AppConstants.eloLeaderboardID, "dev.kaichen.sudoku.app.leaderboard.elo")
        XCTAssertEqual(AppConstants.leaderboardID(for: "EASY"), "dev.kaichen.sudoku.app.leaderboard.easy")
        XCTAssertEqual(AppConstants.leaderboardID(for: "MASTER"), "dev.kaichen.sudoku.app.leaderboard.master")
        XCTAssertEqual(
            AppConstants.leaderboardID(for: "unknown"),
            AppConstants.leaderboardPrefix,
            "Unknown difficulties must fall back to the bare prefix"
        )
    }

    func testTimeLeaderboardValueIsWholeSecondsAndGuarded() {
        XCTAssertEqual(AppConstants.timeLeaderboardValue(for: 0), 0, "Zero duration must be rejected by callers")
        XCTAssertEqual(AppConstants.timeLeaderboardValue(for: -5), 0, "Negative durations must map to the rejected value")
        XCTAssertEqual(AppConstants.timeLeaderboardValue(for: 0.4), 1, "Sub-second solves round up to one second, never zero")
        XCTAssertEqual(AppConstants.timeLeaderboardValue(for: 59.6), 60)
        XCTAssertEqual(AppConstants.timeLeaderboardValue(for: 754.4), 754)
    }
}
