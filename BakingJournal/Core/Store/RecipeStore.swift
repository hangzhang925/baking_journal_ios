import Foundation

@MainActor
final class RecipeStore: ObservableObject {
    enum RecipeTemplate: String, CaseIterable, Identifiable {
        case toast
        case chiffon
        case countryBread

        var id: String { rawValue }

        var label: String {
            switch self {
            case .toast: BakingTerms.toastTemplateLabel
            case .chiffon: BakingTerms.chiffonTemplateLabel
            case .countryBread: BakingTerms.countryBreadTemplateLabel
            }
        }
    }

    @Published var recipeName: String = BakingTerms.toastRecipeName {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var recipeOverallNotes: String = "" {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var stepText: String = "" {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var items: [RecipeItem] = [] {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var steps: [JournalStep] = [] {
        didSet {
            syncStepModeBackupFromActiveSteps()
            if steps.isEmpty {
                currentWorkflowState = .draft
            }
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var cookState = CookState() { didSet { persist() } }
    @Published var currentRecipeID: UUID? { didSet { persist() } }
    @Published var savedRecipes: [SavedRecipe] = [] { didSet { persist() } }
    @Published var bakeHistory: [BakeRecord] = [] { didSet { persist() } }
    @Published var activeBakeRecordID: UUID? { didSet { persist() } }
    @Published var starterProfiles: [StarterProfile] = [StarterProfile()] { didSet { persist() } }
    @Published var currentWorkflowState: RecipeWorkflowState = .draft {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var currentRecipeKind: RecipeKind = .toast {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var formulaIngredientLockMode: FormulaIngredientLockMode = .weight {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published var stepsMode: RecipeStepsMode = .simple {
        didSet {
            persist()
            autosaveCurrentRecipeIfNeeded()
        }
    }
    @Published private(set) var hasLoadedPersistedState = false

    static let starterOptions = [BakingTerms.levainStarter, BakingTerms.liquidStarter, BakingTerms.tangzhongStarter, BakingTerms.scaldedStarter, BakingTerms.poolishStarter]
    static let starterRatioOptions = ["1:1", "1:2", "1:5"]
    static let yeastOptions = [BakingTerms.dryYeast, BakingTerms.freshYeast, BakingTerms.liquidYeast]
    static let eggOptions = [BakingTerms.yolk, BakingTerms.white, BakingTerms.beatenEgg]
    static let eggWaterContent = [
        BakingTerms.wholeEgg: 75.0,
        BakingTerms.beatenEgg: 75.0,
        BakingTerms.yolk: 48.0,
        BakingTerms.white: 88.0
    ]
    static let starterReminderHours = [9, 12, 17]

    static var starterReminderTimeLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        return starterReminderHours.compactMap { hour in
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()).map {
                formatter.string(from: $0)
            }
        }
    }

    private let notifications: BakingNotificationScheduling
    private let storageKey = "baking-journal-ios:state"
    private var isLoading = false
    private var simpleStep = RecipeStore.makeSimpleStep()
    private var customSteps: [JournalStep] = []

    init(notifications: BakingNotificationScheduling) {
        self.notifications = notifications
        load()
    }

    var summary: RecipeSummary {
        summary(for: items)
    }

    func summary(for recipe: SavedRecipe) -> RecipeSummary {
        summary(for: recipe.items)
    }

    func summary(for items: [RecipeItem]) -> RecipeSummary {
        let doughWeight = items.reduce(0) { $0 + $1.weight }
        let flourWeight = items.reduce(0) { $0 + flourContribution($1) }
        let waterWeight = items.reduce(0) { $0 + waterContribution($1) }
        return RecipeSummary(
            doughWeight: doughWeight,
            flourWeight: flourWeight,
            waterWeight: waterWeight,
            hydration: flourWeight > 0 ? waterWeight / flourWeight * 100 : 0
        )
    }

    func flourTablePercentage(for item: RecipeItem, in tableItems: [RecipeItem]) -> Double {
        let totalFlour = tableItems.reduce(0) { $0 + flourContribution($1) }
        guard totalFlour > 0 else { return 0 }
        return flourContribution(item) / totalFlour * 100
    }

    var currentRecipeDisplayName: String {
        let trimmed = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.unnamedRecipe : trimmed
    }

    var currentStarterDisplayName: String {
        let trimmed = starterProfiles.first?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? BakingTerms.starterProfileDefaultName : trimmed
    }

    func starterDisplayName(for profile: StarterProfile) -> String {
        let trimmed = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.starterProfileDefaultName : trimmed
    }

    func starterFinalWeight(for profile: StarterProfile) -> Double {
        return max(0, profile.measuredWeight - profile.containerWeight)
    }

    func starterFeedFlourWeight(for profile: StarterProfile) -> Double {
        max(0, profile.feedFlourWeight)
    }

    func starterFeedWaterWeight(for profile: StarterProfile) -> Double {
        max(0, profile.feedWaterWeight)
    }

    var isStarterReminderDue: Bool {
        starterProfiles.contains { profile in
            isStarterReminderDue(for: profile)
        }
    }

    func isStarterReminderDue(for profile: StarterProfile) -> Bool {
        guard profile.isReminderEnabled else { return false }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let nextFeedingStart = calendar.startOfDay(for: starterNextFeedingDate(for: profile))
        return todayStart >= nextFeedingStart && profile.lastFedAt < nextFeedingStart
    }

    func starterNextFeedingDate(for profile: StarterProfile) -> Date {
        StarterProfile.scheduledNextFeedingDate(
            after: profile.lastFedAt,
            frequencyDays: profile.feedingFrequencyDays
        )
    }

    var bakesThisWeek: Int {
        let calendar = Calendar.current
        return bakeHistory.filter { calendar.isDate($0.startedAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    var bakesThisMonth: Int {
        let calendar = Calendar.current
        return bakeHistory.filter { calendar.isDate($0.startedAt, equalTo: Date(), toGranularity: .month) }.count
    }

    var activeBakeRecord: BakeRecord? {
        guard let activeBakeRecordID else { return nil }
        return bakeHistory.first(where: { $0.id == activeBakeRecordID })
    }

    var hasActiveBakeInProgress: Bool {
        activeBakeRecordID != nil && cookState.completedAt == nil && cookState.totalStartedAt != nil && isReadyToBake
    }

    var currentCookStep: JournalStep? {
        guard !steps.isEmpty, hasActiveBakeInProgress else { return nil }
        let index = min(cookState.currentIndex, max(steps.count - 1, 0))
        return steps[index]
    }

    var recipeWorkflowState: RecipeWorkflowState {
        canMarkReadyToBake ? currentWorkflowState : .draft
    }

    var isReadyToBake: Bool {
        canMarkReadyToBake
    }

    var canMarkReadyToBake: Bool {
        Self.hasReadyStepContent(
            steps: steps,
            stepsMode: stepsMode,
            simpleStep: simpleStep
        )
    }

    func isReadyToBake(_ recipe: SavedRecipe) -> Bool {
        Self.hasReadyStepContent(
            steps: recipe.steps,
            stepsMode: recipe.stepsMode,
            simpleStep: recipe.simpleStep
        )
    }

    var readinessMessage: String {
        if !canMarkReadyToBake {
            return BakingTerms.readinessNeedsSteps
        }

        if recipeWorkflowState == .ready {
            return BakingTerms.readinessReadyToBake
        }

        return BakingTerms.readinessNeedsReadyTap
    }

    @discardableResult
    func markReadyToBake() -> Bool {
        guard canMarkReadyToBake else {
            currentWorkflowState = .draft
            return false
        }
        currentWorkflowState = .ready
        return true
    }

    func markDraft() {
        currentWorkflowState = .draft
    }

    func setStepsMode(_ mode: RecipeStepsMode) {
        guard mode != stepsMode else {
            ensureActiveStepsForCurrentMode()
            return
        }

        captureActiveStepsForCurrentMode()
        stepsMode = mode
        switch mode {
        case .simple:
            simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(simpleStep, kind: currentRecipeKind, items: items)
            steps = [simpleStep]
        case .custom:
            steps = customSteps.isEmpty ? [makeStep(type: .prep)] : customSteps
        }
        cookState = CookState()
        activeBakeRecordID = nil
        cancelCookTimerReminder()
    }

    @discardableResult
    func addItem(category: ItemCategory, tag: ItemTag? = nil) -> RecipeItem {
        let item = Self.makeItem(category: category, tag: tag)
        let snapshots = materialPercentageSnapshotsIfNeeded(forFlourChangeIn: [item])
        var nextItems = items
        nextItems.append(item)
        items = applyingMaterialPercentageSnapshots(snapshots, to: nextItems)
        return item
    }

    func createEmptyRecipe() {
        cancelCookTimerReminder()
        isLoading = true
        recipeName = BakingTerms.defaultRecipeName
        currentRecipeKind = .custom
        recipeOverallNotes = ""
        stepText = ""
        items = []
        stepsMode = .simple
        simpleStep = Self.makeSimpleStep()
        customSteps = []
        steps = [simpleStep]
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .draft
        formulaIngredientLockMode = .weight
        isLoading = false
        persist()
    }

    func createDraftRecipe() {
        createEmptyRecipe()
        saveCurrentRecipe()
    }

    func createNewRecipe() {
        applyTemplate(.toast)
    }

    func createRecipeCopy(from recipe: SavedRecipe) {
        cancelCookTimerReminder()
        isLoading = true
        recipeName = recipe.name.isEmpty ? BakingTerms.defaultRecipeName : BakingTerms.recipeCopyName(recipe.name)
        currentRecipeKind = recipe.kind
        recipeOverallNotes = recipe.overallNotes
        stepText = recipe.stepText
        items = recipe.items
        stepsMode = recipe.stepsMode
        simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(recipe.simpleStep ?? recipe.steps.first, kind: recipe.kind, items: recipe.items)
        customSteps = customSteps(for: recipe)
        steps = activeSteps(for: recipe)
        formulaIngredientLockMode = recipe.formulaIngredientLockMode
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .draft
        isLoading = false
        persist()
    }

    @discardableResult
    func copyCurrentRecipe() -> SavedRecipe {
        saveCurrentRecipe()
        let now = Date()
        let recipe = SavedRecipe(
            id: UUID(),
            name: BakingTerms.recipeCopyName(currentRecipeDisplayName),
            kind: currentRecipeKind,
            overallNotes: recipeOverallNotes,
            stepText: stepText,
            items: items,
            steps: currentActiveStepsForPersistence(),
            stepsMode: stepsMode,
            simpleStep: currentSimpleStepForPersistence(),
            customSteps: currentCustomStepsForPersistence(),
            formulaIngredientLockMode: formulaIngredientLockMode,
            workflowState: recipeWorkflowState,
            createdAt: now,
            updatedAt: now
        )
        savedRecipes.insert(recipe, at: 0)
        loadRecipe(recipe)
        return recipe
    }

    func applyTemplate(_ template: RecipeTemplate) {
        cancelCookTimerReminder()
        isLoading = true
        let templateItems: [RecipeItem]
        let templateKind: RecipeKind
        let templateName: String

        switch template {
        case .toast:
            templateItems = Self.defaultItems
            templateKind = .toast
            templateName = BakingTerms.toastRecipeName
        case .chiffon:
            templateItems = Self.chiffonItems
            templateKind = .chiffon
            templateName = BakingTerms.chiffonRecipeName
        case .countryBread:
            templateItems = Self.countryBreadItems
            templateKind = .countryBread
            templateName = BakingTerms.countryBreadRecipeName
        }

        let templateSteps = Self.templateTutorialSteps(kind: templateKind, items: templateItems)
        recipeName = templateName
        currentRecipeKind = templateKind
        recipeOverallNotes = ""
        stepText = ""
        items = templateItems
        stepsMode = .simple
        simpleStep = templateSteps.simple
        customSteps = templateSteps.custom
        steps = [simpleStep]
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .ready
        formulaIngredientLockMode = .weight
        isLoading = false
        persist()
    }

    func saveCurrentRecipe() {
        let now = Date()
        let activeSteps = currentActiveStepsForPersistence()
        let simpleStepSnapshot = currentSimpleStepForPersistence()
        let customStepsSnapshot = currentCustomStepsForPersistence()
        if let currentRecipeID, let index = savedRecipes.firstIndex(where: { $0.id == currentRecipeID }) {
            savedRecipes[index].name = currentRecipeDisplayName
            savedRecipes[index].kind = currentRecipeKind
            savedRecipes[index].overallNotes = recipeOverallNotes
            savedRecipes[index].stepText = stepText
            savedRecipes[index].items = items
            savedRecipes[index].steps = activeSteps
            savedRecipes[index].stepsMode = stepsMode
            savedRecipes[index].simpleStep = simpleStepSnapshot
            savedRecipes[index].customSteps = customStepsSnapshot
            savedRecipes[index].formulaIngredientLockMode = formulaIngredientLockMode
            savedRecipes[index].workflowState = recipeWorkflowState
            savedRecipes[index].updatedAt = now
        } else {
            let recipe = SavedRecipe(
                id: UUID(),
                name: currentRecipeDisplayName,
                kind: currentRecipeKind,
                overallNotes: recipeOverallNotes,
                stepText: stepText,
                items: items,
                steps: activeSteps,
                stepsMode: stepsMode,
                simpleStep: simpleStepSnapshot,
                customSteps: customStepsSnapshot,
                formulaIngredientLockMode: formulaIngredientLockMode,
                workflowState: recipeWorkflowState,
                createdAt: now,
                updatedAt: now
            )
            currentRecipeID = recipe.id
            savedRecipes.insert(recipe, at: 0)
        }
    }

    private func autosaveCurrentRecipeIfNeeded() {
        guard !isLoading,
              let currentRecipeID,
              let index = savedRecipes.firstIndex(where: { $0.id == currentRecipeID }) else {
            return
        }

        let workflowState = recipeWorkflowState
        let activeSteps = currentActiveStepsForPersistence()
        let simpleStepSnapshot = currentSimpleStepForPersistence()
        let customStepsSnapshot = currentCustomStepsForPersistence()
        let currentRecipe = savedRecipes[index]
        guard currentRecipe.name != currentRecipeDisplayName
            || currentRecipe.kind != currentRecipeKind
            || currentRecipe.overallNotes != recipeOverallNotes
            || currentRecipe.stepText != stepText
            || currentRecipe.items != items
            || currentRecipe.steps != activeSteps
            || currentRecipe.stepsMode != stepsMode
            || currentRecipe.simpleStep != simpleStepSnapshot
            || currentRecipe.customSteps != customStepsSnapshot
            || currentRecipe.formulaIngredientLockMode != formulaIngredientLockMode
            || currentRecipe.workflowState != workflowState else {
            return
        }

        var recipes = savedRecipes
        recipes[index].name = currentRecipeDisplayName
        recipes[index].kind = currentRecipeKind
        recipes[index].overallNotes = recipeOverallNotes
        recipes[index].stepText = stepText
        recipes[index].items = items
        recipes[index].steps = activeSteps
        recipes[index].stepsMode = stepsMode
        recipes[index].simpleStep = simpleStepSnapshot
        recipes[index].customSteps = customStepsSnapshot
        recipes[index].formulaIngredientLockMode = formulaIngredientLockMode
        recipes[index].workflowState = workflowState
        recipes[index].updatedAt = Date()
        savedRecipes = recipes
    }

    func refreshCurrentRecipeForDisplay() {
        var didChange = applyBackwardCompatibleRecipeUpdatesToSavedRecipes()

        if let currentRecipeID,
           let recipe = savedRecipes.first(where: { $0.id == currentRecipeID }) {
            if recipeName != recipe.name
                || currentRecipeKind != recipe.kind
                || recipeOverallNotes != recipe.overallNotes
                || stepText != recipe.stepText
                || items != recipe.items
                || steps != activeSteps(for: recipe)
                || stepsMode != recipe.stepsMode
                || simpleStep != Self.simpleStepApplyingBackwardCompatibleUpdates(recipe.simpleStep ?? recipe.steps.first, kind: recipe.kind, items: recipe.items)
                || customSteps != customSteps(for: recipe)
                || formulaIngredientLockMode != recipe.formulaIngredientLockMode
                || currentWorkflowState != recipe.workflowState {
                isLoading = true
                recipeName = recipe.name
                currentRecipeKind = recipe.kind
                recipeOverallNotes = recipe.overallNotes
                stepText = recipe.stepText
                items = recipe.items
                stepsMode = recipe.stepsMode
                simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(recipe.simpleStep ?? recipe.steps.first, kind: recipe.kind, items: recipe.items)
                customSteps = customSteps(for: recipe)
                steps = activeSteps(for: recipe)
                formulaIngredientLockMode = recipe.formulaIngredientLockMode
                currentWorkflowState = recipe.workflowState
                isLoading = false
                didChange = true
            }
        } else {
            let normalizedSteps = Self.stepsApplyingBackwardCompatibleUpdates(steps, kind: currentRecipeKind)
            if normalizedSteps != steps {
                isLoading = true
                steps = normalizedSteps
                isLoading = false
                didChange = true
            }
        }

        if didChange {
            persist()
        }
    }

    func loadRecipe(_ recipe: SavedRecipe) {
        cancelCookTimerReminder()
        isLoading = true
        recipeName = recipe.name
        currentRecipeKind = recipe.kind
        recipeOverallNotes = recipe.overallNotes
        stepText = recipe.stepText
        items = recipe.items
        stepsMode = recipe.stepsMode
        simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(recipe.simpleStep ?? recipe.steps.first, kind: recipe.kind, items: recipe.items)
        customSteps = customSteps(for: recipe)
        steps = activeSteps(for: recipe)
        formulaIngredientLockMode = recipe.formulaIngredientLockMode
        cookState = CookState()
        currentRecipeID = recipe.id
        activeBakeRecordID = nil
        currentWorkflowState = recipe.workflowState
        isLoading = false
        persist()
    }

    func deleteRecipe(_ recipe: SavedRecipe) {
        savedRecipes.removeAll { $0.id == recipe.id }
        if currentRecipeID == recipe.id {
            currentRecipeID = nil
        }
    }

    @discardableResult
    func createStarterProfile() -> StarterProfile {
        let starter = StarterProfile()
        starterProfiles.insert(starter, at: 0)
        return starter
    }

    func updateStarterProfile(_ profile: StarterProfile) {
        guard let index = starterProfiles.firstIndex(where: { $0.id == profile.id }) else { return }
        let previous = starterProfiles[index]
        var nextProfile = profile
        syncStarterFeedWeightsIfNeeded(from: previous, into: &nextProfile)
        nextProfile.normalizeFeedingSchedule()
        starterProfiles[index] = nextProfile
        if previous.isReminderEnabled != nextProfile.isReminderEnabled
            || !Calendar.current.isDate(previous.nextFeedingDate, inSameDayAs: nextProfile.nextFeedingDate)
            || previous.feedingFrequencyDays != nextProfile.feedingFrequencyDays
            || previous.name != nextProfile.name {
            rescheduleStarterReminders()
        }
    }

    func deleteStarterProfile(_ profile: StarterProfile) {
        starterProfiles.removeAll { $0.id == profile.id }
        if starterProfiles.isEmpty {
            starterProfiles = [StarterProfile()]
        }
        rescheduleStarterReminders()
    }

    func updateStarterFinalWeight(_ finalWeight: Double, for profile: StarterProfile) {
        var next = profile
        next.measuredWeight = max(0, finalWeight) + next.containerWeight
        updateStarterProfile(next)
    }

    func updateStarterFeedingRatio(_ ratio: StarterFeedingRatio, for profile: StarterProfile) {
        var next = profile
        next.feedingRatio = ratio
        let defaultFeedWeight = defaultStarterFeedWeight(for: next)
        next.feedFlourWeight = defaultFeedWeight
        next.feedWaterWeight = defaultFeedWeight
        updateStarterProfile(next)
    }

    func updateStarterFeedFlourWeight(_ weight: Double, for profile: StarterProfile) {
        var next = profile
        next.feedFlourWeight = max(0, weight)
        updateStarterProfile(next)
    }

    func updateStarterFeedWaterWeight(_ weight: Double, for profile: StarterProfile) {
        var next = profile
        next.feedWaterWeight = max(0, weight)
        updateStarterProfile(next)
    }

    func updateStarterFeedingFrequencyDays(_ days: Double, for profile: StarterProfile) {
        var next = profile
        next.feedingFrequencyDays = StarterProfile.normalizedFeedingFrequencyDays(Int(days.rounded()))
        next.normalizeFeedingSchedule()
        updateStarterProfile(next)
    }

    func markStarterFed(_ profile: StarterProfile) {
        var next = profile
        let currentWeight = starterFinalWeight(for: profile)
        let addedWeight = starterFeedFlourWeight(for: profile) + starterFeedWaterWeight(for: profile)
        next.lastFedAt = Date()
        next.measuredWeight = currentWeight + addedWeight + next.containerWeight
        updateStarterProfile(next)
    }

    private func syncStarterFeedWeightsIfNeeded(from previous: StarterProfile, into next: inout StarterProfile) {
        let didChangeBaseWeight = !Self.isSameWeight(
            starterFinalWeight(for: previous),
            starterFinalWeight(for: next)
        )
        let didChangeRatio = previous.feedingRatio != next.feedingRatio
        guard didChangeBaseWeight || didChangeRatio else { return }

        let previousDefaultFeedWeight = defaultStarterFeedWeight(for: previous)
        let shouldSyncFlour = didChangeRatio
            || Self.isSameWeight(previous.feedFlourWeight, previousDefaultFeedWeight)
        let shouldSyncWater = didChangeRatio
            || Self.isSameWeight(previous.feedWaterWeight, previousDefaultFeedWeight)
        let nextDefaultFeedWeight = defaultStarterFeedWeight(for: next)

        if shouldSyncFlour {
            next.feedFlourWeight = nextDefaultFeedWeight
        }

        if shouldSyncWater {
            next.feedWaterWeight = nextDefaultFeedWeight
        }
    }

    private func defaultStarterFeedWeight(for profile: StarterProfile) -> Double {
        starterFinalWeight(for: profile) * profile.feedingRatio.feedMultiplier
    }

    private static func isSameWeight(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.0001
    }

    func updateBakeRecordNotes(_ notes: String, for record: BakeRecord) {
        guard let index = bakeHistory.firstIndex(where: { $0.id == record.id }) else { return }
        bakeHistory[index].notes = notes
    }

    func deleteBakeRecord(_ record: BakeRecord) {
        bakeHistory.removeAll { $0.id == record.id }
        if activeBakeRecordID == record.id {
            cookState = CookState()
            activeBakeRecordID = nil
            cancelCookTimerReminder()
        }
    }

    func removeItem(_ item: RecipeItem) {
        let flourCount = items.filter { $0.category == .flour }.count
        guard item.category != .flour || flourCount > 1 else { return }
        let snapshots = materialPercentageSnapshotsIfNeeded(forFlourChangeIn: [item])
        let nextItems = items.filter { $0.id != item.id }
        items = applyingMaterialPercentageSnapshots(snapshots, to: nextItems)
        steps = steps.map { step in
            var next = step
            next.materialAllocations.removeAll { $0.itemId == item.id }
            return next
        }
        simpleStep.materialAllocations.removeAll { $0.itemId == item.id }
        customSteps = customSteps.map { step in
            var next = step
            next.materialAllocations.removeAll { $0.itemId == item.id }
            return next
        }
    }

    func updateItem(_ item: RecipeItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let snapshots = materialPercentageSnapshotsIfNeeded(forFlourChangeIn: [items[index], item])
        var nextItems = items
        nextItems[index] = item
        items = applyingMaterialPercentageSnapshots(snapshots, to: nextItems)
    }

    func toggleFormulaIngredientLockMode() {
        guard currentRecipeKind.usesBakerPercentageSystem else {
            formulaIngredientLockMode = .weight
            return
        }
        formulaIngredientLockMode = formulaIngredientLockMode.toggled
    }

    func moveItem(_ itemId: UUID, before targetId: UUID) {
        guard itemId != targetId,
              let movingItem = items.first(where: { $0.id == itemId }),
              let targetItem = items.first(where: { $0.id == targetId }) else { return }

        let movingGroup = displayGroup(for: movingItem.category)
        let targetGroup = displayGroup(for: targetItem.category)
        guard movingGroup == targetGroup else { return }

        let sectionItems = items.filter { displayGroup(for: $0.category) == movingGroup }
        guard let sourceIndex = sectionItems.firstIndex(where: { $0.id == itemId }),
              let targetIndex = sectionItems.firstIndex(where: { $0.id == targetId }) else { return }

        var reorderedSectionItems = sectionItems
        let moved = reorderedSectionItems.remove(at: sourceIndex)
        let destinationIndex = sourceIndex < targetIndex ? max(0, targetIndex - 1) : targetIndex
        reorderedSectionItems.insert(moved, at: destinationIndex)

        var rebuilt: [RecipeItem] = []
        var insertedSection = false
        for item in items {
            if displayGroup(for: item.category) == movingGroup {
                if !insertedSection {
                    rebuilt.append(contentsOf: reorderedSectionItems)
                    insertedSection = true
                }
            } else {
                rebuilt.append(item)
            }
        }
        items = rebuilt
    }

    func moveItemToEnd(_ itemId: UUID, in category: ItemCategory) {
        guard let movingItem = items.first(where: { $0.id == itemId }) else { return }
        let targetGroup = displayGroup(for: category)
        let movingGroup = displayGroup(for: movingItem.category)
        guard movingGroup == targetGroup else { return }

        let sectionItems = items.filter { displayGroup(for: $0.category) == movingGroup }
        guard let sourceIndex = sectionItems.firstIndex(where: { $0.id == itemId }) else { return }

        var reorderedSectionItems = sectionItems
        let moved = reorderedSectionItems.remove(at: sourceIndex)
        reorderedSectionItems.append(moved)

        var rebuilt: [RecipeItem] = []
        var insertedSection = false
        for item in items {
            if displayGroup(for: item.category) == movingGroup {
                if !insertedSection {
                    rebuilt.append(contentsOf: reorderedSectionItems)
                    insertedSection = true
                }
            } else {
                rebuilt.append(item)
            }
        }
        items = rebuilt
    }

    func reorderItems(in category: ItemCategory, orderedIDs: [UUID]) {
        let targetGroup = displayGroup(for: category)
        let sectionItems = items.filter { displayGroup(for: $0.category) == targetGroup }
        let sectionIDs = Set(sectionItems.map(\.id))
        guard Set(orderedIDs) == sectionIDs else { return }

        let itemsByID = Dictionary(uniqueKeysWithValues: sectionItems.map { ($0.id, $0) })
        let reorderedSectionItems = orderedIDs.compactMap { itemsByID[$0] }

        var rebuilt: [RecipeItem] = []
        var insertedSection = false
        for item in items {
            if displayGroup(for: item.category) == targetGroup {
                if !insertedSection {
                    rebuilt.append(contentsOf: reorderedSectionItems)
                    insertedSection = true
                }
            } else {
                rebuilt.append(item)
            }
        }
        items = rebuilt
    }

    func reorderCakeMaterialItems(orderedIDs: [UUID]) {
        let sectionItems = items.filter { $0.category != .starter }
        let sectionIDs = Set(sectionItems.map(\.id))
        guard Set(orderedIDs) == sectionIDs else { return }

        let itemsByID = Dictionary(uniqueKeysWithValues: sectionItems.map { ($0.id, $0) })
        let reorderedSectionItems = orderedIDs.compactMap { itemsByID[$0] }

        var rebuilt: [RecipeItem] = []
        var insertedSection = false
        for item in items {
            if item.category != .starter {
                if !insertedSection {
                    rebuilt.append(contentsOf: reorderedSectionItems)
                    insertedSection = true
                }
            } else {
                rebuilt.append(item)
            }
        }
        items = rebuilt
    }

    func updateItemWeight(_ item: RecipeItem, weight: Double) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        if next.category == .starter {
            let optionalWeight = (next.starterYeastWeight ?? 0) + starterEggWeight(next)
            let currentFlour = flourContribution(next)
            let currentWater = starterBaseWater(next)
            let currentBase = currentFlour + currentWater
            let nextBase = max(0, weight - optionalWeight)
            if currentBase > 0 {
                let scale = nextBase / currentBase
                setStarterParts(&next, flour: currentFlour * scale, water: currentWater * scale)
            } else {
                let hydrationPct = starterHydrationForRebuild(next)
                let flour = nextBase / (1 + hydrationPct / 100)
                setStarterParts(&next, flour: flour, water: nextBase - flour)
            }
        } else if next.tag == .egg {
            setEggWeight(&next, weight: weight)
        } else {
            next.weight = max(0, weight)
        }
        updateItem(next)
    }

    private func starterHydrationForRebuild(_ item: RecipeItem) -> Double {
        if let hydrationPct = item.hydrationPct, hydrationPct > 0 {
            return hydrationPct
        }
        return Self.hydration(forStarterRatio: item.starterRatio ?? "1:1")
    }

    func updateEggType(_ type: String, for item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        let normalizedType = Self.eggOptions.contains(type) ? type : BakingTerms.beatenEgg

        next.eggType = normalizedType
        next.name = BakingTerms.egg
        next.waterContentPct = Self.waterContent(forEggType: normalizedType)
        updateItem(next)
    }

    func updateEggWeight(_ item: RecipeItem, weight: Double) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        setEggWeight(&next, weight: weight)
        updateItem(next)
    }

    func updateItemPercent(_ item: RecipeItem, percent: Double) {
        let clampedPercent = max(0, percent)
        let nextWeight = summary.flourWeight * clampedPercent / 100
        updateItemWeight(item, weight: nextWeight)
    }

    func applyStarterType(_ type: String, to item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterType = type
        next.name = BakingTerms.starterDisplayName(type)
        next.starterRatio = Self.defaultStarterRatio[type] ?? "1:1"
        next.starterEditMode = .ratio
        applyStarterHydrationPreset(&next, hydrationPct: Self.hydration(forStarterRatio: next.starterRatio ?? "1:1"))
        updateItem(next)
    }

    func applyStarterRatio(_ ratio: String, to item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterRatio = ratio
        next.starterEditMode = .ratio
        applyStarterHydrationPreset(&next, hydrationPct: Self.hydration(forStarterRatio: ratio))
        updateItem(next)
    }

    func updateStarterEditMode(_ mode: StarterEditMode, for item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterEditMode = mode
        next.starterRatio = starterRatioLabel(for: next)
        updateItem(next)
    }

    func updateStarterParts(_ item: RecipeItem, flour: Double? = nil, water: Double? = nil) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterEditMode = .weight
        setStarterParts(
            &next,
            flour: flour ?? flourContribution(next),
            water: water ?? starterBaseWater(next)
        )
        next.starterRatio = starterRatioLabel(for: next)
        updateItem(next)
    }

    func updateStarterYeast(_ item: RecipeItem, weight: Double?) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterYeastWeight = weight.map { max(0, $0) }
        syncStarterWeight(&next)
        updateItem(next)
    }

    func updateStarterEgg(_ item: RecipeItem, count: Double?, unitWeight: Double? = nil) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterEggCount = count.map { max(0, $0) }
        next.starterEggUnitWeight = unitWeight ?? (count == nil ? nil : (next.starterEggUnitWeight ?? 50))
        syncStarterWeight(&next)
        updateItem(next)
    }

    @discardableResult
    func addStep(type: StepType) -> JournalStep {
        let step = makeStep(type: type)
        steps.append(step)
        return step
    }

    @discardableResult
    func addTextStep() -> JournalStep {
        let step = JournalStep(id: UUID(), type: .prep, name: BakingTerms.stepsCategoryPrepWork, notes: "", materialAllocations: [])
        steps.append(step)
        return step
    }

    func removeStep(_ step: JournalStep) {
        steps.removeAll { $0.id == step.id }
        cookState.checked[step.id] = nil
        cookState.completedStepIDs.remove(step.id)
        cookState.currentIndex = min(cookState.currentIndex, max(steps.count - 1, 0))
    }

    func updateStep(_ step: JournalStep) {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else { return }
        steps[index] = step
    }

    func moveSteps(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
    }

    func moveStep(_ stepId: UUID, before targetId: UUID) {
        guard stepId != targetId,
              let sourceIndex = steps.firstIndex(where: { $0.id == stepId }),
              let targetIndex = steps.firstIndex(where: { $0.id == targetId }) else { return }

        var reorderedSteps = steps
        let movedStep = reorderedSteps.remove(at: sourceIndex)
        let destinationIndex = sourceIndex < targetIndex ? max(0, targetIndex - 1) : targetIndex
        reorderedSteps.insert(movedStep, at: destinationIndex)
        steps = reorderedSteps
    }

    func moveStepToEnd(_ stepId: UUID) {
        guard let sourceIndex = steps.firstIndex(where: { $0.id == stepId }) else { return }
        var reorderedSteps = steps
        let movedStep = reorderedSteps.remove(at: sourceIndex)
        reorderedSteps.append(movedStep)
        steps = reorderedSteps
    }

    func reorderSteps(_ reorderedSteps: [JournalStep]) {
        guard Set(reorderedSteps.map(\.id)) == Set(steps.map(\.id)) else { return }
        steps = reorderedSteps
    }

    private func ensureActiveStepsForCurrentMode() {
        switch stepsMode {
        case .simple:
            let nextStep = Self.normalizedSimpleStep(steps.first ?? simpleStep)
            simpleStep = nextStep
            if steps != [nextStep] {
                steps = [nextStep]
            }
        case .custom:
            if steps.isEmpty, !customSteps.isEmpty {
                steps = customSteps
            }
        }
    }

    private func captureActiveStepsForCurrentMode() {
        switch stepsMode {
        case .simple:
            simpleStep = Self.normalizedSimpleStep(steps.first ?? simpleStep)
        case .custom:
            customSteps = steps
        }
    }

    private func syncStepModeBackupFromActiveSteps() {
        switch stepsMode {
        case .simple:
            simpleStep = Self.normalizedSimpleStep(steps.first ?? simpleStep)
        case .custom:
            customSteps = steps
        }
    }

    func assign(itemId: UUID, to step: JournalStep) {
        assign(itemId: itemId, percentage: 100, to: step)
    }

    func assign(itemId: UUID, percentage: Double, to step: JournalStep) {
        let clamped = min(max(0, percentage), 100)
        guard clamped > 0 else { return }
        var nextSteps = steps
        guard let stepIndex = nextSteps.firstIndex(where: { $0.id == step.id }) else { return }

        if let allocationIndex = nextSteps[stepIndex].materialAllocations.firstIndex(where: { $0.itemId == itemId }) {
            nextSteps[stepIndex].materialAllocations[allocationIndex].percentage = clamped
        } else {
            nextSteps[stepIndex].materialAllocations.append(
                StepMaterialAllocation(itemId: itemId, percentage: clamped)
            )
        }
        steps = nextSteps
    }

    func assignAllItems(to step: JournalStep) {
        var nextSteps = steps
        guard let stepIndex = nextSteps.firstIndex(where: { $0.id == step.id }) else { return }
        for item in items {
            if let allocationIndex = nextSteps[stepIndex].materialAllocations.firstIndex(where: { $0.itemId == item.id }) {
                nextSteps[stepIndex].materialAllocations[allocationIndex].percentage = 100
            } else {
                nextSteps[stepIndex].materialAllocations.append(
                    StepMaterialAllocation(itemId: item.id, percentage: 100)
                )
            }
        }
        steps = nextSteps
    }

    func removeAssignedItem(_ itemId: UUID, from step: JournalStep) {
        guard var next = steps.first(where: { $0.id == step.id }) else { return }
        next.materialAllocations.removeAll { $0.itemId == itemId }
        updateStep(next)
    }

    func items(for step: JournalStep) -> [RecipeItem] {
        allocatedItems(for: step).map(\.item)
    }

    func allocatedItems(for step: JournalStep) -> [AllocatedRecipeItem] {
        step.materialAllocations.compactMap { allocation in
            guard let item = items.first(where: { $0.id == allocation.itemId }) else { return nil }
            let percentage = min(max(0, allocation.percentage), 100)
            return AllocatedRecipeItem(
                item: item,
                percentage: percentage,
                weight: allocatedWeight(for: item, percentage: percentage)
            )
        }
    }

    func allocationPercentage(for itemId: UUID, in step: JournalStep) -> Double {
        step.materialAllocations.first { $0.itemId == itemId }?.percentage ?? 0
    }

    func allocatedWeight(for item: RecipeItem, percentage: Double) -> Double {
        item.weight * min(max(0, percentage), 100) / 100
    }

    func stepMinutes(_ step: JournalStep) -> Double {
        if let foldPlan = step.foldPlan {
            return Double(foldPlan.totalMinutes)
        }

        let value = step.timeValue ?? 0
        return step.timeUnit == .hr ? value * 60 : value
    }

    func totalStepMinutes() -> Double {
        steps.reduce(0) { $0 + stepMinutes($1) }
    }

    func cookStepStartedAt(for step: JournalStep) -> Date? {
        if steps.indices.contains(cookState.currentIndex),
           steps[cookState.currentIndex].id == step.id,
           let stepStartedAt = cookState.stepStartedAt {
            return stepStartedAt
        }

        return activeBakeRecord?.stepTimings.last(where: { $0.stepID == step.id })?.startedAt
    }

    func cookStepEstimatedCompletionAt(for step: JournalStep) -> Date? {
        if let foldPlan = step.foldPlan {
            let records = foldRecords(for: step)
            let completedCount = min(records.count, foldPlan.normalizedTargetCount)
            if completedCount >= foldPlan.normalizedTargetCount {
                return records.last?.foldedAt ?? cookStepStartedAt(for: step)
            }

            guard let baseDate = records.last?.foldedAt ?? cookStepStartedAt(for: step) else { return nil }
            let remainingCount = foldPlan.normalizedTargetCount - completedCount
            return baseDate.addingTimeInterval(Double(remainingCount * foldPlan.normalizedIntervalMinutes) * 60)
        }

        guard let startedAt = cookStepStartedAt(for: step) else { return nil }
        return startedAt.addingTimeInterval(stepMinutes(step) * 60)
    }

    func isFoldStep(_ step: JournalStep) -> Bool {
        step.foldPlan != nil
    }

    func foldRecords(for step: JournalStep) -> [BakeFoldRecord] {
        activeBakeRecord?.foldRecords
            .filter { $0.stepID == step.id }
            .sorted {
                if $0.sequence == $1.sequence {
                    return $0.foldedAt < $1.foldedAt
                }
                return $0.sequence < $1.sequence
            } ?? []
    }

    func foldProgress(for step: JournalStep) -> (completed: Int, target: Int)? {
        guard let foldPlan = step.foldPlan else { return nil }
        return (min(foldRecords(for: step).count, foldPlan.normalizedTargetCount), foldPlan.normalizedTargetCount)
    }

    func nextFoldReminderDate(for step: JournalStep) -> Date? {
        guard let foldPlan = step.foldPlan else { return nil }
        let records = foldRecords(for: step)
        guard records.count < foldPlan.normalizedTargetCount else { return nil }
        guard let baseDate = records.last?.foldedAt ?? cookStepStartedAt(for: step) else { return nil }
        return baseDate.addingTimeInterval(Double(foldPlan.normalizedIntervalMinutes) * 60)
    }

    func isStepCompletionReminderEnabled(for step: JournalStep) -> Bool {
        guard cookState.timerStepId == step.id else { return false }
        return cookState.timerPurpose == nil || cookState.timerPurpose == .stepCompletion
    }

    func isFoldReminderEnabled(for step: JournalStep) -> Bool {
        cookState.timerStepId == step.id && cookState.timerPurpose == .foldReminder && cookState.timerEndsAt != nil
    }

    func toggleCookItem(stepId: UUID, itemId: UUID) {
        guard ensureCookStarted() else { return }
        var checked = cookState.checked[stepId] ?? []
        if checked.contains(itemId) {
            checked.remove(itemId)
        } else {
            checked.insert(itemId)
        }
        cookState.checked[stepId] = checked
    }

    func isCookStepCompleted(_ step: JournalStep) -> Bool {
        cookState.completedStepIDs.contains(step.id)
    }

    @discardableResult
    func completeCookStep(at index: Int) -> Bool {
        guard ensureCookStarted(),
              steps.indices.contains(index),
              index == cookState.currentIndex else { return false }
        guard steps.indices.contains(cookState.currentIndex) else { return false }
        cookState.completedStepIDs.insert(steps[cookState.currentIndex].id)
        moveCookStep(1)
        return true
    }

    func startTimer(for step: JournalStep) {
        guard ensureCookStarted() else { return }
        guard let estimatedCompletionAt = cookStepEstimatedCompletionAt(for: step) else {
            cancelCookTimerReminder()
            return
        }

        scheduleCookStepReminder(for: step, at: estimatedCompletionAt)
    }

    func scheduleCookStepReminder(for step: JournalStep, at fireDate: Date) {
        guard ensureCookStarted() else { return }
        guard stepMinutes(step) > 0 else {
            clearActiveCookTimerState()
            cancelCookTimerReminder()
            return
        }

        cookState.timerStepId = step.id
        cookState.timerEndsAt = fireDate
        cookState.timerPurpose = .stepCompletion

        scheduleCookTimerReminder(for: step, endsAt: fireDate)
    }

    func clearCookStepReminder(for step: JournalStep) {
        guard cookState.timerStepId == step.id else { return }
        guard cookState.timerPurpose == nil || cookState.timerPurpose == .stepCompletion else { return }
        clearActiveCookTimerState()
        cancelCookTimerReminder()
    }

    func scheduleFoldReminder(for step: JournalStep) {
        guard ensureCookStarted(),
              let foldPlan = step.foldPlan,
              let nextFoldDate = nextFoldReminderDate(for: step) else {
            clearFoldReminder(for: step)
            return
        }

        let fireDate = max(nextFoldDate, Date().addingTimeInterval(1))
        let nextSequence = min(foldRecords(for: step).count + 1, foldPlan.normalizedTargetCount)
        cookState.timerStepId = step.id
        cookState.timerEndsAt = fireDate
        cookState.timerPurpose = .foldReminder
        scheduleCookFoldReminder(for: step, foldIndex: nextSequence, endsAt: fireDate)
    }

    func clearFoldReminder(for step: JournalStep) {
        guard cookState.timerStepId == step.id, cookState.timerPurpose == .foldReminder else { return }
        clearActiveCookTimerState()
        cancelCookTimerReminder()
    }

    func recordFold(for step: JournalStep) {
        guard ensureCookStarted(),
              let foldPlan = step.foldPlan,
              steps.indices.contains(cookState.currentIndex),
              steps[cookState.currentIndex].id == step.id,
              !isCookStepCompleted(step),
              let activeBakeRecordID,
              let recordIndex = bakeHistory.firstIndex(where: { $0.id == activeBakeRecordID }) else {
            return
        }

        let existingRecords = bakeHistory[recordIndex].foldRecords
            .filter { $0.stepID == step.id }
        guard existingRecords.count < foldPlan.normalizedTargetCount else {
            clearFoldReminder(for: step)
            return
        }

        let sequence = (existingRecords.map(\.sequence).max() ?? 0) + 1
        bakeHistory[recordIndex].foldRecords.append(
            BakeFoldRecord(
                id: UUID(),
                stepID: step.id,
                stepName: step.name,
                sequence: sequence,
                foldedAt: Date()
            )
        )

        let updatedCount = existingRecords.count + 1
        if updatedCount >= foldPlan.normalizedTargetCount {
            clearFoldReminder(for: step)
        } else if isFoldReminderEnabled(for: step) {
            scheduleFoldReminder(for: step)
        }
    }

    func moveCookStep(_ direction: Int) {
        guard ensureCookStarted() else { return }
        let nextIndex = cookState.currentIndex + direction
        guard nextIndex >= 0 else { return }
        if nextIndex >= steps.count {
            let finishedAt = Date()
            closeCurrentStepTiming(at: finishedAt)
            cookState.completedAt = finishedAt
            finalizeBakeRecord()
            clearActiveCookTimerState()
            cancelCookTimerReminder()
            return
        }
        let now = Date()
        closeCurrentStepTiming(at: now)
        cookState.currentIndex = nextIndex
        cookState.stepStartedAt = now
        clearActiveCookTimerState()
        startTimingForCurrentStep(at: now)
        cancelCookTimerReminder()
    }

    /// Jumps directly to a step (e.g. from the step carousel). Resets the per-step timer like `moveCookStep`.
    func goToCookStep(_ index: Int) {
        guard ensureCookStarted() else { return }
        let clamped = min(max(0, index), max(steps.count - 1, 0))
        guard clamped != cookState.currentIndex else { return }
        let now = Date()
        closeCurrentStepTiming(at: now)
        cookState.currentIndex = clamped
        cookState.stepStartedAt = now
        clearActiveCookTimerState()
        startTimingForCurrentStep(at: now)
        cancelCookTimerReminder()
    }

    func resetCook() {
        cookState = CookState()
        activeBakeRecordID = nil
        cancelCookTimerReminder()
    }

    @discardableResult
    func startNewBake() -> Bool {
        guard isReadyToBake else { return false }
        cancelCookTimerReminder()

        let startedAt = Date()
        cookState = CookState()
        cookState.totalStartedAt = startedAt
        activeBakeRecordID = createBakeRecord(startedAt: startedAt)
        cookState.stepStartedAt = startedAt
        startTimingForCurrentStep(at: startedAt)
        return true
    }

    func completeBake() {
        guard ensureCookStarted() else { return }
        let finishedAt = Date()
        if steps.indices.contains(cookState.currentIndex) {
            cookState.completedStepIDs.insert(steps[cookState.currentIndex].id)
        }
        closeCurrentStepTiming(at: finishedAt)
        cookState.completedAt = finishedAt
        finalizeBakeRecord()
        clearActiveCookTimerState()
        cancelCookTimerReminder()
    }

    /// Whether an in-progress record can be opened in the cooking page.
    /// The live bake is always resumable; an orphaned one is resumable as long as its source recipe still exists.
    func canResumeBake(_ record: BakeRecord) -> Bool {
        guard record.completedAt == nil else { return false }
        if record.id == activeBakeRecordID { return true }
        guard let recipeID = record.recipeID else { return false }
        return savedRecipes.contains { $0.id == recipeID }
    }

    /// Re-activates an in-progress record so the cooking page reflects it.
    /// If it is already the live bake, the existing progress (step index, checks, timer) is kept.
    /// Otherwise the source recipe is reloaded and cooking restarts from the first step.
    func resumeBake(_ record: BakeRecord) {
        if record.id == activeBakeRecordID, cookState.totalStartedAt != nil, cookState.completedAt == nil {
            return
        }
        guard let recipeID = record.recipeID,
              let recipe = savedRecipes.first(where: { $0.id == recipeID }) else { return }
        loadRecipe(recipe)
        activeBakeRecordID = record.id
        cookState.totalStartedAt = record.startedAt
        cookState.stepStartedAt = Date()
        startTimingForCurrentStep(at: cookState.stepStartedAt ?? Date())
    }

    func beginCookIfNeeded() {
        _ = ensureCookStarted()
    }

    func exportRecipeData() throws -> Data {
        try exportCurrentRecipeExchangeData()
    }

    func importRecipeData(_ data: Data) throws {
        _ = try importRecipeExchangeData(data)
    }

    func exportCurrentRecipeExchangeData() throws -> Data {
        let document = RecipeExchangeDocumentV1.document(
            name: currentRecipeDisplayName,
            kind: currentRecipeKind,
            overallNotes: recipeOverallNotes,
            items: items,
            steps: currentActiveStepsForPersistence()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(document).addingUTF8ByteOrderMark()
    }

    @discardableResult
    func importRecipeExchangeJSONString(_ text: String) throws -> SavedRecipe {
        try importRecipeExchangeData(RecipeExchangeDocumentV1.data(fromJSONString: text))
    }

    @discardableResult
    func importRecipeExchangeData(_ data: Data) throws -> SavedRecipe {
        let document: RecipeExchangeDocumentV1
        do {
            document = try RecipeExchangeDocumentV1.decode(from: data)
        } catch let error as RecipeExchangeError {
            throw error
        } catch {
            throw RecipeExchangeError.invalidJSON
        }
        let importedRecipe = try document.makeSavedRecipe()
        cancelCookTimerReminder()
        isLoading = true
        recipeName = importedRecipe.name
        currentRecipeKind = importedRecipe.kind
        recipeOverallNotes = importedRecipe.overallNotes
        stepText = importedRecipe.stepText
        items = importedRecipe.items
        stepsMode = importedRecipe.stepsMode
        simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(importedRecipe.simpleStep ?? importedRecipe.steps.first, kind: importedRecipe.kind, items: importedRecipe.items)
        customSteps = customSteps(for: importedRecipe)
        steps = activeSteps(for: importedRecipe)
        formulaIngredientLockMode = importedRecipe.formulaIngredientLockMode
        cookState = CookState()
        currentRecipeID = importedRecipe.id
        activeBakeRecordID = nil
        currentWorkflowState = importedRecipe.workflowState
        savedRecipes.insert(importedRecipe, at: 0)
        isLoading = false
        persist()
        return importedRecipe
    }

    func flourContribution(_ item: RecipeItem) -> Double {
        if item.category == .flour { return item.weight }
        guard item.category == .starter else { return 0 }
        if let starterFlour = item.starterFlour { return starterFlour }
        let hydrationPct = item.hydrationPct
            ?? Self.starterRatioHydration[item.starterRatio ?? ""]
            ?? Self.parsedHydration(forStarterRatio: item.starterRatio ?? "")
            ?? Self.starterHydrationPresets[item.starterType ?? ""]
            ?? 100
        let hydration = hydrationPct / 100
        let optionalWeight = (item.starterYeastWeight ?? 0) + starterEggWeight(item)
        return max(0, item.weight - optionalWeight) / (1 + hydration)
    }

    func waterContribution(_ item: RecipeItem) -> Double {
        if item.tag == .water { return item.weight * ((item.waterContentPct ?? 100) / 100) }
        if item.category == .starter { return starterBaseWater(item) + starterEggWater(item) }
        if item.tag == .egg { return item.weight * (Self.waterContent(forEggType: item.eggType) / 100) }
        if item.category == .other { return item.weight * ((item.waterContentPct ?? 0) / 100) }
        if item.yeastType == BakingTerms.liquidYeast { return item.weight }
        return 0
    }

    func hasWaterContent(_ item: RecipeItem) -> Bool {
        waterContribution(item) > 0
    }

    static func waterContent(forEggType type: String?) -> Double {
        eggWaterContent[type ?? BakingTerms.beatenEgg] ?? eggWaterContent[BakingTerms.beatenEgg] ?? 75
    }

    func starterBaseWater(_ item: RecipeItem) -> Double {
        if let starterWater = item.starterWater { return starterWater }
        let optionalWeight = (item.starterYeastWeight ?? 0) + starterEggWeight(item)
        return max(0, item.weight - optionalWeight) - flourContribution(item)
    }

    func starterEditMode(for item: RecipeItem) -> StarterEditMode {
        item.starterEditMode ?? .ratio
    }

    func starterRatioLabel(for item: RecipeItem) -> String {
        let flour = flourContribution(item)
        let water = starterBaseWater(item)
        return Self.starterRatioLabel(flour: flour, water: water, fallback: item.starterRatio ?? "1:1")
    }

    func starterEggWeight(_ item: RecipeItem) -> Double {
        (item.starterEggCount ?? 0) * (item.starterEggUnitWeight ?? 50)
    }

    func starterEggWater(_ item: RecipeItem) -> Double {
        starterEggWeight(item) * 0.75
    }

    @discardableResult
    private func ensureCookStarted() -> Bool {
        guard isReadyToBake else { return false }
        if cookState.totalStartedAt == nil {
            let now = Date()
            cookState.totalStartedAt = now
            activeBakeRecordID = createBakeRecord(startedAt: now)
            cookState.stepStartedAt = now
            startTimingForCurrentStep(at: now)
        }
        if cookState.stepStartedAt == nil {
            let now = Date()
            cookState.stepStartedAt = now
            startTimingForCurrentStep(at: now)
        }
        return true
    }

    private func scheduleCookTimerReminder(for step: JournalStep, endsAt: Date) {
        let recipeName = currentRecipeDisplayName
        Task { [notifications] in
            await notifications.cancel(scope: .cookTimer)
            _ = await notifications.schedule(
                .cookTimerFinished(
                    recipeName: recipeName,
                    stepId: step.id,
                    stepName: step.name,
                    fireDate: endsAt
                )
            )
        }
    }

    private func scheduleCookFoldReminder(for step: JournalStep, foldIndex: Int, endsAt: Date) {
        let recipeName = currentRecipeDisplayName
        Task { [notifications] in
            await notifications.cancel(scope: .cookTimer)
            _ = await notifications.schedule(
                .cookFoldReminder(
                    recipeName: recipeName,
                    stepId: step.id,
                    stepName: step.name,
                    foldIndex: foldIndex,
                    fireDate: endsAt
                )
            )
        }
    }

    private func clearActiveCookTimerState() {
        cookState.timerEndsAt = nil
        cookState.timerStepId = nil
        cookState.timerPurpose = nil
    }

    private func cancelCookTimerReminder() {
        Task { [notifications] in
            await notifications.cancel(scope: .cookTimer)
        }
    }

    private func rescheduleStarterReminders() {
        let profiles = starterProfiles
        Task { [notifications] in
            await notifications.cancel(scope: .starterReminder)

            let calendar = Calendar.current
            let now = Date()
            let todayStart = calendar.startOfDay(for: now)

            for profile in profiles where profile.isReminderEnabled {
                let starterName = starterDisplayName(for: profile)
                let reminderDay = calendar.startOfDay(
                    for: StarterProfile.scheduledNextFeedingDate(
                        after: profile.lastFedAt,
                        frequencyDays: profile.feedingFrequencyDays,
                        calendar: calendar
                    )
                )

                if reminderDay < todayStart {
                    guard let fireDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) else {
                        continue
                    }
                    _ = await notifications.schedule(
                        .starterFeedingReminder(
                            profileId: profile.id,
                            starterName: starterName,
                            fireDate: fireDate,
                            repeatsDaily: true
                        )
                    )
                    continue
                }

                for hour in Self.starterReminderHours {
                    guard let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: reminderDay),
                          fireDate > now else {
                        continue
                    }
                    _ = await notifications.schedule(
                        .starterFeedingReminder(
                            profileId: profile.id,
                            starterName: starterName,
                            fireDate: fireDate,
                            repeatsDaily: false
                        )
                    )
                }
            }
        }
    }

    private func createBakeRecord(startedAt: Date) -> UUID {
        let record = BakeRecord(
            id: UUID(),
            recipeID: currentRecipeID,
            recipeName: currentRecipeDisplayName,
            recipeSnapshotName: currentRecipeDisplayName,
            startedAt: startedAt,
            completedAt: nil,
            notes: "",
            stepCount: steps.count
        )
        bakeHistory.insert(record, at: 0)
        return record.id
    }

    private func finalizeBakeRecord() {
        guard let activeBakeRecordID,
              let index = bakeHistory.firstIndex(where: { $0.id == activeBakeRecordID }) else { return }
        bakeHistory[index].completedAt = cookState.completedAt ?? Date()
        bakeHistory[index].recipeName = currentRecipeDisplayName
        bakeHistory[index].recipeSnapshotName = currentRecipeDisplayName
        bakeHistory[index].stepCount = steps.count
    }

    private func startTimingForCurrentStep(at startedAt: Date) {
        guard let activeBakeRecordID,
              steps.indices.contains(cookState.currentIndex),
              let recordIndex = bakeHistory.firstIndex(where: { $0.id == activeBakeRecordID }) else { return }

        let step = steps[cookState.currentIndex]
        if bakeHistory[recordIndex].stepTimings.last?.stepID == step.id,
           bakeHistory[recordIndex].stepTimings.last?.completedAt == nil {
            return
        }

        bakeHistory[recordIndex].stepTimings.append(
            BakeStepTiming(
                id: UUID(),
                stepID: step.id,
                stepName: step.name,
                startedAt: startedAt,
                completedAt: nil
            )
        )
    }

    private func closeCurrentStepTiming(at completedAt: Date) {
        guard let activeBakeRecordID,
              let startedAt = cookState.stepStartedAt,
              steps.indices.contains(cookState.currentIndex),
              let recordIndex = bakeHistory.firstIndex(where: { $0.id == activeBakeRecordID }) else { return }

        let step = steps[cookState.currentIndex]
        if let timingIndex = bakeHistory[recordIndex].stepTimings.lastIndex(where: {
            $0.stepID == step.id && $0.completedAt == nil
        }) {
            bakeHistory[recordIndex].stepTimings[timingIndex].stepName = step.name
            bakeHistory[recordIndex].stepTimings[timingIndex].completedAt = completedAt
        } else {
            bakeHistory[recordIndex].stepTimings.append(
                BakeStepTiming(
                    id: UUID(),
                    stepID: step.id,
                    stepName: step.name,
                    startedAt: startedAt,
                    completedAt: completedAt
                )
            )
        }
    }

    private func currentActiveStepsForPersistence() -> [JournalStep] {
        switch stepsMode {
        case .simple:
            return [currentSimpleStepForPersistence()]
        case .custom:
            return currentCustomStepsForPersistence()
        }
    }

    private func currentSimpleStepForPersistence() -> JournalStep {
        Self.normalizedSimpleStep(stepsMode == .simple ? steps.first ?? simpleStep : simpleStep)
    }

    private func currentCustomStepsForPersistence() -> [JournalStep] {
        Self.stepsApplyingBackwardCompatibleUpdates(stepsMode == .custom ? steps : customSteps, kind: currentRecipeKind)
    }

    private func activeSteps(for recipe: SavedRecipe) -> [JournalStep] {
        switch recipe.stepsMode {
        case .simple:
            return [Self.simpleStepApplyingBackwardCompatibleUpdates(recipe.simpleStep ?? recipe.steps.first, kind: recipe.kind, items: recipe.items)]
        case .custom:
            return customSteps(for: recipe)
        }
    }

    private func customSteps(for recipe: SavedRecipe) -> [JournalStep] {
        Self.stepsApplyingBackwardCompatibleUpdates(
            recipe.customSteps.isEmpty && recipe.stepsMode == .custom ? recipe.steps : recipe.customSteps,
            kind: recipe.kind
        )
    }

    private func currentDraftActiveSteps(_ draft: LegacyPersistedRecipe, kind: RecipeKind, items: [RecipeItem]) -> [JournalStep] {
        switch draft.stepsMode {
        case .simple:
            return [Self.simpleStepApplyingBackwardCompatibleUpdates(draft.simpleStep ?? draft.steps.first, kind: kind, items: items)]
        case .custom:
            return customSteps(for: draft, kind: kind)
        }
    }

    private func customSteps(for draft: LegacyPersistedRecipe, kind: RecipeKind) -> [JournalStep] {
        Self.stepsApplyingBackwardCompatibleUpdates(
            draft.customSteps.isEmpty && draft.stepsMode == .custom ? draft.steps : draft.customSteps,
            kind: kind
        )
    }

    private static func makeSimpleStep() -> JournalStep {
        JournalStep(
            id: UUID(),
            type: .other,
            name: BakingTerms.stepsSimpleStepName,
            notes: "",
            materialAllocations: []
        )
    }

    private static func normalizedSimpleStep(_ step: JournalStep?) -> JournalStep {
        var next = step ?? makeSimpleStep()
        next.type = .other
        if next.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            next.name = BakingTerms.stepsSimpleStepName
        }
        next.timeValue = nil
        next.timeUnit = nil
        next.temperature = nil
        next.temperatureUnit = nil
        next.productionMethod = nil
        next.shapingPieceCount = nil
        next.foldPlan = nil
        return next
    }

    private static func simpleStepApplyingBackwardCompatibleUpdates(
        _ step: JournalStep?,
        kind: RecipeKind,
        items: [RecipeItem]
    ) -> JournalStep {
        let normalized = normalizedSimpleStep(step)
        let hasUserContent = !normalized.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !normalized.materialAllocations.isEmpty
        guard !hasUserContent || isGeneratedSimpleTemplateSummary(normalized, kind: kind, items: items),
              let template = templateSimpleStep(kind: kind, items: items) else {
            return normalized
        }
        return normalizedSimpleStep(template)
    }

    private static func hasReadyStepContent(
        steps: [JournalStep],
        stepsMode: RecipeStepsMode,
        simpleStep: JournalStep?
    ) -> Bool {
        switch stepsMode {
        case .simple:
            return hasSimpleStepText(steps.first ?? simpleStep)
        case .custom:
            return !steps.isEmpty
        }
    }

    private static func hasSimpleStepText(_ step: JournalStep?) -> Bool {
        guard let step else { return false }
        return !step.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func makeStep(type: StepType) -> JournalStep {
        let nextCount = steps.filter { $0.type == type }.count + 1
        switch type {
        case .prep:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryPrepWork, notes: nextCount == 1 ? BakingTerms.stepPrepNote : "", materialAllocations: [])
        case .mixing:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryMixing, notes: nextCount == 1 ? BakingTerms.stepMixingFirstNote : BakingTerms.stepMixingLaterNote, materialAllocations: [], timeValue: 20, timeUnit: .min)
        case .fermentation:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryFermentation, notes: "", materialAllocations: [], timeValue: 60, timeUnit: .min, temperature: 85)
        case .baking:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryBaking, notes: "", materialAllocations: [], timeValue: 30, timeUnit: .min, temperature: 350, temperatureUnit: .fahrenheit, productionMethod: .bake)
        case .rest:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryProofing, notes: "", materialAllocations: [], timeValue: 20, timeUnit: .min)
        case .shaping:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepsCategoryShaping, notes: "", materialAllocations: [], timeValue: 15, timeUnit: .min)
        case .other:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.customStepName, notes: "", materialAllocations: [])
        }
    }

    private func setStarterParts(_ item: inout RecipeItem, flour: Double, water: Double) {
        item.starterFlour = max(0, flour)
        item.starterWater = max(0, water)
        syncStarterWeight(&item)
    }

    private func setEggWeight(_ item: inout RecipeItem, weight: Double) {
        let nextWeight = max(0, weight)
        item.waterContentPct = Self.waterContent(forEggType: item.eggType)
        item.weight = nextWeight
    }

    private func materialPercentageSnapshotsIfNeeded(forFlourChangeIn changedItems: [RecipeItem]) -> [UUID: Double] {
        guard currentRecipeKind.usesBakerPercentageSystem,
              formulaIngredientLockMode == .percentage,
              changedItems.contains(where: { displayGroup(for: $0.category) == .flour }) else {
            return [:]
        }

        let flourWeight = summary(for: items).flourWeight
        guard flourWeight > 0 else { return [:] }
        return Dictionary(uniqueKeysWithValues: items.compactMap { item in
            guard displayGroup(for: item.category) == .basic else { return nil }
            return (item.id, item.weight / flourWeight * 100)
        })
    }

    private func applyingMaterialPercentageSnapshots(_ snapshots: [UUID: Double], to nextItems: [RecipeItem]) -> [RecipeItem] {
        guard !snapshots.isEmpty else { return nextItems }
        let flourWeight = summary(for: nextItems).flourWeight
        return nextItems.map { item in
            guard displayGroup(for: item.category) == .basic,
                  let percentage = snapshots[item.id] else {
                return item
            }

            var next = item
            setMaterialWeight(&next, weight: flourWeight * percentage / 100)
            return next
        }
    }

    private func setMaterialWeight(_ item: inout RecipeItem, weight: Double) {
        if item.tag == .egg {
            setEggWeight(&item, weight: weight)
        } else {
            item.weight = max(0, weight)
        }
    }

    private func displayGroup(for category: ItemCategory) -> ItemCategory {
        switch category {
        case .starter:
            return .flour
        case .other:
            return .basic
        default:
            return category
        }
    }

    private func syncStarterWeight(_ item: inout RecipeItem) {
        let flour = max(0, flourContribution(item))
        let water = max(0, starterBaseWater(item))
        item.starterFlour = flour
        item.starterWater = water
        item.hydrationPct = flour > 0 ? water / flour * 100 : 0
        item.weight = flour + water + (item.starterYeastWeight ?? 0) + starterEggWeight(item)
    }

    private func applyStarterHydrationPreset(_ item: inout RecipeItem, hydrationPct: Double) {
        let baseWeight = max(1, flourContribution(item) + starterBaseWater(item))
        let flour = baseWeight / (1 + hydrationPct / 100)
        setStarterParts(&item, flour: flour, water: baseWeight - flour)
        item.starterRatio = Self.starterRatioLabel(flour: flour, water: baseWeight - flour, fallback: item.starterRatio ?? "1:1")
    }

    private static func hydration(forStarterRatio ratio: String) -> Double {
        starterRatioHydration[ratio] ?? parsedHydration(forStarterRatio: ratio) ?? 100
    }

    private static func parsedHydration(forStarterRatio ratio: String) -> Double? {
        let normalized = ratio.replacingOccurrences(of: "：", with: ":")
        let parts = normalized.split(separator: ":")
        guard parts.count == 2,
              let flourPart = Double(parts[0]),
              let waterPart = Double(parts[1]),
              flourPart > 0 else { return nil }
        return waterPart / flourPart * 100
    }

    private static func starterRatioLabel(flour: Double, water: Double, fallback: String) -> String {
        guard flour > 0 else { return fallback }
        let waterPart = max(0, water / flour)
        let roundedWhole = waterPart.rounded()
        if abs(waterPart - roundedWhole) < 0.05 {
            return "1:\(Int(roundedWhole))"
        }
        return String(format: "1:%.1f", waterPart)
    }

    private func load() {
        isLoading = true
        defer {
            isLoading = false
            hasLoadedPersistedState = true
            rescheduleStarterReminders()
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            let templateItems = Self.defaultItems
            let templateSteps = Self.templateTutorialSteps(kind: .toast, items: templateItems)
            recipeName = BakingTerms.toastRecipeName
            currentRecipeKind = .toast
            recipeOverallNotes = ""
            stepText = ""
            items = templateItems
            stepsMode = .simple
            simpleStep = templateSteps.simple
            customSteps = templateSteps.custom
            steps = [simpleStep]
            starterProfiles = [StarterProfile()]
            formulaIngredientLockMode = .weight
            return
        }

        if let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            recipeName = decoded.currentDraft.recipeName
            recipeOverallNotes = decoded.currentDraft.overallNotes
            stepText = decoded.currentDraft.stepText
            items = decoded.currentDraft.items.isEmpty ? Self.defaultItems : decoded.currentDraft.items
            formulaIngredientLockMode = decoded.currentDraft.formulaIngredientLockMode
            currentRecipeKind = decoded.currentRecipeKind
            stepsMode = decoded.currentDraft.stepsMode
            simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(decoded.currentDraft.simpleStep ?? decoded.currentDraft.steps.first, kind: currentRecipeKind, items: items)
            customSteps = customSteps(for: decoded.currentDraft, kind: currentRecipeKind)
            steps = currentDraftActiveSteps(decoded.currentDraft, kind: currentRecipeKind, items: items)
            cookState = decoded.cookState
            currentRecipeID = decoded.currentRecipeID
            savedRecipes = decoded.savedRecipes.map(Self.recipeApplyingBackwardCompatibleUpdates)
            bakeHistory = decoded.bakeHistory
            activeBakeRecordID = decoded.activeBakeRecordID
            starterProfiles = decoded.starterProfiles.isEmpty ? [StarterProfile()] : decoded.starterProfiles
            currentWorkflowState = decoded.currentWorkflowState
            return
        }

        if let legacy = try? JSONDecoder().decode(LegacyPersistedRecipe.self, from: data) {
            recipeName = legacy.recipeName
            recipeOverallNotes = legacy.overallNotes
            stepText = legacy.stepText
            items = legacy.items.isEmpty ? Self.defaultItems : legacy.items
            formulaIngredientLockMode = legacy.formulaIngredientLockMode
            currentRecipeKind = RecipeKind.inferred(name: recipeName, items: items)
            stepsMode = legacy.stepsMode
            simpleStep = Self.simpleStepApplyingBackwardCompatibleUpdates(legacy.simpleStep ?? legacy.steps.first, kind: currentRecipeKind, items: items)
            customSteps = customSteps(for: legacy, kind: currentRecipeKind)
            steps = currentDraftActiveSteps(legacy, kind: currentRecipeKind, items: items)
            cookState = CookState()
            currentRecipeID = nil
            savedRecipes = []
            bakeHistory = []
            activeBakeRecordID = nil
            starterProfiles = [StarterProfile()]
            currentWorkflowState = .draft
            return
        }

        recipeName = BakingTerms.toastRecipeName
        currentRecipeKind = .toast
        recipeOverallNotes = ""
        stepText = ""
        let templateItems = Self.defaultItems
        let templateSteps = Self.templateTutorialSteps(kind: .toast, items: templateItems)
        items = templateItems
        stepsMode = .simple
        simpleStep = templateSteps.simple
        customSteps = templateSteps.custom
        steps = [simpleStep]
        cookState = CookState()
        currentRecipeID = nil
        savedRecipes = []
        bakeHistory = []
        activeBakeRecordID = nil
        starterProfiles = [StarterProfile()]
        currentWorkflowState = .draft
        formulaIngredientLockMode = .weight
    }

    private func persist() {
        guard !isLoading else { return }
        let state = PersistedState(
            currentDraft: LegacyPersistedRecipe(
                recipeName: recipeName,
                overallNotes: recipeOverallNotes,
                stepText: stepText,
                items: items,
                steps: steps,
                stepsMode: stepsMode,
                simpleStep: currentSimpleStepForPersistence(),
                customSteps: currentCustomStepsForPersistence(),
                formulaIngredientLockMode: formulaIngredientLockMode
            ),
            cookState: cookState,
            currentRecipeID: currentRecipeID,
            savedRecipes: savedRecipes,
            bakeHistory: bakeHistory,
            activeBakeRecordID: activeBakeRecordID,
            starterProfiles: starterProfiles,
            currentWorkflowState: currentWorkflowState,
            currentRecipeKind: currentRecipeKind
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private struct PersistedState: Codable {
        var currentDraft: LegacyPersistedRecipe
        var cookState: CookState
        var currentRecipeID: UUID?
        var savedRecipes: [SavedRecipe]
        var bakeHistory: [BakeRecord]
        var activeBakeRecordID: UUID?
        var starterProfiles: [StarterProfile]
        var currentWorkflowState: RecipeWorkflowState
        var currentRecipeKind: RecipeKind

        init(
            currentDraft: LegacyPersistedRecipe,
            cookState: CookState,
            currentRecipeID: UUID?,
            savedRecipes: [SavedRecipe],
            bakeHistory: [BakeRecord],
            activeBakeRecordID: UUID?,
            starterProfiles: [StarterProfile],
            currentWorkflowState: RecipeWorkflowState,
            currentRecipeKind: RecipeKind
        ) {
            self.currentDraft = currentDraft
            self.cookState = cookState
            self.currentRecipeID = currentRecipeID
            self.savedRecipes = savedRecipes
            self.bakeHistory = bakeHistory
            self.activeBakeRecordID = activeBakeRecordID
            self.starterProfiles = starterProfiles
            self.currentWorkflowState = currentWorkflowState
            self.currentRecipeKind = currentRecipeKind
        }

        private enum CodingKeys: String, CodingKey {
            case currentDraft
            case cookState
            case currentRecipeID
            case savedRecipes
            case bakeHistory
            case activeBakeRecordID
            case starterProfile
            case starterProfiles
            case currentWorkflowState
            case currentRecipeKind
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentDraft = try container.decode(LegacyPersistedRecipe.self, forKey: .currentDraft)
            cookState = try container.decode(CookState.self, forKey: .cookState)
            currentRecipeID = try container.decodeIfPresent(UUID.self, forKey: .currentRecipeID)
            savedRecipes = try container.decode([SavedRecipe].self, forKey: .savedRecipes)
            bakeHistory = try container.decode([BakeRecord].self, forKey: .bakeHistory)
            activeBakeRecordID = try container.decodeIfPresent(UUID.self, forKey: .activeBakeRecordID)
            if let profiles = try container.decodeIfPresent([StarterProfile].self, forKey: .starterProfiles), !profiles.isEmpty {
                starterProfiles = profiles
            } else if let profile = try container.decodeIfPresent(StarterProfile.self, forKey: .starterProfile) {
                starterProfiles = [profile]
            } else {
                starterProfiles = [StarterProfile()]
            }
            currentWorkflowState = try container.decodeIfPresent(RecipeWorkflowState.self, forKey: .currentWorkflowState) ?? .draft
            currentRecipeKind = try container.decodeIfPresent(RecipeKind.self, forKey: .currentRecipeKind)
                ?? RecipeKind.inferred(name: currentDraft.recipeName, items: currentDraft.items)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(currentDraft, forKey: .currentDraft)
            try container.encode(cookState, forKey: .cookState)
            try container.encodeIfPresent(currentRecipeID, forKey: .currentRecipeID)
            try container.encode(savedRecipes, forKey: .savedRecipes)
            try container.encode(bakeHistory, forKey: .bakeHistory)
            try container.encodeIfPresent(activeBakeRecordID, forKey: .activeBakeRecordID)
            try container.encode(starterProfiles, forKey: .starterProfiles)
            try container.encode(currentWorkflowState, forKey: .currentWorkflowState)
            try container.encode(currentRecipeKind, forKey: .currentRecipeKind)
        }
    }

    private struct LegacyPersistedRecipe: Codable {
        var recipeName: String
        var overallNotes: String
        var stepText: String
        var items: [RecipeItem]
        var steps: [JournalStep]
        var stepsMode: RecipeStepsMode
        var simpleStep: JournalStep?
        var customSteps: [JournalStep]
        var formulaIngredientLockMode: FormulaIngredientLockMode

        init(
            recipeName: String,
            overallNotes: String = "",
            stepText: String = "",
            items: [RecipeItem],
            steps: [JournalStep],
            stepsMode: RecipeStepsMode = .simple,
            simpleStep: JournalStep? = nil,
            customSteps: [JournalStep] = [],
            formulaIngredientLockMode: FormulaIngredientLockMode = .weight
        ) {
            self.recipeName = recipeName
            self.overallNotes = overallNotes
            self.stepText = stepText
            self.items = items
            self.steps = steps
            self.stepsMode = stepsMode
            self.simpleStep = simpleStep
            self.customSteps = customSteps
            self.formulaIngredientLockMode = formulaIngredientLockMode
        }

        private enum CodingKeys: String, CodingKey {
            case recipeName
            case overallNotes
            case stepText
            case items
            case steps
            case stepsMode
            case simpleStep
            case customSteps
            case formulaIngredientLockMode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            recipeName = try container.decode(String.self, forKey: .recipeName)
            overallNotes = try container.decodeIfPresent(String.self, forKey: .overallNotes) ?? ""
            stepText = try container.decodeIfPresent(String.self, forKey: .stepText) ?? ""
            items = try container.decode([RecipeItem].self, forKey: .items)
            steps = try container.decode([JournalStep].self, forKey: .steps)
            stepsMode = try container.decodeIfPresent(RecipeStepsMode.self, forKey: .stepsMode)
                ?? (steps.count > 1 ? .custom : .simple)
            simpleStep = try container.decodeIfPresent(JournalStep.self, forKey: .simpleStep)
            customSteps = try container.decodeIfPresent([JournalStep].self, forKey: .customSteps)
                ?? (stepsMode == .custom ? steps : [])
            formulaIngredientLockMode = try container.decodeIfPresent(FormulaIngredientLockMode.self, forKey: .formulaIngredientLockMode) ?? .weight
        }
    }

    private static let defaultItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.flour, weight: 500),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.water, weight: 350, waterContentPct: 100),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: BakingTerms.salt, weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .butter, name: BakingTerms.butter, weight: 40),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: BakingTerms.yeast, weight: 5),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: BakingTerms.sugar, weight: 35)
    ]

    private static let chiffonItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.lowGlutenFlour, weight: 90),
        RecipeItem(id: UUID(), category: .basic, tag: .egg, name: BakingTerms.egg, weight: 250, waterContentPct: 75, eggType: BakingTerms.beatenEgg),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: BakingTerms.granulatedSugar, weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .cream, name: BakingTerms.cream, weight: 100),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.milk, weight: 60, waterContentPct: 100),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: BakingTerms.cornOil, weight: 55, waterContentPct: 0)
    ]

    private static let countryBreadItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.highGlutenFlour, weight: 420),
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.wholeWheatFlour, weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.water, weight: 380, waterContentPct: 100),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: BakingTerms.salt, weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: BakingTerms.yeast, weight: 4),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: BakingTerms.oliveOil, weight: 12, waterContentPct: 0)
    ]

    private static let defaultCountryBreadFoldPlan = StepFoldPlan(targetCount: 4, intervalMinutes: 30)
    private static let countryBreadFoldStepAliases = [
        "折叠发酵",
        "Fold and ferment"
    ]

    @discardableResult
    private func applyBackwardCompatibleRecipeUpdatesToSavedRecipes() -> Bool {
        let updatedRecipes = savedRecipes.map(Self.recipeApplyingBackwardCompatibleUpdates)
        guard updatedRecipes != savedRecipes else { return false }
        savedRecipes = updatedRecipes
        return true
    }

    private static func recipeApplyingBackwardCompatibleUpdates(_ recipe: SavedRecipe) -> SavedRecipe {
        var next = recipe
        let simpleStep = simpleStepApplyingBackwardCompatibleUpdates(
            recipe.simpleStep ?? recipe.steps.first,
            kind: recipe.kind,
            items: recipe.items
        )
        next.simpleStep = simpleStep
        next.steps = recipe.stepsMode == .simple
            ? [simpleStep]
            : stepsApplyingBackwardCompatibleUpdates(recipe.steps, kind: recipe.kind)
        let customSource = recipe.customSteps.isEmpty && recipe.stepsMode == .custom ? recipe.steps : recipe.customSteps
        next.customSteps = stepsApplyingBackwardCompatibleUpdates(customSource, kind: recipe.kind)
        return next
    }

    /// Applies additive schema updates to existing recipes without syncing them to the latest template.
    ///
    /// Template definitions are only the source of truth for newly created recipes. Existing recipes may
    /// contain older template steps, renamed steps, or user-added steps, and those must be preserved.
    /// Backward-compatible updates here may only fill missing metadata on existing steps.
    /// Do not delete, reorder, rename, or replace steps from a newer template list.
    private static func stepsApplyingBackwardCompatibleUpdates(_ steps: [JournalStep], kind: RecipeKind) -> [JournalStep] {
        guard kind == .countryBread,
              !steps.contains(where: { $0.foldPlan != nil }) else {
            return steps
        }

        var nextSteps = steps
        let explicitIndex = nextSteps.firstIndex(where: isCountryBreadFoldStep)
        let fallbackIndex = nextSteps.firstIndex { $0.type == .fermentation }

        guard let foldStepIndex = explicitIndex ?? fallbackIndex else {
            return steps
        }

        nextSteps[foldStepIndex].foldPlan = defaultCountryBreadFoldPlan
        return nextSteps
    }

    private static func isCountryBreadFoldStep(_ step: JournalStep) -> Bool {
        guard step.type == .fermentation else { return false }
        let normalizedName = step.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if countryBreadFoldStepAliases.contains(where: { alias in
            normalizedName.localizedCaseInsensitiveContains(alias)
        }) {
            return true
        }

        let normalizedNotes = step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedNotes.localizedCaseInsensitiveContains("拉伸折叠")
            || normalizedNotes.localizedCaseInsensitiveContains("stretch-and-fold")
            || normalizedNotes.localizedCaseInsensitiveContains("stretch and fold")
    }

    private static func templateTutorialSteps(kind: RecipeKind, items: [RecipeItem]) -> (simple: JournalStep, custom: [JournalStep]) {
        let customSteps = templateCustomSteps(kind: kind, items: items)
        return (
            simple: templateSimpleStep(from: customSteps, items: items) ?? makeSimpleStep(),
            custom: customSteps
        )
    }

    private static func templateCustomSteps(kind: RecipeKind, items: [RecipeItem]) -> [JournalStep] {
        switch kind {
        case .toast:
            return toastTemplateSteps(items: items)
        case .chiffon:
            return chiffonTemplateSteps(items: items)
        case .countryBread:
            return countryBreadTemplateSteps(items: items)
        case .custom:
            return []
        }
    }

    private static func templateSimpleStep(kind: RecipeKind, items: [RecipeItem]) -> JournalStep? {
        templateSimpleStep(from: templateCustomSteps(kind: kind, items: items), items: items)
    }

    private static func templateSimpleStep(from customSteps: [JournalStep], items: [RecipeItem]) -> JournalStep? {
        let note = simpleTutorialNote(from: customSteps)
        guard !note.isEmpty else { return nil }

        return JournalStep(
            id: UUID(),
            type: .other,
            name: BakingTerms.stepsSimpleStepName,
            notes: note,
            materialAllocations: allocations(in: items)
        )
    }

    static func simpleStepForRecipeExchangeImport(steps: [JournalStep], items: [RecipeItem]) -> JournalStep {
        JournalStep(
            id: UUID(),
            type: .other,
            name: BakingTerms.stepsSimpleStepName,
            notes: simpleTutorialNote(from: steps),
            materialAllocations: allocations(in: items)
        )
    }

    static func stepsForRecipeExchangeImport(_ steps: [JournalStep], kind: RecipeKind) -> [JournalStep] {
        stepsApplyingBackwardCompatibleUpdates(steps, kind: kind)
    }

    private static func simpleTutorialNote(from steps: [JournalStep]) -> String {
        steps.enumerated()
            .map { index, step in
                [
                    "\(index + 1). \(step.name)",
                    step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                ]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func isGeneratedSimpleTemplateSummary(
        _ step: JournalStep,
        kind: RecipeKind,
        items: [RecipeItem]
    ) -> Bool {
        let summary: String?
        switch kind {
        case .toast:
            summary = BakingTerms.templateToastSimpleNote
        case .chiffon:
            summary = BakingTerms.templateChiffonSimpleNote
        case .countryBread:
            summary = BakingTerms.templateCountryBreadSimpleNote
        case .custom:
            summary = nil
        }

        guard let summary else { return false }
        let expectedNotes = templateNote(summary, materials: materialLines(in: items))
        return step.notes.trimmingCharacters(in: .whitespacesAndNewlines) == expectedNotes
    }

    private static func toastTemplateSteps(items: [RecipeItem]) -> [JournalStep] {
        let mixAllocations = allocations(in: items, tags: [.flour, .water, .sugar, .yeast])
        let butterAllocations = allocations(in: items, tags: [.salt, .butter])

        return [
            templateStep(
                type: .prep,
                name: BakingTerms.templateToastPrepName,
                notes: BakingTerms.templateToastPrepNote,
                timeValue: 10,
                timeUnit: .min
            ),
            templateStep(
                type: .mixing,
                name: BakingTerms.templateToastMixName,
                notes: templateNote(
                    BakingTerms.templateToastMixNote,
                    materials: materialLines(in: items, allocations: mixAllocations)
                ),
                allocations: mixAllocations,
                timeValue: 15,
                timeUnit: .min
            ),
            templateStep(
                type: .mixing,
                name: BakingTerms.templateToastButterName,
                notes: templateNote(
                    BakingTerms.templateToastButterNote,
                    materials: materialLines(in: items, allocations: butterAllocations)
                ),
                allocations: butterAllocations,
                timeValue: 10,
                timeUnit: .min
            ),
            templateStep(
                type: .fermentation,
                name: BakingTerms.templateToastBulkName,
                notes: BakingTerms.templateToastBulkNote,
                timeValue: 60,
                timeUnit: .min,
                temperature: 28,
                temperatureUnit: .celsius
            ),
            templateStep(
                type: .shaping,
                name: BakingTerms.templateToastShapeName,
                notes: BakingTerms.templateToastShapeNote,
                timeValue: 15,
                timeUnit: .min,
                shapingPieceCount: 4
            ),
            templateStep(
                type: .rest,
                name: BakingTerms.templateToastProofName,
                notes: BakingTerms.templateToastProofNote,
                timeValue: 45,
                timeUnit: .min,
                temperature: 30,
                temperatureUnit: .celsius
            ),
            templateStep(
                type: .baking,
                name: BakingTerms.templateToastBakeName,
                notes: BakingTerms.templateToastBakeNote,
                timeValue: 32,
                timeUnit: .min,
                temperature: 350,
                temperatureUnit: .fahrenheit,
                productionMethod: .bake
            )
        ]
    }

    private static func chiffonTemplateSteps(items: [RecipeItem]) -> [JournalStep] {
        let yolkAllocations = allocations(in: items, tags: [.flour, .water, .cream, .other])
            + allocations(in: items, tags: [.egg], percentage: 50)
            + allocations(in: items, tags: [.sugar], percentage: 30)
        let meringueAllocations = allocations(in: items, tags: [.egg], percentage: 50)
            + allocations(in: items, tags: [.sugar], percentage: 70)

        return [
            templateStep(
                type: .prep,
                name: BakingTerms.templateChiffonPrepName,
                notes: BakingTerms.templateChiffonPrepNote,
                timeValue: 10,
                timeUnit: .min
            ),
            templateStep(
                type: .mixing,
                name: BakingTerms.templateChiffonYolkName,
                notes: templateNote(
                    BakingTerms.templateChiffonYolkNote,
                    materials: materialLines(in: items, allocations: yolkAllocations)
                ),
                allocations: yolkAllocations,
                timeValue: 10,
                timeUnit: .min
            ),
            templateStep(
                type: .mixing,
                name: BakingTerms.templateChiffonMeringueName,
                notes: templateNote(
                    BakingTerms.templateChiffonMeringueNote,
                    materials: materialLines(in: items, allocations: meringueAllocations)
                ),
                allocations: meringueAllocations,
                timeValue: 8,
                timeUnit: .min
            ),
            templateStep(
                type: .mixing,
                name: BakingTerms.templateChiffonFoldName,
                notes: BakingTerms.templateChiffonFoldNote,
                timeValue: 8,
                timeUnit: .min
            ),
            templateStep(
                type: .baking,
                name: BakingTerms.templateChiffonBakeName,
                notes: BakingTerms.templateChiffonBakeNote,
                timeValue: 50,
                timeUnit: .min,
                temperature: 340,
                temperatureUnit: .fahrenheit,
                productionMethod: .bake
            ),
            templateStep(
                type: .rest,
                name: BakingTerms.templateChiffonCoolName,
                notes: BakingTerms.templateChiffonCoolNote,
                timeValue: 60,
                timeUnit: .min
            )
        ]
    }

    private static func countryBreadTemplateSteps(items: [RecipeItem]) -> [JournalStep] {
        let mixAllocations = allocations(in: items)

        return [
            templateStep(
                type: .mixing,
                name: BakingTerms.templateCountryBreadMixName,
                notes: templateNote(
                    BakingTerms.templateCountryBreadMixNote,
                    materials: materialLines(in: items, allocations: mixAllocations)
                ),
                allocations: mixAllocations,
                timeValue: 10,
                timeUnit: .min
            ),
            templateStep(
                type: .fermentation,
                name: BakingTerms.templateCountryBreadBulkName,
                notes: BakingTerms.templateCountryBreadBulkNote,
                temperature: 24,
                temperatureUnit: .celsius,
                foldPlan: defaultCountryBreadFoldPlan
            ),
            templateStep(
                type: .rest,
                name: BakingTerms.templateCountryBreadColdName,
                notes: BakingTerms.templateCountryBreadColdNote,
                timeValue: 8,
                timeUnit: .hr
            ),
            templateStep(
                type: .shaping,
                name: BakingTerms.templateCountryBreadPreshapeName,
                notes: BakingTerms.templateCountryBreadPreshapeNote,
                timeValue: 30,
                timeUnit: .min
            ),
            templateStep(
                type: .rest,
                name: BakingTerms.templateCountryBreadProofName,
                notes: BakingTerms.templateCountryBreadProofNote,
                timeValue: 150,
                timeUnit: .min,
                temperature: 24,
                temperatureUnit: .celsius
            ),
            templateStep(
                type: .baking,
                name: BakingTerms.templateCountryBreadBakeName,
                notes: BakingTerms.templateCountryBreadBakeNote,
                timeValue: 45,
                timeUnit: .min,
                temperature: 450,
                temperatureUnit: .fahrenheit,
                productionMethod: .bake
            )
        ]
    }

    private static func templateNote(_ note: String, materials: [String] = []) -> String {
        ([note.trimmingCharacters(in: .whitespacesAndNewlines)] + materials)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func materialLines(in items: [RecipeItem]) -> [String] {
        items.compactMap { item in
            materialLine(name: item.name, item: item, weight: item.weight)
        }
    }

    private static func materialLines(
        in items: [RecipeItem],
        allocations: [StepMaterialAllocation]
    ) -> [String] {
        let itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return allocations.compactMap { allocation in
            guard let item = itemsByID[allocation.itemId] else { return nil }
            return materialLine(
                name: item.name,
                item: item,
                weight: item.weight * min(max(0, allocation.percentage), 100) / 100
            )
        }
    }

    private static func materialLine(name: String, item: RecipeItem, weight: Double) -> String? {
        guard weight > 0 else { return nil }
        let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? item.tag.label : name
        return "\(displayName)\(BakingFormat.compactWeight(weight, gramPrecision: materialWeightPrecision(for: weight)))"
    }

    private static func materialWeightPrecision(for weight: Double) -> Int {
        let roundedWhole = weight.rounded()
        if abs(weight - roundedWhole) < 0.05 {
            return 0
        }

        let roundedTenth = (weight * 10).rounded() / 10
        return abs(weight - roundedTenth) < 0.005 ? 1 : 2
    }

    private static func templateStep(
        type: StepType,
        name: String,
        notes: String,
        allocations: [StepMaterialAllocation] = [],
        timeValue: Double? = nil,
        timeUnit: TimeUnit? = nil,
        temperature: Double? = nil,
        temperatureUnit: TemperatureUnit? = nil,
        productionMethod: ProductionMethod? = nil,
        shapingPieceCount: Double? = nil,
        foldPlan: StepFoldPlan? = nil
    ) -> JournalStep {
        JournalStep(
            id: UUID(),
            type: type,
            name: name,
            notes: notes,
            materialAllocations: allocations,
            timeValue: timeValue,
            timeUnit: timeUnit,
            temperature: temperature,
            temperatureUnit: temperatureUnit,
            productionMethod: productionMethod,
            shapingPieceCount: shapingPieceCount,
            foldPlan: foldPlan
        )
    }

    private static func allocations(
        in items: [RecipeItem],
        tags: Set<ItemTag>? = nil,
        percentage: Double = 100
    ) -> [StepMaterialAllocation] {
        items
            .filter { item in
                guard let tags else { return true }
                return tags.contains(item.tag)
            }
            .map { StepMaterialAllocation(itemId: $0.id, percentage: percentage) }
    }

    private static let defaultStarterRatio = [
        BakingTerms.levainStarter: "1:1",
        BakingTerms.liquidStarter: "1:5",
        BakingTerms.tangzhongStarter: "1:5",
        BakingTerms.scaldedStarter: "1:1",
        BakingTerms.poolishStarter: "1:1"
    ]

    private static let starterRatioHydration = [
        "1:1": 100.0,
        "1:2": 200.0,
        "1:5": 500.0,
        "2:1": 200.0,
        "5:1": 500.0
    ]

    private static let starterHydrationPresets = [
        BakingTerms.levainStarter: 100.0,
        BakingTerms.liquidStarter: 500.0,
        BakingTerms.tangzhongStarter: 500.0,
        BakingTerms.scaldedStarter: 100.0,
        BakingTerms.poolishStarter: 100.0
    ]

    private static func makeItem(category: ItemCategory, tag: ItemTag?) -> RecipeItem {
        switch category {
        case .flour:
            return RecipeItem(id: UUID(), category: category, tag: .flour, name: BakingTerms.flour, weight: 100)
        case .starter:
            return RecipeItem(id: UUID(), category: category, tag: .starter, name: BakingTerms.starterDisplayName(BakingTerms.levainStarter), weight: 100, hydrationPct: 100, starterFlour: 50, starterRatio: "1:1", starterWater: 50, starterType: BakingTerms.levainStarter)
        case .other:
            return RecipeItem(id: UUID(), category: category, tag: .other, name: BakingTerms.custom, weight: 20, waterContentPct: 0)
        case .basic:
            switch tag ?? .water {
            case .egg:
                return RecipeItem(id: UUID(), category: category, tag: .egg, name: BakingTerms.egg, weight: 50, waterContentPct: 75, eggType: BakingTerms.beatenEgg)
            case .salt:
                return RecipeItem(id: UUID(), category: category, tag: .salt, name: BakingTerms.salt, weight: 10)
            case .yeast:
                return RecipeItem(id: UUID(), category: category, tag: .yeast, name: BakingTerms.yeast, weight: 5)
            case .sugar:
                return RecipeItem(id: UUID(), category: category, tag: .sugar, name: BakingTerms.sugar, weight: 35)
            case .butter:
                return RecipeItem(id: UUID(), category: category, tag: .butter, name: BakingTerms.butter, weight: 50)
            case .cream:
                return RecipeItem(id: UUID(), category: category, tag: .cream, name: BakingTerms.cream, weight: 100)
            default:
                return RecipeItem(id: UUID(), category: category, tag: .water, name: BakingTerms.water, weight: 50, waterContentPct: 100)
            }
        }
    }
}
