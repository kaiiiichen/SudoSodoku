import SwiftUI

struct GridLinesOverlay: View {
    let width: CGFloat
    var body: some View {
        ZStack {
            HStack(spacing: 0) { Spacer(); Rectangle().frame(width: 2).foregroundColor(.white); Spacer(); Rectangle().frame(width: 2).foregroundColor(.white); Spacer() }
            VStack(spacing: 0) { Spacer(); Rectangle().frame(height: 2).foregroundColor(.white); Spacer(); Rectangle().frame(height: 2).foregroundColor(.white); Spacer() }
        }.allowsHitTesting(false)
    }
}


