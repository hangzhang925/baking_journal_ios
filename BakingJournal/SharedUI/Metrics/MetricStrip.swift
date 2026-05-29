import SwiftUI

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
        VStack(alignment: .leading, spacing: BakingSpace.xs) {
            BakingLabel(text: title, role: .readOnlyLabel)
            Text(value)
                .font(BakingTypography.readOnlyValue)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
    }
}
