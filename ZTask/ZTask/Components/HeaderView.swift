import SwiftUI

struct HeaderView: View {
    @Binding var showMenu: Bool

    var body: some View {
        HStack {
            // Menu button
            Button(action: { showMenu.toggle() }) {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.textPrimary)
            }

            Spacer()

            // App logo - sunrise/sunset icon
            ZStack {
                // Sun arc
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 32, height: 32)

                // Horizon line
                Rectangle()
                    .fill(Color.textSecondary)
                    .frame(width: 40, height: 2)
                    .offset(y: 0)
            }

            Spacer()

            // Calendar button
            Button(action: {}) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.textPrimary, lineWidth: 1.5)
                        .frame(width: 28, height: 28)

                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.textPrimary)
                            .frame(width: 20, height: 2)

                        Text("\(Calendar.current.component(.day, from: Date()))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    HeaderView(showMenu: .constant(false))
        .background(Color.appBackground)
}
