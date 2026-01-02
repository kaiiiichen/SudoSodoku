import SwiftUI

struct RecordRow: View {
    let record: GameRecord
    var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    if record.isFavorite { Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.yellow) }
                    Text(dateFormatter.string(from: record.lastPlayedTime)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.white)
                }
                HStack {
                    Text(record.difficulty).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(Difficulty(rawValue: record.difficulty)?.color ?? .gray)
                    if record.isSolved {
                        Text("[COMPLETED]").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.green)
                        if let gain = record.ratingChange { Text("+\(gain) RP").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.yellow) }
                    } else {
                        Text("[IN_PROGRESS]").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.cyan)
                    }
                }
            }
            Spacer()
            Text("\(record.progress)%").font(.system(size: 24, weight: .bold, design: .monospaced)).foregroundColor(record.isSolved ? .green : .cyan).padding(.trailing, 10)
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(record.isSolved ? Color.green.opacity(0.5) : Color.gray.opacity(0.3), lineWidth: 1)).padding(.vertical, 4)
    }
}

