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

    @State private var dropIndex: Int? = nil

    private var headerColor: Color {
        switch section {
        case .today: return .todayHeader
        case .tomorrow: return .tomorrowHeader
        case .nextWeek: return .nextWeekHeader
        case .later: return .laterHeader
        }
    }

    private var isTargeted: Bool {
        dropIndex != nil
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

            // Todos with drop zones between them
            ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                let isDragging = draggingTodo?.id == todo.id

                VStack(spacing: 0) {
                    // Drop zone before this item
                    if dropIndex == index && !isDragging {
                        DropPlaceholder()
                    }

                    // The actual row
                    if !isDragging {
                        TodoRowWithDropZone(
                            todo: todo,
                            index: index,
                            showDayLabel: showDayLabel,
                            onToggle: { onToggle(todo) },
                            onDragStart: { draggingTodo = todo },
                            onDragEnd: { draggingTodo = nil }
                        )
                    }
                }
            }

            // Drop zone at the end
            if dropIndex == todos.count {
                DropPlaceholder()
            }

            // Empty section placeholder
            if todos.isEmpty && draggingTodo == nil {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 20)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentCyan.opacity(0.08) : Color.clear)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: dropIndex)
        .onDrop(of: [.text], delegate: SectionDropDelegate(
            todos: todos,
            draggingTodo: $draggingTodo,
            dropIndex: $dropIndex,
            onMove: onMove
        ))
    }
}

// MARK: - Drop Placeholder

struct DropPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentCyan.opacity(0.15))
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentCyan.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
            )
            .padding(.vertical, 4)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
    }
}

// MARK: - Todo Row With Drop Zone

struct TodoRowWithDropZone: View {
    let todo: Todo
    let index: Int
    let showDayLabel: Bool
    let onToggle: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

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
        .contentShape(Rectangle())
        .draggable(todo.id.uuidString) {
            DragPreview(title: todo.title, onDragEnd: onDragEnd)
                .onAppear {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onDragStart()
                }
        }
    }
}

// MARK: - Section Drop Delegate

struct SectionDropDelegate: DropDelegate {
    let todos: [Todo]
    @Binding var draggingTodo: Todo?
    @Binding var dropIndex: Int?
    let onMove: (Todo) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateDropIndex(at: info.location)
        return DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        updateDropIndex(at: info.location)
    }

    func dropExited(info: DropInfo) {
        dropIndex = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let todo = draggingTodo else { return false }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        onMove(todo)
        dropIndex = nil
        draggingTodo = nil
        return true
    }

    private func updateDropIndex(at location: CGPoint) {
        // Approximate row height
        let rowHeight: CGFloat = 56
        let headerHeight: CGFloat = 60

        let y = location.y - headerHeight
        var index = Int(y / rowHeight)

        // Adjust for dragging todo if it's in this section
        if let dragging = draggingTodo,
           let draggingIndex = todos.firstIndex(where: { $0.id == dragging.id }) {
            if index > draggingIndex {
                index += 1
            }
        }

        index = max(0, min(index, todos.count))

        if dropIndex != index {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            dropIndex = index
        }
    }
}

// MARK: - Drag Preview

struct DragPreview: View {
    let title: String
    let onDragEnd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentCyan, lineWidth: 2)
                .frame(width: 22, height: 22)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(width: 300, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        .onDisappear {
            // Reset dragging state when drag preview disappears (drag cancelled or completed)
            onDragEnd()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
