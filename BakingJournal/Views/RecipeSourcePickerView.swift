import SwiftUI

struct RecipeSourcePickerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                Button {
                    store.createEmptyRecipe()
                    navigationController.push(.recipeWorkspace(.formula))
                } label: {
                    RecipeSourceRow(
                        icon: .start,
                        title: "从空白开始",
                        detail: "手动搭建一个全新的配方"
                    )
                }
                .buttonStyle(.plain)
            } header: {
                Text("新建")
            }

            Section("系统预设") {
                ForEach(RecipeStore.RecipeTemplate.allCases) { template in
                    Button {
                        store.applyTemplate(template)
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

            Section("从已有配方开始") {
                if sortedRecipes.isEmpty {
                    ContentUnavailableView("还没有已保存配方", systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            store.createRecipeCopy(from: recipe)
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
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
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
