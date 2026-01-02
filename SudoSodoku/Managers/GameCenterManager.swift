import SwiftUI
import GameKit
import Combine

class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    @Published var isAuthenticated = false
    @Published var playerName: String = "Guest"
    @Published var playerPhoto: Image?
    
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
                }
            }
        }
    }
}

