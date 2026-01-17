import SwiftUI

struct SectionHeaderView: View {
    let section: TodoSection
    let completedCount: Int?
    let totalCount: Int?

    init(section: TodoSection, completedCount: Int? = nil, totalCount: Int? = nil) {
        self.section = section
        self.completedCount = completedCount
        self.totalCount = totalCount
    }

    private var headerColor: Color {
        switch section {
        case .today:
            return .todayHeader
        case .tomorrow:
            return .tomorrowHeader
        case .nextWeek:
            return .nextWeekHeader
        case .later:
            return .laterHeader
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(section.displayName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(headerColor)

            if let completed = completedCount, let total = totalCount, section == .today {
                Text("\(completed)/\(total)")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.cardBackground)
                    )
            }

            Spacer()
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
    }
}

#Preview {
    VStack {
        SectionHeaderView(section: .today, completedCount: 0, totalCount: 5)
        SectionHeaderView(section: .tomorrow)
        SectionHeaderView(section: .nextWeek)
        SectionHeaderView(section: .later)
    }
    .padding()
    .background(Color.appBackground)
}
