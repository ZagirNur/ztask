import SwiftUI

struct AddTodoView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var todoStore: TodoStore

    @State private var title: String = ""
    @State private var selectedSection: TodoSection = .today
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var hasReminder: Bool = false
    @State private var reminderDate: Date = Date()
    @State private var isRepeating: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)

                            TextField("What needs to be done?", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(.textPrimary)
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }

                        // Section picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(TodoSection.allCases, id: \.self) { section in
                                    SectionPill(
                                        section: section,
                                        isSelected: selectedSection == section
                                    ) {
                                        selectedSection = section
                                        updateDueDateForSection()
                                    }
                                }
                            }
                        }

                        // Due date toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasDueDate) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.accentOrange)
                                    Text("Due Date")
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            .tint(.accentCyan)

                            if hasDueDate {
                                DatePicker(
                                    "",
                                    selection: $dueDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)

                        // Reminder toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasReminder) {
                                HStack {
                                    Image(systemName: "bell")
                                        .foregroundColor(.accentCyan)
                                    Text("Reminder")
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            .tint(.accentCyan)

                            if hasReminder {
                                DatePicker(
                                    "",
                                    selection: $reminderDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)

                        // Repeat toggle
                        Toggle(isOn: $isRepeating) {
                            HStack {
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundColor(.accentGreen)
                                Text("Repeat")
                                    .foregroundColor(.textPrimary)
                            }
                        }
                        .tint(.accentCyan)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addTodo()
                    }
                    .foregroundColor(.accentCyan)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func updateDueDateForSection() {
        let calendar = Calendar.current
        let now = Date()

        switch selectedSection {
        case .today:
            dueDate = now
        case .tomorrow:
            dueDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .nextWeek:
            dueDate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        case .later:
            dueDate = calendar.date(byAdding: .day, value: 14, to: now) ?? now
        }

        hasDueDate = selectedSection != .today
    }

    private func addTodo() {
        let todo = Todo(
            title: title,
            dueDate: hasDueDate ? dueDate : nil,
            reminder: hasReminder ? reminderDate : nil,
            isRepeating: isRepeating
        )

        todoStore.addTodo(todo)
        dismiss()
    }
}

struct SectionPill: View {
    let section: TodoSection
    let isSelected: Bool
    let action: () -> Void

    private var pillColor: Color {
        switch section {
        case .today:
            return .todayHeader
        case .tomorrow:
            return .tomorrowHeader
        case .nextWeek:
            return .nextWeekHeader
        case .later:
            return .laterHeader
        }
    }

    var body: some View {
        Button(action: action) {
            Text(section.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .appBackground : pillColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? pillColor : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(pillColor, lineWidth: 1)
                        )
                )
        }
    }
}

#Preview {
    AddTodoView()
        .environmentObject(TodoStore())
}
