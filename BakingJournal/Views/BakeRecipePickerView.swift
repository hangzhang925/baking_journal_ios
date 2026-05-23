import SwiftUI

struct BakeRecipePickerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                if sortedRecipes.isEmpty {
                    ContentUnavailableView("还没有可烘焙的配方", systemImage: "flame")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            store.loadRecipe(recipe)
                            navigationController.push(.recipePreview)
                        } label: {
                            RecipeLibraryRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("选择一个配方")
            } footer: {
                if !sortedRecipes.isEmpty {
                    Text("进入预览后，你可以再决定什么时候开始烘焙。")
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
