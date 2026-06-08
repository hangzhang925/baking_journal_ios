import SwiftUI

struct BakeRecipePickerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var replacementRecipe: SavedRecipe?
    @State private var isReplacementDialogPresented = false

    var body: some View {
        List {
            Section {
                if sortedRecipes.isEmpty {
                    BakingEmptyState(title: BakingTerms.bakePickerEmptyReadyRecipes, systemImage: "flame")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            select(recipe)
                        } label: {
                            RecipeLibraryRow(
                                recipe: recipe,
                                bakeCount: bakeCount(for: recipe)
                            )
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
        .confirmationDialog(
            BakingTerms.bakePickerReplaceActiveTitle,
            isPresented: $isReplacementDialogPresented,
            titleVisibility: .visible
        ) {
            Button(BakingTerms.bakePickerReplaceActiveConfirm, role: .destructive) {
                if let replacementRecipe {
                    startBake(with: replacementRecipe)
                }
            }
            Button(BakingTerms.cancel, role: .cancel) {}
        } message: {
            Text(BakingTerms.bakePickerReplaceActiveMessage)
        }
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes
            .filter { store.isReadyToBake($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func bakeCount(for recipe: SavedRecipe) -> Int {
        store.bakeHistory.filter { $0.recipeID == recipe.id }.count
    }

    private func select(_ recipe: SavedRecipe) {
        if store.hasActiveBakeInProgress {
            replacementRecipe = recipe
            isReplacementDialogPresented = true
            return
        }

        startBake(with: recipe)
    }

    private func startBake(with recipe: SavedRecipe) {
        store.loadRecipe(recipe)
        navigationController.push(.cook)
    }
}
