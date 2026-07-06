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

    func submitScore(_ score: Int, difficulty: String) {
        guard isAuthenticated else { return }

        let leaderboardID = AppConstants.leaderboardID(for: difficulty)
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { _ in }
    }
}
