import SwiftUI

struct RankRow: View {
    let range: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(range).font(.system(size: 12, design: .monospaced)).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(title).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(color)
            Spacer()
        }
    }
}


