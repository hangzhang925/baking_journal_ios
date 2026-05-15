import SwiftUI

@main
struct BakingJournalApp: App {
    @StateObject private var store = RecipeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
