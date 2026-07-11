import XCTest
@testable import SudoSodoku

final class PrivacyPolicyLinkTests: XCTestCase {

    /// The in-app link must point at the same document declared as the
    /// privacy policy URL in App Store Connect; a drift between the two is a
    /// review finding waiting to happen.
    func testPrivacyPolicyURLMatchesAppStoreConnectDeclaration() {
        XCTAssertEqual(
            AppConstants.privacyPolicyURL.absoluteString,
            "https://sudosodoku.kaichen.dev/privacy"
        )
    }

    func testPrivacyPolicyURLUsesHTTPS() {
        XCTAssertEqual(AppConstants.privacyPolicyURL.scheme, "https")
    }
}
