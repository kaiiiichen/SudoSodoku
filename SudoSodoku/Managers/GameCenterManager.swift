import SwiftUI
import GameKit
import Combine

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    @Published var isAuthenticated = false
    @Published var playerName: String = "Guest"
    @Published var playerPhoto: Image?
    @Published var leaderboardID: String = "com.kaichen.SudoSodoku.leaderboard"
    
    func authenticateUser() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            if let vc = vc {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(vc, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                    self.playerName = localPlayer.displayName
                    localPlayer.loadPhoto(for: .small) { image, _ in
                        if let image = image { self.playerPhoto = Image(uiImage: image) }
                    }
                    // Load leaderboards and achievements
                    self.loadLeaderboards()
                    self.loadAchievements()
                }
            } else {
                DispatchQueue.main.async {
                    self.isAuthenticated = false
                    self.playerName = "Guest"
                    self.playerPhoto = nil
                }
            }
        }
    }
    
    private func loadLeaderboards() {
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            if let error = error {
                print("Error loading leaderboards: \(error.localizedDescription)")
            } else {
                print("Successfully loaded \(leaderboards?.count ?? 0) leaderboards")
            }
        }
    }
    
    private func loadAchievements() {
        GKAchievement.loadAchievements { achievements, error in
            if let error = error {
                print("Error loading achievements: \(error.localizedDescription)")
            } else {
                print("Successfully loaded \(achievements?.count ?? 0) achievements")
            }
        }
    }
    
    func submitScore(_ score: Int, difficulty: String) {
        guard isAuthenticated else {
            print("User not authenticated with Game Center")
            return
        }
        
        let leaderboardID = getLeaderboardID(for: difficulty)
        
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Error submitting score: \(error.localizedDescription)")
            } else {
                print("Successfully submitted score: \(score) to leaderboard: \(leaderboardID)")
            }
        }
    }
    
    private func getLeaderboardID(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy":
            return "com.kaichen.SudoSodoku.leaderboard.easy"
        case "medium":
            return "com.kaichen.SudoSodoku.leaderboard.medium"
        case "hard":
            return "com.kaichen.SudoSodoku.leaderboard.hard"
        case "expert":
            return "com.kaichen.SudoSodoku.leaderboard.expert"
        default:
            return leaderboardID
        }
    }
    
    func showLeaderboard(for difficulty: String) {
        guard isAuthenticated else {
            print("User not authenticated with Game Center")
            return
        }
        
        let leaderboardID = getLeaderboardID(for: difficulty)
        let gameCenterViewController = GKGameCenterViewController()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gameCenterViewController, animated: true)
        }
        
        // Load and show specific leaderboard
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { leaderboards, error in
            DispatchQueue.main.async {
                if let leaderboard = leaderboards?.first {
                    gameCenterViewController.leaderboardIdentifier = leaderboard.identifier
                }
            }
        }
    }
    
    func showAchievements() {
        guard isAuthenticated else {
            print("User not authenticated with Game Center")
            return
        }
        
        let gameCenterViewController = GKGameCenterViewController()
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(gameCenterViewController, animated: true)
        }
    }
}


