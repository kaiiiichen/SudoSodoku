import SwiftUI

struct UserProfileView: View {
    var commandPrefix: String = "sudo sudosodoku whoami"

    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var stats = StatisticsManager.shared
    @ObservedObject private var achievements = AchievementManager.shared

    #if DEBUG
    @State private var showWipeConfirmation = false
    #endif

    private var ratingInfo: (title: String, color: Color) {
        RatingManager.shared.getRankTitle(rating: storage.userRating)
    }

    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(spacing: 30) {
                    ExecutedCommandLine(command: commandPrefix)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20).padding(.horizontal)
                    VStack(spacing: 15) {
                        ZStack {
                            Circle().stroke(ratingInfo.color, lineWidth: 4).frame(width: 120, height: 120).shadow(color: ratingInfo.color.opacity(0.5), radius: 10)
                            if let photo = GameCenterManager.shared.playerPhoto {
                                photo.resizable().scaledToFit().clipShape(Circle()).frame(width: 100, height: 100)
                            } else {
                                Image(systemName: "person.fill").font(.system(size: 50)).foregroundColor(ratingInfo.color)
                            }
                        }
                        VStack(spacing: 5) {
                            Text(ratingInfo.title).font(.system(size: 24, weight: .heavy, design: .monospaced)).foregroundColor(ratingInfo.color)
                            Text("ELO RATING: \(storage.userRating)").font(.system(size: 16, design: .monospaced)).foregroundColor(.white)
                        }
                    }.padding(.top, 10)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatCard(title: "GAMES PLAYED", value: "\(stats.overallStats.totalGames)", icon: "gamecontroller")
                        StatCard(title: "PUZZLES SOLVED", value: "\(stats.overallStats.solvedGames)", icon: "checkmark.seal")
                    }.padding(.horizontal)

                    NavigationLink(destination: LeaderboardView()) {
                        HStack {
                            Image(systemName: "network")
                            Text("cat /leaderboard")
                        }
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.5), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACHIEVEMENTS:").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        ForEach(Achievement.wallList(isUnlocked: achievements.isUnlocked)) { achievement in
                            achievementRow(achievement)
                        }
                    }.padding().background(Color.white.opacity(0.05)).cornerRadius(12).padding(.horizontal)

                    Spacer()

                    VStack(alignment: .leading, spacing: 15) {
                        Text("SYSTEM_RANK_TABLE:").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        ForEach(RankTier.allCases, id: \.self) { tier in
                            RankRow(range: tier.rangeLabel, title: tier.title, color: tier.color)
                        }
                    }.padding().background(Color.white.opacity(0.05)).cornerRadius(12).padding(.horizontal)

                    privacyLink

                    #if DEBUG
                    debugWipeButton
                    #endif

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Opens the privacy policy in the browser. Quiet by design: a secondary
    /// footer action, not a green primary like `cat /leaderboard`.
    private var privacyLink: some View {
        Link(destination: AppConstants.privacyPolicyURL) {
            HStack {
                Image(systemName: "lock.shield")
                Text("cat /privacy")
            }
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.35), lineWidth: 1))
        }
        .padding(.horizontal)
    }

    #if DEBUG
    /// Debug builds only: factory reset for verifying first-run flows
    /// (achievement unlocks, the sudoers joke) on an already-played account.
    private var debugWipeButton: some View {
        Button(role: .destructive, action: { showWipeConfirmation = true }) {
            HStack {
                Image(systemName: "trash")
                Text("$ rm -rf /user_data")
            }
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.red)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
        }
        .padding(.horizontal)
        .confirmationDialog("WIPE_USER_DATA?", isPresented: $showWipeConfirmation, titleVisibility: .visible) {
            Button("CONFIRM (irreversible)", role: .destructive) {
                StorageManager.shared.wipeAllData()
                AchievementManager.shared.resetAllProgress()
                UserDefaults.standard.removeObject(forKey: SudoersJoke.seenKey)
            }
            Button("CANCEL", role: .cancel) {}
        } message: {
            Text("Erases local records and rating, clears achievements, and resets Game Center achievement progress.")
        }
    }
    #endif

    @ViewBuilder
    private func achievementRow(_ achievement: Achievement) -> some View {
        let unlocked = achievements.isUnlocked(achievement)
        HStack(spacing: 10) {
            Text(unlocked ? "[✓]" : "[ ]")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(unlocked ? .green : .gray.opacity(0.6))
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(unlocked ? .white : .gray)
                Text(achievement.detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
            }
            Spacer()
        }
    }
}
