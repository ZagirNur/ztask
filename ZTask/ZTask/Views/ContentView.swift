import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todoStore: TodoStore
    @State private var showMenu = false
    @State private var showAddTodo = false
    @State private var showCompletedTasks = false

    // Drag state
    @State private var draggingItem: Todo?
    @State private var dragOffset: CGSize = .zero
    @State private var draggingFrame: CGRect = .zero
    @State private var itemFrames: [UUID: CGRect] = [:]
    @State private var sectionFrames: [TodoSection: CGRect] = [:]
    @State private var targetSection: TodoSection?
    @State private var targetIndex: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HeaderView(showMenu: $showMenu)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            DragSection(
                                section: .today,
                                todos: todoStore.todayTodos,
                                showDayLabel: false,
                                showCounter: true,
                                totalCount: todoStore.totalTodayCount,
                                draggingItem: $draggingItem,
                                dragOffset: $dragOffset,
                                draggingFrame: $draggingFrame,
                                itemFrames: $itemFrames,
                                sectionFrames: $sectionFrames,
                                targetSection: $targetSection,
                                targetIndex: $targetIndex,
                                onToggle: { todoStore.toggleComplete($0) },
                                onDrop: { todo, section in todoStore.moveTodo(todo, to: section) }
                            )

                            DragSection(
                                section: .tomorrow,
                                todos: todoStore.tomorrowTodos,
                                showDayLabel: false,
                                draggingItem: $draggingItem,
                                dragOffset: $dragOffset,
                                draggingFrame: $draggingFrame,
                                itemFrames: $itemFrames,
                                sectionFrames: $sectionFrames,
                                targetSection: $targetSection,
                                targetIndex: $targetIndex,
                                onToggle: { todoStore.toggleComplete($0) },
                                onDrop: { todo, section in todoStore.moveTodo(todo, to: section) }
                            )

                            DragSection(
                                section: .nextWeek,
                                todos: todoStore.nextWeekTodos,
                                showDayLabel: true,
                                draggingItem: $draggingItem,
                                dragOffset: $dragOffset,
                                draggingFrame: $draggingFrame,
                                itemFrames: $itemFrames,
                                sectionFrames: $sectionFrames,
                                targetSection: $targetSection,
                                targetIndex: $targetIndex,
                                onToggle: { todoStore.toggleComplete($0) },
                                onDrop: { todo, section in todoStore.moveTodo(todo, to: section) }
                            )

                            DragSection(
                                section: .later,
                                todos: todoStore.laterTodos,
                                showDayLabel: false,
                                draggingItem: $draggingItem,
                                dragOffset: $dragOffset,
                                draggingFrame: $draggingFrame,
                                itemFrames: $itemFrames,
                                sectionFrames: $sectionFrames,
                                targetSection: $targetSection,
                                targetIndex: $targetIndex,
                                onToggle: { todoStore.toggleComplete($0) },
                                onDrop: { todo, section in todoStore.moveTodo(todo, to: section) }
                            )

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .coordinateSpace(name: "scroll")
                    }
                }

                // Floating drag preview
                if let item = draggingItem {
                    DragPreviewOverlay(
                        todo: item,
                        frame: draggingFrame,
                        offset: dragOffset
                    )
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

// MARK: - Drag Section

struct DragSection: View {
    let section: TodoSection
    let todos: [Todo]
    let showDayLabel: Bool
    var showCounter: Bool = false
    var totalCount: Int = 0

    @Binding var draggingItem: Todo?
    @Binding var dragOffset: CGSize
    @Binding var draggingFrame: CGRect
    @Binding var itemFrames: [UUID: CGRect]
    @Binding var sectionFrames: [TodoSection: CGRect]
    @Binding var targetSection: TodoSection?
    @Binding var targetIndex: Int?

    let onToggle: (Todo) -> Void
    let onDrop: (Todo, TodoSection) -> Void

    private var headerColor: Color {
        switch section {
        case .today: return .todayHeader
        case .tomorrow: return .tomorrowHeader
        case .nextWeek: return .nextWeekHeader
        case .later: return .laterHeader
        }
    }

    private var isTargeted: Bool {
        targetSection == section
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
            ForEach(Array(todos.enumerated()), id: \.element.id) { index, todo in
                let isDragging = draggingItem?.id == todo.id
                let showPlaceholderBefore = isTargeted && targetIndex == index && draggingItem?.id != todo.id

                VStack(spacing: 0) {
                    if showPlaceholderBefore {
                        DropPlaceholder()
                    }

                    if !isDragging {
                        DraggableRow(
                            todo: todo,
                            showDayLabel: showDayLabel,
                            onToggle: { onToggle(todo) },
                            onDragStart: { frame in
                                draggingFrame = frame
                                draggingItem = todo
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            },
                            onDragChange: { offset, currentFrame in
                                dragOffset = offset
                                updateTargetPosition(currentY: currentFrame.midY + offset.height)
                            },
                            onDragEnd: {
                                if let target = targetSection {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    onDrop(todo, target)
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    draggingItem = nil
                                    dragOffset = .zero
                                    targetSection = nil
                                    targetIndex = nil
                                }
                            }
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    itemFrames[todo.id] = geo.frame(in: .named("scroll"))
                                }
                                .onChange(of: geo.frame(in: .named("scroll"))) { _, newFrame in
                                    itemFrames[todo.id] = newFrame
                                }
                            }
                        )
                    }
                }
            }

            // Placeholder at end of section
            if isTargeted && targetIndex == todos.count {
                DropPlaceholder()
            }

            // Empty section drop zone
            if todos.isEmpty || (todos.count == 1 && draggingItem?.id == todos.first?.id) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50)
            }
        }
        .padding(8)
        .background(
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? Color.accentCyan.opacity(0.08) : Color.clear)
                    .onAppear {
                        sectionFrames[section] = geo.frame(in: .named("scroll"))
                    }
                    .onChange(of: geo.frame(in: .named("scroll"))) { _, newFrame in
                        sectionFrames[section] = newFrame
                    }
            }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: targetIndex)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: targetSection)
    }

    private func updateTargetPosition(currentY: CGFloat) {
        // Find which section we're over
        var newSection: TodoSection?
        for (sec, frame) in sectionFrames {
            if currentY >= frame.minY && currentY <= frame.maxY {
                newSection = sec
                break
            }
        }

        // If no section found, find closest
        if newSection == nil {
            var closestSection: TodoSection?
            var closestDistance: CGFloat = .infinity
            for (sec, frame) in sectionFrames {
                let distance = min(abs(currentY - frame.minY), abs(currentY - frame.maxY))
                if distance < closestDistance {
                    closestDistance = distance
                    closestSection = sec
                }
            }
            newSection = closestSection
        }

        if newSection != targetSection {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            targetSection = newSection
        }

        // Find index within section
        guard let section = newSection else { return }

        let sectionTodos: [Todo]
        switch section {
        case .today:
            sectionTodos = todos // This won't work correctly across sections
        case .tomorrow, .nextWeek, .later:
            sectionTodos = todos
        }

        // Calculate index based on Y position
        var newIndex = 0
        for todo in sectionTodos where draggingItem?.id != todo.id {
            if let frame = itemFrames[todo.id] {
                if currentY > frame.midY {
                    newIndex += 1
                }
            }
        }

        if newIndex != targetIndex {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
            targetIndex = newIndex
        }
    }
}

// MARK: - Draggable Row

struct DraggableRow: View {
    let todo: Todo
    let showDayLabel: Bool
    let onToggle: () -> Void
    let onDragStart: (CGRect) -> Void
    let onDragChange: (CGSize, CGRect) -> Void
    let onDragEnd: () -> Void

    @State private var isDragging = false
    @State private var rowFrame: CGRect = .zero

    private var isScheduled: Bool {
        todo.dueDate?.isInNextWeek ?? false
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
                        .foregroundColor(.textPrimary)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    rowFrame = geo.frame(in: .global)
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    rowFrame = newFrame
                }
            }
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture(coordinateSpace: .global))
                .onChanged { value in
                    switch value {
                    case .first(true):
                        // Long press recognized
                        break
                    case .second(true, let drag):
                        if !isDragging {
                            isDragging = true
                            onDragStart(rowFrame)
                        }
                        if let drag = drag {
                            onDragChange(drag.translation, rowFrame)
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    onDragEnd()
                }
        )
    }
}

// MARK: - Drag Preview Overlay

struct DragPreviewOverlay: View {
    let todo: Todo
    let frame: CGRect
    let offset: CGSize

    private var isScheduled: Bool {
        todo.dueDate?.isInNextWeek ?? false
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Checkbox visual
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isScheduled ? Color.accentCyan : Color.textSecondary, lineWidth: 2)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 16))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(width: frame.width, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .position(
            x: frame.midX + offset.width,
            y: frame.midY + offset.height
        )
        .ignoresSafeArea()
    }
}

// MARK: - Drop Placeholder

struct DropPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(Color.accentCyan.opacity(0.1))
            .frame(height: 56)
            .cornerRadius(8)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
    }
}

#Preview {
    ContentView()
        .environmentObject(TodoStore())
}
