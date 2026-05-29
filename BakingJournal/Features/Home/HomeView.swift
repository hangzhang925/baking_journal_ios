import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        tabContent(navigationController.selectedTab)
        .background(Color.brandBackground)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: AppRoute.self) { route in
            routeDestination(route)
                .navigationBarBackButtonHidden(true)
        }
    }

    @ViewBuilder
    private func tabContent(_ tab: HomeTab) -> some View {
        switch tab {
        case .home:
            HomeFeedPlaceholderView()
        case .formula:
            recipeLibraryTab
        case .history:
            BakeHistoryView()
        case .starter:
            StarterView()
        }
    }

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        switch route {
        case .recipeSourcePicker:
            RecipeSourcePickerView()
        case .bakeRecipePicker:
            BakeRecipePickerView()
        case .recipeWorkspace(let initialStage):
            RecipeWorkspaceView(initialStage: initialStage)
        case .recipeItemEditor(let itemID):
            RecipeItemEditorRouteView(itemID: itemID)
        case .cook:
            CookView()
        case .bakeRecordDetail(let recordID):
            BakeRecordDetailView(recordID: recordID)
        }
    }

    private var recipeLibraryTab: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(trailing: {
                recipeActionsMenu
            })

            recipeLibrary
        }
    }

    private var recipeActionsMenu: some View {
        BakingIconButton(
            icon: .add,
            accessibilityLabel: BakingTerms.addRecipe,
            role: .primary
        ) {
            navigationController.push(.recipeSourcePicker)
        }
    }

    private var recipeLibrary: some View {
        List {
            if store.hasActiveBakeInProgress {
                Section {
                    Button {
                        navigationController.push(.cook)
                    } label: {
                        ActiveBakeResumeRow(
                            recipeName: store.activeBakeRecord?.recipeSnapshotName ?? store.currentRecipeDisplayName,
                            stepName: store.currentCookStep?.name ?? BakingTerms.continueBake,
                            stepIndex: store.cookState.currentIndex,
                            totalSteps: store.steps.count
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(BakingTerms.activeBakeSection)
                }
                .listRowBackground(BakingSurface.cardBackground)
            }

            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if sortedRecipes.isEmpty {
                    BakingEmptyState(title: BakingTerms.noRecipes, systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            if store.hasActiveBakeInProgress, recipe.id == store.currentRecipeID {
                                navigationController.push(.recipeWorkspace(.preview))
                            } else {
                                store.loadRecipe(recipe)
                                navigationController.push(.recipeWorkspace(.preview))
                            }
                        } label: {
                            RecipeLibraryRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(BakingSurface.cardBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.deleteRecipe(recipe)
                            } label: {
                                Label(BakingTerms.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listRowBackground(BakingSurface.cardBackground)
        }
        .listStyle(.insetGrouped)
        .contentMargins(.top, BakingLayout.contentTopInset, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes.sorted { $0.updatedAt > $1.updatedAt }
    }
}

enum HomeTab {
    case home
    case formula
    case history
    case starter

    var title: String {
        switch self {
        case .home: BakingTerms.homeTabTitle
        case .formula: BakingTerms.recipeTabTitle
        case .history: BakingTerms.bakeHistoryTabTitle
        case .starter: BakingTerms.starterTabTitle
        }
    }

    var icon: BakingIcon {
        switch self {
        case .home: .home
        case .formula: .recipe
        case .history: .timer
        case .starter: .starter
        }
    }
}

struct BakingTabBar: View {
    @Binding var selection: HomeTab
    let isStarterReminderDue: Bool

    private let tabs: [HomeTab] = [.home, .formula, .history, .starter]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    BakingTabItem(
                        tab: tab,
                        isSelected: selection == tab,
                        showsBadge: tab == .starter && isStarterReminderDue
                    )
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(tab.title)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, BakingSpace.lg)
        .padding(.top, BakingSpace.xs)
        .padding(.bottom, BakingSpace.xs)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.brandPrimary.opacity(0.08))
                .frame(height: 0.6)
        }
    }
}

private struct BakingTabItem: View {
    let tab: HomeTab
    let isSelected: Bool
    let showsBadge: Bool

    var body: some View {
        BakingTabIconLabel(
            icon: tab.icon,
            isSelected: isSelected,
            showsBadge: showsBadge
        )
    }
}

private struct HomeFeedPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: BakingSpace.sm) {
                BakingMaterialIconBadge(
                    icon: .home,
                    size: BakingTouchTarget.materialBadge,
                    iconSize: BakingTouchTarget.materialBadgeGlyph,
                    color: .brandPrimary,
                    background: Color.brandPrimary.opacity(0.10)
                )

                Text(BakingTerms.homeFeedPlaceholderTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.brandText)

                Text(BakingTerms.homeFeedPlaceholderBody)
                    .font(.callout)
                    .foregroundStyle(Color.brandSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, BakingSpace.xxl)
            .padding(.vertical, 48)
            .bakingCard()
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)
        }
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }
}

private struct ActiveBakeResumeRow: View {
    let recipeName: String
    let stepName: String
    let stepIndex: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 14) {
            BakingMaterialIconBadge(
                icon: .start,
                color: .brandPrimary,
                background: Color.brandPrimary.opacity(0.10)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(recipeName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)

                Text(BakingTerms.activeBakeProgress(stepIndex: stepIndex + 1, totalSteps: totalSteps, stepName: stepName))
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(BakingTerms.continueAction)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
