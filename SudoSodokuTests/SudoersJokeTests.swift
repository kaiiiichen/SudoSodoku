import XCTest
@testable import SudoSodoku

final class SudoersJokeTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suiteName = "SudoersJokeTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testShowsOnlyForMaster() {
        XCTAssertTrue(SudoersJoke.shouldShow(for: .master, defaults: defaults))
        XCTAssertFalse(SudoersJoke.shouldShow(for: .easy, defaults: defaults))
        XCTAssertFalse(SudoersJoke.shouldShow(for: .medium, defaults: defaults))
        XCTAssertFalse(SudoersJoke.shouldShow(for: .hard, defaults: defaults))
    }

    func testFiresExactlyOnce() {
        XCTAssertTrue(SudoersJoke.shouldShow(for: .master, defaults: defaults))
        SudoersJoke.markSeen(in: defaults)
        XCTAssertFalse(SudoersJoke.shouldShow(for: .master, defaults: defaults),
                       "The incident is only ever reported once")
    }
}
