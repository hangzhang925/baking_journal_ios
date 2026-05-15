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
            case .toast: "吐司"
            case .chiffon: "戚风蛋糕"
            case .countryBread: "欧包"
            }
        }
    }

    @Published var recipeName: String = "吐司配方" { didSet { persist() } }
    @Published var items: [RecipeItem] = [] { didSet { persist() } }
    @Published var steps: [JournalStep] = [] { didSet { persist() } }
    @Published var cookState = CookState() { didSet { persist() } }
    @Published var currentRecipeID: UUID? { didSet { persist() } }
    @Published var savedRecipes: [SavedRecipe] = [] { didSet { persist() } }
    @Published var bakeHistory: [BakeRecord] = [] { didSet { persist() } }
    @Published var activeBakeRecordID: UUID? { didSet { persist() } }

    static let starterOptions = ["鲁邦种", "液种", "汤种", "烫种", "波兰种"]
    static let starterRatioOptions = ["1:1", "2:1", "5:1"]
    static let yeastOptions = ["干酵母", "鲜酵母", "酵液"]
    static let eggOptions = ["鸡蛋", "全蛋液", "蛋黄", "蛋白"]

    private let storageKey = "baking-journal-ios:state"
    private var isLoading = false

    init() {
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
        return trimmed.isEmpty ? "未命名配方" : trimmed
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

    func addItem(category: ItemCategory, tag: ItemTag? = nil) {
        items.append(Self.makeItem(category: category, tag: tag))
    }

    func createNewRecipe() {
        isLoading = true
        recipeName = "吐司配方"
        items = Self.defaultItems
        steps = []
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        isLoading = false
        persist()
    }

    func applyTemplate(_ template: RecipeTemplate) {
        isLoading = true
        switch template {
        case .toast:
            recipeName = "吐司配方"
            items = Self.defaultItems
            steps = []
        case .chiffon:
            recipeName = "戚风蛋糕"
            items = Self.chiffonItems
            steps = []
        case .countryBread:
            recipeName = "欧包配方"
            items = Self.countryBreadItems
            steps = []
        }
        cookState = CookState()
        currentRecipeID = nil
        activeBakeRecordID = nil
        isLoading = false
        persist()
    }

    func saveCurrentRecipe() {
        let now = Date()
        if let currentRecipeID, let index = savedRecipes.firstIndex(where: { $0.id == currentRecipeID }) {
            savedRecipes[index].name = currentRecipeDisplayName
            savedRecipes[index].items = items
            savedRecipes[index].steps = steps
            savedRecipes[index].updatedAt = now
        } else {
            let recipe = SavedRecipe(
                id: UUID(),
                name: currentRecipeDisplayName,
                items: items,
                steps: steps,
                createdAt: now,
                updatedAt: now
            )
            currentRecipeID = recipe.id
            savedRecipes.insert(recipe, at: 0)
        }
    }

    func loadRecipe(_ recipe: SavedRecipe) {
        isLoading = true
        recipeName = recipe.name
        items = recipe.items
        steps = recipe.steps
        cookState = CookState()
        currentRecipeID = recipe.id
        activeBakeRecordID = nil
        isLoading = false
        persist()
    }

    func deleteRecipe(_ recipe: SavedRecipe) {
        savedRecipes.removeAll { $0.id == recipe.id }
        if currentRecipeID == recipe.id {
            currentRecipeID = nil
        }
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
            next.itemIds.removeAll { $0 == item.id }
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
        let otherWeight = max(0, summary.doughWeight - item.weight)

        let nextWeight: Double
        if clampedPercent >= 100 {
            nextWeight = otherWeight * 100
        } else {
            nextWeight = otherWeight * clampedPercent / max(0.0001, (100 - clampedPercent))
        }

        updateItemWeight(item, weight: nextWeight)
    }

    func applyStarterType(_ type: String, to item: RecipeItem) {
        guard var next = items.first(where: { $0.id == item.id }) else { return }
        next.starterType = type
        next.name = type
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

    func assign(itemId: UUID, to step: JournalStep) {
        var nextSteps = steps
        for index in nextSteps.indices {
            nextSteps[index].itemIds.removeAll { $0 == itemId }
        }
        guard let stepIndex = nextSteps.firstIndex(where: { $0.id == step.id }) else { return }
        if !nextSteps[stepIndex].itemIds.contains(itemId) {
            nextSteps[stepIndex].itemIds.append(itemId)
        }
        steps = nextSteps
    }

    func assignAllItems(to step: JournalStep) {
        var nextSteps = steps
        for index in nextSteps.indices {
            if nextSteps[index].id == step.id {
                nextSteps[index].itemIds = items.map(\.id)
            } else {
                nextSteps[index].itemIds.removeAll { itemId in
                    items.contains(where: { $0.id == itemId })
                }
            }
        }
        steps = nextSteps
    }

    func removeAssignedItem(_ itemId: UUID, from step: JournalStep) {
        guard var next = steps.first(where: { $0.id == step.id }) else { return }
        next.itemIds.removeAll { $0 == itemId }
        updateStep(next)
    }

    func items(for step: JournalStep) -> [RecipeItem] {
        step.itemIds.compactMap { id in items.first { $0.id == id } }
    }

    func unassignedItems() -> [RecipeItem] {
        let assigned = Set(steps.flatMap(\.itemIds))
        return items.filter { !assigned.contains($0.id) }
    }

    func stepContaining(itemId: UUID) -> JournalStep? {
        steps.first { $0.itemIds.contains(itemId) }
    }

    func stepMinutes(_ step: JournalStep) -> Double {
        let value = step.timeValue ?? 0
        return step.timeUnit == .hr ? value * 60 : value
    }

    func totalStepMinutes() -> Double {
        steps.reduce(0) { $0 + stepMinutes($1) }
    }

    func toggleCookItem(stepId: UUID, itemId: UUID) {
        ensureCookStarted()
        var checked = cookState.checked[stepId] ?? []
        if checked.contains(itemId) {
            checked.remove(itemId)
        } else {
            checked.insert(itemId)
        }
        cookState.checked[stepId] = checked
    }

    func startTimer(for step: JournalStep) {
        ensureCookStarted()
        let now = Date()
        cookState.timerStepId = step.id
        cookState.timerEndsAt = now.addingTimeInterval(stepMinutes(step) * 60)
    }

    func moveCookStep(_ direction: Int) {
        ensureCookStarted()
        let nextIndex = cookState.currentIndex + direction
        guard nextIndex >= 0 else { return }
        if nextIndex >= steps.count {
            cookState.completedAt = Date()
            finalizeBakeRecord()
            return
        }
        cookState.currentIndex = nextIndex
        cookState.stepStartedAt = Date()
        cookState.timerEndsAt = nil
        cookState.timerStepId = nil
    }

    func resetCook() {
        cookState = CookState()
        activeBakeRecordID = nil
    }

    func exportRecipeData() throws -> Data {
        let state = LegacyPersistedRecipe(recipeName: recipeName, items: items, steps: steps)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(state)
    }

    func importRecipeData(_ data: Data) throws {
        let decoded = try JSONDecoder().decode(LegacyPersistedRecipe.self, from: data)
        isLoading = true
        recipeName = decoded.recipeName.isEmpty ? "吐司配方" : decoded.recipeName
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
        if item.yeastType == "酵液" { return item.weight }
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

    private func ensureCookStarted() {
        if cookState.totalStartedAt == nil {
            let now = Date()
            cookState.totalStartedAt = now
            activeBakeRecordID = createBakeRecord(startedAt: now)
        }
        if cookState.stepStartedAt == nil { cookState.stepStartedAt = Date() }
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
            return JournalStep(id: UUID(), type: type, name: "准备工作", notes: nextCount == 1 ? "制作种面，或提前处理需要预混的材料。" : "", itemIds: [])
        case .mixing:
            return JournalStep(id: UUID(), type: type, name: "打面", notes: nextCount == 1 ? "除了盐黄油，混合均匀，打至后膜" : "加入盐，黄油，打到手套膜，温度控制28。", itemIds: [], timeValue: 20, timeUnit: .min)
        case .fermentation:
            return JournalStep(id: UUID(), type: type, name: "发酵（\(nextCount == 1 ? "一发" : "二发")）", notes: "", itemIds: [], timeValue: 60, timeUnit: .min, temperature: 85)
        case .baking:
            return JournalStep(id: UUID(), type: type, name: "烘烤", notes: "", itemIds: [], timeValue: 30, timeUnit: .min, temperature: 350, temperatureUnit: .fahrenheit)
        case .rest:
            return JournalStep(id: UUID(), type: type, name: type.label, notes: "", itemIds: [], timeValue: 20, timeUnit: .min)
        case .shaping:
            return JournalStep(id: UUID(), type: type, name: type.label, notes: "", itemIds: [], timeValue: 15, timeUnit: .min)
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
        defer { isLoading = false }
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            recipeName = "吐司配方"
            items = Self.defaultItems
            steps = []
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
            return
        }

        recipeName = "吐司配方"
        items = Self.defaultItems
        steps = []
        cookState = CookState()
        currentRecipeID = nil
        savedRecipes = []
        bakeHistory = []
        activeBakeRecordID = nil
    }

    private func persist() {
        guard !isLoading else { return }
        let state = PersistedState(
            currentDraft: LegacyPersistedRecipe(recipeName: recipeName, items: items, steps: steps),
            cookState: cookState,
            currentRecipeID: currentRecipeID,
            savedRecipes: savedRecipes,
            bakeHistory: bakeHistory,
            activeBakeRecordID: activeBakeRecordID
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
    }

    private struct LegacyPersistedRecipe: Codable {
        var recipeName: String
        var items: [RecipeItem]
        var steps: [JournalStep]
    }

    private static let defaultItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: "面粉", weight: 500),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: "水", weight: 350),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: "盐", weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .butter, name: "黄油", weight: 40),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: "酵母", weight: 5),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: "糖", weight: 35)
    ]

    private static let chiffonItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: "低粉", weight: 90),
        RecipeItem(id: UUID(), category: .basic, tag: .egg, name: "鸡蛋", weight: 250, waterContentPct: 75, eggCount: 5, eggUnitWeight: 50, eggType: "鸡蛋"),
        RecipeItem(id: UUID(), category: .basic, tag: .sugar, name: "细砂糖", weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: "牛奶", weight: 60),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: "玉米油", weight: 55)
    ]

    private static let countryBreadItems: [RecipeItem] = [
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: "高粉", weight: 420),
        RecipeItem(id: UUID(), category: .flour, tag: .flour, name: "全麦粉", weight: 80),
        RecipeItem(id: UUID(), category: .basic, tag: .water, name: "水", weight: 380),
        RecipeItem(id: UUID(), category: .basic, tag: .salt, name: "盐", weight: 10),
        RecipeItem(id: UUID(), category: .basic, tag: .yeast, name: "酵母", weight: 4),
        RecipeItem(id: UUID(), category: .other, tag: .other, name: "橄榄油", weight: 12)
    ]

    private static let defaultStarterRatio = [
        "鲁邦种": "1:1",
        "液种": "5:1",
        "汤种": "5:1",
        "烫种": "1:1",
        "波兰种": "1:1"
    ]

    private static let starterRatioHydration = [
        "1:1": 100.0,
        "2:1": 200.0,
        "5:1": 500.0
    ]

    private static let starterHydrationPresets = [
        "鲁邦种": 100.0,
        "液种": 500.0,
        "汤种": 500.0,
        "烫种": 100.0,
        "波兰种": 100.0
    ]

    private static func makeItem(category: ItemCategory, tag: ItemTag?) -> RecipeItem {
        switch category {
        case .flour:
            return RecipeItem(id: UUID(), category: category, tag: .flour, name: "面粉", weight: 100)
        case .starter:
            return RecipeItem(id: UUID(), category: category, tag: .starter, name: "鲁邦种", weight: 100, hydrationPct: 100, starterFlour: 50, starterRatio: "1:1", starterWater: 50, starterType: "鲁邦种")
        case .other:
            return RecipeItem(id: UUID(), category: category, tag: .other, name: "自定义", weight: 20)
        case .basic:
            switch tag ?? .water {
            case .egg:
                return RecipeItem(id: UUID(), category: category, tag: .egg, name: "鸡蛋", weight: 50, waterContentPct: 75, eggCount: 1, eggUnitWeight: 50, eggType: "鸡蛋")
            case .salt:
                return RecipeItem(id: UUID(), category: category, tag: .salt, name: "盐", weight: 10)
            case .yeast:
                return RecipeItem(id: UUID(), category: category, tag: .yeast, name: "酵母", weight: 5)
            case .sugar:
                return RecipeItem(id: UUID(), category: category, tag: .sugar, name: "糖", weight: 35)
            case .butter:
                return RecipeItem(id: UUID(), category: category, tag: .butter, name: "黄油", weight: 50)
            default:
                return RecipeItem(id: UUID(), category: category, tag: .water, name: "水", weight: 50)
            }
        }
    }
}
