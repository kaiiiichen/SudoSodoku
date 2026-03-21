import SwiftUI

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
    
}
