import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @StateObject private var navigationController = AppNavigationController()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.brandBackground
                    .ignoresSafeArea()

                NavigationStack(path: $navigationController.path) {
                    HomeView()
                        .id(languageSettings.selectedLanguage.id)
                }
                .id(navigationController.resetToken)
                .tint(.brandPrimary)
                .environmentObject(navigationController)
                .environment(\.historySwipeSuppressionHandler) { isSuppressed in
                    navigationController.setHistorySwipeSuppressed(isSuppressed)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: RootTabBarMetrics.contentInsetHeight)
                }

                BakingTabBar(
                    selection: Binding(
                        get: { navigationController.selectedTab },
                        set: { navigationController.selectTab($0) }
                    )
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.keyboard, edges: .bottom)

                GlobalHistoryPanLayer(
                    width: proxy.size.width,
                    onChanged: navigationController.updateHistorySwipe,
                    onEnded: navigationController.finishHistorySwipe
                )
                .ignoresSafeArea()
            }
        }
    }
}

private enum RootTabBarMetrics {
    static let contentInsetHeight = BakingComponentMetrics.tabBarVisualHeight
}
