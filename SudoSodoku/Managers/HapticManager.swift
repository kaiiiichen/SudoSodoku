import SwiftUI

class HapticManager {
    static let shared = HapticManager()

    private var isHapticsEnabled: Bool {
        UIDevice.current.userInterfaceIdiom != .pad
    }
    
    func lightImpact() {
        guard isHapticsEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }
    
    func success() {
        guard isHapticsEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    
    func error() {
        guard isHapticsEnabled else { return }
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}

