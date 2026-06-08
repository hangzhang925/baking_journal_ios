import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var recipeStatusFilter: RecipeLibraryStatusFilter = .all
    @State private var recipeModifiedSort: RecipeModifiedSort = .newestFirst
    @State private var recipeSearchText = ""
    @State private var recipePendingDeletion: SavedRecipe?
    @State private var showingDeleteRecipeConfirmation = false

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
        case .formula:
            recipeLibraryTab
        case .history:
            BakeHistoryView()
        case .starter:
            StarterView()
        case .settings:
            SettingsTabView()
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
        case .starterDetail(let starterID):
            StarterDetailRouteView(starterID: starterID)
        case .cook:
            CookView()
        case .toolbox:
            ToolboxView()
        case .kitchenTimer:
            KitchenTimerView()
        case .bakeRecordDetail(let recordID):
            BakeRecordDetailView(recordID: recordID)
        }
    }

    private var recipeLibraryTab: some View {
        BakingLibraryListShell(
            searchText: $recipeSearchText,
            searchPrompt: BakingTerms.recipeSearchPrompt,
            clearSearchAccessibilityLabel: BakingTerms.clearRecipeSearch,
            filters: { recipeFilterControls },
            action: { recipeActionsMenu }
        ) {
            recipeLibrary
        }
    }

    private var recipeFilterControls: some View {
        HStack(spacing: BakingSpace.xs) {
            Button {
                recipeStatusFilter = recipeStatusFilter.next
            } label: {
                BakingIconButtonLabel(
                    icon: recipeStatusFilter.icon,
                    role: .primary,
                    size: .primary,
                    isSelected: recipeStatusFilter != .all
                )
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .accessibilityLabel(BakingTerms.recipeStatusFilter)
            .accessibilityValue(recipeStatusFilter.accessibilityValue)

            Button {
                recipeModifiedSort = recipeModifiedSort.toggled
            } label: {
                BakingIconButtonLabel(
                    icon: recipeModifiedSort.icon,
                    role: .secondary,
                    size: .primary,
                    isSelected: recipeModifiedSort == .oldestFirst
                )
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .accessibilityLabel(BakingTerms.recipeSortModified)
            .accessibilityValue(recipeModifiedSort.accessibilityValue)
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
        BakingLibraryList {
            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if recipeLibraryCandidates.isEmpty {
                    BakingEmptyState(title: BakingTerms.noRecipes, systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else if displayedRecipes.isEmpty {
                    BakingEmptyState(title: BakingTerms.noMatchingRecipes, systemImage: "line.3.horizontal.decrease.circle")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(displayedRecipes) { recipe in
                        Button {
                            store.loadRecipe(recipe)
                            navigationController.push(.recipeWorkspace(.preview))
                        } label: {
                            RecipeLibraryRow(
                                recipe: recipe,
                                bakeCount: bakeCount(for: recipe)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(BakingSurface.rowBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                recipePendingDeletion = recipe
                                showingDeleteRecipeConfirmation = true
                            } label: {
                                Label(BakingTerms.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listRowBackground(BakingSurface.rowBackground)
        }
        .confirmationDialog(
            BakingTerms.deleteRecipeConfirmationTitle,
            isPresented: $showingDeleteRecipeConfirmation,
            titleVisibility: .visible,
            presenting: recipePendingDeletion
        ) { recipe in
            Button(BakingTerms.deleteRecipeConfirmationButton, role: .destructive) {
                store.deleteRecipe(recipe)
                recipePendingDeletion = nil
            }
            Button(BakingTerms.cancel, role: .cancel) {
                recipePendingDeletion = nil
            }
        } message: { recipe in
            Text(BakingTerms.deleteRecipeConfirmationMessage(recipe.name))
        }
        .onChange(of: showingDeleteRecipeConfirmation) { _, isPresented in
            if !isPresented {
                recipePendingDeletion = nil
            }
        }
    }

    private var displayedRecipes: [SavedRecipe] {
        let filteredByStatus = recipeLibraryCandidates.filter { recipe in
            recipeStatusFilter.includes(recipe)
        }
        let trimmedSearch = recipeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredByName = trimmedSearch.isEmpty ? filteredByStatus : filteredByStatus.filter { recipe in
            recipe.name.localizedStandardContains(trimmedSearch)
        }
        return filteredByName.sorted { lhs, rhs in
            switch recipeModifiedSort {
            case .newestFirst:
                return lhs.updatedAt > rhs.updatedAt
            case .oldestFirst:
                return lhs.updatedAt < rhs.updatedAt
            }
        }
    }

    private var recipeLibraryCandidates: [SavedRecipe] {
        store.savedRecipes
    }

    private func bakeCount(for recipe: SavedRecipe) -> Int {
        store.bakeHistory.filter { $0.recipeID == recipe.id }.count
    }
}

private enum RecipeLibraryStatusFilter {
    case all
    case ready
    case draft

    var next: RecipeLibraryStatusFilter {
        switch self {
        case .all:
            return .ready
        case .ready:
            return .draft
        case .draft:
            return .all
        }
    }

    var icon: BakingIcon {
        switch self {
        case .all:
            return .filterAll
        case .ready:
            return .complete
        case .draft:
            return .edit
        }
    }

    var accessibilityValue: String {
        switch self {
        case .all:
            return BakingTerms.recipeStatusFilterAll
        case .ready:
            return RecipeWorkflowState.ready.label
        case .draft:
            return RecipeWorkflowState.draft.label
        }
    }

    func includes(_ recipe: SavedRecipe) -> Bool {
        switch self {
        case .all:
            return true
        case .ready:
            return recipe.workflowState == .ready
        case .draft:
            return recipe.workflowState == .draft
        }
    }
}

private enum RecipeModifiedSort {
    case newestFirst
    case oldestFirst

    var icon: BakingIcon {
        switch self {
        case .newestFirst:
            return .sortNewest
        case .oldestFirst:
            return .sortOldest
        }
    }

    var toggled: RecipeModifiedSort {
        switch self {
        case .newestFirst:
            return .oldestFirst
        case .oldestFirst:
            return .newestFirst
        }
    }

    var accessibilityValue: String {
        switch self {
        case .newestFirst:
            return BakingTerms.recipeSortModifiedNewest
        case .oldestFirst:
            return BakingTerms.recipeSortModifiedOldest
        }
    }
}

enum HomeTab {
    case formula
    case history
    case starter
    case settings

    var title: String {
        switch self {
        case .formula: BakingTerms.recipeTabTitle
        case .history: BakingTerms.bakeHistoryTabTitle
        case .starter: BakingTerms.starterTabTitle
        case .settings: BakingTerms.settingsTabTitle
        }
    }

    var icon: BakingIcon {
        switch self {
        case .formula: .recipe
        case .history: .bakes
        case .starter: .starter
        case .settings: .settings
        }
    }
}

struct BakingTabBar: View {
    @Binding var selection: HomeTab
    let isStarterReminderDue: Bool

    private let tabs: [HomeTab] = [.formula, .history, .starter, .settings]

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
        .padding(.top, BakingSpace.xxs)
        .padding(.bottom, BakingSpace.xxs)
        .frame(maxWidth: .infinity)
        .background(BakingSurface.bottomBarBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BakingSurfaceTheme.separator)
                .frame(height: 0.6)
        }
    }
}

private struct BakingTabItem: View {
    let tab: HomeTab
    let isSelected: Bool
    let showsBadge: Bool

    var body: some View {
        VStack(spacing: 0) {
            BakingTabIconLabel(
                icon: tab.icon,
                isSelected: isSelected,
                showsBadge: showsBadge
            )

            Text(tab.title)
                .font(BakingTypography.tabCaption)
                .foregroundStyle(isSelected ? BakingNavigationItemTheme.selectedTextColor : BakingNavigationItemTheme.defaultTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: BakingComponentMetrics.tabItemHeight)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(isSelected ? BakingNavigationItemTheme.selectedTextColor : Color.clear)
                .frame(height: BakingComponentMetrics.stageIndicatorHeight)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tab.title)
    }
}

private struct SettingsTabView: View {
    @EnvironmentObject private var navigationController: AppNavigationController

    var body: some View {
        List {
            Section {
                Button {
                    navigationController.push(.toolbox)
                } label: {
                    SettingsNavigationRow(
                        icon: .toolbox,
                        title: BakingTerms.toolboxTitle,
                        detail: BakingTerms.settingsToolboxDetail
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.toolboxTitle)
            } header: {
                Text(BakingTerms.settingsSectionTools)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }
}

private struct ToolboxView: View {
    @EnvironmentObject private var navigationController: AppNavigationController

    var body: some View {
        List {
            Section {
                Button {
                    navigationController.push(.kitchenTimer)
                } label: {
                    SettingsNavigationRow(
                        icon: .timer,
                        title: BakingTerms.kitchenTimerTitle,
                        detail: BakingTerms.toolboxKitchenTimerDetail
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.kitchenTimerOpenAccessibility)
            } header: {
                Text(BakingTerms.toolboxSectionTools)
            }
        }
        .navigationTitle(BakingTerms.toolboxTitle)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }
}

private struct SettingsNavigationRow: View {
    let icon: BakingIcon
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            BakingMaterialIconBadge(
                icon: icon,
                color: .brandPrimary,
                background: BakingSurfaceTheme.theme(for: .inputSurface).background
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)

                Text(detail)
                    .font(BakingTypography.appSecondaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: BakingSpace.sm)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandTertiaryText)
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
