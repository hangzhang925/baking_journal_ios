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

    @Published var recipeName: String = BakingTerms.toastRecipeName { didSet { persist() } }
    @Published var items: [RecipeItem] = [] { didSet { persist() } }
    @Published var steps: [JournalStep] = [] {
        didSet {
            if steps.isEmpty {
                currentWorkflowState = .draft
            }
            persist()
        }
    }
    @Published var cookState = CookState() { didSet { persist() } }
    @Published var currentRecipeID: UUID? { didSet { persist() } }
    @Published var savedRecipes: [SavedRecipe] = [] { didSet { persist() } }
    @Published var bakeHistory: [BakeRecord] = [] { didSet { persist() } }
    @Published var activeBakeRecordID: UUID? { didSet { persist() } }
    @Published var starterProfile = StarterProfile() { didSet { persist() } }
    @Published var currentWorkflowState: RecipeWorkflowState = .draft { didSet { persist() } }
    @Published private(set) var hasLoadedPersistedState = false

    static let starterOptions = [BakingTerms.levainStarter, BakingTerms.liquidStarter, BakingTerms.tangzhongStarter, BakingTerms.scaldedStarter, BakingTerms.poolishStarter]
    static let starterRatioOptions = ["1:1", "2:1", "5:1"]
    static let yeastOptions = [BakingTerms.dryYeast, BakingTerms.freshYeast, BakingTerms.liquidYeast]
    static let eggOptions = [BakingTerms.wholeEgg, BakingTerms.yolk, BakingTerms.white]
    // TODO: When starter notifications are added, schedule nextFeedingDate at these local reminder hours.
    static let starterReminderHours = [9, 12, 17]

    static var starterReminderTimeLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
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

    init(notifications: BakingNotificationScheduling) {
        self.notifications = notifications
        load()
    }

    var summary: RecipeSummary {
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

    var currentRecipeDisplayName: String {
        let trimmed = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.unnamedRecipe : trimmed
    }

    var currentStarterDisplayName: String {
        let trimmed = starterProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.starterProfileDefaultName : trimmed
    }

    var starterFinalWeight: Double {
        let containerWeight = starterProfile.isContainerWeightEnabled ? starterProfile.containerWeight : 0
        return max(0, starterProfile.measuredWeight - containerWeight)
    }

    var starterFeedFlourWeight: Double {
        starterFinalWeight * starterProfile.feedingRatio.feedMultiplier
    }

    var starterFeedWaterWeight: Double {
        starterFinalWeight * starterProfile.feedingRatio.feedMultiplier
    }

    var isStarterReminderDue: Bool {
        guard starterProfile.isReminderEnabled else { return false }
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let nextFeedingStart = calendar.startOfDay(for: starterProfile.nextFeedingDate)
        return todayStart >= nextFeedingStart && starterProfile.lastFedAt < nextFeedingStart
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
        recipeWorkflowState == .ready
    }

    var canMarkReadyToBake: Bool {
        !steps.isEmpty
    }

    func isReadyToBake(_ recipe: SavedRecipe) -> Bool {
        recipe.workflowState == .ready && !recipe.steps.isEmpty
    }

    var readinessMessage: String {
        if steps.isEmpty {
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

    @discardableResult
    func addItem(category: ItemCategory, tag: ItemTag? = nil) -> RecipeItem {
        let item = Self.makeItem(category: category, tag: tag)
        items.append(item)
        return item
    }

    func createEmptyRecipe() {
        cancelCookTimerReminder()
        isLoading = true
        recipeName = BakingTerms.defaultRecipeName
        items = []
        steps = []
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .draft
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
        items = recipe.items
        steps = recipe.steps
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .draft
        isLoading = false
        persist()
    }

    func applyTemplate(_ template: RecipeTemplate) {
        cancelCookTimerReminder()
        isLoading = true
        switch template {
        case .toast:
            recipeName = BakingTerms.toastRecipeName
            items = Self.defaultItems
            steps = []
        case .chiffon:
            recipeName = BakingTerms.chiffonRecipeName
            items = Self.chiffonItems
            steps = []
        case .countryBread:
            recipeName = BakingTerms.countryBreadRecipeName
            items = Self.countryBreadItems
            steps = []
        }
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        currentWorkflowState = .draft
        isLoading = false
        persist()
    }

    func saveCurrentRecipe() {
        let now = Date()
        if let currentRecipeID, let index = savedRecipes.firstIndex(where: { $0.id == currentRecipeID }) {
            savedRecipes[index].name = currentRecipeDisplayName
            savedRecipes[index].items = items
            savedRecipes[index].steps = steps
            savedRecipes[index].workflowState = recipeWorkflowState
            savedRecipes[index].updatedAt = now
        } else {
            let recipe = SavedRecipe(
                id: UUID(),
                name: currentRecipeDisplayName,
                items: items,
                steps: steps,
                workflowState: recipeWorkflowState,
                createdAt: now,
                updatedAt: now
            )
            currentRecipeID = recipe.id
            savedRecipes.insert(recipe, at: 0)
        }
    }

    func loadRecipe(_ recipe: SavedRecipe) {
        cancelCookTimerReminder()
        isLoading = true
        recipeName = recipe.name
        items = recipe.items
        steps = recipe.steps
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

    func updateStarterFinalWeight(_ finalWeight: Double) {
        var next = starterProfile
        let containerWeight = next.isContainerWeightEnabled ? next.containerWeight : 0
        next.measuredWeight = max(0, finalWeight) + containerWeight
        starterProfile = next
    }

    func markStarterFed() {
        var next = starterProfile
        let currentWeight = starterFinalWeight
        let addedWeight = starterFeedFlourWeight + starterFeedWaterWeight
        let containerWeight = next.isContainerWeightEnabled ? next.containerWeight : 0
        next.lastFedAt = Date()
        next.measuredWeight = currentWeight + addedWeight + containerWeight
        starterProfile = next
    }

    func updateBakeRecordNotes(_ notes: String, for record: BakeRecord) {
        guard let index = bakeHistory.firstIndex(where: { $0.id == record.id }) else { return }
        bakeHistory[index].notes = notes
    }

    func removeItem(_ item: RecipeItem) {
        let flourCount = items.filter { $0.category == .flour }.count
        guard item.category != .flour || flourCount > 1 else { return }
        items.removeAll { $0.id == item.id }
        steps = steps.map { step in
            var next = step
            next.materialAllocations.removeAll { $0.itemId == item.id }
            return next
        }
    }

    func updateItem(_ item: RecipeItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
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

    func updateItemWeight(_ item: RecipeItem, weight: Double) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        if next.category == .starter {
            let optionalWeight = (next.starterYeastWeight ?? 0) + starterEggWeight(next)
            let currentBase = max(1, flourContribution(next) + starterBaseWater(next))
            let nextBase = max(0, weight - optionalWeight)
            let scale = nextBase / currentBase
            setStarterParts(&next, flour: flourContribution(next) * scale, water: starterBaseWater(next) * scale)
        } else {
            next.weight = max(0, weight)
        }
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
        applyStarterHydrationPreset(&next, hydrationPct: Self.starterRatioHydration[next.starterRatio ?? ""] ?? 100)
        updateItem(next)
    }

    func applyStarterRatio(_ ratio: String, to item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterRatio = ratio
        applyStarterHydrationPreset(&next, hydrationPct: Self.starterRatioHydration[ratio] ?? 100)
        updateItem(next)
    }

    func updateStarterParts(_ item: RecipeItem, flour: Double? = nil, water: Double? = nil) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        setStarterParts(
            &next,
            flour: flour ?? flourContribution(next),
            water: water ?? starterBaseWater(next)
        )
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

    func addStep(type: StepType) {
        steps.append(makeStep(type: type))
    }

    func removeStep(_ step: JournalStep) {
        steps.removeAll { $0.id == step.id }
        cookState.checked[step.id] = nil
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

    func assign(itemId: UUID, to step: JournalStep) {
        assign(itemId: itemId, percentage: remainingPercentage(for: itemId, excluding: step.id), to: step)
    }

    func assign(itemId: UUID, percentage: Double, to step: JournalStep) {
        let clamped = min(max(0, percentage), remainingPercentage(for: itemId, excluding: step.id))
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
            let available = remainingPercentage(for: item.id, excluding: step.id)
            guard available > 0 else { continue }
            if let allocationIndex = nextSteps[stepIndex].materialAllocations.firstIndex(where: { $0.itemId == item.id }) {
                nextSteps[stepIndex].materialAllocations[allocationIndex].percentage = available
            } else {
                nextSteps[stepIndex].materialAllocations.append(
                    StepMaterialAllocation(itemId: item.id, percentage: available)
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

    func unassignedItems() -> [RecipeItem] {
        items.filter { remainingPercentage(for: $0.id) > 0 }
    }

    func stepContaining(itemId: UUID) -> JournalStep? {
        steps.first { step in
            step.materialAllocations.contains { $0.itemId == itemId }
        }
    }

    func allocationPercentage(for itemId: UUID, in step: JournalStep) -> Double {
        step.materialAllocations.first { $0.itemId == itemId }?.percentage ?? 0
    }

    func allocatedPercentage(for itemId: UUID, excluding stepId: UUID? = nil) -> Double {
        steps.reduce(0) { total, step in
            if step.id == stepId { return total }
            return total + step.materialAllocations
                .filter { $0.itemId == itemId }
                .reduce(0) { $0 + $1.percentage }
        }
    }

    func remainingPercentage(for itemId: UUID, excluding stepId: UUID? = nil) -> Double {
        max(0, 100 - allocatedPercentage(for: itemId, excluding: stepId))
    }

    func allocatedWeight(for item: RecipeItem, percentage: Double) -> Double {
        item.weight * min(max(0, percentage), 100) / 100
    }

    func stepMinutes(_ step: JournalStep) -> Double {
        let value = step.timeValue ?? 0
        return step.timeUnit == .hr ? value * 60 : value
    }

    func totalStepMinutes() -> Double {
        steps.reduce(0) { $0 + stepMinutes($1) }
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

    func startTimer(for step: JournalStep) {
        guard ensureCookStarted() else { return }
        let now = Date()
        let minutes = stepMinutes(step)
        cookState.timerStepId = step.id
        cookState.timerEndsAt = now.addingTimeInterval(minutes * 60)

        guard minutes > 0, let timerEndsAt = cookState.timerEndsAt else {
            cancelCookTimerReminder()
            return
        }

        scheduleCookTimerReminder(for: step, endsAt: timerEndsAt)
    }

    func moveCookStep(_ direction: Int) {
        guard ensureCookStarted() else { return }
        let nextIndex = cookState.currentIndex + direction
        guard nextIndex >= 0 else { return }
        if nextIndex >= steps.count {
            cookState.completedAt = Date()
            finalizeBakeRecord()
            cancelCookTimerReminder()
            return
        }
        cookState.currentIndex = nextIndex
        cookState.stepStartedAt = Date()
        cookState.timerEndsAt = nil
        cookState.timerStepId = nil
        cancelCookTimerReminder()
    }

    func resetCook() {
        cookState = CookState()
        activeBakeRecordID = nil
        cancelCookTimerReminder()
    }

    func beginCookIfNeeded() {
        _ = ensureCookStarted()
    }

    func exportRecipeData() throws -> Data {
        let state = LegacyPersistedRecipe(recipeName: recipeName, items: items, steps: steps)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(state)
    }

    func importRecipeData(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(LegacyPersistedRecipe.self, from: data)
        cancelCookTimerReminder()
        isLoading = true
        recipeName = decoded.recipeName.isEmpty ? BakingTerms.toastRecipeName : decoded.recipeName
        items = decoded.items.isEmpty ? Self.defaultItems : decoded.items
        steps = decoded.steps
        isLoading = false
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        persist()
    }

    func flourContribution(_ item: RecipeItem) -> Double {
        if item.category == .flour { return item.weight }
        guard item.category == .starter else { return 0 }
        if let starterFlour = item.starterFlour { return starterFlour }
        let hydration = (item.hydrationPct ?? Self.starterRatioHydration[item.starterRatio ?? ""] ?? Self.starterHydrationPresets[item.starterType ?? ""] ?? 100) / 100
        let optionalWeight = (item.starterYeastWeight ?? 0) + starterEggWeight(item)
        return max(0, item.weight - optionalWeight) / (1 + hydration)
    }

    func waterContribution(_ item: RecipeItem) -> Double {
        if item.tag == .water { return item.weight }
        if item.category == .starter { return starterBaseWater(item) + starterEggWater(item) }
        if item.tag == .egg { return item.weight * ((item.waterContentPct ?? 75) / 100) }
        if item.category == .other { return item.weight * ((item.waterContentPct ?? 0) / 100) }
        if item.yeastType == BakingTerms.liquidYeast { return item.weight }
        return 0
    }

    func hasWaterContent(_ item: RecipeItem) -> Bool {
        waterContribution(item) > 0
    }

    func starterBaseWater(_ item: RecipeItem) -> Double {
        if let starterWater = item.starterWater { return starterWater }
        let optionalWeight = (item.starterYeastWeight ?? 0) + starterEggWeight(item)
        return max(0, item.weight - optionalWeight) - flourContribution(item)
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
        }
        if cookState.stepStartedAt == nil { cookState.stepStartedAt = Date() }
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

    private func cancelCookTimerReminder() {
        Task { [notifications] in
            await notifications.cancel(scope: .cookTimer)
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

    private func makeStep(type: StepType) -> JournalStep {
        let nextCount = steps.filter { $0.type == type }.count + 1
        switch type {
        case .prep:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepPrepName, notes: nextCount == 1 ? BakingTerms.stepPrepNote : "", materialAllocations: [])
        case .mixing:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.stepMixingName, notes: nextCount == 1 ? BakingTerms.stepMixingFirstNote : BakingTerms.stepMixingLaterNote, materialAllocations: [], timeValue: 20, timeUnit: .min)
        case .fermentation:
            let stage = nextCount == 1 ? BakingTerms.fermentationStageFirst : BakingTerms.fermentationStageSecond
            return JournalStep(id: UUID(), type: type, name: BakingTerms.fermentationStepName(stage: stage), notes: "", materialAllocations: [], timeValue: 60, timeUnit: .min, temperature: 85)
        case .baking:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.productionStepName, notes: "", materialAllocations: [], timeValue: 30, timeUnit: .min, temperature: 350, temperatureUnit: .fahrenheit, productionMethod: .bake)
        case .rest:
            return JournalStep(id: UUID(), type: type, name: type.label, notes: "", materialAllocations: [], timeValue: 20, timeUnit: .min)
        case .shaping:
            return JournalStep(id: UUID(), type: type, name: type.label, notes: "", materialAllocations: [], timeValue: 15, timeUnit: .min)
        case .other:
            return JournalStep(id: UUID(), type: type, name: BakingTerms.customStepName, notes: "", materialAllocations: [])
        }
    }

    private func setStarterParts(_ item: inout RecipeItem, flour: Double, water: Double) {
        item.starterFlour = max(0, flour)
        item.starterWater = max(0, water)
        syncStarterWeight(&item)
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
    }

    private func load() {
        isLoading = true
        defer {
            isLoading = false
            hasLoadedPersistedState = true
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            recipeName = BakingTerms.toastRecipeName
            items = Self.defaultItems
            steps = []
            starterProfile = StarterProfile()
            return
        }

        if let decoded = try? JSONDecoder().decode(PersistedState.self, from: data) {
            recipeName = decoded.currentDraft.recipeName
            items = decoded.currentDraft.items.isEmpty ? Self.defaultItems : decoded.currentDraft.items
            steps = decoded.currentDraft.steps
            cookState = decoded.cookState
            currentRecipeID = decoded.currentRecipeID
            savedRecipes = decoded.savedRecipes
            bakeHistory = decoded.bakeHistory
            activeBakeRecordID = decoded.activeBakeRecordID
            starterProfile = decoded.starterProfile
            currentWorkflowState = decoded.currentWorkflowState
            return
        }

        if let legacy = try? JSONDecoder().decode(LegacyPersistedRecipe.self, from: data) {
            recipeName = legacy.recipeName
            items = legacy.items.isEmpty ? Self.defaultItems : legacy.items
            steps = legacy.steps
            cookState = CookState()
            currentRecipeID = nil
            savedRecipes = []
            bakeHistory = []
            activeBakeRecordID = nil
            starterProfile = StarterProfile()
            currentWorkflowState = .draft
            return
        }

        recipeName = BakingTerms.toastRecipeName
        items = Self.defaultItems
        steps = []
        cookState = CookState()
        currentRecipeID = nil
        savedRecipes = []
        bakeHistory = []
        activeBakeRecordID = nil
        starterProfile = StarterProfile()
        currentWorkflowState = .draft
    }

    private func persist() {
        guard !isLoading else { return }
        let state = PersistedState(
            currentDraft: LegacyPersistedRecipe(recipeName: recipeName, items: items, steps: steps),
            cookState: cookState,
            currentRecipeID: currentRecipeID,
            savedRecipes: savedRecipes,
            bakeHistory: bakeHistory,
            activeBakeRecordID: activeBakeRecordID,
            starterProfile: starterProfile,
            currentWorkflowState: currentWorkflowState
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
        var starterProfile: StarterProfile
        var currentWorkflowState: RecipeWorkflowState

        init(
            currentDraft: LegacyPersistedRecipe,
            cookState: CookState,
            currentRecipeID: UUID?,
            savedRecipes: [SavedRecipe],
            bakeHistory: [BakeRecord],
            activeBakeRecordID: UUID?,
            starterProfile: StarterProfile,
            currentWorkflowState: RecipeWorkflowState
        ) {
            self.currentDraft = currentDraft
            self.cookState = cookState
            self.currentRecipeID = currentRecipeID
            self.savedRecipes = savedRecipes
            self.bakeHistory = bakeHistory
            self.activeBakeRecordID = activeBakeRecordID
            self.starterProfile = starterProfile
            self.currentWorkflowState = currentWorkflowState
        }

        private enum CodingKeys: String, CodingKey {
            case currentDraft
            case cookState
            case currentRecipeID
            case savedRecipes
            case bakeHistory
            case activeBakeRecordID
            case starterProfile
            case currentWorkflowState
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentDraft = try container.decode(LegacyPersistedRecipe.self, forKey: .currentDraft)
            cookState = try container.decode(CookState.self, forKey: .cookState)
            currentRecipeID = try container.decodeIfPresent(UUID.self, forKey: .currentRecipeID)
            savedRecipes = try container.decode([SavedRecipe].self, forKey: .savedRecipes)
            bakeHistory = try container.decode([BakeRecord].self, forKey: .bakeHistory)
            activeBakeRecordID = try container.decodeIfPresent(UUID.self, forKey: .activeBakeRecordID)
            starterProfile = try container.decodeIfPresent(StarterProfile.self, forKey: .starterProfile) ?? StarterProfile()
            currentWorkflowState = try container.decodeIfPresent(RecipeWorkflowState.self, forKey: .currentWorkflowState) ?? .draft
        }
    }

    private struct LegacyPersistedRecipe: Codable {
        var recipeName: String
        var items: [RecipeItem]
        var steps: [JournalStep]
    }

    private static let defaultItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.flour, weight: 500),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.water, weight: 350),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: BakingTerms.salt, weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .butter, name: BakingTerms.butter, weight: 40),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: BakingTerms.yeast, weight: 5),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: BakingTerms.sugar, weight: 35)
    ]

    private static let chiffonItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.lowGlutenFlour, weight: 90),
        RecipeItem(id: UUID(), category: .basic, tag: .egg, name: BakingTerms.egg, weight: 250, waterContentPct: 75, eggCount: 5, eggUnitWeight: 50, eggType: BakingTerms.wholeEgg),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: BakingTerms.granulatedSugar, weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.milk, weight: 60),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: BakingTerms.cornOil, weight: 55)
    ]

    private static let countryBreadItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.highGlutenFlour, weight: 420),
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: BakingTerms.wholeWheatFlour, weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: BakingTerms.water, weight: 380),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: BakingTerms.salt, weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: BakingTerms.yeast, weight: 4),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: BakingTerms.oliveOil, weight: 12)
    ]

    private static let defaultStarterRatio = [
        BakingTerms.levainStarter: "1:1",
        BakingTerms.liquidStarter: "5:1",
        BakingTerms.tangzhongStarter: "5:1",
        BakingTerms.scaldedStarter: "1:1",
        BakingTerms.poolishStarter: "1:1"
    ]

    private static let starterRatioHydration = [
        "1:1": 100.0,
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
            return RecipeItem(id: UUID(), category: category, tag: .other, name: BakingTerms.custom, weight: 20)
        case .basic:
            switch tag ?? .water {
            case .egg:
                return RecipeItem(id: UUID(), category: category, tag: .egg, name: BakingTerms.egg, weight: 50, waterContentPct: 75, eggCount: 1, eggUnitWeight: 50, eggType: BakingTerms.wholeEgg)
            case .salt:
                return RecipeItem(id: UUID(), category: category, tag: .salt, name: BakingTerms.salt, weight: 10)
            case .yeast:
                return RecipeItem(id: UUID(), category: category, tag: .yeast, name: BakingTerms.yeast, weight: 5)
            case .sugar:
                return RecipeItem(id: UUID(), category: category, tag: .sugar, name: BakingTerms.sugar, weight: 35)
            case .butter:
                return RecipeItem(id: UUID(), category: category, tag: .butter, name: BakingTerms.butter, weight: 50)
            default:
                return RecipeItem(id: UUID(), category: category, tag: .water, name: BakingTerms.water, weight: 50)
            }
        }
    }
}
