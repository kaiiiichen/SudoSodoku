import Foundation

/// Headline statistics. A no-fail puzzle game has no "win rate" — boards are
/// only finished or unfinished — so the honest measures are volume (solved),
/// speed (fastest solve), and depth (hardest tier solved). Rating lives in
/// StorageManager. totalGames counts every session and belongs to the
/// archive-flavored surfaces (WHOAMI), never to a ratio.
struct OverallStats {
    let totalGames: Int
    let solvedGames: Int
    let fastestSolve: TimeInterval?
    let hardestSolved: Difficulty?
}
