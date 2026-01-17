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
                // Background
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HeaderView(showMenu: $showMenu)

                    // Todo List
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Today Section
                            if !todoStore.todayTodos.isEmpty {
                                TodoSectionView(
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
                                    onDrop: { todo in
                                        todoStore.moveTodo(todo, to: .today)
                                    }
                                )
                            } else {
                                DropZoneView(section: .today, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .today)
                                }
                            }

                            // Tomorrow Section
                            if !todoStore.tomorrowTodos.isEmpty {
                                TodoSectionView(
                                    section: .tomorrow,
                                    todos: todoStore.tomorrowTodos,
                                    showDayLabel: false,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onDrop: { todo in
                                        todoStore.moveTodo(todo, to: .tomorrow)
                                    }
                                )
                            } else {
                                DropZoneView(section: .tomorrow, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .tomorrow)
                                }
                            }

                            // Next Week Section
                            if !todoStore.nextWeekTodos.isEmpty {
                                TodoSectionView(
                                    section: .nextWeek,
                                    todos: todoStore.nextWeekTodos,
                                    showDayLabel: true,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onDrop: { todo in
                                        todoStore.moveTodo(todo, to: .nextWeek)
                                    }
                                )
                            } else {
                                DropZoneView(section: .nextWeek, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .nextWeek)
                                }
                            }

                            // Later Section
                            if !todoStore.laterTodos.isEmpty {
                                TodoSectionView(
                                    section: .later,
                                    todos: todoStore.laterTodos,
                                    showDayLabel: false,
                                    draggedTodo: $draggedTodo,
                                    onToggle: { todo in
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            todoStore.toggleComplete(todo)
                                        }
                                    },
                                    onDrop: { todo in
                                        todoStore.moveTodo(todo, to: .later)
                                    }
                                )
                            } else {
                                DropZoneView(section: .later, draggedTodo: $draggedTodo) { todo in
                                    todoStore.moveTodo(todo, to: .later)
                                }
                            }

                            // Bottom padding for FAB
                            Spacer()
                                .frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Floating Action Button
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

                // Side Menu
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

// MARK: - Todo Section View with Drag Support

struct TodoSectionView: View {
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var completedCount: Int? = nil
    var totalCount: Int? = nil
    @Binding var draggedTodo: Todo?
    let onToggle: (Todo) -> Void
    let onDrop: (Todo) -> Void

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderView(
                section: section,
                completedCount: completedCount,
                totalCount: totalCount
            )

            ForEach(todos) { todo in
                DraggableTodoRow(
                    todo: todo,
                    showDayLabel: showDayLabel,
                    draggedTodo: $draggedTodo,
                    onToggle: { onToggle(todo) }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentCyan.opacity(0.1) : Color.clear)
        )
        .dropDestination(for: String.self) { items, _ in
            guard let todoId = items.first,
                  let uuid = UUID(uuidString: todoId),
                  let todo = draggedTodo,
                  todo.id == uuid else {
                return false
            }
            onDrop(todo)
            draggedTodo = nil
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
}

// MARK: - Draggable Todo Row

struct DraggableTodoRow: View {
    let todo: Todo
    let showDayLabel: Bool
    @Binding var draggedTodo: Todo?
    let onToggle: () -> Void

    var body: some View {
        TodoRowView(todo: todo, showDayLabel: showDayLabel, onToggle: onToggle)
            .draggable(todo.id.uuidString) {
                // Drag preview
                HStack(spacing: 12) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.textSecondary)
                    Text(todo.title)
                        .font(.system(size: 14))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cardBackground)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .onAppear {
                    draggedTodo = todo
                }
            }
    }
}

// MARK: - Drop Zone for Empty Sections

struct DropZoneView: View {
    let section: TodoSection
    @Binding var draggedTodo: Todo?
    let onDrop: (Todo) -> Void

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
        VStack(alignment: .leading, spacing: 8) {
            Text(section.displayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(headerColor.opacity(0.5))
                .padding(.top, 24)

            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(.accentCyan)
                    .frame(height: 50)
                    .overlay(
                        Text("Drop here")
                            .font(.system(size: 14))
                            .foregroundColor(.accentCyan)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dropDestination(for: String.self) { items, _ in
            guard let todoId = items.first,
                  let uuid = UUID(uuidString: todoId),
                  let todo = draggedTodo,
                  todo.id == uuid else {
                return false
            }
            onDrop(todo)
            draggedTodo = nil
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isTargeted = targeted
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
