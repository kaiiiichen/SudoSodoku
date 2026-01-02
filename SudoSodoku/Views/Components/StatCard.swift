import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: icon).foregroundColor(.green); Spacer() }
            Text(value).font(.system(size: 28, weight: .bold, design: .monospaced)).foregroundColor(.white)
            Text(title).font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}


