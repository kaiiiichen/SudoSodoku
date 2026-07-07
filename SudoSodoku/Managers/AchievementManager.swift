import Combine
import Foundation
import GameKit

/// Owns the unlocked-achievement set: evaluates victories, persists locally,
/// reports to Game Center, and queues reports made while signed out.
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    /// Achievements unlocked by the most recent event, for the in-game toast.
    @Published private(set) var justUnlocked: [Achievement] = []

    private let defaults: UserDefaults
    private let unlockedKey = "unlockedAchievements"
    private let pendingReportsKey = "pendingAchievementReports"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Queries

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedIDs.contains(achievement.rawValue)
    }

    private var unlockedIDs: Set<String> {
        Set(defaults.stringArray(forKey: unlockedKey) ?? [])
    }

    // MARK: - Events

    func evaluateVictory(_ context: VictoryContext) {
        unlock(Achievement.satisfied(by: context))
    }

    /// Easter egg hook for the sudoers interstitial (#15).
    func unlockIncidentReported() {
        unlock([.incidentReported])
    }

    /// Called after Game Center authentication succeeds.
    func flushPendingReports() {
        let pending = defaults.stringArray(forKey: pendingReportsKey) ?? []
        guard !pending.isEmpty else { return }
        defaults.removeObject(forKey: pendingReportsKey)
        report(pending.compactMap(Achievement.init(rawValue:)))
    }

    // MARK: - Internals

    private func unlock(_ candidates: [Achievement]) {
        let fresh = candidates.filter { !isUnlocked($0) }
        guard !fresh.isEmpty else { return }

        defaults.set(Array(unlockedIDs.union(fresh.map(\.rawValue))), forKey: unlockedKey)
        objectWillChange.send()
        justUnlocked = fresh
        report(fresh)
    }

    private func report(_ achievements: [Achievement]) {
        guard !achievements.isEmpty else { return }
        guard GameCenterManager.shared.isAuthenticated else {
            queueForLater(achievements)
            return
        }

        let reports = achievements.map { achievement in
            let gk = GKAchievement(identifier: achievement.gameCenterID)
            gk.percentComplete = 100
            gk.showsCompletionBanner = false // the terminal toast is ours
            return gk
        }
        GKAchievement.report(reports) { [weak self] error in
            if error != nil {
                Task { @MainActor in self?.queueForLater(achievements) }
            }
        }
    }

    private func queueForLater(_ achievements: [Achievement]) {
        let existing = Set(defaults.stringArray(forKey: pendingReportsKey) ?? [])
        let merged = existing.union(achievements.map(\.rawValue))
        defaults.set(Array(merged), forKey: pendingReportsKey)
    }
}
