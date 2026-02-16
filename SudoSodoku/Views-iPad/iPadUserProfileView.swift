import SwiftUI

/// iPad-optimized user profile view
struct iPadUserProfileView: View {
    @ObservedObject var storage = StorageManager.shared
    
    var ratingInfo: (title: String, color: Color) { RatingManager.shared.getRankTitle(rating: storage.userRating) }
    var totalGames: Int { storage.records.count }
    var solvedGames: Int { storage.records.filter { $0.isSolved }.count }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(spacing: 40) {
                    // User info section
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(ratingInfo.color, lineWidth: 6)
                                .frame(width: 150, height: 150)
                                .shadow(color: ratingInfo.color.opacity(0.5), radius: 15)
                            
                            if let photo = GameCenterManager.shared.playerPhoto {
                                photo.resizable()
                                    .scaledToFit()
                                    .clipShape(Circle())
                                    .frame(width: 130, height: 130)
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(ratingInfo.color)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text(ratingInfo.title)
                                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                .foregroundColor(ratingInfo.color)
                            Text("ELO RATING: \(storage.userRating)")
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 60)
                    
                    // Stats section with iPad-optimized layout
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 30) {
                        iPadStatCard(title: "GAMES PLAYED", value: "\(totalGames)", icon: "gamecontroller")
                        iPadStatCard(title: "PUZZLES SOLVED", value: "\(solvedGames)", icon: "checkmark.seal")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Rank table with iPad-optimized sizing
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SYSTEM_RANK_TABLE:")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 15) {
                            iPadRankRow(range: "0-1199", title: "SCRIPT_KIDDIE", color: .gray)
                            iPadRankRow(range: "1200-1399", title: "USER", color: .green)
                            iPadRankRow(range: "1400-1599", title: "SUDOER", color: .cyan)
                            iPadRankRow(range: "1600-1799", title: "SYS_ADMIN", color: .blue)
                            iPadRankRow(range: "1800-1999", title: "KERNEL_HACKER", color: .purple)
                            iPadRankRow(range: "2000+", title: "THE_ARCHITECT", color: .orange)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            GameCenterManager.shared.authenticateUser()
        }
    }
}

/// iPad-optimized stat card
private struct iPadStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.green)
            
            VStack(spacing: 5) {
                Text(value)
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.all, 30)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

/// iPad-optimized rank row
private struct iPadRankRow: View {
    let range: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            Text(range)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 120, alignment: .leading)
            
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}
