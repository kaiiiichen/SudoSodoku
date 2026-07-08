import Foundation
import Combine

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    @Published var personalBests: [Difficulty: GameRecord] = [:]
    @Published var overallStats: OverallStats = OverallStats(
        totalGames: 0,
        solvedGames: 0,
        fastestSolve: nil,
        hardestSolved: nil
    )

    private var cancellables = Set<AnyCancellable>()

    init() {
        refresh(with: StorageManager.shared.records)
        // A @Published publisher emits on *willSet*: when this fires, the
        // singleton still holds the records from before the change. Stats
        // must be derived from the emitted value - reading back through
        // StorageManager here would lag storage by one mutation (zeros on
        // launch, stale numbers after a wipe).
        StorageManager.shared.$records
            .sink { [weak self] records in self?.refresh(with: records) }
            .store(in: &cancellables)
    }

    private func refresh(with records: [GameRecord]) {
        // A personal best is the fastest timed solve; records from before
        // time tracking (duration 0) fall back to the most efficient solve.
        var bests: [Difficulty: GameRecord] = [:]
        for difficulty in Difficulty.allCases {
            let solved = records.filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
            bests[difficulty] = solved
                .filter { $0.playDuration > 0 }
                .min { $0.playDuration < $1.playDuration }
                ?? solved.max { $0.logicalEfficiency < $1.logicalEfficiency }
        }
        personalBests = bests

        let solvedRecords = records.filter(\.isSolved)
        let solvedDifficulties = Set(solvedRecords.compactMap { Difficulty(rawValue: $0.difficulty) })
        overallStats = OverallStats(
            totalGames: records.count,
            solvedGames: solvedRecords.count,
            fastestSolve: solvedRecords.map(\.playDuration).filter { $0 > 0 }.min(),
            hardestSolved: Difficulty.allCases.last { solvedDifficulties.contains($0) }
        )
    }

    // The methods below are called from view bodies at render time, after
    // storage's didSet has completed, so reading the singleton is safe here.

    func getDifficultyDistribution() -> [Difficulty: Int] {
        var distribution: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            distribution[difficulty] = StorageManager.shared.records
                .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
                .count
        }
        return distribution
    }

    func getRecentCompletions(limit: Int = 20) -> [GameRecord] {
        StorageManager.shared.records
            .filter(\.isSolved)
            .sorted { $0.lastPlayedTime > $1.lastPlayedTime }
            .prefix(limit)
            .map { $0 }
    }
}
