import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false

    var body: some View {
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
                            SectionHeaderView(
                                section: .today,
                                completedCount: todoStore.completedTodayCount,
                                totalCount: todoStore.totalTodayCount
                            )

                            ForEach(todoStore.todayTodos) { todo in
                                TodoRowView(todo: todo) {
                                    todoStore.toggleComplete(todo)
                                }
                            }
                        }

                        // Tomorrow Section
                        if !todoStore.tomorrowTodos.isEmpty {
                            SectionHeaderView(section: .tomorrow)

                            ForEach(todoStore.tomorrowTodos) { todo in
                                TodoRowView(todo: todo) {
                                    todoStore.toggleComplete(todo)
                                }
                            }
                        }

                        // Next Week Section
                        if !todoStore.nextWeekTodos.isEmpty {
                            SectionHeaderView(section: .nextWeek)

                            ForEach(todoStore.nextWeekTodos) { todo in
                                TodoRowView(
                                    todo: todo,
                                    showDayLabel: true
                                ) {
                                    todoStore.toggleComplete(todo)
                                }
                            }
                        }

                        // Later Section
                        if !todoStore.laterTodos.isEmpty {
                            SectionHeaderView(section: .later)

                            ForEach(todoStore.laterTodos) { todo in
                                TodoRowView(todo: todo) {
                                    todoStore.toggleComplete(todo)
                                }
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
        }
        .sheet(isPresented: $showAddTodo) {
            AddTodoView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
