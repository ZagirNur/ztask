import SwiftUI

struct SideMenuView: View {
    @EnvironmentObject var todoStore: TodoStore
    @Binding var isShowing: Bool
    @Binding var showCompletedTasks: Bool

    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }

            // Menu content
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
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
                                .frame(width: 40, height: 40)

                            Rectangle()
                                .fill(Color.textSecondary)
                                .frame(width: 48, height: 2)
                        }
                        .padding(.bottom, 8)

                        Text("ZTask")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Text("\(todoStore.activeTodos.count) active tasks")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    Divider()
                        .background(Color.textSecondary.opacity(0.3))

                    // Menu items
                    VStack(spacing: 0) {
                        MenuRow(icon: "house.fill", title: "Tasks", badge: nil) {
                            withAnimation {
                                isShowing = false
                            }
                        }

                        MenuRow(
                            icon: "checkmark.circle.fill",
                            title: "Completed",
                            badge: todoStore.completedTodos.count > 0 ? "\(todoStore.completedTodos.count)" : nil
                        ) {
                            withAnimation {
                                isShowing = false
                                showCompletedTasks = true
                            }
                        }
                    }
                    .padding(.top, 16)

                    Spacer()

                    // Footer
                    Divider()
                        .background(Color.textSecondary.opacity(0.3))

                    MenuRow(icon: "gearshape", title: "Settings", badge: nil) {
                        // Settings action
                    }
                    .padding(.bottom, 32)
                }
                .frame(width: 280)
                .background(Color.cardBackground)
                .offset(x: isShowing ? 0 : -280)

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.accentCyan)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentCyan)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    SideMenuView(isShowing: .constant(true), showCompletedTasks: .constant(false))
        .environmentObject(TodoStore())
}
