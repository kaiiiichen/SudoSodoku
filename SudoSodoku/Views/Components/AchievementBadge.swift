import SwiftUI

/// The unlock badge: a bordered, glowing card that gives an achievement the
/// presence a reward deserves. Shared by the victory sequence and the
/// sudoers interstitial.
struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 4) {
            Text("ACHIEVEMENT_UNLOCKED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow.opacity(0.7))
                .tracking(2)
            Text(achievement.title)
                .font(.system(size: 21, weight: .heavy, design: .monospaced))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.7), radius: 12)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 22)
        .background(Color.yellow.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.7), lineWidth: 1.5))
    }
}
