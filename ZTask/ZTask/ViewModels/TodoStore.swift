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

    var todayTodos: [Todo] {
        todos.filter { todo in
            guard let dueDate = todo.dueDate else {
                return Calendar.current.isDateInToday(todo.createdAt)
            }
            return Calendar.current.isDateInToday(dueDate)
        }
    }

    var tomorrowTodos: [Todo] {
        todos.filter { todo in
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

        return todos.filter { todo in
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

        return todos.filter { todo in
            guard let dueDate = todo.dueDate else { return false }
            let startOfDue = calendar.startOfDay(for: dueDate)
            return startOfDue >= weekFromNow
        }.union(
            todos.filter { todo in
                todo.dueDate == nil && !Calendar.current.isDateInToday(todo.createdAt)
            }
        )
    }

    var completedTodayCount: Int {
        todayTodos.filter { $0.isCompleted }.count
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
            saveTodos()
        }
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
            Todo(title: "Намаз", dueDate: now),
            Todo(title: "Выйти гулять", dueDate: now),
            Todo(title: "Завтрак", dueDate: now),
            Todo(title: "Весы", dueDate: now),
            Todo(title: "Умыться", dueDate: now)
        ]

        // Tomorrow's todo
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowTodos = [
            Todo(title: "Проснулся", dueDate: tomorrow)
        ]

        // Next week todos
        let nextSunday = calendar.date(byAdding: .day, value: 7, to: now)!
        var components1 = calendar.dateComponents([.year, .month, .day], from: nextSunday)
        components1.hour = 7
        components1.minute = 0
        let sundayMorning = calendar.date(from: components1)!

        var components2 = calendar.dateComponents([.year, .month, .day], from: nextSunday)
        components2.hour = 22
        components2.minute = 50
        let sundayEvening = calendar.date(from: components2)!

        let nextWeekTodos = [
            Todo(
                title: "Проснуться в 7, умыться, зубы, завтрак.",
                dueDate: sundayMorning,
                reminder: sundayMorning,
                isRepeating: true
            ),
            Todo(
                title: "Зарядка перед сном и подготовка",
                dueDate: sundayEvening,
                reminder: sundayEvening,
                isRepeating: true
            )
        ]

        // Later todos
        let laterDate = calendar.date(byAdding: .day, value: 14, to: now)!
        let laterTodos = [
            Todo(title: "Купить билеты Гузель", dueDate: laterDate),
            Todo(title: "Разобраться с гугллм", dueDate: laterDate, hasSubtasks: true)
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
