import SwiftUI
import Combine

struct MatrixVictoryOverlay: View {
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var matrixChars: [String] = []
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ<>?[]{}"
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack {
                ForEach(0..<10, id: \.self) { _ in
                    HStack {
                        ForEach(0..<15, id: \.self) { _ in
                            Text(String(characters.randomElement()!))
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color.green.opacity(Double.random(in: 0.2...0.8)))
                        }
                    }
                }
            }
            .opacity(0.3)
            
            VStack(spacing: 20) {
                Text("ACCESS GRANTED")
                    .font(.system(size: 40, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green)
                    .shadow(color: .green, radius: 20)
                    .scaleEffect(scale)
                
                Text("SYSTEM COMPROMISED")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 10)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) { opacity = 1.0; scale = 1.1 }
            withAnimation(.easeInOut(duration: 0.1).repeatForever()) { scale = 1.0 }
        }
    }
}

