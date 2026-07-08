import XCTest
@testable import SudoSodoku

/// Regression tests for the stats/storage desync: `@Published` emits on
/// willSet, and the old implementation read the records back through the
/// singleton — so the WHOAMI numbers always lagged storage by one mutation
/// (zeros on launch, stale after a wipe).
final class StatisticsSyncTests: XCTestCase {

    private let currentFileName = "save_data_v4.json"

    override func setUp() {
        super.setUp()
        StorageManager.shared.wipeAllData()
    }

    override func tearDown() {
        StorageManager.shared.wipeAllData()
        try? FileManager.default.removeItem(
            at: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(currentFileName)
        )
        super.tearDown()
    }

    func testStatsReflectASaveImmediately() {
        let before = StatisticsManager.shared.overallStats.totalGames
        XCTAssertEqual(before, 0)

        StorageManager.shared.saveGame(makeRecord(solved: true))

        let stats = StatisticsManager.shared.overallStats
        XCTAssertEqual(stats.totalGames, 1, "Stats must include the record in the same mutation, not lag by one")
        XCTAssertEqual(stats.solvedGames, 1)
    }

    func testStatsReflectAWipeImmediately() {
        StorageManager.shared.saveGame(makeRecord(solved: true))
        StorageManager.shared.saveGame(makeRecord(solved: false))
        XCTAssertEqual(StatisticsManager.shared.overallStats.totalGames, 2)

        StorageManager.shared.wipeAllData()

        XCTAssertEqual(StatisticsManager.shared.overallStats.totalGames, 0,
                       "The wipe must zero the WHOAMI numbers immediately")
        XCTAssertEqual(StatisticsManager.shared.overallStats.solvedGames, 0)
        XCTAssertTrue(StatisticsManager.shared.personalBests.isEmpty)
    }

    func testStatsReflectADeletionImmediately() {
        let record = makeRecord(solved: true)
        StorageManager.shared.saveGame(record)
        XCTAssertEqual(StatisticsManager.shared.overallStats.totalGames, 1)

        StorageManager.shared.deleteRecord(id: record.id)

        XCTAssertEqual(StatisticsManager.shared.overallStats.totalGames, 0)
    }

    func testPersonalBestsTrackTheEmittedRecords() {
        StorageManager.shared.saveGame(makeRecord(solved: true, undoCount: 10))
        let cleaner = makeRecord(solved: true, undoCount: 0)
        StorageManager.shared.saveGame(cleaner)

        XCTAssertEqual(StatisticsManager.shared.personalBests[.easy]?.id, cleaner.id,
                       "Personal best must be recomputed from the just-changed records")
    }

    // MARK: - Fixtures

    private func makeRecord(solved: Bool, undoCount: Int = 0) -> GameRecord {
        GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: Array(repeating: 0, count: 81),
            solution: Array(repeating: 1, count: 81),
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: nil,
            isSolved: solved,
            ratingChange: nil,
            undoCount: undoCount
        )
    }
}
