import SwiftUI

struct CheckboxView: View {
    let isChecked: Bool
    let isScheduled: Bool
    let action: () -> Void

    init(isChecked: Bool, isScheduled: Bool = false, action: @escaping () -> Void) {
        self.isChecked = isChecked
        self.isScheduled = isScheduled
        self.action = action
    }

    private var checkboxColor: Color {
        isScheduled ? .checkboxScheduled : .checkboxDefault
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(checkboxColor, lineWidth: 2)
                    .frame(width: 22, height: 22)

                if isChecked {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(checkboxColor)
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appBackground)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        CheckboxView(isChecked: false, action: {})
        CheckboxView(isChecked: true, action: {})
        CheckboxView(isChecked: false, isScheduled: true, action: {})
        CheckboxView(isChecked: true, isScheduled: true, action: {})
    }
    .padding()
    .background(Color.appBackground)
}
