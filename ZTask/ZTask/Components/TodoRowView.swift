import SwiftUI

struct TodoRowView: View {
    let todo: Todo
    let showDayLabel: Bool
    let onToggle: () -> Void

    init(todo: Todo, showDayLabel: Bool = false, onToggle: @escaping () -> Void) {
        self.todo = todo
        self.showDayLabel = showDayLabel
        self.onToggle = onToggle
    }

    private var isScheduled: Bool {
        todo.dueDate?.isInNextWeek ?? false
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CheckboxView(
                isChecked: todo.isCompleted,
                isScheduled: isScheduled,
                action: onToggle
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(todo.title)
                        .font(.system(size: 16))
                        .foregroundColor(todo.isCompleted ? .textSecondary : .textPrimary)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(2)

                    if todo.hasSubtasks {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    if showDayLabel, let dueDate = todo.dueDate {
                        Text(dueDate.shortDayName)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                    }
                }

                // Repeat and Reminder indicators
                if todo.isRepeating || todo.reminder != nil {
                    HStack(spacing: 8) {
                        if todo.isRepeating {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }

                        if let reminder = todo.reminder {
                            HStack(spacing: 4) {
                                Image(systemName: "bell")
                                    .font(.system(size: 12))
                                Text(reminder.formattedReminder)
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        TodoRowView(
            todo: Todo(title: "Намаз"),
            onToggle: {}
        )

        TodoRowView(
            todo: Todo(
                title: "Проснуться в 7, умыться, зубы, завтрак.",
                dueDate: Date().addingTimeInterval(86400 * 7),
                reminder: Date().addingTimeInterval(86400 * 7),
                isRepeating: true
            ),
            showDayLabel: true,
            onToggle: {}
        )

        TodoRowView(
            todo: Todo(
                title: "Разобраться с гугллм",
                hasSubtasks: true
            ),
            onToggle: {}
        )
    }
    .padding()
    .background(Color.appBackground)
}
