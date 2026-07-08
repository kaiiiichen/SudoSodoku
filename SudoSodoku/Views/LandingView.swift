import SwiftUI

private enum LandingTarget: String, Identifiable {
    case breach, archives, stats, whoami
    var id: String { rawValue }
}

struct LandingView: View {
    @State private var glowStrength = 1.0
    @State private var launchTarget: LandingTarget?
    @State private var composerKey = UUID()
    @ObservedObject var gcManager = GameCenterManager.shared

    var body: some View {
        ZStack {
            TerminalBackground()

            VStack {
                identityRow
                Spacer()

                TerminalCommandComposer(
                    awaitingComment: "# awaiting command",
                    baseCommand: "sudo sudosodoku",
                    completionComment: "# tab_completion:",
                    options: [
                        CommandOption(id: LandingTarget.breach.rawValue, label: "breach", detail: "// initiate new puzzle", color: .green),
                        CommandOption(id: LandingTarget.archives.rawValue, label: "archives", detail: "// puzzle history & records", color: .gray),
                        CommandOption(id: LandingTarget.stats.rawValue, label: "stats", detail: "// performance metrics", color: .gray),
                        CommandOption(id: LandingTarget.whoami.rawValue, label: "whoami", detail: "// operator profile", color: .gray),
                    ],
                    hint: nil,
                    onExecute: { option in
                        launchTarget = LandingTarget(rawValue: option.id)
                    },
                    hero: { hero }
                )
                .id(composerKey)

                Spacer()
            }
        }
        .navigationDestination(item: $launchTarget) { target in
            switch target {
            case .breach:
                ModeSelectionView(commandPrefix: "sudo sudosodoku")
            case .archives:
                ArchiveView(commandPrefix: "sudo sudosodoku archives")
            case .stats:
                StatsView(commandPrefix: "sudo sudosodoku stats")
            case .whoami:
                UserProfileView(commandPrefix: "sudo sudosodoku whoami")
            }
        }
        .onAppear {
            composerKey = UUID()
        }
    }

    // MARK: - Sections

    private var identityRow: some View {
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
        }
        .padding(.top, 50).padding(.horizontal)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("sudo sudosodoku")
                .font(.system(size: 54, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .green.opacity(glowStrength), radius: 15)
                .shadow(color: .green.opacity(glowStrength * 0.6), radius: 40)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        glowStrength = 0.4
                    }
                }

            Text("KERNEL_V\(AppConstants.marketingVersion)").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray).padding(.top, 5)
            Text("// root access for logical purists")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.green.opacity(0.55))
                .padding(.top, 2)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
