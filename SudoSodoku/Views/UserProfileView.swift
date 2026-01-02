import SwiftUI

struct UserProfileView: View {
    @ObservedObject var storage = StorageManager.shared
    var ratingInfo: (title: String, color: Color) { RatingManager.shared.getRankTitle(rating: storage.userRating) }
    var totalGames: Int { storage.records.count }
    var solvedGames: Int { storage.records.filter { $0.isSolved }.count }
    var totalDigitsFilled: Int {
        storage.records.reduce(0) { res, rec in
            res + rec.playerBoard.enumerated().filter { $0.element != 0 && rec.initialBoard[$0.offset] == 0 }.count
        }
    }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(spacing: 30) {
                    VStack(spacing: 15) {
                        ZStack {
                            Circle().stroke(ratingInfo.color, lineWidth: 4).frame(width: 120, height: 120).shadow(color: ratingInfo.color.opacity(0.5), radius: 10)
                            if let photo = GameCenterManager.shared.playerPhoto { photo.resizable().scaledToFit().clipShape(Circle()).frame(width: 100, height: 100) }
                            else { Image(systemName: "person.fill").font(.system(size: 50)).foregroundColor(ratingInfo.color) }
                        }
                        VStack(spacing: 5) {
                            Text(ratingInfo.title).font(.system(size: 24, weight: .heavy, design: .monospaced)).foregroundColor(ratingInfo.color)
                            Text("ELO RATING: \(storage.userRating)").font(.system(size: 16, design: .monospaced)).foregroundColor(.white)
                        }
                    }.padding(.top, 40)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        StatCard(title: "GAMES PLAYED", value: "\(totalGames)", icon: "gamecontroller")
                        StatCard(title: "PUZZLES SOLVED", value: "\(solvedGames)", icon: "checkmark.seal")
                        StatCard(title: "DIGITS FILLED", value: "\(totalDigitsFilled)", icon: "number.square.fill")
                        StatCard(title: "HIGHEST ELO", value: "\(storage.userRating)", icon: "chart.line.uptrend.xyaxis")
                    }.padding(.horizontal)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("SYSTEM_RANK_TABLE:").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                        RankRow(range: "0-1199", title: "SCRIPT_KIDDIE", color: .gray)
                        RankRow(range: "1200-1399", title: "USER", color: .green)
                        RankRow(range: "1400-1599", title: "SUDOER", color: .cyan)
                        RankRow(range: "1600-1799", title: "SYS_ADMIN", color: .blue)
                        RankRow(range: "1800-1999", title: "KERNEL_HACKER", color: .purple)
                        RankRow(range: "2000+", title: "THE_ARCHITECT", color: .orange)
                    }.padding().background(Color.white.opacity(0.05)).cornerRadius(12).padding(.horizontal)
                    Spacer()
                }
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}


