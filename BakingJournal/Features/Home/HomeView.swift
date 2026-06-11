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
        case .aiRecipeImport:
            AIRecipeImportView()
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
                    isSelected: recipeStatusFilter != .all,
                    tintOverride: recipeStatusFilter.iconTint
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
                } else if displayedRecipeRows.isEmpty {
                    BakingEmptyState(title: BakingTerms.noMatchingRecipes, systemImage: "line.3.horizontal.decrease.circle")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(displayedRecipeRows) { row in
                        Button {
                            store.loadRecipe(row.recipe)
                            navigationController.push(.recipeWorkspace(.preview))
                        } label: {
                            RecipeLibraryRow(
                                recipe: row.recipe,
                                bakeCount: bakeCount(for: row.recipe),
                                filterMatchState: row.filterMatchState
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(BakingSurface.rowBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                recipePendingDeletion = row.recipe
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

    private var displayedRecipeRows: [RecipeLibraryDisplayRow] {
        let trimmedSearch = recipeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedSearch.isEmpty {
            return sortedByModified(
                recipeLibraryCandidates.filter { recipe in
                    recipeStatusFilter.includes(recipe) &&
                    recipe.name.localizedStandardContains(trimmedSearch)
                }
            ).map { recipe in
                RecipeLibraryDisplayRow(
                    recipe: recipe,
                    filterMatchState: .matching
                )
            }
        }

        let filteredInRows = sortedByModified(
            recipeLibraryCandidates.filter { recipeStatusFilter.includes($0) }
        ).map { recipe in
            RecipeLibraryDisplayRow(
                recipe: recipe,
                filterMatchState: .matching
            )
        }

        let filteredOutRows = sortedByModified(
            recipeLibraryCandidates.filter { !recipeStatusFilter.includes($0) }
        ).map { recipe in
            RecipeLibraryDisplayRow(
                recipe: recipe,
                filterMatchState: .filteredOut
            )
        }

        return filteredInRows + filteredOutRows
    }

    private func sortedByModified(_ recipes: [SavedRecipe]) -> [SavedRecipe] {
        recipes.sorted { lhs, rhs in
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

private struct RecipeLibraryDisplayRow: Identifiable {
    let recipe: SavedRecipe
    let filterMatchState: BakingFilterMatchState

    var id: UUID { recipe.id }
}

private enum RecipeLibraryStatusFilter: CaseIterable, Hashable, Identifiable {
    case all
    case ready
    case draft

    var id: Self { self }

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

    var iconTint: Color? {
        switch self {
        case .all:
            return nil
        case .ready:
            return RecipeWorkflowState.ready.badgeForegroundColor
        case .draft:
            return RecipeWorkflowState.draft.badgeForegroundColor
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

    var analyticsName: String {
        switch self {
        case .formula: "formula"
        case .history: "history"
        case .starter: "starter"
        case .settings: "settings"
        }
    }

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

    private let tabs: [HomeTab] = [.formula, .history, .starter, .settings]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    BakingAnalytics.logNavTabClick(tabName: tab.analyticsName)
                    selection = tab
                } label: {
                    BakingTabItem(
                        tab: tab,
                        isSelected: selection == tab
                    )
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(tab.title)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, BakingSpace.lg)
        .padding(.top, BakingComponentMetrics.tabBarVerticalPadding)
        .padding(.bottom, BakingComponentMetrics.tabBarVerticalPadding)
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

    var body: some View {
        VStack(spacing: 0) {
            BakingTabIconLabel(
                icon: tab.icon,
                isSelected: isSelected
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
    @EnvironmentObject private var languageSettings: AppLanguageSettings
    @State private var showingLanguageDropdown = false
    @State private var showingOnboardingTutorial = false
    @State private var showingAboutBready = false

    var body: some View {
        BakingLibraryList {
            Section {
                Button {
                    showingLanguageDropdown = true
                } label: {
                    SettingsNavigationRow(
                        icon: .settings,
                        title: BakingTerms.settingsLanguageTitle,
                        detail: languageSettings.selectedLanguage.displayName,
                        accessory: .dropdown
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.settingsLanguageOpenAccessibility)
                .accessibilityValue(languageSettings.selectedLanguage.displayName)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(BakingSurface.rowBackground)
                .popover(isPresented: $showingLanguageDropdown, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    languageDropdown
                }

                Button {
                    navigationController.push(.kitchenTimer)
                } label: {
                    SettingsNavigationRow(
                        icon: .timer,
                        title: BakingTerms.kitchenTimerTitle
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.kitchenTimerOpenAccessibility)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(BakingSurface.rowBackground)

                Button {
                    showingOnboardingTutorial = true
                } label: {
                    SettingsNavigationRow(
                        icon: .preview,
                        title: BakingTerms.settingsTutorialTitle
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.settingsTutorialOpenAccessibility)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(BakingSurface.rowBackground)
            }
            .listRowBackground(BakingSurface.rowBackground)

            // Keep About Bready as the final settings entry.
            Section {
                Button {
                    showingAboutBready = true
                } label: {
                    SettingsNavigationRow(
                        icon: .settings,
                        title: BakingTerms.settingsAboutTitle
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.settingsAboutOpenAccessibility)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(BakingSurface.rowBackground)
            }
            .listRowBackground(BakingSurface.rowBackground)
        }
        .background(Color.brandBackground)
        .sheet(isPresented: $showingOnboardingTutorial) {
            OnboardingView {
                showingOnboardingTutorial = false
            }
            .presentationBackground(Color.brandBackground)
        }
        .sheet(isPresented: $showingAboutBready) {
            SettingsAboutBreadyView()
                .presentationDragIndicator(.visible)
        }
    }

    private var languageDropdown: some View {
        BakingDropdownPopover(width: 220) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    showingLanguageDropdown = false
                    languageSettings.select(language)
                } label: {
                    BakingDropdownRow(
                        title: language.displayName,
                        isSelected: language == languageSettings.selectedLanguage,
                        showsLeadingSlot: false
                    ) {
                        EmptyView()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(language.displayName)
            }
        }
    }
}

private struct SettingsAboutBreadyView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(BakingTerms.settingsAboutFeedbackMessage)
                        .bakingLabelStyle(.inputLabel)

                    Text(BakingTerms.settingsAboutLocalDataMessage)
                        .bakingLabelStyle(.helperText)
                }
                .listRowBackground(BakingSurface.rowBackground)

                Section {
                    SettingsContactRow(
                        title: BakingTerms.settingsAboutVersion,
                        value: AppInfo.current.displayVersion(
                            fallback: BakingTerms.settingsAboutVersionUnavailable
                        )
                    )

                    SettingsContactRow(
                        title: BakingTerms.settingsAboutContactEmail,
                        value: BakingTerms.settingsAboutContactEmailValue
                    )

                    SettingsContactRow(
                        title: BakingTerms.settingsAboutXiaohongshu,
                        value: BakingTerms.settingsAboutXiaohongshuValue
                    )

                    SettingsContactRow(
                        title: BakingTerms.settingsAboutInstagram,
                        value: BakingTerms.settingsAboutInstagramValue
                    )
                }
                .listRowBackground(BakingSurface.rowBackground)
            }
            .navigationTitle(BakingTerms.settingsAboutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.brandBackground)
        }
        .presentationBackground(Color.brandBackground)
    }
}

private struct SettingsContactRow: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent {
            Text(value)
                .bakingLabelStyle(.helperText)
                .multilineTextAlignment(.trailing)
        } label: {
            BakingLabel(text: title, role: .inputLabel)
        }
    }
}

private struct SettingsNavigationRow: View {
    let icon: BakingIcon
    let title: String
    var detail: String?
    var accessory: SettingsRowAccessory = .navigation

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
                        .font(BakingTypography.helperText)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: BakingSpace.sm)

            Image(systemName: accessory.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandTertiaryText)
        }
        .frame(minHeight: BakingComponentMetrics.listRowMinHeight)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }
}

private enum SettingsRowAccessory {
    case navigation
    case dropdown

    var systemImage: String {
        switch self {
        case .navigation:
            return "chevron.right"
        case .dropdown:
            return "chevron.down"
        }
    }
}
