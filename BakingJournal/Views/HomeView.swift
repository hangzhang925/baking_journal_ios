import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var showingRecipeActions = false

    var body: some View {
        currentTabContent
            .safeAreaInset(edge: .bottom) {
                BakingTabBar(
                    selection: Binding(
                        get: { navigationController.selectedTab },
                        set: { navigationController.selectTab($0) }
                    ),
                    isStarterReminderDue: store.isStarterReminderDue
                )
            }
        .background(Color.brandBackground)
        .toolbar {
            if navigationController.selectedTab == .formula {
                ToolbarItem(placement: .topBarTrailing) {
                    recipeActionsMenu
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: AppRoute.self) { route in
            routeDestination(route)
                .navigationBarBackButtonHidden(true)
        }
    }

    @ViewBuilder
    private var currentTabContent: some View {
        switch navigationController.selectedTab {
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
        case .recipePreview:
            RecipePreviewView()
        case .recipeWorkspace(let initialStage):
            RecipeWorkspaceView(initialStage: initialStage)
        case .cook:
            CookView()
        case .bakeRecordDetail(let recordID):
            BakeRecordDetailView(recordID: recordID)
        }
    }

    private var recipeLibraryTab: some View {
        recipeLibrary
    }

    private var recipeActionsMenu: some View {
        Button {
            showingRecipeActions = true
        } label: {
            BakingSystemIconButtonLabel(systemImage: "plus")
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.moreActions)
        .popover(isPresented: $showingRecipeActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingDropdownPopover(width: 188) {
                if store.hasActiveBakeInProgress {
                    Button {
                        showingRecipeActions = false
                        navigationController.push(.cook)
                    } label: {
                        BakingDropdownRow(title: BakingTerms.continueBake) {
                            Image(systemName: "play.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showingRecipeActions = false
                    navigationController.push(.recipeSourcePicker)
                } label: {
                    BakingDropdownRow(title: BakingTerms.addRecipe) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    showingRecipeActions = false
                    if store.hasActiveBakeInProgress {
                        navigationController.push(.cook)
                    } else {
                        navigationController.push(.bakeRecipePicker)
                    }
                } label: {
                    BakingDropdownRow(title: BakingTerms.bakeAction) {
                        Image(systemName: "flame")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.brandPrimary)
                    }
                }
                .buttonStyle(.plain)
            }
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
            }

            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if sortedRecipes.isEmpty {
                    ContentUnavailableView(BakingTerms.noRecipes, systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            if store.hasActiveBakeInProgress, recipe.id == store.currentRecipeID {
                                navigationController.push(.recipePreview)
                            } else {
                                store.loadRecipe(recipe)
                                navigationController.push(.recipePreview)
                            }
                        } label: {
                            RecipeLibraryRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
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
        }
        .listStyle(.insetGrouped)
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

private struct BakingTabBar: View {
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
        ZStack(alignment: .topTrailing) {
            BakingIconView(
                icon: tab.icon,
                size: BakingTouchTarget.tabIconGlyph,
                color: isSelected ? .brandPrimary : .brandText
            )
            .frame(width: BakingTouchTarget.tabIconSurface, height: BakingTouchTarget.tabIconSurface)

            if showsBadge {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 7, height: 7)
                    .offset(x: 1, y: 1)
            }
        }
        .frame(width: BakingTouchTarget.primaryAction, height: BakingTouchTarget.primaryAction)
        .contentShape(Rectangle())
    }
}

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
            .padding(.horizontal, 14)
            .padding(.top, 6)
        }
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }
}

private struct BakeHistoryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if sortedHistory.isEmpty {
                    ContentUnavailableView(BakingTerms.noRecords, systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedHistory) { record in
                        if record.id == store.activeBakeRecordID && record.completedAt == nil {
                            Button {
                                navigationController.push(.cook)
                            } label: {
                                BakeHistoryRow(record: record)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                navigationController.push(.bakeRecordDetail(record.id))
                            } label: {
                                BakeHistoryRow(record: record)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var sortedHistory: [BakeRecord] {
        store.bakeHistory.sorted { $0.startedAt > $1.startedAt }
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

private struct BakeHistoryRow: View {
    let record: BakeRecord

    var body: some View {
        HStack(spacing: 12) {
            BakingMaterialIconBadge(
                icon: .timer,
                size: BakingTouchTarget.materialBadge,
                iconSize: BakingTouchTarget.materialBadgeGlyph,
                color: statusColor,
                background: statusColor.opacity(0.10)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(record.recipeSnapshotName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
            }

            Spacer()

            Image(systemName: record.completedAt == nil ? "flame.fill" : "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 3)
    }

    private var statusColor: Color {
        record.completedAt == nil ? .brandPrimary : .brandSage
    }

    private var dateRangeText: String {
        let start = record.startedAt.formatted(date: .abbreviated, time: .shortened)
        if let completedAt = record.completedAt {
            return "\(start) - \(completedAt.formatted(date: .omitted, time: .shortened))"
        }
        return start
    }
}

enum RecipeWorkspaceStage: String, CaseIterable, Hashable, Identifiable {
    case formula
    case steps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .formula: BakingTerms.workspaceStageFormula
        case .steps: BakingTerms.workspaceStageSteps
        }
    }
}

struct RecipeWorkspaceView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var stage: RecipeWorkspaceStage
    @State private var justSaved = false

    init(initialStage: RecipeWorkspaceStage = .formula) {
        _stage = State(initialValue: initialStage)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                workspaceStageControl
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(Color.brandBackground)

            Group {
                switch stage {
                case .formula:
                    FormulaView(embedded: true)
                case .steps:
                    StepsView(embedded: true)
                }
            }
        }
        .background(Color.brandBackground)
    }

    private var workspaceStageControl: some View {
        Picker(BakingTerms.workspaceStagePicker, selection: $stage) {
            ForEach(RecipeWorkspaceStage.allCases) { stage in
                Text(stage.title).tag(stage)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
    }

    private var saveButton: some View {
        Button {
            store.saveCurrentRecipe()
            flashSavedState()
        } label: {
            BakingSystemIconButtonLabel(
                systemImage: justSaved ? "checkmark.circle.fill" : "checkmark",
                tint: justSaved ? .brandSage : .brandPrimary,
                background: .brandSurface
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(justSaved ? BakingTerms.saved : BakingTerms.save)
    }

    private func flashSavedState() {
        justSaved = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            justSaved = false
        }
    }
}

private struct BakeRecordDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    let recordID: UUID

    var body: some View {
        List {
            Section(BakingTerms.time) {
                LabeledContent(BakingTerms.start) {
                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent(BakingTerms.end) {
                    if let completedAt = record.completedAt {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        Text(BakingTerms.notFinished)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent(BakingTerms.stepCount) {
                    Text("\(record.stepCount)")
                        .monospacedDigit()
                }
            }

            Section(BakingTerms.reviewNotes) {
                TextEditor(text: notesBinding)
                    .frame(minHeight: 160)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var record: BakeRecord {
        store.bakeHistory.first(where: { $0.id == recordID }) ?? BakeRecord(
            id: recordID,
            recipeID: nil,
            recipeName: BakingTerms.unknownRecipe,
            recipeSnapshotName: BakingTerms.unknownRecipe,
            startedAt: Date(),
            completedAt: nil,
            notes: "",
            stepCount: 0
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { record.notes },
            set: { store.updateBakeRecordNotes($0, for: record) }
        )
    }
}
