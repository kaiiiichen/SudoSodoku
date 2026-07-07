import XCTest
@testable import SudoSodoku

final class AchievementManagerTests: XCTestCase {

    private var defaults: UserDefaults!
    private var manager: AchievementManager!
    private let suiteName = "AchievementManagerTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        manager = AchievementManager(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Pure evaluation

    func testFirstOrdinaryVictoryEarnsOnlyHelloWorld() {
        let earned = Achievement.satisfied(by: context(totalSolved: 1, undoCount: 3, duration: 400))
        XCTAssertEqual(earned, [.helloWorld])
    }

    func testPerformanceAchievements() {
        let earned = Achievement.satisfied(by: context(
            difficulty: .master, totalSolved: 12, undoCount: 0, duration: 150
        ))
        XCTAssertTrue(earned.contains(.rootPrivileges))
        XCTAssertTrue(earned.contains(.cleanCommit))
        XCTAssertTrue(earned.contains(.overclocked))
        XCTAssertTrue(earned.contains(.uptime10))
        XCTAssertFalse(earned.contains(.uptime50))
    }

    func testZeroDurationNeverCountsAsSpeedrun() {
        let earned = Achievement.satisfied(by: context(undoCount: 0, duration: 0))
        XCTAssertFalse(earned.contains(.overclocked), "Legacy records without a duration must not unlock OVERCLOCKED")
    }

    func testRatingThresholdsUnlockEveryTierPassed() {
        let earned = Achievement.satisfied(by: context(rating: 1650))
        XCTAssertTrue(earned.contains(.rankSudoer))
        XCTAssertTrue(earned.contains(.rankSysAdmin))
        XCTAssertFalse(earned.contains(.rankKernelHacker))
    }

    // MARK: - Manager state

    func testUnlockPersistsAndNeverRepeats() {
        manager.evaluateVictory(context(totalSolved: 1))
        XCTAssertTrue(manager.isUnlocked(.helloWorld))
        XCTAssertEqual(manager.justUnlocked, [.helloWorld])

        manager.evaluateVictory(context(totalSolved: 2))
        XCTAssertEqual(manager.justUnlocked, [.helloWorld],
                       "A repeat victory must not re-announce old unlocks")
        XCTAssertEqual(defaults.stringArray(forKey: "unlockedAchievements")?.count, 1)
    }

    func testIncidentReportedIsAOneShotEasterEgg() {
        manager.unlockIncidentReported()
        XCTAssertTrue(manager.isUnlocked(.incidentReported))
        XCTAssertEqual(manager.justUnlocked, [.incidentReported])
    }

    func testUnauthenticatedUnlocksQueueForLaterReport() {
        // Simulator tests are never Game Center authenticated, so reports
        // must land in the pending queue instead of being dropped.
        manager.evaluateVictory(context(totalSolved: 1))
        let pending = defaults.stringArray(forKey: "pendingAchievementReports") ?? []
        XCTAssertTrue(pending.contains(Achievement.helloWorld.rawValue))
    }

    // MARK: - Fixtures

    private func context(
        difficulty: Difficulty = .easy,
        totalSolved: Int = 1,
        undoCount: Int = 5,
        duration: TimeInterval = 600,
        rating: Int = 1210
    ) -> VictoryContext {
        VictoryContext(
            difficulty: difficulty,
            undoCount: undoCount,
            playDuration: duration,
            newRating: rating,
            totalSolved: totalSolved
        )
    }

    private func context(rating: Int) -> VictoryContext {
        context(difficulty: .easy, totalSolved: 1, undoCount: 5, duration: 600, rating: rating)
    }
}
