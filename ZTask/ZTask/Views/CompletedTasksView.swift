import SwiftUI

struct CompletedTasksView: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    Text("Completed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Spacer()

                    if !todoStore.completedTodos.isEmpty {
                        Button(action: {
                            withAnimation {
                                todoStore.clearCompleted()
                            }
                        }) {
                            Text("Clear")
                                .font(.system(size: 14))
                                .foregroundColor(.accentCyan)
                        }
                    } else {
                        Color.clear.frame(width: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if todoStore.completedTodos.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.textSecondary.opacity(0.5))

                        Text("No completed tasks")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(todoStore.completedTodos) { todo in
                                CompletedTodoRow(todo: todo) {
                                    withAnimation {
                                        todoStore.restoreTodo(todo)
                                    }
                                } onDelete: {
                                    withAnimation {
                                        todoStore.deleteTodo(todo)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct CompletedTodoRow: View {
    let todo: Todo
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Completed checkmark
            ZStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 22, height: 22)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.appBackground)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .strikethrough()

                if let completedAt = todo.completedAt {
                    Text(completedAt.relativeFormatted)
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            // Restore button
            Button(action: onRestore) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .padding(8)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
            }
            .padding(8)
        }
        .padding(.vertical, 12)
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

#Preview {
    CompletedTasksView()
        .environmentObject(TodoStore())
}
