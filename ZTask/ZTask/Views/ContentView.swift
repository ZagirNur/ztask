import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false
    @State private var showCompletedTasks = false
    @State private var draggingTodo: Todo?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            DropSection(
                                section: .today,
                                todos: todoStore.todayTodos,
                                showDayLabel: false,
                                showCounter: true,
                                totalCount: todoStore.totalTodayCount,
                                draggingTodo: $draggingTodo,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .today) }
                            )

                            DropSection(
                                section: .tomorrow,
                                todos: todoStore.tomorrowTodos,
                                showDayLabel: false,
                                draggingTodo: $draggingTodo,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .tomorrow) }
                            )

                            DropSection(
                                section: .nextWeek,
                                todos: todoStore.nextWeekTodos,
                                showDayLabel: true,
                                draggingTodo: $draggingTodo,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .nextWeek) }
                            )

                            DropSection(
                                section: .later,
                                todos: todoStore.laterTodos,
                                showDayLabel: false,
                                draggingTodo: $draggingTodo,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .later) }
                            )

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton { showAddTodo = true }
                            .padding(.trailing, 20)
                            .padding(.bottom, 30)
                    }
                }

                SideMenuView(isShowing: $showMenu, showCompletedTasks: $showCompletedTasks)
            }
            .sheet(isPresented: $showAddTodo) { AddTodoView() }
            .fullScreenCover(isPresented: $showCompletedTasks) { CompletedTasksView() }
        }
    }
}

// MARK: - Drop Section

struct DropSection: View {
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var showCounter: Bool = false
    var totalCount: Int = 0
    @Binding var draggingTodo: Todo?
    let onToggle: (Todo) -> Void
    let onMove: (Todo) -> Void

    @State private var isTargeted = false

    private var headerColor: Color {
        switch section {
        case .today: return .todayHeader
        case .tomorrow: return .tomorrowHeader
        case .nextWeek: return .nextWeekHeader
        case .later: return .laterHeader
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack(spacing: 12) {
                Text(section.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(headerColor)

                if showCounter && totalCount > 0 {
                    Text("0/\(totalCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.cardBackground))
                }
                Spacer()
            }
            .padding(.top, 24)
            .padding(.bottom, 12)

            // Drop indicator when targeted and empty
            if isTargeted && todos.isEmpty {
                DropIndicatorLine()
            }

            // Todos
            ForEach(todos) { todo in
                let isDragging = draggingTodo?.id == todo.id

                TodoDragRow(
                    todo: todo,
                    showDayLabel: showDayLabel,
                    isDragging: isDragging,
                    isTargeted: isTargeted && !isDragging,
                    onToggle: { onToggle(todo) },
                    onDragStart: { draggingTodo = todo },
                    onDragEnd: { draggingTodo = nil }
                )
            }

            // Empty area for drop
            if todos.isEmpty {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 44)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentCyan.opacity(0.1) : Color.clear)
        )
        .dropDestination(for: String.self) { items, _ in
            guard items.first != nil, let todo = draggingTodo else { return false }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                onMove(todo)
                draggingTodo = nil
            }
            return true
        } isTargeted: { targeted in
            if targeted && !isTargeted {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                isTargeted = targeted
            }
        }
    }
}

// MARK: - Todo Drag Row

struct TodoDragRow: View {
    let todo: Todo
    let showDayLabel: Bool
    let isDragging: Bool
    let isTargeted: Bool
    let onToggle: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    private var isScheduled: Bool {
        todo.dueDate?.isInNextWeek ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Show drop indicator above when section is targeted
            if isTargeted {
                DropIndicatorLine()
                    .transition(.scale.combined(with: .opacity))
            }

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
                            .foregroundColor(.textPrimary)
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
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDragging ? Color.cardBackground : Color.clear)
            )
            .opacity(isDragging ? 0.6 : 1)
            .scaleEffect(isDragging ? 0.98 : 1)
            .contentShape(Rectangle())
            .draggable(todo.id.uuidString) {
                // Drag preview
                DragPreview(title: todo.title)
                    .onAppear {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onDragStart()
                    }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isTargeted)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
    }
}

// MARK: - Drop Indicator Line

struct DropIndicatorLine: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.accentCyan)
                .frame(width: 10, height: 10)

            Rectangle()
                .fill(Color.accentCyan)
                .frame(height: 3)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Drag Preview

struct DragPreview: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.textSecondary)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
