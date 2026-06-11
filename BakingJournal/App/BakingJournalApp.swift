import FirebaseCore
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        AppLogger.configureCrashContext()
        return true
    }
}

@main
struct BakingJournalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var languageSettings = AppLanguageSettings()
    @StateObject private var notificationService: BakingNotificationService
    @StateObject private var store: RecipeStore

    init() {
        let notificationService = BakingNotificationService()
        _notificationService = StateObject(wrappedValue: notificationService)
        _store = StateObject(wrappedValue: RecipeStore(notifications: notificationService))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootView()
                } else {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                }
            }
                .environmentObject(store)
                .environmentObject(notificationService)
                .environmentObject(languageSettings)
                .environment(\.locale, languageSettings.locale)
        }
    }
}
