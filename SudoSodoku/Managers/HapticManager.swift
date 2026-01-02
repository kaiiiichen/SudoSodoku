import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    func lightImpact() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    
    func mediumImpact() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }
    
    func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
    
    func error() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.error)
    }
}


