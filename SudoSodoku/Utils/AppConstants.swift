import Foundation

enum AppConstants {
    static let bundleIdentifier = "dev.kaichen.sudoku.app"
    static let leaderboardPrefix = "dev.kaichen.sudoku.app.leaderboard"

    /// Global ELO ranking (ASC format: Integer, best = highest).
    static let eloLeaderboardID = "\(leaderboardPrefix).elo"

    static let achievementPrefix = "dev.kaichen.sudoku.app.achievement"

    /// Per-difficulty boards are configured in ASC as "Elapsed Time — To the
    /// Second" (best = lowest), so submitted values are whole seconds.
    /// Returns 0 for non-positive durations, which callers must not submit —
    /// a zero-second entry would otherwise own rank one forever.
    static func timeLeaderboardValue(for duration: TimeInterval) -> Int {
        duration <= 0 ? 0 : max(1, Int(duration.rounded()))
    }

    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
    }

    /// Privacy policy served from the public repository; App Review
    /// Guideline 5.1.1(i) requires it reachable from inside the app, and it
    /// must match the URL declared in App Store Connect.
    static let privacyPolicyURL = URL(string: "https://github.com/SudoSodokuApp/SudoSodoku/blob/main/PRIVACY.md")!

    static func leaderboardID(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy":
            return "\(leaderboardPrefix).easy"
        case "medium":
            return "\(leaderboardPrefix).medium"
        case "hard":
            return "\(leaderboardPrefix).hard"
        case "master":
            return "\(leaderboardPrefix).master"
        default:
            return leaderboardPrefix
        }
    }
}
