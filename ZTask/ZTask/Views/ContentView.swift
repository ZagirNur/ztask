import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false
    @State private var showCompletedTasks = false
    @State private var draggingTodo: Todo?
    @State private var dropTargetSection: TodoSection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Today Section
                            TodoSectionView(
                                section: .today,
                                todos: todoStore.todayTodos,
                                showDayLabel: false,
                                completedCount: todoStore.completedTodayCount,
                                totalCount: todoStore.totalTodayCount,
                                draggingTodo: $draggingTodo,
                                dropTargetSection: $dropTargetSection,
                                onToggle: { todo in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        todoStore.toggleComplete(todo)
                                    }
                                },
                                onMove: { todo in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        todoStore.moveTodo(todo, to: .today)
                                    }
                                }
                            )

                            // Tomorrow Section
                            TodoSectionView(
                                section: .tomorrow,
                                todos: todoStore.tomorrowTodos,
                                showDayLabel: false,
                                draggingTodo: $draggingTodo,
                                dropTargetSection: $dropTargetSection,
                                onToggle: { todo in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        todoStore.toggleComplete(todo)
                                    }
                                },
                                onMove: { todo in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        todoStore.moveTodo(todo, to: .tomorrow)
                                    }
                                }
                            )

                            // Next Week Section
                            TodoSectionView(
                                section: .nextWeek,
                                todos: todoStore.nextWeekTodos,
                                showDayLabel: true,
                                draggingTodo: $draggingTodo,
                                dropTargetSection: $dropTargetSection,
                                onToggle: { todo in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        todoStore.toggleComplete(todo)
                                    }
                                },
                                onMove: { todo in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        todoStore.moveTodo(todo, to: .nextWeek)
                                    }
                                }
                            )

                            // Later Section
                            TodoSectionView(
                                section: .later,
                                todos: todoStore.laterTodos,
                                showDayLabel: false,
                                draggingTodo: $draggingTodo,
                                dropTargetSection: $dropTargetSection,
                                onToggle: { todo in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        todoStore.toggleComplete(todo)
                                    }
                                },
                                onMove: { todo in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        todoStore.moveTodo(todo, to: .later)
                                    }
                                }
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
                        FloatingActionButton {
                            showAddTodo = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }

                SideMenuView(
                    isShowing: $showMenu,
                    showCompletedTasks: $showCompletedTasks
                )
            }
            .sheet(isPresented: $showAddTodo) {
                AddTodoView()
            }
            .fullScreenCover(isPresented: $showCompletedTasks) {
                CompletedTasksView()
            }
        }
    }
}

// MARK: - Todo Section View

struct TodoSectionView: View {
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var completedCount: Int? = nil
    var totalCount: Int? = nil
    @Binding var draggingTodo: Todo?
    @Binding var dropTargetSection: TodoSection?
    let onToggle: (Todo) -> Void
    let onMove: (Todo) -> Void

    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)

    private var isDropTarget: Bool {
        dropTargetSection == section && draggingTodo != nil
    }

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
            // Header
            HStack(spacing: 12) {
                Text(section.displayName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(todos.isEmpty && draggingTodo == nil ? headerColor.opacity(0.4) : headerColor)

                if let completed = completedCount, let total = totalCount, section == .today, !todos.isEmpty {
                    Text("\(completed)/\(total)")
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

            // Drop zone indicator at top
            if isDropTarget && todos.isEmpty {
                DropIndicator()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Todo items
            ForEach(todos) { todo in
                let isDragging = draggingTodo?.id == todo.id

                VStack(spacing: 0) {
                    // Drop indicator above item
                    if isDropTarget && !isDragging && todos.first?.id == todo.id {
                        DropIndicator()
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    DraggableTodoRow(
                        todo: todo,
                        showDayLabel: showDayLabel,
                        isDragging: isDragging,
                        onToggle: { onToggle(todo) },
                        onDragStarted: {
                            impactMedium.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                draggingTodo = todo
                            }
                        },
                        onDragEnded: {
                            if let targetSection = dropTargetSection, let todo = draggingTodo {
                                impactLight.impactOccurred()
                                onMove(todo)
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                draggingTodo = nil
                                dropTargetSection = nil
                            }
                        }
                    )
                    .opacity(isDragging ? 0.5 : 1.0)
                }
            }

            // Empty section drop zone
            if todos.isEmpty && draggingTodo != nil {
                Color.clear
                    .frame(height: 50)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTarget ? Color.accentCyan.opacity(0.08) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        )
        .onDrop(of: [.text], delegate: TodoSectionDropDelegate(
            section: section,
            draggingTodo: $draggingTodo,
            dropTargetSection: $dropTargetSection,
            onMove: onMove,
            impactLight: impactLight
        ))
    }
}

// MARK: - Drop Indicator

struct DropIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentCyan)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(Color.accentCyan)
                .frame(height: 2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Draggable Todo Row

struct DraggableTodoRow: View {
    let todo: Todo
    let showDayLabel: Bool
    let isDragging: Bool
    let onToggle: () -> Void
    let onDragStarted: () -> Void
    let onDragEnded: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isPressed = false

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
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDragging || isPressed ? Color.cardBackground : Color.clear)
                .shadow(
                    color: isDragging ? .black.opacity(0.3) : .clear,
                    radius: isDragging ? 12 : 0,
                    y: isDragging ? 6 : 0
                )
        )
        .scaleEffect(isDragging ? 1.05 : isPressed ? 1.02 : 1.0)
        .offset(dragOffset)
        .zIndex(isDragging ? 100 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .contentShape(Rectangle())
        .gesture(
            LongPressGesture(minimumDuration: 0.2)
                .onChanged { _ in
                    withAnimation {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onDragStarted()
                }
                .sequenced(before: DragGesture(coordinateSpace: .global))
                .onChanged { value in
                    switch value {
                    case .first(true):
                        break
                    case .second(true, let drag):
                        if let drag = drag {
                            dragOffset = drag.translation
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        isPressed = false
                    }
                    onDragEnded()
                }
        )
        .draggable(todo.id.uuidString) {
            // Drag preview
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.textSecondary)
                Text(todo.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .onAppear {
                onDragStarted()
            }
        }
    }
}

// MARK: - Section Drop Delegate

struct TodoSectionDropDelegate: DropDelegate {
    let section: TodoSection
    @Binding var draggingTodo: Todo?
    @Binding var dropTargetSection: TodoSection?
    let onMove: (Todo) -> Void
    let impactLight: UIImpactFeedbackGenerator

    func performDrop(info: DropInfo) -> Bool {
        guard let todo = draggingTodo else { return false }

        impactLight.impactOccurred()
        onMove(todo)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            draggingTodo = nil
            dropTargetSection = nil
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        guard draggingTodo != nil else { return }

        if dropTargetSection != section {
            impactLight.impactOccurred()
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            dropTargetSection = section
        }
    }

    func dropExited(info: DropInfo) {
        if dropTargetSection == section {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                dropTargetSection = nil
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return draggingTodo != nil
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
