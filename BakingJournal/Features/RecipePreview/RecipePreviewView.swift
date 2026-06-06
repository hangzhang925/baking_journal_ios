import SwiftUI
import UIKit

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

struct RecipePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var showsDoneButton: Bool = false
    var showsToolbar: Bool = true
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    @State private var exportError: String?
    @State private var showingCookView = false
    @State private var showingWorkspace = false
    @State private var localWorkspaceStage: RecipeWorkspaceStage = .formula
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
        .sheet(isPresented: $showingShareSheet) {
            if let shareImage {
                ActivityViewController(activityItems: [shareImage])
            }
        }
        .navigationDestination(isPresented: $showingCookView) {
            CookView()
        }
        .navigationDestination(isPresented: $showingWorkspace) {
            RecipeWorkspaceView(initialStage: localWorkspaceStage)
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
    }

    private var previewTopActionRow: some View {
        BakingTopActionRow(
            leading: {
                if showsDoneButton || navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        if showsDoneButton {
                            dismiss()
                        } else {
                            navigationController.goBack()
                        }
                    }
                }
            },
            trailing: {
                HStack(spacing: BakingSpace.xs) {
                    BakingIconButton(
                        icon: .share,
                        accessibilityLabel: BakingTerms.exportLongImage
                    ) {
                        exportLongImage()
                    }

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
        )
    }

    private func presentCook() {
        if showsDoneButton {
            showingCookView = true
        } else {
            navigationController.push(.cook)
        }
    }

    private func presentWorkspace(_ stage: RecipeWorkspaceStage) {
        if showsDoneButton {
            localWorkspaceStage = stage
            showingWorkspace = true
        } else {
            navigationController.push(.recipeWorkspace(stage))
        }
    }

    private var previewStack: some View {
        LazyVStack(spacing: BakingSpace.lg) {
            summaryCard
            timePlanCard
            metricsCard
            overallNotesCard
            ingredientsCard
            stepsCard
        }
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingLayout.contentTopInset)
        .padding(.bottom, 24)
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
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
        .bakingCard()
        .previewDismissesKeyboardOnTap()
    }

    private var metricsCard: some View {
        PreviewMetricsOverview(
            summary: store.summary,
            items: store.items,
            flourContribution: store.flourContribution,
            waterContribution: store.waterContribution
        )
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.xs)
            .bakingCard()
            .previewDismissesKeyboardOnTap()
    }

    @ViewBuilder
    private var overallNotesCard: some View {
        if !trimmedOverallNotes.isEmpty {
            PreviewOverallNotesDisplay(notesText: trimmedOverallNotes)
                .previewDismissesKeyboardOnTap()
        }
    }

    private var trimmedOverallNotes: String {
        store.recipeOverallNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var ingredientsCard: some View {
        BakingSectionCard(title: BakingTerms.recipePreviewIngredients) {
            PreviewIngredientList(ingredients: previewIngredientSnapshots)
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
        previewItems.map {
            PreviewIngredientSnapshot(
                item: $0,
                weightParts: BakingFormat.weightParts($0.weight, gramPrecision: $0.tag == .yeast ? 1 : 0),
                percentValue: $0.category == .flour ? nil : BakingFormat.number(percentForPreview($0), precision: 1),
                detailText: secondaryDetail(for: $0),
                hasWater: store.hasWaterContent($0)
            )
        }
    }

    private var previewStepSnapshots: [PreviewStepSnapshot] {
        store.steps.enumerated().map { index, step in
            PreviewStepSnapshot(
                index: index + 1,
                name: step.name,
                durationText: BakingFormat.duration(minutes: store.stepMinutes(step)),
                temperatureText: temperatureText(for: step),
                itemsText: stepItemsText(for: step),
                notesText: previewNotes(for: step)
            )
        }
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
            case .yeast: return 6
            case .sugar: return 7
            default: return 8
            }
        case .other:
            return 9
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

    private func exportLongImage() {
        let exportView = RecipePreviewExportContent(
            currentRecipeDisplayName: store.currentRecipeDisplayName,
            summary: store.summary,
            totalDuration: store.totalStepMinutes(),
            overallNotes: store.recipeOverallNotes,
            ingredients: previewIngredientSnapshots,
            steps: previewStepSnapshots
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.proposedSize = ProposedViewSize(width: UIScreen.main.bounds.width, height: nil)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else {
            exportError = BakingTerms.recipePreviewExportRenderFailed
            return
        }

        shareImage = image
        showingShareSheet = true
    }
}

private struct RecipePreviewTitleBlock: View {
    @Binding var recipeName: String

    var body: some View {
        BakingInlineTextField(
            text: $recipeName,
            placeholder: BakingTerms.recipeNamePromptLabel,
            font: RecipePreviewTypography.titleUIFont,
            maxLength: 24
        )
        .bakingFittedInputField(
            width: BakingComponentMetrics.compactRecipeTitleInputFieldWidth,
            height: BakingComponentMetrics.compactInputFieldHeight,
            alignment: .leading
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

    var body: some View {
        HStack(spacing: 0) {
            PreviewMetricColumn(title: BakingTerms.formulaMetricDough, value: BakingFormat.weight(summary.doughWeight))
            previewColumnDivider
            PreviewMetricColumn(title: BakingTerms.formulaMetricFlour, value: BakingFormat.weight(summary.flourWeight))
            previewColumnDivider
            PreviewMetricColumn(
                title: BakingTerms.formulaMetricHydration,
                value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                hydrationReceipt: hydrationReceipt
            )
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
            .frame(width: 0.6, height: 34)
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
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
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
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var previewColumnDivider: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(width: 0.6, height: 34)
            .padding(.horizontal, 6)
    }
}

private struct CompactIngredientRow: View {
    let item: RecipeItem
    let weightParts: BakingFormattedUnitValue
    let percentValue: String?
    let detailText: String?
    let hasWater: Bool

    var body: some View {
        let rowMinHeight: CGFloat = detailText == nil ? 40 : 46

        HStack(alignment: .center, spacing: 8) {
            BakingIconView(icon: BakingIcon.material(for: item), size: BakingComponentMetrics.materialChipIcon, color: item.materialPalette.tint)
                .frame(width: BakingTouchTarget.dropdownIconSurface, height: BakingTouchTarget.dropdownIconSurface)
                .background(item.materialPalette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
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

                if let detailText, !detailText.isEmpty {
                    Text(detailText)
                        .font(RecipePreviewTypography.tableSecondary)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
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
            .frame(width: 124, alignment: .trailing)
            .layoutPriority(0)
        }
        .frame(minHeight: rowMinHeight)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

private struct PreviewIngredientList: View {
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
                        detailText: snapshot.detailText,
                        hasWater: snapshot.hasWater
                    )

                    if index < ingredients.count - 1 {
                        BakingTableDivider(leadingInset: 42)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        HStack(alignment: .top, spacing: 8) {
            Text("\(index)")
                .font(RecipePreviewTypography.tableUnit.monospacedDigit())
                .foregroundStyle(Color.brandText)
                .frame(width: 20, height: 20)
                .background(BakingSurface.selectedRowBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
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
                        BakingTableDivider(leadingInset: 42)
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

private struct PreviewOverallNotesDisplay: View {
    let notesText: String

    var body: some View {
        BakingSectionCard(title: BakingTerms.recipePreviewOverallNotes) {
            Text(notesText)
                .font(RecipePreviewTypography.tablePrimary)
                .foregroundStyle(Color.brandText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }
}

private struct PreviewIngredientSnapshot: Identifiable {
    let item: RecipeItem
    let weightParts: BakingFormattedUnitValue
    let percentValue: String?
    let detailText: String?
    let hasWater: Bool

    var id: UUID { item.id }
}

private struct PreviewStepSnapshot: Identifiable {
    let index: Int
    let name: String
    let durationText: String
    let temperatureText: String?
    let itemsText: String?
    let notesText: String?

    var id: Int { index }
}

private struct RecipePreviewExportContent: View {
    let currentRecipeDisplayName: String
    let summary: RecipeSummary
    let totalDuration: Double
    let overallNotes: String
    let ingredients: [PreviewIngredientSnapshot]
    let steps: [PreviewStepSnapshot]

    var body: some View {
        let trimmedOverallNotes = overallNotes.trimmingCharacters(in: .whitespacesAndNewlines)

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

                PreviewMetricsOverview(summary: summary)
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.vertical, BakingSpace.xs)
                    .bakingCard()

                if !trimmedOverallNotes.isEmpty {
                    PreviewOverallNotesDisplay(notesText: trimmedOverallNotes)
                }

                BakingSectionCard(title: BakingTerms.recipePreviewIngredients) {
                    PreviewIngredientList(ingredients: ingredients)
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

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension View {
    func previewDismissesKeyboardOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded {
            dismissActiveKeyboard()
        })
    }
}
