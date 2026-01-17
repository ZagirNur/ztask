import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false
    @State private var showCompletedTasks = false
    @State private var draggingTodoId: UUID?

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
                                draggingTodoId: $draggingTodoId,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .today) }
                            )

                            DropSection(
                                section: .tomorrow,
                                todos: todoStore.tomorrowTodos,
                                showDayLabel: false,
                                draggingTodoId: $draggingTodoId,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .tomorrow) }
                            )

                            DropSection(
                                section: .nextWeek,
                                todos: todoStore.nextWeekTodos,
                                showDayLabel: true,
                                draggingTodoId: $draggingTodoId,
                                onToggle: { todoStore.toggleComplete($0) },
                                onMove: { todoStore.moveTodo($0, to: .nextWeek) }
                            )

                            DropSection(
                                section: .later,
                                todos: todoStore.laterTodos,
                                showDayLabel: false,
                                draggingTodoId: $draggingTodoId,
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
    @EnvironmentObject var todoStore: TodoStore
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var showCounter: Bool = false
    var totalCount: Int = 0
    @Binding var draggingTodoId: UUID?
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

            // Todos
            ForEach(todos) { todo in
                let isDragging = draggingTodoId == todo.id

                TodoRowView(
                    todo: todo,
                    showDayLabel: showDayLabel,
                    onToggle: { onToggle(todo) }
                )
                .opacity(isDragging ? 0.3 : 1.0)
                .onDrag {
                    draggingTodoId = todo.id
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    return NSItemProvider(object: todo.id.uuidString as NSString)
                }
            }

            // Drop zone placeholder when section is targeted and empty or has items
            if isTargeted {
                DropPlaceholder()
            }

            // Empty section placeholder
            if todos.isEmpty && !isTargeted {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 40)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentCyan.opacity(0.08) : Color.clear)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isTargeted)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            guard let todoId = draggingTodoId,
                  let todo = findTodo(by: todoId) else {
                return false
            }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            onMove(todo)
            draggingTodoId = nil
            return true
        }
    }

    private func findTodo(by id: UUID) -> Todo? {
        // Search in all todos
        return todoStore.todos.first { $0.id == id }
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
            .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
