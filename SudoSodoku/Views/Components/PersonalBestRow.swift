import SwiftUI

struct PersonalBestRow: View {
    let difficulty: Difficulty
    let record: GameRecord?
    
    var body: some View {
        HStack {
            // Difficulty label
            VStack(spacing: 2) {
                Text(difficulty.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(difficulty.color)
                Text("LEVEL")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Logical quality information
            if let record = record {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                            .foregroundColor(record.undoCount > 5 ? .orange : .green)
                        Text("UNDOS: \(record.undoCount)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("QUALITY: \(record.logicalQuality)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Logical efficiency indicator
                VStack(spacing: 2) {
                    Text("\(record.logicalEfficiency)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(getEfficiencyColor(record.logicalEfficiency))
                    Text("EFFICIENCY")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("NO_RECORD")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("START_PLAYING_TO_SET_RECORD")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
                
                Text("--")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(8)
    }
    
    private func getEfficiencyColor(_ score: Int) -> Color {
        switch score {
        case 900...: return .green
        case 700..<900: return .yellow
        case 500..<700: return .orange
        default: return .red
        }
    }
}
