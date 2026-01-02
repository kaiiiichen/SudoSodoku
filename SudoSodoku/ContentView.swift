import SwiftUI

struct ContentView: View {
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some View {
        NavigationStack {
            LandingView()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            GameCenterManager.shared.authenticateUser()
        }
    }
}
