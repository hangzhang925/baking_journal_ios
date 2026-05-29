import SwiftUI

struct BakeRecipePickerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                if sortedRecipes.isEmpty {
                    BakingEmptyState(title: BakingTerms.bakePickerEmptyReadyRecipes, systemImage: "flame")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            store.loadRecipe(recipe)
                            navigationController.push(.recipeWorkspace(.preview))
                        } label: {
                            RecipeLibraryRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                BakingLabel(text: BakingTerms.bakePickerChooseRecipe, role: .sectionHeader)
            } footer: {
                if !sortedRecipes.isEmpty {
                    Text(BakingTerms.bakePickerFooter)
                        .bakingLabelStyle(.helperText)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes
            .filter { store.isReadyToBake($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}
