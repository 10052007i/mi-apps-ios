import SwiftUI

struct ContentView: View {
    @State private var contador = 0

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "swift")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("¡Hola mundo desde Windows!")
                .font(.title2)
            Text("Toques: \(contador)")
            Button("Tócame") {
                contador += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
