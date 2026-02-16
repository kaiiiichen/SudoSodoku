import SwiftUI
import Combine

/// View router to handle platform-specific UI routing
@MainActor
class ViewRouter: ObservableObject {
    @Published var currentPlatform: Platform = .phone
    
    init() {
        updatePlatform()
        
        // Listen for platform changes
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.updatePlatform()
            }
        }
    }
    
    private func updatePlatform() {
        currentPlatform = UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
    }
    
    /// Get appropriate game view based on platform
    func gameView(game: SudokuGame, difficulty: Difficulty?, record: GameRecord?) -> AnyView {
        switch currentPlatform {
        case .phone:
            return AnyView(GameView(game: game, difficulty: difficulty, record: record))
        case .pad:
            return AnyView(iPadGameView(game: game, difficulty: difficulty, record: record))
        }
    }
    
    /// Get appropriate user profile view based on platform
    func userProfileView() -> AnyView {
        switch currentPlatform {
        case .phone:
            return AnyView(UserProfileView())
        case .pad:
            return AnyView(iPadUserProfileView())
        }
    }
    
    /// Get appropriate archive view based on platform
    func archiveView() -> AnyView {
        switch currentPlatform {
        case .phone:
            return AnyView(ArchiveView())
        case .pad:
            return AnyView(iPadArchiveView())
        }
    }
}
