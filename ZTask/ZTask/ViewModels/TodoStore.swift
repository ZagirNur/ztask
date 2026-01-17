import Foundation
import SwiftUI

class TodoStore: ObservableObject {
    @Published var todos: [Todo] = []

    private let saveKey = "ztask_todos"

    init() {
        loadTodos()
        if todos.isEmpty {
            loadSampleData()
        }
    }

    // MARK: - Computed Properties

    var activeTodos: [Todo] {
        todos.filter { !$0.isCompleted }
    }

    var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }
            .sorted { ($0.dueDate ?? $0.createdAt) > ($1.dueDate ?? $1.createdAt) }
    }

    var todayTodos: [Todo] {
        activeTodos.filter { todo in
            guard let dueDate = todo.dueDate else {
                return Calendar.current.isDateInToday(todo.createdAt)
            }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var tomorrowTodos: [Todo] {
        activeTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            return Calendar.current.isDateInTomorrow(dueDate)
        }
    }

    var nextWeekTodos: [Todo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let twoDaysFromNow = calendar.date(byAdding: .day, value: 2, to: today),
              let weekFromNow = calendar.date(byAdding: .day, value: 8, to: today) else {
            return []
        }

        return activeTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let startOfDue = calendar.startOfDay(for: dueDate)
            return startOfDue >= twoDaysFromNow && startOfDue < weekFromNow
        }
    }

    var laterTodos: [Todo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekFromNow = calendar.date(byAdding: .day, value: 8, to: today) else {
            return []
        }

        return activeTodos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let startOfDue = calendar.startOfDay(for: dueDate)
            return startOfDue >= weekFromNow
        }.union(
            activeTodos.filter { todo in
                todo.dueDate == nil && !Calendar.current.isDateInToday(todo.createdAt)
            }
        )
    }

    var completedTodayCount: Int {
        0 // All completed are hidden
    }

    var totalTodayCount: Int {
        todayTodos.count
    }

    // MARK: - CRUD Operations

    func addTodo(_ todo: Todo) {
        todos.append(todo)
        saveTodos()
    }

    func updateTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos()
        }
    }

    func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
        saveTodos()
    }

    func toggleComplete(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
            if todos[index].isCompleted {
                todos[index].completedAt = Date()
            } else {
                todos[index].completedAt = nil
            }
            saveTodos()
        }
    }

    func moveTodo(_ todo: Todo, to section: TodoSection) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }

        let calendar = Calendar.current
        let now = Date()

        switch section {
        case .today:
            todos[index].dueDate = now
        case .tomorrow:
            todos[index].dueDate = calendar.date(byAdding: .day, value: 1, to: now)
        case .nextWeek:
            todos[index].dueDate = calendar.date(byAdding: .day, value: 7, to: now)
        case .later:
            todos[index].dueDate = calendar.date(byAdding: .day, value: 14, to: now)
        }

        saveTodos()
    }

    func restoreTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted = false
            todos[index].completedAt = nil
            saveTodos()
        }
    }

    func clearCompleted() {
        todos.removeAll { $0.isCompleted }
        saveTodos()
    }

    // MARK: - Persistence

    private func saveTodos() {
        if let encoded = try? JSONEncoder().encode(todos) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadTodos() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Todo].self, from: data) {
            todos = decoded
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        let calendar = Calendar.current
        let now = Date()

        // Today's todos
        let todayTodos = [
            Todo(title: "Утренняя пробежка", dueDate: now),
            Todo(title: "Прочитать 30 страниц книги", dueDate: now),
            Todo(title: "Позвонить родителям", dueDate: now),
            Todo(title: "Оплатить интернет", dueDate: now)
        ]

        // Tomorrow's todos
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowTodos = [
            Todo(title: "Встреча с Артемом в 14:00", dueDate: tomorrow),
            Todo(title: "Сдать отчет", dueDate: tomorrow)
        ]

        // Next week todos
        let monday = calendar.date(byAdding: .day, value: 3, to: now)!
        var componentsGym = calendar.dateComponents([.year, .month, .day], from: monday)
        componentsGym.hour = 19
        componentsGym.minute = 0
        let gymTime = calendar.date(from: componentsGym)!

        let friday = calendar.date(byAdding: .day, value: 5, to: now)!
        var componentsDentist = calendar.dateComponents([.year, .month, .day], from: friday)
        componentsDentist.hour = 10
        componentsDentist.minute = 30
        let dentistTime = calendar.date(from: componentsDentist)!

        let saturday = calendar.date(byAdding: .day, value: 6, to: now)!

        let nextWeekTodos = [
            Todo(
                title: "Тренировка в зале",
                dueDate: gymTime,
                reminder: gymTime,
                isRepeating: true
            ),
            Todo(
                title: "Стоматолог - плановый осмотр",
                dueDate: dentistTime,
                reminder: dentistTime
            ),
            Todo(
                title: "Уборка квартиры",
                dueDate: saturday,
                isRepeating: true
            )
        ]

        // Later todos
        let inTwoWeeks = calendar.date(byAdding: .day, value: 14, to: now)!
        let inThreeWeeks = calendar.date(byAdding: .day, value: 21, to: now)!

        let laterTodos = [
            Todo(title: "Обновить резюме", dueDate: inTwoWeeks, hasSubtasks: true),
            Todo(title: "Записаться на курсы английского", dueDate: inTwoWeeks),
            Todo(title: "Техосмотр машины", dueDate: inThreeWeeks),
            Todo(title: "День рождения мамы - купить подарок", dueDate: inThreeWeeks)
        ]

        todos = todayTodos + tomorrowTodos + nextWeekTodos + laterTodos
        saveTodos()
    }
}

// Helper extension for array union
extension Array where Element: Equatable {
    func union(_ other: [Element]) -> [Element] {
        var result = self
        for element in other {
            if !result.contains(element) {
                result.append(element)
            }
        }
        return result
    }
}
