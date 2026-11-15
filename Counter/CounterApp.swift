import SwiftUI

@main
struct CounterApp: App {
    @StateObject private var store = CounterStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
