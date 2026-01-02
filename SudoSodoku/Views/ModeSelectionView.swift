import SwiftUI

struct ModeSelectionView: View {
    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading, spacing: 30) {
                Text("SELECT DIFFICULTY FLAGS:").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray).padding(.leading)
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            NavigationLink(destination: GameView(difficulty: diff)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("--\(diff.rawValue.lowercased())").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(diff.color)
                                        Text("DIFFICULTY_INDEX: \(diff.scoreRange.lowerBound)-\(diff.scoreRange.upperBound)").font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    Spacer(); Image(systemName: "chevron.right").foregroundColor(diff.color)
                                }
                                .padding().background(Color.black.opacity(0.5)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(diff.color.opacity(0.5), lineWidth: 1))
                            }
                        }
                    }.padding(.horizontal)
                }
            }
        }.navigationBarTitleDisplayMode(.inline)
    }
}

