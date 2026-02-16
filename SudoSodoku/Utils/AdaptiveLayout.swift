import SwiftUI

/// Adaptive layout modifier for platform-specific views
struct AdaptiveLayout<PhoneContent: View, PadContent: View>: View {
    let phoneContent: PhoneContent
    let padContent: PadContent
    
    @StateObject private var platformDetector = PlatformDetector()
    
    init(
        phone: @escaping () -> PhoneContent,
        pad: @escaping () -> PadContent
    ) {
        self.phoneContent = phone()
        self.padContent = pad()
    }
    
    var body: some View {
        Group {
            if platformDetector.isPad {
                padContent
            } else {
                phoneContent
            }
        }
    }
}

/// Extension for easy adaptive layout usage
extension View {
    /// Provide different layouts for iPhone and iPad
    func adaptiveLayout<PadContent: View>(
        pad: @escaping () -> PadContent
    ) -> some View where Self: View {
        AdaptiveLayout(phone: { self }, pad: pad)
    }
}

/// Size class utilities for responsive design
extension View {
    /// Apply modifiers based on horizontal size class
    func horizontalSizeClass<Content: View>(
        compact: @escaping () -> Content,
        regular: @escaping () -> Content
    ) -> some View {
        self.modifier(HorizontalSizeClassModifier(
            compact: compact,
            regular: regular
        ))
    }
    
    /// Apply modifiers based on vertical size class
    func verticalSizeClass<Content: View>(
        compact: @escaping () -> Content,
        regular: @escaping () -> Content
    ) -> some View {
        self.modifier(VerticalSizeClassModifier(
            compact: compact,
            regular: regular
        ))
    }
}

/// Modifier for horizontal size class adaptation
struct HorizontalSizeClassModifier<CompactContent: View, RegularContent: View>: ViewModifier {
    let compact: () -> CompactContent
    let regular: () -> RegularContent
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    func body(content: Content) -> some View {
        Group {
            if horizontalSizeClass == .compact {
                compact()
            } else {
                regular()
            }
        }
    }
}

/// Modifier for vertical size class adaptation
struct VerticalSizeClassModifier<CompactContent: View, RegularContent: View>: ViewModifier {
    let compact: () -> CompactContent
    let regular: () -> RegularContent
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    func body(content: Content) -> some View {
        Group {
            if verticalSizeClass == .compact {
                compact()
            } else {
                regular()
            }
        }
    }
}
