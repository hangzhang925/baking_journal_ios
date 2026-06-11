import SwiftUI
import UIKit
import Photos

private enum RecipePreviewTypography {
    static let title: Font = BakingTypography.appPrimaryText
    static let titleUIFont = UIFontMetrics(forTextStyle: .subheadline).scaledFont(
        for: UIFont.systemFont(ofSize: 15, weight: .semibold)
    )
    static let sectionHeading: Font = .headline.weight(.semibold)
    static let statusLabel: Font = BakingTypography.appPrimaryText
    static let metricLabel: Font = BakingTypography.appSecondaryText
    static let metricValue: Font = BakingTypography.appPrimaryText.monospacedDigit().weight(.bold)
    static let tablePrimary: Font = BakingTypography.appPrimaryText
    static let tableSecondary: Font = BakingTypography.appSecondaryText
    static let tableNumber: Font = BakingTypography.appPrimaryText.monospacedDigit().weight(.bold)
    static let tableUnit: Font = BakingTypography.appSecondaryText.weight(.bold)
}

enum RecipePreviewToolbarMode {
    case standard
    case embedded
    case referenceSheet
}

struct RecipePreviewView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var toolbarMode: RecipePreviewToolbarMode = .standard
    @State private var exportError: String?
    @State private var exportSuccessMessage: String?
    @State private var showingTextTutorial = false
    @State private var plannedStartTime = Date()

    var body: some View {
        VStack(spacing: 0) {
            if showsToolbar {
                previewTopActionRow
            }

            ScrollView {
                previewStack
            }
            .background(Color.brandBackground)
            .onTapGesture {
                dismissActiveKeyboard()
            }
        }
        .background(Color.brandBackground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingTextTutorial) {
            RecipePreviewTextTutorialSheet(text: textTutorial)
        }
        .alert(BakingTerms.recipePreviewExportFailed, isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) {
                exportError = nil
            }
        } message: {
            Text(exportError ?? "")
        }
        .alert(BakingTerms.recipePreviewSaveImageSucceeded, isPresented: Binding(
            get: { exportSuccessMessage != nil },
            set: { if !$0 { exportSuccessMessage = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) {
                exportSuccessMessage = nil
            }
        } message: {
            Text(exportSuccessMessage ?? "")
        }
    }

    private var previewTopActionRow: some View {
        BakingTopActionRow(
            leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            },
            trailing: {
                HStack(spacing: BakingSpace.xs) {
                    Menu {
                        Button {
                            saveLongImage()
                        } label: {
                            Label(BakingTerms.saveAsImage, systemImage: "photo")
                        }

                        Button {
                            showingTextTutorial = true
                        } label: {
                            Label(BakingTerms.generateTextTutorial, systemImage: "doc.text")
                        }
                    } label: {
                        BakingIconButtonLabel(
                            icon: .share,
                            role: .secondary
                        )
                    }
                    .buttonStyle(BakingPressFeedbackButtonStyle())
                    .accessibilityLabel(BakingTerms.share)

                    if toolbarMode != .referenceSheet {
                        BakingIconButton(
                            icon: .start,
                            accessibilityLabel: store.isReadyToBake ? BakingTerms.startBake : BakingTerms.viewIncompleteSteps,
                            role: .primary
                        ) {
                            if store.isReadyToBake {
                                presentCook()
                            } else {
                                presentWorkspace(.steps)
                            }
                        }

                        BakingIconButton(
                            icon: .edit,
                            accessibilityLabel: BakingTerms.editRecipe
                        ) {
                            presentWorkspace(.formula)
                        }
                    }
                }
            }
        )
    }

    private func presentCook() {
        guard store.startNewBake() else { return }
        navigationController.selectTab(.history)
        navigationController.push(.cook)
    }

    private func presentWorkspace(_ stage: RecipeWorkspaceStage) {
        navigationController.push(.recipeWorkspace(stage))
    }

    private var showsToolbar: Bool {
        toolbarMode == .standard
    }

    private var previewStack: some View {
        LazyVStack(spacing: BakingSpace.lg) {
            if toolbarMode != .referenceSheet {
                summaryCard
            }
            timePlanCard
            if store.currentRecipeKind.showsPreviewSummaryMetrics {
                metricsCard
            }
            ingredientsCard
            stepsCard
        }
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingLayout.contentTopInset)
        .padding(.bottom, previewBottomClearance)
    }

    private var previewBottomClearance: CGFloat {
        toolbarMode == .referenceSheet ? BakingSpace.xxl : BakingComponentMetrics.tabBarScrollContentClearance
    }

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: BakingSpace.xxl) {
            RecipePreviewTitleBlock(
                recipeName: Binding(
                    get: { store.recipeName },
                    set: { store.recipeName = $0 }
                )
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            RecipeWorkflowStateButton()
                .frame(width: BakingComponentMetrics.statusCapsuleWidth, alignment: .trailing)
        }
        .frame(minHeight: BakingTouchTarget.primaryAction)
    }

    private var timePlanCard: some View {
        PreviewTimePlanner(
            totalDuration: store.totalStepMinutes(),
            startTime: $plannedStartTime
        )
        .padding(.horizontal, BakingComponentMetrics.metricStripHorizontalPadding)
        .padding(.vertical, BakingComponentMetrics.metricStripVerticalPadding)
        .bakingCard()
        .previewDismissesKeyboardOnTap()
    }

    private var metricsCard: some View {
        PreviewMetricsOverview(
            summary: store.summary,
            items: store.items,
            flourContribution: store.flourContribution,
            waterContribution: store.waterContribution,
            showsHydration: store.currentRecipeKind.usesHydrationSystem
        )
            .padding(.horizontal, BakingComponentMetrics.metricStripHorizontalPadding)
            .padding(.vertical, BakingComponentMetrics.metricStripVerticalPadding)
            .bakingCard()
            .previewDismissesKeyboardOnTap()
    }

    private var previewShareContent: RecipePreviewShareContent {
        RecipePreviewShareContent(store: store)
    }

    private var ingredientsCard: some View {
        BakingSectionCard(title: BakingTerms.recipePreviewIngredients) {
            PreviewIngredientList(ingredients: previewIngredientSnapshots)
                .environment(\.showsPreviewIngredientPercentages, store.currentRecipeKind.usesBakerPercentageSystem)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .previewDismissesKeyboardOnTap()
    }

    private var stepsCard: some View {
        BakingSectionCard(title: BakingTerms.recipePreviewSteps) {
            PreviewStepList(steps: previewStepSnapshots)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .previewDismissesKeyboardOnTap()
    }

    private var previewIngredientSnapshots: [PreviewIngredientSnapshot] {
        previewShareContent.ingredients
    }

    private var previewStepSnapshots: [PreviewStepSnapshot] {
        previewShareContent.steps
    }

    private var previewItems: [RecipeItem] {
        store.items.sorted { lhs, rhs in
            previewSortRank(for: lhs) < previewSortRank(for: rhs)
        }
    }

    private func previewSortRank(for item: RecipeItem) -> Int {
        switch item.category {
        case .flour:
            return 0
        case .starter:
            return 1
        case .basic:
            switch item.tag {
            case .water: return 2
            case .salt: return 3
            case .egg: return 4
            case .butter: return 5
            case .cream: return 6
            case .yeast: return 7
            case .sugar: return 8
            default: return 9
            }
        case .other:
            return 10
        }
    }

    private func stepItemsText(for step: JournalStep) -> String? {
        let names = store.allocatedItems(for: step).map { allocatedItem in
            let item = allocatedItem.item
            return "\(item.name) \(BakingFormat.weight(allocatedItem.weight, gramPrecision: item.tag == .yeast ? 1 : 0))"
        }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " · ")
    }

    private func temperatureText(for step: JournalStep) -> String? {
        guard let temperature = step.temperature else { return nil }
        return "\(BakingFormat.number(temperature, precision: 0))\(step.temperatureUnit?.rawValue ?? "C")"
    }

    private func previewNotes(for step: JournalStep) -> String? {
        let trimmed = step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func secondaryDetail(for item: RecipeItem) -> String? {
        if item.category == .starter {
            return BakingTerms.recipePreviewStarterDetail(
                flour: BakingFormat.weight(store.flourContribution(item)),
                water: BakingFormat.weight(store.waterContribution(item))
            )
        }
        if item.tag == .egg {
            return BakingTerms.recipePreviewEggDetail(
                count: BakingFormat.number(1, precision: 0),
                water: BakingFormat.weight(store.waterContribution(item))
            )
        }
        if item.tag == .water {
            return nil
        }
        return nil
    }

    private func percentForPreview(_ item: RecipeItem) -> Double {
        let flourWeight = store.summary.flourWeight
        guard flourWeight > 0 else { return 0 }
        return item.weight / flourWeight * 100
    }

    private var textTutorial: String {
        previewShareContent.textTutorial
    }

    private func saveLongImage() {
        guard let image = renderLongImage() else { return }
        saveImageToPhotoLibrary(image)
    }

    private func renderLongImage() -> UIImage? {
        guard let image = previewShareContent.renderLongImage() else {
            exportError = BakingTerms.recipePreviewExportRenderFailed
            return nil
        }

        return image
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            performPhotoLibrarySave(image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                Task { @MainActor in
                    if status == .authorized || status == .limited {
                        performPhotoLibrarySave(image)
                    } else {
                        exportError = BakingTerms.recipePreviewPhotoAccessDenied
                    }
                }
            }
        case .denied, .restricted:
            exportError = BakingTerms.recipePreviewPhotoAccessDenied
        @unknown default:
            exportError = BakingTerms.recipePreviewPhotoAccessDenied
        }
    }

    private func performPhotoLibrarySave(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            Task { @MainActor in
                if success {
                    exportSuccessMessage = BakingTerms.recipePreviewSaveImageSucceededMessage
                } else {
                    exportError = error?.localizedDescription ?? BakingTerms.recipePreviewSaveImageFailed
                }
            }
        }
    }
}

private struct RecipePreviewTitleBlock: View {
    @Binding var recipeName: String
    @State private var isFocused = false

    var body: some View {
        BakingInlineTextField(
            text: $recipeName,
            placeholder: BakingTerms.recipeNamePromptLabel,
            isFocused: $isFocused,
            font: RecipePreviewTypography.titleUIFont,
            maxLength: 24
        )
        .bakingFittedInputField(
            width: BakingComponentMetrics.compactRecipeTitleInputFieldWidth,
            height: BakingComponentMetrics.compactInputFieldHeight,
            alignment: .leading,
            kind: isFocused ? .focused : .field
        )
        .frame(minHeight: BakingTouchTarget.primaryAction, alignment: .leading)
    }
}

private struct RecipePreviewTitleText: View {
    let currentRecipeDisplayName: String

    var body: some View {
        Text(currentRecipeDisplayName)
            .font(RecipePreviewTypography.title)
            .foregroundStyle(Color.brandText)
            .lineLimit(2)
            .frame(minHeight: BakingTouchTarget.primaryAction, alignment: .center)
    }
}

private struct PreviewMetricsOverview: View {
    let summary: RecipeSummary
    var items: [RecipeItem] = []
    var flourContribution: ((RecipeItem) -> Double)?
    var waterContribution: ((RecipeItem) -> Double)?
    var showsHydration = true

    var body: some View {
        HStack(spacing: 0) {
            PreviewMetricColumn(title: BakingTerms.formulaMetricDough, value: BakingFormat.weight(summary.doughWeight))
            previewColumnDivider
            PreviewMetricColumn(title: BakingTerms.formulaMetricFlour, value: BakingFormat.weight(summary.flourWeight))
            if showsHydration {
                previewColumnDivider
                PreviewMetricColumn(
                    title: BakingTerms.formulaMetricHydration,
                    value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                    hydrationReceipt: hydrationReceipt
                )
            }
        }
    }

    private var hydrationReceipt: HydrationReceipt? {
        HydrationReceipt(
            items: items,
            summary: summary,
            flourContribution: flourContribution,
            waterContribution: waterContribution
        )
    }

    private var previewColumnDivider: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(
                width: BakingComponentMetrics.metricStripDividerWidth,
                height: BakingComponentMetrics.metricStripDividerHeight
            )
            .padding(.horizontal, 6)
    }
}

private struct PreviewMetricColumn: View {
    let title: String
    let value: String
    var accent: Color = .brandText
    var titleTint: Color = .brandSecondaryText
    var hydrationReceipt: HydrationReceipt?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(title)
                    .font(RecipePreviewTypography.metricLabel)
                    .foregroundStyle(titleTint)

                if let hydrationReceipt {
                    HydrationReceiptInfoButton(receipt: hydrationReceipt, iconSize: 15)
                }
            }

            Text(value)
                .font(RecipePreviewTypography.metricValue)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: BakingComponentMetrics.metricStripCellMinHeight, alignment: .leading)
    }
}

private struct PreviewTimePlanner: View {
    let totalDuration: Double
    @Binding var startTime: Date
    @State private var showingStartTimePicker = false

    var body: some View {
        HStack(spacing: 0) {
            startTimeButton

            previewColumnDivider

            timePill(
                title: BakingTerms.recipePreviewEstimatedDuration,
                value: BakingFormat.duration(minutes: totalDuration)
            )

            previewColumnDivider

            timePill(
                title: BakingTerms.cookFinishAt,
                value: finishTimeText
            )
        }
    }

    private var startTimeButton: some View {
        Button {
            showingStartTimePicker = true
        } label: {
            timePill(
                titleContent: {
                    HStack(spacing: BakingSpace.xs) {
                        BakingIconView(icon: .timer, size: 13, color: .brandPrimary)

                        Text(BakingTerms.recipePreviewStartTime)
                            .font(RecipePreviewTypography.metricLabel)
                            .foregroundStyle(Color.brandSecondaryText)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.brandSecondaryText)
                    }
                },
                valueContent: {
                    Text(startTimeText)
                        .font(RecipePreviewTypography.metricValue)
                        .foregroundStyle(Color.brandText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.recipePreviewStartTime)
        .accessibilityValue(startTimeText)
        .popover(isPresented: $showingStartTimePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            BakingTimePickerPopover(date: $startTime)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var finishTimeText: String {
        startTime
            .addingTimeInterval(max(0, totalDuration) * 60)
            .formatted(date: .omitted, time: .shortened)
    }

    private var startTimeText: String {
        startTime.formatted(date: .omitted, time: .shortened)
    }

    private func timePill(title: String, value: String) -> some View {
        timePill(
            titleContent: {
                Text(title)
                    .font(RecipePreviewTypography.metricLabel)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            },
            valueContent: {
                Text(value)
                    .font(RecipePreviewTypography.metricValue)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        )
    }

    private func timePill<TitleContent: View, ValueContent: View>(
        @ViewBuilder titleContent: () -> TitleContent,
        @ViewBuilder valueContent: () -> ValueContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            titleContent()

            valueContent()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: BakingComponentMetrics.metricStripCellMinHeight, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var previewColumnDivider: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(
                width: BakingComponentMetrics.metricStripDividerWidth,
                height: BakingComponentMetrics.metricStripDividerHeight
            )
            .padding(.horizontal, 6)
    }
}

private struct CompactIngredientRow: View {
    let item: RecipeItem
    let weightParts: BakingFormattedUnitValue
    let percentValue: String?
    let hasWater: Bool
    let showsPercentage: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Text(item.name)
                    .font(RecipePreviewTypography.tablePrimary)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)

                if hasWater {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.waterText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if showsPercentage {
                    if let percentValue {
                        BakingPercentColumn(
                            value: percentValue,
                            valueFont: RecipePreviewTypography.tableNumber,
                            unitFont: RecipePreviewTypography.tableUnit,
                            color: Color.brandText,
                            unitColor: Color.brandSecondaryText,
                            width: 48
                        )
                    } else {
                        Color.clear
                            .frame(width: 48, height: 1)
                    }
                }

                BakingQuantityColumn(
                    value: weightParts.value,
                    unit: weightParts.unit,
                    valueFont: RecipePreviewTypography.tableNumber,
                    unitFont: RecipePreviewTypography.tableUnit,
                    valueColor: Color.brandText,
                    unitColor: Color.brandSecondaryText,
                    valueWidth: 46,
                    unitWidth: 14
                )
            }
            .frame(width: showsPercentage ? 124 : 64, alignment: .trailing)
            .layoutPriority(0)
        }
        .frame(minHeight: 58)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct PreviewIngredientList: View {
    @Environment(\.showsPreviewIngredientPercentages) private var showsPercentages
    let ingredients: [PreviewIngredientSnapshot]

    var body: some View {
        VStack(spacing: 0) {
            if ingredients.isEmpty {
                PreviewEmptyOrTextContent(text: "", emptyText: BakingTerms.formulaEmptyMaterials)
            } else {
                ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, snapshot in
                    CompactIngredientRow(
                        item: snapshot.item,
                        weightParts: snapshot.weightParts,
                        percentValue: snapshot.percentValue,
                        hasWater: snapshot.hasWater,
                        showsPercentage: showsPercentages
                    )

                    if index < ingredients.count - 1 {
                        BakingTableDivider(leadingInset: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ShowsPreviewIngredientPercentagesKey: EnvironmentKey {
    static let defaultValue = true
}

private extension EnvironmentValues {
    var showsPreviewIngredientPercentages: Bool {
        get { self[ShowsPreviewIngredientPercentagesKey.self] }
        set { self[ShowsPreviewIngredientPercentagesKey.self] = newValue }
    }
}

private struct CompactStepRow: View {
    let index: Int
    let name: String
    let durationText: String
    let temperatureText: String?
    let itemsText: String?
    let notesText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("\(index). \(name)")
                    .font(RecipePreviewTypography.tablePrimary)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(durationText)
                    .font(RecipePreviewTypography.tableSecondary.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.brandSecondaryText)

                if let temperatureText {
                    Text(temperatureText)
                        .font(RecipePreviewTypography.tableSecondary.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                }
            }

            if let itemsText {
                Text(itemsText)
                    .font(RecipePreviewTypography.tableSecondary)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            }

            if let notesText {
                Text(notesText)
                    .font(RecipePreviewTypography.tableSecondary)
                    .foregroundStyle(Color.brandText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }
}

private struct PreviewStepList: View {
    let steps: [PreviewStepSnapshot]

    var body: some View {
        VStack(spacing: 0) {
            if steps.isEmpty {
                PreviewEmptyOrTextContent(text: "", emptyText: BakingTerms.stepsEmptyMessage)
            } else {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    CompactStepRow(
                        index: step.index,
                        name: step.name,
                        durationText: step.durationText,
                        temperatureText: step.temperatureText,
                        itemsText: step.itemsText,
                        notesText: step.notesText
                    )

                    if index < steps.count - 1 {
                        BakingTableDivider(leadingInset: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PreviewEmptyOrTextContent: View {
    let text: String
    let emptyText: String

    var body: some View {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        Text(trimmedText.isEmpty ? emptyText : trimmedText)
            .font(RecipePreviewTypography.tablePrimary)
            .foregroundStyle(trimmedText.isEmpty ? Color.brandSecondaryText : Color.brandText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
    }
}

struct PreviewIngredientSnapshot: Identifiable {
    let item: RecipeItem
    let weightParts: BakingFormattedUnitValue
    let percentValue: String?
    let detailText: String?
    let hasWater: Bool

    var id: UUID { item.id }
}

struct PreviewStepSnapshot: Identifiable {
    let index: Int
    let name: String
    let durationText: String
    let temperatureText: String?
    let itemsText: String?
    let notesText: String?

    var id: Int { index }
}

@MainActor
struct RecipePreviewShareContent {
    let currentRecipeDisplayName: String
    let summary: RecipeSummary
    let totalDuration: Double
    let usesBakerPercentageSystem: Bool
    let usesHydrationSystem: Bool
    let showsSummaryMetrics: Bool
    let ingredients: [PreviewIngredientSnapshot]
    let steps: [PreviewStepSnapshot]

    init(store: RecipeStore) {
        let showsPercentages = store.currentRecipeKind.usesBakerPercentageSystem
        let showsHydration = store.currentRecipeKind.usesHydrationSystem
        let usesUnifiedIngredientList = store.currentRecipeKind.usesUnifiedIngredientList
        currentRecipeDisplayName = store.currentRecipeDisplayName
        summary = store.summary
        totalDuration = store.totalStepMinutes()
        usesBakerPercentageSystem = showsPercentages
        usesHydrationSystem = showsHydration
        showsSummaryMetrics = store.currentRecipeKind.showsPreviewSummaryMetrics

        let visibleItems = usesUnifiedIngredientList ? store.items.filter { $0.category != .starter } : store.items
        let sortedItems = visibleItems.sorted { lhs, rhs in
            Self.previewSortRank(for: lhs) < Self.previewSortRank(for: rhs)
        }
        ingredients = sortedItems.map { item in
            PreviewIngredientSnapshot(
                item: item,
                weightParts: BakingFormat.weightParts(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0),
                percentValue: showsPercentages && item.category != .flour ? BakingFormat.number(Self.percentForPreview(item, summary: store.summary), precision: 1) : nil,
                detailText: showsHydration ? Self.secondaryDetail(for: item, store: store) : nil,
                hasWater: showsHydration && store.hasWaterContent(item)
            )
        }

        steps = store.steps.enumerated().map { index, step in
            PreviewStepSnapshot(
                index: index + 1,
                name: step.name,
                durationText: BakingFormat.duration(minutes: store.stepMinutes(step)),
                temperatureText: Self.temperatureText(for: step),
                itemsText: Self.stepItemsText(for: step, store: store),
                notesText: Self.previewNotes(for: step)
            )
        }
    }

    var textTutorial: String {
        var sections: [String] = []

        sections.append(currentRecipeDisplayName)
        var metricLines = [
            "\(BakingTerms.recipePreviewEstimatedDuration): \(BakingFormat.duration(minutes: totalDuration))"
        ]
        if showsSummaryMetrics {
            metricLines.append("\(BakingTerms.formulaMetricDough): \(BakingFormat.weight(summary.doughWeight))")
            metricLines.append("\(BakingTerms.formulaMetricFlour): \(BakingFormat.weight(summary.flourWeight))")
            if usesHydrationSystem {
                metricLines.append("\(BakingTerms.formulaMetricHydration): \(BakingFormat.number(summary.hydration, precision: 1))%")
            }
        }
        sections.append(metricLines.joined(separator: "\n"))

        let ingredientLines = ingredients.map { snapshot in
            var line = "- \(snapshot.item.name): \(snapshot.weightParts.value) \(snapshot.weightParts.unit)"
            if let percentValue = snapshot.percentValue {
                line += " (\(percentValue)%)"
            }
            if let detailText = snapshot.detailText {
                line += " - \(detailText)"
            }
            return line
        }
        sections.append("\(BakingTerms.recipePreviewIngredients)\n\(ingredientLines.isEmpty ? BakingTerms.formulaEmptyMaterials : ingredientLines.joined(separator: "\n"))")

        let stepLines = steps.map { step in
            var parts = ["\(step.index). \(step.name)", step.durationText]
            if let temperatureText = step.temperatureText {
                parts.append(temperatureText)
            }
            var line = parts.joined(separator: " - ")
            if let itemsText = step.itemsText {
                line += "\n   \(itemsText)"
            }
            if let notesText = step.notesText {
                line += "\n   \(notesText)"
            }
            return line
        }
        sections.append("\(BakingTerms.recipePreviewSteps)\n\(stepLines.isEmpty ? BakingTerms.stepsEmptyMessage : stepLines.joined(separator: "\n"))")

        return sections.joined(separator: "\n\n")
    }

    @MainActor
    func renderLongImage() -> UIImage? {
        let exportView = RecipePreviewExportContent(
            currentRecipeDisplayName: currentRecipeDisplayName,
            summary: summary,
            totalDuration: totalDuration,
            showsSummaryMetrics: showsSummaryMetrics,
            showsHydration: usesHydrationSystem,
            showsIngredientPercentages: usesBakerPercentageSystem,
            ingredients: ingredients,
            steps: steps
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.proposedSize = ProposedViewSize(width: UIScreen.main.bounds.width, height: nil)
        renderer.scale = UIScreen.main.scale

        return renderer.uiImage
    }

    private static func previewSortRank(for item: RecipeItem) -> Int {
        switch item.category {
        case .flour:
            return 0
        case .starter:
            return 1
        case .basic:
            switch item.tag {
            case .water: return 2
            case .salt: return 3
            case .egg: return 4
            case .butter: return 5
            case .cream: return 6
            case .yeast: return 7
            case .sugar: return 8
            default: return 9
            }
        case .other:
            return 10
        }
    }

    private static func stepItemsText(for step: JournalStep, store: RecipeStore) -> String? {
        let names = store.allocatedItems(for: step).map { allocatedItem in
            let item = allocatedItem.item
            return "\(item.name) \(BakingFormat.weight(allocatedItem.weight, gramPrecision: item.tag == .yeast ? 1 : 0))"
        }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " · ")
    }

    private static func temperatureText(for step: JournalStep) -> String? {
        guard let temperature = step.temperature else { return nil }
        return "\(BakingFormat.number(temperature, precision: 0))\(step.temperatureUnit?.rawValue ?? "C")"
    }

    private static func previewNotes(for step: JournalStep) -> String? {
        let trimmed = step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func secondaryDetail(for item: RecipeItem, store: RecipeStore) -> String? {
        if item.category == .starter {
            return BakingTerms.recipePreviewStarterDetail(
                flour: BakingFormat.weight(store.flourContribution(item)),
                water: BakingFormat.weight(store.waterContribution(item))
            )
        }
        if item.tag == .egg {
            return BakingTerms.recipePreviewEggDetail(
                count: BakingFormat.number(1, precision: 0),
                water: BakingFormat.weight(store.waterContribution(item))
            )
        }
        if item.tag == .water {
            return nil
        }
        return nil
    }

    private static func percentForPreview(_ item: RecipeItem, summary: RecipeSummary) -> Double {
        guard summary.flourWeight > 0 else { return 0 }
        return item.weight / summary.flourWeight * 100
    }
}

private struct RecipePreviewExportContent: View {
    let currentRecipeDisplayName: String
    let summary: RecipeSummary
    let totalDuration: Double
    let showsSummaryMetrics: Bool
    let showsHydration: Bool
    let showsIngredientPercentages: Bool
    let ingredients: [PreviewIngredientSnapshot]
    let steps: [PreviewStepSnapshot]

    var body: some View {
        ZStack {
            Color.brandBackground
                .ignoresSafeArea()

            LazyVStack(spacing: BakingLayout.cardStackSpacing) {
                VStack(alignment: .leading, spacing: 10) {
                    RecipePreviewTitleText(currentRecipeDisplayName: currentRecipeDisplayName)

                    HStack(spacing: 5) {
                        BakingIconView(icon: .timer, size: 13, color: .brandPrimary)
                        Text("\(BakingTerms.recipePreviewEstimatedDuration) \(BakingFormat.duration(minutes: totalDuration))")
                            .font(RecipePreviewTypography.tableSecondary.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.brandSecondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
                .padding(12)
                .bakingCard()

                if showsSummaryMetrics {
                    PreviewMetricsOverview(summary: summary, showsHydration: showsHydration)
                        .padding(.horizontal, BakingComponentMetrics.metricStripHorizontalPadding)
                        .padding(.vertical, BakingComponentMetrics.metricStripVerticalPadding)
                        .bakingCard()
                }

                BakingSectionCard(title: BakingTerms.recipePreviewIngredients) {
                    PreviewIngredientList(ingredients: ingredients)
                        .environment(\.showsPreviewIngredientPercentages, showsIngredientPercentages)
                        .padding(.horizontal, BakingSpace.md)
                        .padding(.bottom, BakingSpace.sm)
                }

                BakingSectionCard(title: BakingTerms.recipePreviewSteps) {
                    PreviewStepList(steps: steps)
                        .padding(.horizontal, BakingSpace.md)
                        .padding(.bottom, BakingSpace.sm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.vertical, BakingLayout.screenHorizontalInset)
        }
        .frame(width: UIScreen.main.bounds.width)
    }
}

struct RecipePreviewTextTutorialSheet: View {
    let text: String
    @State private var hasCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(BakingTypography.appSecondaryText)
                    .foregroundStyle(Color.brandText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BakingSpace.md)
                    .bakingCard()
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingLayout.contentTopInset)
                    .padding(.bottom, BakingTouchTarget.primaryAction + BakingSpace.xxl * 2)
            }
            .background(Color.brandBackground)
            .navigationTitle(BakingTerms.textTutorialTitle)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: BakingSpace.sm) {
                    if hasCopied {
                        Text(BakingTerms.copiedToClipboard)
                            .font(BakingTypography.appSecondaryText)
                            .foregroundStyle(Color.brandSage)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    BakingActionButton(
                        title: BakingTerms.copyTextTutorial,
                        accessibilityLabel: BakingTerms.copyTextTutorial,
                        icon: .copy
                    ) {
                        UIPasteboard.general.string = text
                        withAnimation(BakingMotion.quick) {
                            hasCopied = true
                        }
                    }
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.sm)
                .padding(.bottom, BakingSpace.md)
                .background(Color.brandBackground)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private extension View {
    func previewDismissesKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded {
            dismissActiveKeyboard()
        })
    }
}
