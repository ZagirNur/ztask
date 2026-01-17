import Foundation

extension Date {
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    var formattedReminder: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' HH:mm"
        return formatter.string(from: self)
    }

    var isInNextWeek: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let twoDaysFromNow = calendar.date(byAdding: .day, value: 2, to: today),
              let weekFromNow = calendar.date(byAdding: .day, value: 8, to: today) else {
            return false
        }
        let startOfSelf = calendar.startOfDay(for: self)
        return startOfSelf >= twoDaysFromNow && startOfSelf < weekFromNow
    }
}
