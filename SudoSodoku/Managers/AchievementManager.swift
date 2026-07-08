import Combine
import Foundation
import GameKit

/// Owns the unlocked-achievement set: evaluates victories, persists locally,
/// reports to Game Center, and queues reports made while signed out.
/// Callers receive freshly unlocked achievements as return values and own
/// their presentation — there is no cross-view announcement state.
final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

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

    /// Returns the achievements this victory freshly unlocked (empty when
    /// everything satisfied was already earned).
    @discardableResult
    func evaluateVictory(_ context: VictoryContext) -> [Achievement] {
        unlock(Achievement.satisfied(by: context))
    }

    /// Easter egg hook for the sudoers interstitial (#15).
    @discardableResult
    func unlockIncidentReported() -> [Achievement] {
        unlock([.incidentReported])
    }

    /// Clears local unlock state and, when signed in, asks Game Center to
    /// reset server-side achievement progress. Used by the debug factory
    /// reset so unlock flows can be re-verified on a played account.
    func resetAllProgress() {
        defaults.removeObject(forKey: unlockedKey)
        defaults.removeObject(forKey: pendingReportsKey)
        objectWillChange.send()
        if GameCenterManager.shared.isAuthenticated {
            GKAchievement.resetAchievements { _ in }
        }
    }

    /// Called after Game Center authentication succeeds.
    func flushPendingReports() {
        let pending = defaults.stringArray(forKey: pendingReportsKey) ?? []
        guard !pending.isEmpty else { return }
        defaults.removeObject(forKey: pendingReportsKey)
        report(pending.compactMap(Achievement.init(rawValue:)))
    }

    // MARK: - Internals

    private func unlock(_ candidates: [Achievement]) -> [Achievement] {
        let fresh = candidates.filter { !isUnlocked($0) }
        guard !fresh.isEmpty else { return [] }

        defaults.set(Array(unlockedIDs.union(fresh.map(\.rawValue))), forKey: unlockedKey)
        objectWillChange.send()
        report(fresh)
        return fresh
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
        // No self capture: a weak `self` is a mutable var, and referencing
        // it inside the Sendable completion is an error in Swift 6.
        GKAchievement.report(reports) { error in
            guard error != nil else { return }
            Task { @MainActor in
                AchievementManager.shared.queueForLater(achievements)
            }
        }
    }

    private func queueForLater(_ achievements: [Achievement]) {
        let existing = Set(defaults.stringArray(forKey: pendingReportsKey) ?? [])
        let merged = existing.union(achievements.map(\.rawValue))
        defaults.set(Array(merged), forKey: pendingReportsKey)
    }
}
