import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.accentCyan)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.accentCyan.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    FloatingActionButton(action: {})
        .padding()
        .background(Color.appBackground)
}
