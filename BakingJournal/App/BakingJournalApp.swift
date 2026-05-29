import SwiftUI

@main
struct BakingJournalApp: App {
    @StateObject private var notificationService: BakingNotificationService
    @StateObject private var store: RecipeStore

    init() {
        let notificationService = BakingNotificationService()
        _notificationService = StateObject(wrappedValue: notificationService)
        _store = StateObject(wrappedValue: RecipeStore(notifications: notificationService))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notificationService)
        }
    }
}
