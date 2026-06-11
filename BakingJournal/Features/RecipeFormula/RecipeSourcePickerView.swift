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

            BakingLibraryList {
                Section {
                    recipeSourceButton(
                        icon: .recipeCustom,
                        title: BakingTerms.aiRecipeImportEntry
                    ) {
                        navigationController.push(.aiRecipeImport)
                    }
                } header: {
                    RecipeSourceSectionHeader(title: BakingTerms.recipeSourceNewSection)
                }

                Section {
                    recipeSourceButton(
                        icon: .recipeCustom,
                        title: BakingTerms.recipeSourceCustom,
                        detail: BakingTerms.recipeSourceStartBlankDetail
                    ) {
                        store.createDraftRecipe()
                        navigationController.push(.recipeWorkspace(.formula))
                    }

                    ForEach(RecipeStore.RecipeTemplate.allCases) { template in
                        recipeSourceButton(
                            icon: presetIcon(for: template),
                            title: template.label,
                            detail: presetDetail(for: template)
                        ) {
                            store.applyTemplate(template)
                            store.saveCurrentRecipe()
                            navigationController.push(.recipeWorkspace(.formula))
                        }
                    }
                } header: {
                    RecipeSourceSectionHeader(title: BakingTerms.recipeSourceTemplatesSection)
                }

                Section {
                    if sortedRecipes.isEmpty {
                        BakingEmptyState(title: BakingTerms.recipeSourceEmptySaved, systemImage: "book.closed")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(sortedRecipes) { recipe in
                            recipeSourceButton(
                                icon: BakingIcon.recipeKind(recipe.kind),
                                title: recipe.name
                            ) {
                                store.createRecipeCopy(from: recipe)
                                store.saveCurrentRecipe()
                                navigationController.push(.recipeWorkspace(.formula))
                            }
                        }
                    }
                } header: {
                    RecipeSourceSectionHeader(title: BakingTerms.recipeSourceExistingSection)
                }
            }
            .listSectionSpacing(BakingSpace.sm)
        }
        .background(Color.brandBackground)
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func presetDetail(for template: RecipeStore.RecipeTemplate) -> String {
        switch template {
        case .toast:
            return BakingTerms.recipeSourceToastTemplateDetail
        case .chiffon:
            return BakingTerms.recipeSourceChiffonTemplateDetail
        case .countryBread:
            return BakingTerms.recipeSourceCountryBreadTemplateDetail
        }
    }

    private func presetIcon(for template: RecipeStore.RecipeTemplate) -> BakingIcon {
        switch template {
        case .toast:
            return .recipeToast
        case .chiffon:
            return .recipeCake
        case .countryBread:
            return .recipeCountryBread
        }
    }

    private func recipeSourceButton(
        icon: BakingIcon,
        title: String,
        detail: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            RecipeSourceRow(icon: icon, title: title, detail: detail)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(BakingSurface.rowBackground)
    }
}

private struct RecipeSourceSectionHeader: View {
    let title: String

    var body: some View {
        BakingLabel(text: title, role: .sectionHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textCase(nil)
    }
}

private struct RecipeSourceRow: View {
    let icon: BakingIcon
    let title: String
    let detail: String?

    var body: some View {
        HStack(spacing: BakingSpace.lg) {
            BakingMaterialIconBadge(icon: icon)

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(title)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                if let detail {
                    Text(detail)
                        .bakingLabelStyle(.helperText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandTertiaryText)
        }
        .frame(minHeight: BakingComponentMetrics.listRowMinHeight)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
