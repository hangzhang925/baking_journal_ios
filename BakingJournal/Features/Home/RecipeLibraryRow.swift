import SwiftUI

struct RecipeLibraryRow: View {
    let recipe: SavedRecipe
    let bakeCount: Int
    var filterMatchState: BakingFilterMatchState = .matching

    var body: some View {
        HStack(spacing: BakingSpace.lg) {
            BakingMaterialIconBadge(icon: BakingIcon.recipeKind(recipe.kind))

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(recipe.name)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RecipeWorkflowBadge(state: recipe.workflowState)
                .frame(width: BakingComponentMetrics.libraryRowStatusColumnWidth, alignment: .center)

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
            .frame(width: BakingComponentMetrics.libraryRowMetadataColumnWidth, alignment: .trailing)
        }
        .frame(minHeight: BakingComponentMetrics.listRowMinHeight)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .bakingFilterMatchState(filterMatchState)
        .contentShape(Rectangle())
    }
}

struct RecipeLibraryMetadataLine: View {
    let title: String
    let value: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(BakingTerms.recipeMetadataLine(title, value))
            Text(value)
        }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.brandSecondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.trailing)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(value)
    }
}
