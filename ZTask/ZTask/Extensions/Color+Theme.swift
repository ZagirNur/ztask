import SwiftUI

extension Color {
    // Background colors
    static let appBackground = Color(hex: "0D1117")
    static let cardBackground = Color(hex: "161B22")

    // Accent colors
    static let accentCyan = Color(hex: "22D3EE")
    static let accentGreen = Color(hex: "10B981")
    static let accentOrange = Color(hex: "F59E0B")
    static let accentBlue = Color(hex: "3B82F6")

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9CA3AF")

    // Section header colors
    static let todayHeader = Color(hex: "F59E0B")
    static let tomorrowHeader = Color(hex: "F59E0B")
    static let nextWeekHeader = Color(hex: "9CA3AF")
    static let laterHeader = Color(hex: "6B7280")

    // Checkbox colors
    static let checkboxDefault = Color(hex: "22D3EE")
    static let checkboxScheduled = Color(hex: "10B981")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
