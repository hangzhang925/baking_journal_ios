import SwiftUI

struct RecipeLibraryRow: View {
    let recipe: SavedRecipe
    let summary: RecipeSummary
    let bakeCount: Int

    var body: some View {
        HStack(spacing: BakingSpace.lg) {
            BakingMaterialIconBadge(icon: BakingIcon.recipeKind(recipe.kind))

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(recipe.name)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: BakingSpace.xs) {
                    BakingIconView(icon: .water, size: BakingComponentMetrics.materialChipIcon, color: .waterText)

                    Text(hydrationLabel)
                        .font(BakingTypography.rowMeta.monospacedDigit())
                        .foregroundStyle(Color.waterText)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(BakingTerms.formulaMetricHydration)
                .accessibilityValue(hydrationLabel)
            }

            Spacer(minLength: BakingSpace.md)

            VStack(alignment: .trailing, spacing: BakingSpace.xs) {
                RecipeLibraryMetadataLine(
                    title: BakingTerms.recipeBakeCount,
                    value: BakingFormat.number(Double(bakeCount), precision: 0)
                )
                RecipeLibraryMetadataLine(
                    title: BakingTerms.recipeUpdatedAt,
                    value: recipe.updatedAt.formatted(date: .numeric, time: .omitted)
                )
            }
        }
        .frame(minHeight: 64)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }

    private var hydrationLabel: String {
        "\(BakingFormat.number(summary.hydration, precision: 1))%"
    }
}

struct RecipeLibraryMetadataLine: View {
    let title: String
    let value: String

    var body: some View {
        Text(BakingTerms.recipeMetadataLine(title, value))
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brandSecondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.86)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
