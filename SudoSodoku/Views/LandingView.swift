import SwiftUI

struct LandingView: View {
    @State private var cursorOpacity = 1.0
    @State private var glowStrength = 1.0
    @ObservedObject var gcManager = GameCenterManager.shared
    
    var body: some View {
        ZStack {
            TerminalBackground()
            
            VStack {
                HStack {
                    if gcManager.isAuthenticated {
                        if let photo = gcManager.playerPhoto {
                            photo.resizable().scaledToFit().frame(width: 30, height: 30).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 1))
                        } else {
                            Image(systemName: "person.circle.fill").font(.system(size: 30)).foregroundColor(.green)
                        }
                        Text("user: \(gcManager.playerName)").font(.system(size: 14, design: .monospaced)).foregroundColor(.green)
                    } else {
                        Image(systemName: "person.circle").font(.system(size: 30)).foregroundColor(.gray)
                        Text("user: guest").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: UserProfileView()) {
                        HStack { Text("WHOAMI"); Image(systemName: "person.text.rectangle") }
                            .font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            .padding(8).background(Color.green.opacity(0.1)).cornerRadius(8)
                    }
                }
                .padding(.top, 50).padding(.horizontal)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("root@ios:~$ ").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        Text("sudo sodoku").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
                    }
                    .padding(.bottom, 20)
                    
                    Text("sudo sodoku")
                        .font(.system(size: 54, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(glowStrength), radius: 15)
                        .shadow(color: .green.opacity(glowStrength * 0.6), radius: 40)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                glowStrength = 0.4
                            }
                        }
                    
                    Text("KERNEL_V0.5.0").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray).padding(.top, 5)
                }
                Spacer()
                
                NavigationLink(destination: ModeSelectionView()) {
                    HStack(spacing: 0) {
                        Text("./execute").font(.system(size: 24, weight: .bold, design: .monospaced))
                        Text("_").font(.system(size: 24, weight: .bold, design: .monospaced)).opacity(cursorOpacity)
                            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { cursorOpacity = 0.0 } }
                    }
                    .foregroundColor(.green).padding(.horizontal, 40).padding(.vertical, 20)
                    .background(Color.green.opacity(0.1)).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green, lineWidth: 2))
                }
                
                NavigationLink(destination: ArchiveView()) {
                    HStack { Image(systemName: "archivebox"); Text("cd /archives") }
                        .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray).padding()
                }
                Spacer()
            }
        }
    }
}

