import SwiftUI

struct ContentView: View {
    @StateObject private var viewRouter = ViewRouter()
    
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewRouter.currentPlatform == .pad {
                    iPadLandingView()
                } else {
                    LandingView()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            GameCenterManager.shared.authenticateUser()
        }
    }
}
