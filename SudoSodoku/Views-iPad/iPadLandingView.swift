import SwiftUI

struct iPadLandingView: View {
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
                            photo.resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle()).overlay(Circle().stroke(Color.green, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill").font(.system(size: 40)).foregroundColor(.green)
                        }
                        Text("user: \(gcManager.playerName)").font(.system(size: 18, design: .monospaced)).foregroundColor(.green)
                    } else {
                        Image(systemName: "person.circle").font(.system(size: 40)).foregroundColor(.gray)
                        Text("user: guest").font(.system(size: 18, design: .monospaced)).foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: iPadUserProfileView()) {
                        HStack { Text("WHOAMI"); Image(systemName: "person.text.rectangle") }
                            .font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.green)
                            .padding(12).background(Color.green.opacity(0.1)).cornerRadius(12)
                    }
                }
                .padding(.top, 60).padding(.horizontal, 40)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("root@ipados:~$ ").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        Text("sudo sodoku").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                    
                    Text("sudo sodoku")
                        .font(.system(size: 84, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(glowStrength), radius: 20)
                        .shadow(color: .green.opacity(glowStrength * 0.6), radius: 50)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                glowStrength = 0.4
                            }
                        }
                    
                    Text("KERNEL_V1.0.0").font(.system(size: 18, design: .monospaced)).foregroundColor(.gray).padding(.top, 8)
                }
                Spacer()
                
                NavigationLink(destination: ModeSelectionView()) {
                    HStack(spacing: 0) {
                        Text("./execute").font(.system(size: 32, weight: .bold, design: .monospaced))
                        Text("_").font(.system(size: 32, weight: .bold, design: .monospaced)).opacity(cursorOpacity)
                            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { cursorOpacity = 0.0 } }
                    }
                    .foregroundColor(.green).padding(.horizontal, 60).padding(.vertical, 25)
                    .background(Color.green.opacity(0.1)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green, lineWidth: 2))
                }
                
                NavigationLink(destination: iPadArchiveView()) {
                    HStack { Image(systemName: "archivebox"); Text("cd /archives") }
                        .font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.gray).padding()
                }
                Spacer()
            }
        }
        .onAppear {
            gcManager.authenticateUser()
        }
    }
}
