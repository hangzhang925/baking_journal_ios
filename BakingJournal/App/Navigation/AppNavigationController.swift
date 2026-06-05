import SwiftUI

@MainActor
final class AppNavigationController: ObservableObject {
    @Published var resetToken = UUID()
    @Published var selectedTab: HomeTab = .formula
    @Published var path: [AppRoute] = []
    @Published private(set) var isHistorySwipeSuppressed = false
    @Published private(set) var historyDragTranslation: CGFloat = 0

    private var backStack: [AppLocation] = []
    private var forwardStack: [AppLocation] = []
    private let historyLimit = 80
    private var historySuppressionCount = 0
    private var activeHistoryDirection: HistorySwipeDirection?
    private var isVerticalHistoryGesture = false

    var canGoBack: Bool {
        !backStack.isEmpty
    }

    func popToHome() {
        selectTab(.formula)
    }

    func selectTab(_ tab: HomeTab) {
        guard selectedTab != tab || !path.isEmpty else { return }
        recordCurrentLocation()
        selectedTab = tab
        path = []
        forwardStack.removeAll()
    }

    func push(_ route: AppRoute) {
        recordCurrentLocation()
        path.append(route)
        forwardStack.removeAll()
    }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentLocation)
        restore(previous)
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentLocation)
        restore(next)
    }

    func updateHistorySwipe(translation: CGSize, velocity: CGPoint, containerWidth: CGFloat) {
        guard !isHistorySwipeSuppressed else { return }
        guard !isVerticalHistoryGesture else { return }

        if activeHistoryDirection == nil {
            if BakingGesturePolicy.isVerticalScrollIntent(translation) {
                isVerticalHistoryGesture = true
                return
            }

            guard BakingGesturePolicy.isHorizontalIntent(
                translation,
                minimumDistance: BakingGesturePolicy.historySwipeActivationDistance,
                ratio: BakingGesturePolicy.historySwipeIntentRatio
            ) else { return }

            let direction: HistorySwipeDirection = translation.width > 0 ? .back : .forward
            guard canNavigate(direction) else { return }
            activeHistoryDirection = direction
        }

        guard let activeHistoryDirection else { return }
        let width = max(containerWidth, 1)
        let rawTranslation = translation.width
        let directionalTranslation: CGFloat
        switch activeHistoryDirection {
        case .back:
            directionalTranslation = max(0, rawTranslation)
        case .forward:
            directionalTranslation = min(0, rawTranslation)
        }
        let capped = min(abs(directionalTranslation), width * 0.72)
        historyDragTranslation = activeHistoryDirection == .back ? capped : -capped
    }

    func finishHistorySwipe(translation: CGSize, velocity: CGPoint, containerWidth: CGFloat) {
        defer {
            isVerticalHistoryGesture = false
            activeHistoryDirection = nil
        }

        guard let activeHistoryDirection else {
            historyDragTranslation = 0
            return
        }

        let width = max(containerWidth, 1)
        let progress = min(abs(historyDragTranslation) / width, 1)
        let projected = translation.width + velocity.x * 0.18
        let shouldCommit = progress > 0.28 || abs(projected) > width * 0.36 || abs(velocity.x) > 720

        guard shouldCommit else {
            withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.86)) {
                historyDragTranslation = 0
            }
            return
        }

        withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.9)) {
            historyDragTranslation = activeHistoryDirection == .back ? width : -width
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.08))
            switch activeHistoryDirection {
            case .back:
                goBack()
            case .forward:
                goForward()
            }
            historyDragTranslation = activeHistoryDirection == .back ? -width * 0.22 : width * 0.22
            withAnimation(.interactiveSpring(response: 0.24, dampingFraction: 0.88)) {
                historyDragTranslation = 0
            }
        }
    }

    func setHistorySwipeSuppressed(_ isSuppressed: Bool) {
        if isSuppressed {
            historySuppressionCount += 1
            isHistorySwipeSuppressed = true
            return
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.18))
            historySuppressionCount = max(0, historySuppressionCount - 1)
            isHistorySwipeSuppressed = historySuppressionCount > 0
        }
    }

    private var currentLocation: AppLocation {
        AppLocation(tab: selectedTab, path: path)
    }

    private func recordCurrentLocation() {
        let location = currentLocation
        guard backStack.last != location else { return }
        backStack.append(location)
        if backStack.count > historyLimit {
            backStack.removeFirst(backStack.count - historyLimit)
        }
    }

    private func restore(_ location: AppLocation) {
        selectedTab = location.tab
        path = location.path
    }

    private func canNavigate(_ direction: HistorySwipeDirection) -> Bool {
        switch direction {
        case .back:
            !backStack.isEmpty
        case .forward:
            !forwardStack.isEmpty
        }
    }
}
