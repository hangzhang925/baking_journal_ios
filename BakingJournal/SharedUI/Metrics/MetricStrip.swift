import SwiftUI

struct MetricStrip: View {
    let summary: RecipeSummary
    var items: [RecipeItem] = []
    var flourContribution: ((RecipeItem) -> Double)?
    var waterContribution: ((RecipeItem) -> Double)?

    var body: some View {
        RecipeMetricsOverviewCard(
            summary: summary,
            items: items,
            flourContribution: flourContribution,
            waterContribution: waterContribution
        )
    }
}

struct RecipeMetricsOverviewCard: View {
    let summary: RecipeSummary
    var items: [RecipeItem] = []
    var flourContribution: ((RecipeItem) -> Double)?
    var waterContribution: ((RecipeItem) -> Double)?

    var body: some View {
        RecipeMetricsOverview(
            summary: summary,
            items: items,
            flourContribution: flourContribution,
            waterContribution: waterContribution
        )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .bakingCard()
    }
}

private struct RecipeMetricsOverview: View {
    let summary: RecipeSummary
    var items: [RecipeItem] = []
    var flourContribution: ((RecipeItem) -> Double)?
    var waterContribution: ((RecipeItem) -> Double)?

    var body: some View {
        HStack(spacing: 0) {
            MetricCell(title: BakingTerms.formulaMetricDough, value: BakingFormat.weight(summary.doughWeight))
            metricDivider
            MetricCell(title: BakingTerms.formulaMetricFlour, value: BakingFormat.weight(summary.flourWeight))
            metricDivider
            MetricCell(
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

    private var metricDivider: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(width: 0.6, height: 38)
            .padding(.horizontal, 6)
    }
}

private struct MetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandText
    var titleTint: Color = .brandSecondaryText
    var hydrationReceipt: HydrationReceipt?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(title)
                    .font(BakingTypography.appSecondaryText)
                    .foregroundStyle(titleTint)

                if let hydrationReceipt {
                    HydrationReceiptInfoButton(receipt: hydrationReceipt, iconSize: 15)
                }
            }

            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HydrationReceipt: Equatable {
    struct Line: Identifiable, Equatable {
        let id: UUID
        let name: String
        let waterWeight: Double
        let flourWeight: Double
    }

    let lines: [Line]
    let waterTotal: Double
    let flourTotal: Double
    let hydration: Double

    init?(
        items: [RecipeItem],
        summary: RecipeSummary,
        flourContribution: ((RecipeItem) -> Double)?,
        waterContribution: ((RecipeItem) -> Double)?
    ) {
        guard let flourContribution, let waterContribution, !items.isEmpty else { return nil }
        lines = items.map { item in
            Line(
                id: item.id,
                name: item.name,
                waterWeight: waterContribution(item),
                flourWeight: flourContribution(item)
            )
        }
        waterTotal = summary.waterWeight
        flourTotal = summary.flourWeight
        hydration = summary.hydration
    }
}

struct HydrationReceiptInfoButton: View {
    let receipt: HydrationReceipt?
    var iconSize: CGFloat = 16
    @State private var showingInfo = false

    var body: some View {
        Group {
            if let receipt {
                Button {
                    showingInfo = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundStyle(Color.waterText)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                        .accessibilityHidden(true)
                }
                .padding(11)
                .padding(-11)
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(BakingTerms.formulaHydrationInfoAccessibility)
                .popover(isPresented: $showingInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    HydrationReceiptPopover(receipt: receipt)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
    }
}

private struct HydrationReceiptPopover: View {
    let receipt: HydrationReceipt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                BakingIconView(icon: .water, size: 18, color: .waterText)
                    .frame(width: 24, height: 24)
                    .background(Color.waterSurfaceStrong.opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.compactIconCornerRadius, style: .continuous))

                Text(BakingTerms.formulaHydrationInfoTitle)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
            }

            VStack(alignment: .leading, spacing: 6) {
                hydrationHeader

                ForEach(receipt.lines) { line in
                    HydrationReceiptRow(
                        title: line.name,
                        water: BakingFormat.weight(line.waterWeight),
                        flour: BakingFormat.weight(line.flourWeight)
                    )
                }

                Divider()
                    .overlay(Color.brandSecondaryText.opacity(0.18))

                HydrationReceiptRow(
                    title: BakingTerms.formulaHydrationReceiptTotal,
                    water: BakingFormat.weight(receipt.waterTotal),
                    flour: BakingFormat.weight(receipt.flourTotal),
                    isTotal: true
                )
            }

            Text(BakingTerms.formulaHydrationReceiptEquation(
                water: BakingFormat.weight(receipt.waterTotal),
                flour: BakingFormat.weight(receipt.flourTotal),
                percent: "\(BakingFormat.number(receipt.hydration, precision: 1))%"
            ))
            .font(BakingTypography.appSecondaryText)
            .foregroundStyle(Color.brandText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .bakingPopoverSurface(width: BakingComponentMetrics.popoverMediumWidth)
    }

    private var hydrationHeader: some View {
        HStack(spacing: 8) {
            Text(BakingTerms.formulaHydrationReceiptIngredient)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(BakingTerms.formulaHydrationReceiptWater)
                .frame(width: 72, alignment: .trailing)
            Text(BakingTerms.formulaHydrationReceiptFlour)
                .frame(width: 72, alignment: .trailing)
        }
        .font(BakingTypography.appSecondaryText.weight(.semibold))
        .foregroundStyle(Color.brandSecondaryText)
    }
}

private struct HydrationReceiptRow: View {
    let title: String
    let water: String
    let flour: String
    var isTotal = false

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(water)
                .monospacedDigit()
                .frame(width: 72, alignment: .trailing)

            Text(flour)
                .monospacedDigit()
                .frame(width: 72, alignment: .trailing)
        }
        .font(isTotal ? BakingTypography.appPrimaryText : BakingTypography.appSecondaryText)
        .foregroundStyle(isTotal ? Color.brandText : Color.brandSecondaryText)
    }
}
