import SwiftUI

struct NoteGridView: View {
    let notes: Set<Int>
    let size: CGFloat
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(size / 3), spacing: 0), count: 3), spacing: 0) {
            ForEach(1...9, id: \.self) { num in
                Text(notes.contains(num) ? "\(num)" : "")
                    .font(.system(size: size * 0.25, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
                    .frame(height: size / 3)
            }
        }
    }
}

