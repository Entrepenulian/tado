import SwiftUI

@main
struct LiquidTodoApp: App {
    @StateObject private var store = TodoStore()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(store)
        } label: {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: "checklist")
                if store.remainingCount > 0 {
                    Text(store.remainingCount, format: .number)
                        .monospacedDigit()
                        .alignmentGuide(VerticalAlignment.center) { d in
                            d[VerticalAlignment.center] - 5
                        }
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
