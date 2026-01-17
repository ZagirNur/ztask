import SwiftUI

@main
struct ZTaskApp: App {
    @StateObject private var todoStore = TodoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(todoStore)
                .preferredColorScheme(.dark)
        }
    }
}
