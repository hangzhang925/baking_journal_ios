import SwiftUI
import UIKit

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

    private let ingredientColumns = [
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 0) {
            if showsToolbar {
                previewTopActionRow
            }

            ScrollView {
                previewStack
            }
            .background(Color.brandBackground)
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
        .alert("导出长图失败", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("好", role: .cancel) {
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
        LazyVStack(spacing: BakingLayout.cardStackSpacing) {
            summaryCard
            ingredientsCard
            if !store.steps.isEmpty {
                stepsCard
            }
        }
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingLayout.contentTopInset)
        .padding(.bottom, 24)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                RecipePreviewTitleBlock(
                    currentRecipeDisplayName: store.currentRecipeDisplayName,
                    totalDuration: store.totalStepMinutes()
                )

                Spacer(minLength: 0)

                RecipeWorkflowBadge(state: store.recipeWorkflowState)
            }

            Text(store.readinessMessage)
                .font(.caption)
                .foregroundStyle(Color.brandSecondaryText)

            CompactPreviewMetrics(summary: store.summary)
        }
        .padding(12)
        .bakingCard(radius: BakingRadius.prominentCard)
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("材料")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandText)

            VStack(spacing: 0) {
                ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, item in
                    CompactIngredientRow(
                        item: item,
                        weightParts: BakingFormat.weightParts(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0),
                        percentValue: item.category == .flour ? nil : BakingFormat.number(percentForPreview(item), precision: 1),
                        detailText: secondaryDetail(for: item),
                        hasWater: store.hasWaterContent(item)
                    )

                    if index < previewItems.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color.brandBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(12)
        .bakingCard(radius: BakingRadius.prominentCard)
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("步骤")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandText)

            VStack(spacing: 0) {
                ForEach(Array(store.steps.enumerated()), id: \.element.id) { index, step in
                    CompactStepRow(
                        index: index + 1,
                        name: step.name,
                        durationText: BakingFormat.duration(minutes: store.stepMinutes(step)),
                        temperatureText: temperatureText(for: step),
                        itemsText: stepItemsText(for: step),
                        notesText: previewNotes(for: step)
                    )

                    if index < store.steps.count - 1 {
                        Divider()
                            .padding(.leading, 34)
                    }
                }
            }
            .background(Color.brandBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(12)
        .bakingCard(radius: BakingRadius.prominentCard)
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
            return "\(BakingFormat.weight(store.flourContribution(item))) 粉 / \(BakingFormat.weight(store.waterContribution(item))) 水"
        }
        if item.tag == .egg {
            return "1 个 / 水 \(BakingFormat.weight(store.waterContribution(item)))"
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
            previewItems: previewItems.map {
                PreviewIngredientSnapshot(
                    item: $0,
                    weightParts: BakingFormat.weightParts($0.weight, gramPrecision: $0.tag == .yeast ? 1 : 0),
                    percentValue: $0.category == .flour ? nil : BakingFormat.number(percentForPreview($0), precision: 1),
                    detailText: secondaryDetail(for: $0),
                    hasWater: store.hasWaterContent($0)
                )
            },
            steps: store.steps.enumerated().map { index, step in
                PreviewStepSnapshot(
                    index: index + 1,
                    name: step.name,
                    durationText: BakingFormat.duration(minutes: store.stepMinutes(step)),
                    temperatureText: temperatureText(for: step),
                    itemsText: stepItemsText(for: step),
                    notesText: previewNotes(for: step)
                )
            }
        )

        let renderer = ImageRenderer(content: exportView)
        renderer.proposedSize = ProposedViewSize(width: UIScreen.main.bounds.width, height: nil)
        renderer.scale = UIScreen.main.scale

        guard let image = renderer.uiImage else {
            exportError = "暂时没能生成长图，请再试一次。"
            return
        }

        shareImage = image
        showingShareSheet = true
    }
}

private struct RecipePreviewTitleBlock: View {
    let currentRecipeDisplayName: String
    let totalDuration: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(currentRecipeDisplayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandText)

            if totalDuration > 0 {
                HStack(spacing: 5) {
                    BakingIconView(icon: .timer, size: 13, color: .brandPrimary)
                    Text("\(BakingTerms.recipePreviewEstimatedDuration) \(BakingFormat.duration(minutes: totalDuration))")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
        }
    }
}

private struct CompactPreviewMetrics: View {
    let summary: RecipeSummary

    var body: some View {
        HStack(spacing: 8) {
            metricPill(title: "面团", value: BakingFormat.weight(summary.doughWeight))
            metricPill(title: "面粉", value: BakingFormat.weight(summary.flourWeight))
            metricPill(title: "含水", value: "\(BakingFormat.number(summary.hydration, precision: 1))%", isWater: true)
        }
    }

    private func metricPill(title: String, value: String, isWater: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(isWater ? Color.waterText.opacity(0.78) : Color.brandSecondaryText)
            Text(value)
                .font(.callout.monospacedDigit().weight(.bold))
                .foregroundStyle(isWater ? Color.waterText : Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct CompactIngredientRow: View {
    let item: RecipeItem
    let weightParts: BakingFormattedUnitValue
    let percentValue: String?
    let detailText: String?
    let hasWater: Bool

    var body: some View {
        let isPureWater = item.tag == .water

        HStack(alignment: .top, spacing: 10) {
            BakingIconView(icon: BakingIcon.material(for: item), size: 16, color: item.materialPalette.tint)
                .frame(width: 28, height: 28)
                .background(item.materialPalette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
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
                        .font(.caption2)
                        .foregroundStyle(hasWater ? Color.waterText.opacity(0.82) : Color.brandSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let percentValue {
                    BakingPercentColumn(
                        value: percentValue,
                        color: isPureWater ? Color.waterText : Color.brandPrimary,
                        width: 60
                    )
                } else {
                    Color.clear
                        .frame(width: 60, height: 1)
                }
                BakingQuantityColumn(
                    value: weightParts.value,
                    unit: weightParts.unit,
                    valueFont: .callout.monospacedDigit().weight(.bold),
                    unitFont: .callout.weight(.bold),
                    valueColor: isPureWater ? Color.waterText : Color.brandText,
                    valueWidth: 48,
                    unitWidth: 16
                )
            }
            .frame(width: 132, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(item.materialPalette.surface.opacity(0.92))
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
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 22, height: 22)
                .background(Color.brandPrimary.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(durationText)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)

                    if let temperatureText {
                        Text(temperatureText)
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.waterText)
                    }
                }

                if let itemsText {
                    Text(itemsText)
                        .font(.caption2)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)
                }

                if let notesText {
                    Text(notesText)
                        .font(.caption)
                        .foregroundStyle(Color.brandText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
    let previewItems: [PreviewIngredientSnapshot]
    let steps: [PreviewStepSnapshot]

    var body: some View {
        ZStack {
            Color.brandBackground
                .ignoresSafeArea()

            LazyVStack(spacing: BakingLayout.cardStackSpacing) {
                VStack(alignment: .leading, spacing: 10) {
                    RecipePreviewTitleBlock(
                        currentRecipeDisplayName: currentRecipeDisplayName,
                        totalDuration: totalDuration
                    )

                    CompactPreviewMetrics(summary: summary)
                }
                .padding(12)
                .bakingCard(radius: BakingRadius.prominentCard)

                VStack(alignment: .leading, spacing: 8) {
                    Text("材料")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)

                    VStack(spacing: 0) {
                        ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, snapshot in
                            CompactIngredientRow(
                                item: snapshot.item,
                                weightParts: snapshot.weightParts,
                                percentValue: snapshot.percentValue,
                                detailText: snapshot.detailText,
                                hasWater: snapshot.hasWater
                            )

                            if index < previewItems.count - 1 {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                    .background(Color.brandBackground.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(12)
                .bakingCard(radius: BakingRadius.prominentCard)

                if !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("步骤")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.brandText)

                        VStack(spacing: 0) {
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
                                    Divider()
                                        .padding(.leading, 34)
                                }
                            }
                        }
                        .background(Color.brandBackground.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(12)
                    .bakingCard(radius: BakingRadius.prominentCard)
                }
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
