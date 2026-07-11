import SwiftUI

private enum LandingTarget: String, Identifiable {
    case breach, archives, stats, whoami
    var id: String { rawValue }
}

struct LandingView: View {
    @State private var glowStrength = 1.0
    @State private var launchTarget: LandingTarget?
    @State private var composerKey = UUID()
    // The terminal boots in (base command types itself) only on the first
    // appearance after launch; back-navigations get the materialized prompt.
    @State private var bootsIn = true
    @State private var hasAppearedBefore = false
    @ObservedObject var gcManager = GameCenterManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    bootsIn: bootsIn,
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
            if hasAppearedBefore { bootsIn = false }
            hasAppearedBefore = true
            composerKey = UUID()
        }
        .onChange(of: launchTarget) { _, newValue in
            // A swipe-back that lands before the push transition settles
            // returns here without this view ever leaving the hierarchy, so
            // onAppear does not fire again and the composer stays stranded
            // mid-composition: isComposing forever true, every option
            // disabled, the picked subcommand stuck on the prompt (#79).
            // The navigation binding, unlike onAppear, always nils on pop —
            // reset on it. bootsIn too: any return from navigation is past
            // the once-per-process boot (#54).
            guard newValue == nil else { return }
            bootsIn = false
            composerKey = UUID()
        }
    }

    // MARK: - Sections

    private var identityRow: some View {
        // Every auth state renders in the same fixed 30x30 avatar slot with a
        // constant row height: signing in must swap pixels in place, never
        // re-flow the layout under the whole screen.
        HStack {
            Group {
                if gcManager.isAuthenticated {
                    if let photo = gcManager.playerPhoto {
                        photo.resizable().scaledToFit()
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.green, lineWidth: 1))
                    } else {
                        Image(systemName: "person.circle.fill").resizable().scaledToFit().foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "person.circle").resizable().scaledToFit().foregroundColor(.gray)
                }
            }
            .frame(width: 30, height: 30)
            Text("user: \(gcManager.isAuthenticated ? gcManager.playerName : "guest")")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(gcManager.isAuthenticated ? .green : .gray)
            Spacer()
        }
        .frame(height: 30)
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
                    // repeatForever animations die when a pushed screen covers
                    // this view; on the way back, animating to the value the
                    // state already holds is a no-op and the glow froze dim.
                    // Reset without animation, then restart the pulse.
                    glowStrength = 1.0
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        glowStrength = 0.4
                    }
                }

            Text("KERNEL_V\(AppConstants.marketingVersion)").font(.system(size: 14, design: .monospaced)).foregroundColor(.gray).padding(.top, 5)
            Text("// logic is root access")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.green.opacity(0.55))
                .padding(.top, 2)
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}
