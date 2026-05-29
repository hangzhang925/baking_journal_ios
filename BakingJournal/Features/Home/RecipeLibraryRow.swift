import SwiftUI

struct RecipeLibraryRow: View {
    let recipe: SavedRecipe

    var body: some View {
        HStack(spacing: 14) {
            BakingMaterialIconBadge(icon: .recipe)

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)

                RecipeWorkflowBadge(state: recipe.workflowState)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandSecondaryText.opacity(0.72))
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

