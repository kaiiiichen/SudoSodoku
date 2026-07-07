import Combine
import UIKit
import SwiftUI
import GameKit

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var playerName: String = "Guest"
    @Published var playerPhoto: Image?

    private var hasStartedAuthentication = false

    func authenticateUser() {
        guard !hasStartedAuthentication else { return }
        hasStartedAuthentication = true

        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }

                if let viewController,
                   let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(viewController, animated: true)
                    return
                }

                if localPlayer.isAuthenticated {
                    self.isAuthenticated = true
                    self.playerName = localPlayer.displayName
                    AchievementManager.shared.flushPendingReports()
                    localPlayer.loadPhoto(for: .small) { image, _ in
                        Task { @MainActor in
                            if let image {
                                self.playerPhoto = Image(uiImage: image)
                            }
                        }
                    }
                } else {
                    self.isAuthenticated = false
                    self.playerName = "Guest"
                    self.playerPhoto = nil
                }
            }
        }
    }

    /// Submits the player's current ELO to the global ranking. The board is
    /// configured as "Most Recent Score" in ASC, so it always shows the
    /// current rating — correct even if ratings can drop in the future.
    func submitRating(_ rating: Int) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(
            rating,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [AppConstants.eloLeaderboardID]
        ) { _ in }
    }

    /// Submits a solve time to the per-difficulty fastest-time board.
    /// Boards are "Best Score" + Low-to-High in ASC, so Game Center keeps
    /// only the fastest submission automatically.
    func submitCompletionTime(_ duration: TimeInterval, difficulty: String) {
        guard isAuthenticated else { return }

        let value = AppConstants.timeLeaderboardValue(for: duration)
        guard value > 0 else { return }

        GKLeaderboard.submitScore(
            value,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [AppConstants.leaderboardID(for: difficulty)]
        ) { _ in }
    }
}
