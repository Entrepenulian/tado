import SwiftUI

@main
struct LiquidTodoApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(store)
        } label: {
            Image(nsImage: MenuBarIcon.render(count: store.remainingCount, nudge: 0))
        }
        .menuBarExtraStyle(.window)
    }
}
