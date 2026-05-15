import SwiftUI
import UIKit

struct RecipePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: RecipeStore

    var showsDoneButton: Bool = false
    @State private var shareImage: UIImage?
    @State private var showingShareSheet = false
    @State private var exportError: String?

    private let ingredientColumns = [
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            previewStack
        }
        .background(Color.brandBackground)
        .navigationTitle(store.currentRecipeDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        BakingToolbarIconButton(icon: .complete, accessibilityLabel: "完成")
                    }
                    .buttonStyle(.plain)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    exportLongImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel("导出长图")

                NavigationLink {
                    CookView()
                } label: {
                    BakingToolbarIconButton(icon: .start, accessibilityLabel: "开始制作")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    RecipeWorkspaceView()
                } label: {
                    BakingToolbarIconButton(icon: .edit, accessibilityLabel: "编辑配方")
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareImage {
                ActivityViewController(activityItems: [shareImage])
            }
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

    private var previewStack: some View {
        LazyVStack(spacing: 10) {
            summaryCard
            ingredientsCard
            if !store.steps.isEmpty {
                stepsCard
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.currentRecipeDisplayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandText)

            CompactPreviewMetrics(summary: store.summary, totalDuration: store.totalStepMinutes())
        }
        .padding(12)
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                        weightText: BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0),
                        percentText: item.category == .flour ? nil : "\(BakingFormat.number(percentForPreview(item), precision: 0))%",
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
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        let names = store.items(for: step).map(\.name)
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
        let doughWeight = store.summary.doughWeight
        guard doughWeight > 0 else { return 0 }
        return item.weight / doughWeight * 100
    }

    private func exportLongImage() {
        let exportView = RecipePreviewExportContent(
            currentRecipeDisplayName: store.currentRecipeDisplayName,
            summary: store.summary,
            totalDuration: store.totalStepMinutes(),
            previewItems: previewItems.map {
                PreviewIngredientSnapshot(
                    item: $0,
                    weightText: BakingFormat.weight($0.weight, gramPrecision: $0.tag == .yeast ? 1 : 0),
                    percentText: $0.category == .flour ? nil : "\(BakingFormat.number(percentForPreview($0), precision: 0))%",
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

private struct CompactPreviewMetrics: View {
    let summary: RecipeSummary
    let totalDuration: Double

    var body: some View {
        HStack(spacing: 8) {
            metricPill(title: "面团", value: BakingFormat.weight(summary.doughWeight))
            metricPill(title: "面粉", value: BakingFormat.weight(summary.flourWeight))
            metricPill(title: "含水", value: "\(BakingFormat.number(summary.hydration, precision: 1))%", isWater: true)
            if totalDuration > 0 {
                metricPill(title: "时长", value: BakingFormat.duration(minutes: totalDuration))
            }
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
    let weightText: String
    let percentText: String?
    let detailText: String?
    let hasWater: Bool

    var body: some View {
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
                if let percentText {
                    Text(percentText)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(hasWater ? Color.waterText : Color.brandPrimary)
                }
                Text(weightText)
                    .font(.callout.monospacedDigit().weight(.bold))
                    .foregroundStyle(hasWater ? Color.waterText : Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
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
    let weightText: String
    let percentText: String?
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

            LazyVStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(currentRecipeDisplayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.brandText)

                    CompactPreviewMetrics(summary: summary, totalDuration: totalDuration)
                }
                .padding(12)
                .background(Color.brandSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("材料")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)

                    VStack(spacing: 0) {
                        ForEach(Array(previewItems.enumerated()), id: \.element.id) { index, snapshot in
                            CompactIngredientRow(
                                item: snapshot.item,
                                weightText: snapshot.weightText,
                                percentText: snapshot.percentText,
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
                .background(Color.brandSurface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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
                    .background(Color.brandSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
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
