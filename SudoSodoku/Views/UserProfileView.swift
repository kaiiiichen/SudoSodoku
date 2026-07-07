import SwiftUI

struct UserProfileView: View {
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var stats = StatisticsManager.shared
    @ObservedObject private var achievements = AchievementManager.shared

    private var ratingInfo: (title: String, color: Color) {
        RatingManager.shared.getRankTitle(rating: storage.userRating)
    }

    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(spacing: 30) {
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
                    }.padding(.top, 40)

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
                        ForEach(Achievement.allCases) { achievement in
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

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

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
                Text(achievement.isSecret && !unlocked ? "????????" : achievement.detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.8))
            }
            Spacer()
        }
    }
}
