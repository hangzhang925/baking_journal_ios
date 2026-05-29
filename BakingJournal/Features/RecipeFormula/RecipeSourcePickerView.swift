import SwiftUI

struct RecipeSourcePickerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            })

            List {
                Section {
                    Button {
                        store.createDraftRecipe()
                        navigationController.push(.recipeWorkspace(.formula))
                    } label: {
                        RecipeSourceRow(
                            icon: .start,
                            title: BakingTerms.recipeSourceStartBlank,
                            detail: BakingTerms.recipeSourceStartBlankDetail
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    BakingLabel(text: BakingTerms.recipeSourceNewSection, role: .sectionHeader)
                }

                Section(BakingTerms.recipeSourceTemplatesSection) {
                    ForEach(RecipeStore.RecipeTemplate.allCases) { template in
                        Button {
                            store.applyTemplate(template)
                            store.saveCurrentRecipe()
                            navigationController.push(.recipeWorkspace(.formula))
                        } label: {
                            RecipeSourceRow(
                                icon: .recipe,
                                title: template.label,
                                detail: presetDetail(for: template)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(BakingTerms.recipeSourceExistingSection) {
                    if sortedRecipes.isEmpty {
                        BakingEmptyState(title: BakingTerms.recipeSourceEmptySaved, systemImage: "book.closed")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(sortedRecipes) { recipe in
                            Button {
                                store.createRecipeCopy(from: recipe)
                                store.saveCurrentRecipe()
                                navigationController.push(.recipeWorkspace(.formula))
                            } label: {
                                RecipeSourceRow(
                                    icon: .recipe,
                                    title: recipe.name,
                                    detail: recipe.updatedAt.formatted(date: .abbreviated, time: .shortened)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.brandBackground)
        }
        .background(Color.brandBackground)
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func presetDetail(for template: RecipeStore.RecipeTemplate) -> String {
        switch template {
        case .toast:
            return "吐司基础配方"
        case .chiffon:
            return "戚风蛋糕基础配方"
        case .countryBread:
            return "欧包基础配方"
        }
    }
}

private struct RecipeSourceRow: View {
    let icon: BakingIcon
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            BakingMaterialIconBadge(icon: icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .bakingLabelStyle(.inputLabel)
                    .lineLimit(1)

                Text(detail)
                    .bakingLabelStyle(.helperText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandSecondaryText.opacity(0.72))
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
