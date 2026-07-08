import Foundation
import Combine

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    @Published var personalBests: [Difficulty: GameRecord] = [:]
    @Published var overallStats: OverallStats = OverallStats(
        totalGames: 0,
        solvedGames: 0,
        totalUndos: 0,
        bestLogicalEfficiency: 0
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
        var bests: [Difficulty: GameRecord] = [:]
        for difficulty in Difficulty.allCases {
            bests[difficulty] = records
                .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
                .max { $0.logicalEfficiency < $1.logicalEfficiency }
        }
        personalBests = bests

        let solvedRecords = records.filter(\.isSolved)
        overallStats = OverallStats(
            totalGames: records.count,
            solvedGames: solvedRecords.count,
            totalUndos: solvedRecords.reduce(0) { $0 + $1.undoCount },
            bestLogicalEfficiency: solvedRecords.max { $0.logicalEfficiency < $1.logicalEfficiency }?.logicalEfficiency ?? 0
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
