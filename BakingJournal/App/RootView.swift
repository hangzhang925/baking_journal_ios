import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: RecipeStore
    @StateObject private var navigationController = AppNavigationController()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.brandBackground
                    .ignoresSafeArea()

                NavigationStack(path: $navigationController.path) {
                    HomeView()
                }
                .id(navigationController.resetToken)
                .tint(.brandPrimary)
                .environmentObject(navigationController)
                .environment(\.historySwipeSuppressionHandler) { isSuppressed in
                    navigationController.setHistorySwipeSuppressed(isSuppressed)
                }
                .safeAreaInset(edge: .bottom) {
                    BakingTabBar(
                        selection: Binding(
                            get: { navigationController.selectedTab },
                            set: { navigationController.selectTab($0) }
                        ),
                        isStarterReminderDue: store.isStarterReminderDue
                    )
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }

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
