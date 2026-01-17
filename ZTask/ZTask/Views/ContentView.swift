import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false
    @State private var showCompletedTasks = false
    @State private var draggedTodo: Todo?

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
                            if !todoStore.todayTodos.isEmpty {
                                ReorderableTodoSection(
                                    section: .today,
                                    todos: todoStore.todayTodos,
                                    showDayLabel: false,
                                    completedCount: todoStore.completedTodayCount,
                                    totalCount: todoStore.totalTodayCount,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onMove: { todo, section in
                                        todoStore.moveTodo(todo, to: section)
                                    }
                                )
                            } else if draggedTodo != nil {
                                DropZoneView(section: .today, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .today)
                                }
                            }

                            // Tomorrow Section
                            if !todoStore.tomorrowTodos.isEmpty {
                                ReorderableTodoSection(
                                    section: .tomorrow,
                                    todos: todoStore.tomorrowTodos,
                                    showDayLabel: false,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onMove: { todo, section in
                                        todoStore.moveTodo(todo, to: section)
                                    }
                                )
                            } else if draggedTodo != nil {
                                DropZoneView(section: .tomorrow, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .tomorrow)
                                }
                            }

                            // Next Week Section
                            if !todoStore.nextWeekTodos.isEmpty {
                                ReorderableTodoSection(
                                    section: .nextWeek,
                                    todos: todoStore.nextWeekTodos,
                                    showDayLabel: true,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onMove: { todo, section in
                                        todoStore.moveTodo(todo, to: section)
                                    }
                                )
                            } else if draggedTodo != nil {
                                DropZoneView(section: .nextWeek, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .nextWeek)
                                }
                            }

                            // Later Section
                            if !todoStore.laterTodos.isEmpty {
                                ReorderableTodoSection(
                                    section: .later,
                                    todos: todoStore.laterTodos,
                                    showDayLabel: false,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onMove: { todo, section in
                                        todoStore.moveTodo(todo, to: section)
                                    }
                                )
                            } else if draggedTodo != nil {
                                DropZoneView(section: .later, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .later)
                                }
                            }

                            Spacer()
                                .frame(height: 100)
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

// MARK: - Reorderable Todo Section

struct ReorderableTodoSection: View {
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var completedCount: Int? = nil
    var totalCount: Int? = nil
    @Binding var draggedTodo: Todo?
    let onToggle: (Todo) -> Void
    let onMove: (Todo, TodoSection) -> Void

    @State private var draggingItem: Todo?
    @State private var hasChangedPosition = false
    @State private var isTargeted = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(
                section: section,
                completedCount: completedCount,
                totalCount: totalCount
            )

            ForEach(todos) { todo in
                DraggableRowItem(
                    todo: todo,
                    showDayLabel: showDayLabel,
                    isDragging: draggingItem?.id == todo.id,
                    onToggle: { onToggle(todo) },
                    onDragStart: {
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred()
                        draggingItem = todo
                        draggedTodo = todo
                    },
                    onDragEnd: {
                        lightFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            draggingItem = nil
                            draggedTodo = nil
                        }
                    }
                )
                .zIndex(draggingItem?.id == todo.id ? 100 : 0)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted && draggingItem == nil ? Color.accentCyan.opacity(0.08) : Color.clear)
        )
        .onDrop(of: [.text], delegate: SectionDropDelegate(
            section: section,
            draggedTodo: $draggedTodo,
            isTargeted: $isTargeted,
            onMove: onMove,
            feedbackGenerator: lightFeedback
        ))
    }
}

// MARK: - Draggable Row Item

struct DraggableRowItem: View {
    let todo: Todo
    let showDayLabel: Bool
    let isDragging: Bool
    let onToggle: () -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragActive = false
    @GestureState private var dragState = DragState.inactive

    private var isScheduled: Bool {
        todo.dueDate?.isInNextWeek ?? false
    }

    enum DragState {
        case inactive
        case pressing
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive, .pressing:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isDragging: Bool {
            switch self {
            case .dragging:
                return true
            default:
                return false
            }
        }
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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDragging || isDragActive ? Color.cardBackground : Color.clear)
                .shadow(
                    color: isDragging || isDragActive ? .black.opacity(0.25) : .clear,
                    radius: isDragging || isDragActive ? 10 : 0,
                    y: isDragging || isDragActive ? 5 : 0
                )
        )
        .scaleEffect(isDragging || isDragActive ? 1.03 : 1.0)
        .offset(dragOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragActive)
        .gesture(
            LongPressGesture(minimumDuration: 0.25)
                .onEnded { _ in
                    isDragActive = true
                    onDragStart()
                }
                .sequenced(before: DragGesture())
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
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                        isDragActive = false
                    }
                    onDragEnd()
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in }
        )
        .draggable(todo.id.uuidString) {
            DragPreviewView(title: todo.title)
                .onAppear {
                    if !isDragActive {
                        onDragStart()
                    }
                }
        }
    }
}

// MARK: - Drag Preview

struct DragPreviewView: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.textSecondary)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Section Drop Delegate

struct SectionDropDelegate: DropDelegate {
    let section: TodoSection
    @Binding var draggedTodo: Todo?
    @Binding var isTargeted: Bool
    let onMove: (Todo, TodoSection) -> Void
    let feedbackGenerator: UIImpactFeedbackGenerator

    func performDrop(info: DropInfo) -> Bool {
        guard let todo = draggedTodo else { return false }
        onMove(todo, section)
        feedbackGenerator.impactOccurred()
        isTargeted = false
        return true
    }

    func dropEntered(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = true
        }
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = false
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return draggedTodo != nil
    }
}

// MARK: - Drop Zone for Empty Sections

struct DropZoneView: View {
    let section: TodoSection
    @Binding var draggedTodo: Todo?
    let onDrop: (Todo) -> Void

    @State private var isTargeted = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var headerColor: Color {
        switch section {
        case .today: return .todayHeader
        case .tomorrow: return .tomorrowHeader
        case .nextWeek: return .nextWeekHeader
        case .later: return .laterHeader
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.displayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(headerColor.opacity(0.5))
                .padding(.top, 24)

            RoundedRectangle(cornerRadius: 10)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(isTargeted ? .accentCyan : .textSecondary.opacity(0.3))
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isTargeted ? Color.accentCyan.opacity(0.1) : Color.clear)
                )
                .overlay(
                    HStack(spacing: 8) {
                        if isTargeted {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentCyan)
                            Text("Drop here")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentCyan)
                        }
                    }
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onDrop(of: [.text], delegate: EmptyDropDelegate(
            draggedTodo: $draggedTodo,
            isTargeted: $isTargeted,
            onDrop: onDrop,
            feedbackGenerator: feedbackGenerator
        ))
    }
}

struct EmptyDropDelegate: DropDelegate {
    @Binding var draggedTodo: Todo?
    @Binding var isTargeted: Bool
    let onDrop: (Todo) -> Void
    let feedbackGenerator: UIImpactFeedbackGenerator

    func performDrop(info: DropInfo) -> Bool {
        guard let todo = draggedTodo else { return false }
        onDrop(todo)
        feedbackGenerator.impactOccurred()
        draggedTodo = nil
        isTargeted = false
        return true
    }

    func dropEntered(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = true
        }
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    func dropExited(info: DropInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            isTargeted = false
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    func validateDrop(info: DropInfo) -> Bool {
        return draggedTodo != nil
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
