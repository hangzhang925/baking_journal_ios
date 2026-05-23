import SwiftUI
import UIKit

@MainActor
final class AppNavigationController: ObservableObject {
    @Published var resetToken = UUID()
    @Published var selectedTab: HomeTab = .home
    @Published var path: [AppRoute] = []
    @Published private(set) var isHistorySwipeSuppressed = false
    @Published private(set) var historyDragTranslation: CGFloat = 0

    private var backStack: [AppLocation] = []
    private var forwardStack: [AppLocation] = []
    private let historyLimit = 80
    private var historySuppressionCount = 0
    private var activeHistoryDirection: HistorySwipeDirection?
    private var isVerticalHistoryGesture = false

    func popToHome() {
        selectTab(.home)
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

enum HistorySwipeDirection {
    case back
    case forward
}

enum AppRoute: Hashable {
    case recipeSourcePicker
    case bakeRecipePicker
    case recipePreview
    case recipeWorkspace(RecipeWorkspaceStage)
    case cook
    case bakeRecordDetail(UUID)
}

struct AppLocation: Equatable {
    let tab: HomeTab
    let path: [AppRoute]
}

struct RootView: View {
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
                .offset(x: navigationController.historyDragTranslation)
                .scaleEffect(historyDragScale(width: proxy.size.width), anchor: .center)
                .shadow(color: Color.black.opacity(historyDragShadowOpacity(width: proxy.size.width)), radius: 18, x: 0, y: 8)
                .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.9), value: navigationController.historyDragTranslation == 0)

                GlobalHistoryPanLayer(
                    width: proxy.size.width,
                    onChanged: navigationController.updateHistorySwipe,
                    onEnded: navigationController.finishHistorySwipe
                )
                .ignoresSafeArea()
            }
        }
    }

    private func historyDragScale(width: CGFloat) -> CGFloat {
        let progress = min(abs(navigationController.historyDragTranslation) / max(width, 1), 1)
        return 1 - progress * 0.025
    }

    private func historyDragShadowOpacity(width: CGFloat) -> Double {
        let progress = min(abs(navigationController.historyDragTranslation) / max(width, 1), 1)
        return Double(progress) * 0.18
    }
}

struct GlobalHistoryPanLayer: UIViewRepresentable {
    let width: CGFloat
    let onChanged: (CGSize, CGPoint, CGFloat) -> Void
    let onEnded: (CGSize, CGPoint, CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = InstallerView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let uiView = uiView as? InstallerView else { return }
        uiView.coordinator = context.coordinator
        uiView.installRecognizerIfNeeded()
        context.coordinator.width = width
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(width: width, onChanged: onChanged, onEnded: onEnded)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var width: CGFloat
        var onChanged: (CGSize, CGPoint, CGFloat) -> Void
        var onEnded: (CGSize, CGPoint, CGFloat) -> Void

        init(
            width: CGFloat,
            onChanged: @escaping (CGSize, CGPoint, CGFloat) -> Void,
            onEnded: @escaping (CGSize, CGPoint, CGFloat) -> Void
        ) {
            self.width = width
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view)
            let velocity = recognizer.velocity(in: view)
            let translationSize = CGSize(width: translation.x, height: translation.y)

            switch recognizer.state {
            case .changed:
                onChanged(translationSize, velocity, width)
            case .ended, .cancelled, .failed:
                onEnded(translationSize, velocity, width)
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }

    final class InstallerView: UIView {
        weak var coordinator: Coordinator?
        private weak var installedView: UIView?
        private weak var recognizer: UIPanGestureRecognizer?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            installRecognizerIfNeeded()
        }

        func installRecognizerIfNeeded() {
            guard let window, let coordinator else { return }
            if installedView === window { return }

            if let recognizer, let installedView {
                installedView.removeGestureRecognizer(recognizer)
            }

            let recognizer = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = coordinator
            window.addGestureRecognizer(recognizer)
            self.recognizer = recognizer
            installedView = window
        }

        deinit {
            if let recognizer, let installedView {
                installedView.removeGestureRecognizer(recognizer)
            }
        }
    }
}

func dismissActiveKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension Color {
    static let brandBackground = adaptiveColor(
        light: RGB(0.99, 0.96, 0.90),
        dark: RGB(0.075, 0.062, 0.050)
    )
    static let brandSurface = adaptiveColor(
        light: RGB(1.0, 0.985, 0.955),
        dark: RGB(0.125, 0.105, 0.088)
    )
    static let brandPrimary = adaptiveColor(
        light: RGB(0.70, 0.26, 0.18),
        dark: RGB(0.94, 0.43, 0.32)
    )
    static let brandSage = adaptiveColor(
        light: RGB(0.34, 0.44, 0.30),
        dark: RGB(0.60, 0.72, 0.50)
    )
    static let brandSea = adaptiveColor(
        light: RGB(0.09, 0.46, 0.62),
        dark: RGB(0.34, 0.70, 0.82)
    )
    static let brandText = adaptiveColor(
        light: RGB(0.08, 0.07, 0.055),
        dark: RGB(0.96, 0.91, 0.84)
    )
    static let brandSecondaryText = adaptiveColor(
        light: RGB(0.46, 0.43, 0.38),
        dark: RGB(0.72, 0.67, 0.59)
    )
    static let waterSurface = adaptiveColor(
        light: RGB(0.86, 0.96, 0.98),
        dark: RGB(0.08, 0.18, 0.22)
    )
    static let waterSurfaceStrong = adaptiveColor(
        light: RGB(0.74, 0.91, 0.96),
        dark: RGB(0.11, 0.28, 0.34)
    )
    static let waterText = adaptiveColor(
        light: RGB(0.04, 0.34, 0.49),
        dark: RGB(0.46, 0.80, 0.90)
    )

    static let flourSurface = adaptiveColor(light: RGB(0.95, 0.97, 0.91), dark: RGB(0.12, 0.16, 0.105))
    static let flourIconSurface = adaptiveColor(light: RGB(0.89, 0.94, 0.84), dark: RGB(0.18, 0.25, 0.15))
    static let starterTint = adaptiveColor(light: RGB(0.10, 0.42, 0.56), dark: RGB(0.42, 0.76, 0.86))
    static let starterSurface = adaptiveColor(light: RGB(0.89, 0.96, 0.98), dark: RGB(0.08, 0.17, 0.21))
    static let starterIconSurface = adaptiveColor(light: RGB(0.79, 0.91, 0.95), dark: RGB(0.11, 0.28, 0.34))
    static let saltTint = adaptiveColor(light: RGB(0.44, 0.47, 0.56), dark: RGB(0.77, 0.80, 0.90))
    static let saltSurface = adaptiveColor(light: RGB(0.95, 0.96, 0.99), dark: RGB(0.12, 0.13, 0.17))
    static let saltIconSurface = adaptiveColor(light: RGB(0.88, 0.90, 0.96), dark: RGB(0.18, 0.20, 0.27))
    static let butterTint = adaptiveColor(light: RGB(0.47, 0.49, 0.29), dark: RGB(0.82, 0.78, 0.46))
    static let butterSurface = adaptiveColor(light: RGB(0.99, 0.96, 0.87), dark: RGB(0.18, 0.15, 0.09))
    static let butterIconSurface = adaptiveColor(light: RGB(0.97, 0.92, 0.72), dark: RGB(0.27, 0.22, 0.10))
    static let yeastTint = adaptiveColor(light: RGB(0.53, 0.46, 0.23), dark: RGB(0.86, 0.73, 0.40))
    static let yeastSurface = adaptiveColor(light: RGB(0.98, 0.94, 0.86), dark: RGB(0.18, 0.13, 0.08))
    static let yeastIconSurface = adaptiveColor(light: RGB(0.96, 0.89, 0.74), dark: RGB(0.27, 0.20, 0.11))
    static let eggTint = adaptiveColor(light: RGB(0.66, 0.39, 0.18), dark: RGB(0.94, 0.62, 0.34))
    static let eggSurface = adaptiveColor(light: RGB(0.99, 0.92, 0.84), dark: RGB(0.20, 0.12, 0.075))
    static let eggIconSurface = adaptiveColor(light: RGB(0.98, 0.86, 0.73), dark: RGB(0.31, 0.18, 0.10))
    static let sugarTint = adaptiveColor(light: RGB(0.39, 0.52, 0.33), dark: RGB(0.66, 0.80, 0.55))
    static let sugarSurface = adaptiveColor(light: RGB(0.94, 0.97, 0.91), dark: RGB(0.12, 0.16, 0.10))
    static let sugarIconSurface = adaptiveColor(light: RGB(0.88, 0.93, 0.83), dark: RGB(0.18, 0.25, 0.14))
    static let otherTint = adaptiveColor(light: RGB(0.43, 0.49, 0.34), dark: RGB(0.72, 0.78, 0.56))
    static let otherSurface = adaptiveColor(light: RGB(0.95, 0.96, 0.89), dark: RGB(0.15, 0.16, 0.10))
    static let otherIconSurface = adaptiveColor(light: RGB(0.89, 0.92, 0.82), dark: RGB(0.22, 0.24, 0.14))
    static let mutedSurface = adaptiveColor(light: RGB(0.0, 0.0, 0.0, alpha: 0.06), dark: RGB(1.0, 1.0, 1.0, alpha: 0.08))
    static let mutedIconSurface = adaptiveColor(light: RGB(1.0, 1.0, 1.0, alpha: 0.65), dark: RGB(1.0, 1.0, 1.0, alpha: 0.10))

    private struct RGB {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    private static func adaptiveColor(light: RGB, dark: RGB) -> Color {
        Color(UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: color.alpha
            )
        })
    }
}

struct MetricStrip: View {
    let summary: RecipeSummary

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                MetricCell(title: "面团", value: BakingFormat.weight(summary.doughWeight))
                MetricCell(title: "面粉", value: BakingFormat.weight(summary.flourWeight))
                MetricCell(
                    title: "含水",
                    value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                    accent: .waterText,
                    background: .waterSurface
                )
            }
        }
        .padding(BakingSpace.lg)
        .bakingCard(radius: BakingRadius.card, stroke: .clear)
    }
}

private struct MetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandPrimary
    var background: Color = .clear

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(accent)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage)
    }
}

struct BakingDropdownTrigger: View {
    let title: String
    var tint: Color = .brandText
    var background: Color = Color.brandBackground.opacity(0.9)

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(background)
        .clipShape(Capsule())
    }
}

struct BakingDropdownPopover<Content: View>: View {
    var width: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content()
        }
        .padding(8)
        .frame(width: width)
        .presentationCompactAdaptation(.popover)
        .background(
            RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                .fill(Color.brandSurface.opacity(0.98))
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
    }
}

struct BakingDropdownRow<Leading: View>: View {
    let title: String
    var isSelected: Bool = false
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 10) {
            leading
                .frame(width: 20, height: 20)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.brandText)

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct RecipeWorkflowBadge: View {
    let state: RecipeWorkflowState

    var body: some View {
        Text(state.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 0.6)
            }
    }

    private var foregroundColor: Color {
        switch state {
        case .draft:
            return .brandPrimary
        case .ready:
            return .brandSage
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .draft:
            return Color.brandPrimary.opacity(0.11)
        case .ready:
            return Color.brandSage.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch state {
        case .draft:
            return Color.brandPrimary.opacity(0.18)
        case .ready:
            return Color.brandSage.opacity(0.20)
        }
    }
}

struct MaterialPalette {
    let tint: Color
    let text: Color
    let surface: Color
    let iconSurface: Color
    let stroke: Color
    let mutedSurface: Color
    let mutedIconSurface: Color
}

extension RecipeItem {
    var materialPalette: MaterialPalette {
        switch tag {
        case .water:
            return MaterialPalette(
                tint: .waterText,
                text: .waterText,
                surface: .waterSurface.opacity(0.92),
                iconSurface: .waterSurfaceStrong.opacity(0.56),
                stroke: .brandSea.opacity(0.16),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .flour:
            return MaterialPalette(
                tint: .brandSage,
                text: .brandText,
                surface: .flourSurface,
                iconSurface: .flourIconSurface,
                stroke: Color.brandSage.opacity(0.15),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .starter:
            return MaterialPalette(
                tint: .starterTint,
                text: .brandText,
                surface: .starterSurface,
                iconSurface: .starterIconSurface,
                stroke: Color.starterTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .salt:
            return MaterialPalette(
                tint: .saltTint,
                text: .brandText,
                surface: .saltSurface,
                iconSurface: .saltIconSurface,
                stroke: Color.saltTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .butter:
            return MaterialPalette(
                tint: .butterTint,
                text: .brandText,
                surface: .butterSurface,
                iconSurface: .butterIconSurface,
                stroke: Color.butterTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .yeast:
            return MaterialPalette(
                tint: .yeastTint,
                text: .brandText,
                surface: .yeastSurface,
                iconSurface: .yeastIconSurface,
                stroke: Color.yeastTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .egg:
            return MaterialPalette(
                tint: .eggTint,
                text: .brandText,
                surface: .eggSurface,
                iconSurface: .eggIconSurface,
                stroke: Color.eggTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .sugar:
            return MaterialPalette(
                tint: .sugarTint,
                text: .brandText,
                surface: .sugarSurface,
                iconSurface: .sugarIconSurface,
                stroke: Color.sugarTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        case .other:
            return MaterialPalette(
                tint: .otherTint,
                text: .brandText,
                surface: .otherSurface,
                iconSurface: .otherIconSurface,
                stroke: Color.otherTint.opacity(0.14),
                mutedSurface: .mutedSurface,
                mutedIconSurface: .mutedIconSurface
            )
        }
    }
}
