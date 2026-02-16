import UIKit
import SwiftUI
import Combine

/// Platform detection utility for adaptive UI
enum Platform {
    case phone
    case pad
}

/// Platform detector to determine current device type
@MainActor
class PlatformDetector: ObservableObject {
    @Published var currentPlatform: Platform = .phone
    
    init() {
        updatePlatform()
        
        // Listen for orientation changes (though platform type won't change, this keeps detection robust)
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
    
    /// Check if current platform is iPad
    var isPad: Bool {
        currentPlatform == .pad
    }
    
    /// Check if current platform is iPhone
    var isPhone: Bool {
        currentPlatform == .phone
    }
}

/// Extension for easy platform detection in SwiftUI
extension UIDevice {
    static var currentPlatform: Platform {
        UIDevice.current.userInterfaceIdiom == .pad ? .pad : .phone
    }
    
    static var isPad: Bool {
        currentPlatform == .pad
    }
    
    static var isPhone: Bool {
        currentPlatform == .phone
    }
}
