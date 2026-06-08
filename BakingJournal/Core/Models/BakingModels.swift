import Foundation

enum StepType: String, Codable, CaseIterable, Identifiable {
    case prep
    case mixing
    case fermentation
    case rest
    case shaping
    case baking
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .prep: L10n.tr("step_type.prep", default: "准备")
        case .mixing: L10n.tr("step_type.mixing", default: "打面")
        case .fermentation: L10n.tr("step_type.fermentation", default: "发酵")
        case .rest: L10n.tr("step_type.rest", default: "松弛")
        case .shaping: L10n.tr("step_type.shaping", default: "整形")
        case .baking: L10n.tr("step_type.baking", default: "制作")
        case .other: L10n.tr("step_type.other", default: "其他")
        }
    }

    var symbol: String {
        switch self {
        case .prep: "tray"
        case .mixing: "fork.knife"
        case .fermentation: "thermometer.medium"
        case .rest: "pause.circle"
        case .shaping: "hand.draw"
        case .baking: "oven"
        case .other: "ellipsis"
        }
    }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case flour
    case starter
    case basic
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flour: L10n.tr("item_category.flour", default: "面粉")
        case .starter: L10n.tr("item_category.starter", default: "种面")
        case .basic: L10n.tr("item_category.basic", default: "材料")
        case .other: L10n.tr("item_category.other", default: "其他")
        }
    }
}

enum ItemTag: String, Codable, CaseIterable, Identifiable {
    case flour
    case starter
    case water
    case salt
    case sugar
    case butter
    case yeast
    case egg
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flour: L10n.tr("item_tag.flour", default: "面粉")
        case .starter: L10n.tr("item_tag.starter", default: "种面")
        case .water: L10n.tr("item_tag.water", default: "水")
        case .salt: L10n.tr("item_tag.salt", default: "盐")
        case .sugar: L10n.tr("item_tag.sugar", default: "糖")
        case .butter: L10n.tr("item_tag.butter", default: "黄油")
        case .yeast: L10n.tr("item_tag.yeast", default: "酵母")
        case .egg: L10n.tr("item_tag.egg", default: "鸡蛋")
        case .other: L10n.tr("item_tag.other", default: "其他")
        }
    }
}

enum StarterEditMode: String, Codable, CaseIterable, Identifiable {
    case ratio
    case weight

    var id: String { rawValue }
}

enum TimeUnit: String, Codable, CaseIterable, Identifiable {
    case min
    case hr

    var id: String { rawValue }
    var label: String { rawValue }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case fahrenheit = "F"
    case celsius = "C"

    var id: String { rawValue }
}

enum ProductionMethod: String, Codable, CaseIterable, Identifiable {
    case bake
    case steam

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bake: L10n.tr("production_method.bake", default: "烘烤")
        case .steam: L10n.tr("production_method.steam", default: "蒸")
        }
    }
}

struct RecipeItem: Identifiable, Codable, Equatable {
    var id: UUID
    var category: ItemCategory
    var tag: ItemTag
    var name: String
    var weight: Double
    var hydrationPct: Double?
    var starterEggCount: Double?
    var starterEggUnitWeight: Double?
    var starterFlour: Double?
    var starterRatio: String?
    var starterWater: Double?
    var starterYeastWeight: Double?
    var starterEditMode: StarterEditMode?
    var waterContentPct: Double?
    var eggCount: Double?
    var eggUnitWeight: Double?
    var eggType: String?
    var starterType: String?
    var yeastType: String?
}

struct StepMaterialAllocation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var itemId: UUID
    var percentage: Double
}

struct AllocatedRecipeItem: Identifiable, Equatable {
    var id: UUID { item.id }
    var item: RecipeItem
    var percentage: Double
    var weight: Double
}

struct JournalStep: Identifiable, Codable, Equatable {
    var id: UUID
    var type: StepType
    var name: String
    var notes: String
    var materialAllocations: [StepMaterialAllocation]
    var timeValue: Double?
    var timeUnit: TimeUnit?
    var temperature: Double?
    var temperatureUnit: TemperatureUnit?
    var productionMethod: ProductionMethod? = nil
}

struct RecipeSummary: Equatable {
    var doughWeight: Double
    var flourWeight: Double
    var waterWeight: Double
    var hydration: Double
}

enum RecipeWorkflowState: String, Codable, CaseIterable, Identifiable {
    case draft
    case ready

    var id: String { rawValue }

    var label: String {
        switch self {
        case .draft: L10n.tr("workflow_state.draft", default: "草稿")
        case .ready: L10n.tr("workflow_state.ready", default: "已准备好")
        }
    }
}

enum RecipeKind: String, Codable, CaseIterable, Identifiable {
    case toast
    case chiffon
    case countryBread
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .toast:
            return BakingTerms.recipeKindToast
        case .chiffon:
            return BakingTerms.recipeKindChiffon
        case .countryBread:
            return BakingTerms.recipeKindCountryBread
        case .custom:
            return BakingTerms.recipeKindCustom
        }
    }

    static func inferred(name: String, items: [RecipeItem]) -> RecipeKind {
        let normalizedName = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if normalizedName.localizedCaseInsensitiveContains(BakingTerms.toastTemplateLabel)
            || normalizedName.localizedCaseInsensitiveContains(BakingTerms.toastRecipeName) {
            return .toast
        }
        if normalizedName.localizedCaseInsensitiveContains(BakingTerms.chiffonTemplateLabel)
            || normalizedName.localizedCaseInsensitiveContains(BakingTerms.chiffonRecipeName) {
            return .chiffon
        }
        if normalizedName.localizedCaseInsensitiveContains(BakingTerms.countryBreadTemplateLabel)
            || normalizedName.localizedCaseInsensitiveContains(BakingTerms.countryBreadRecipeName) {
            return .countryBread
        }

        let tags = Set(items.map(\.tag))
        let ingredientNames = items.map(\.name).joined(separator: " ")
        if tags.contains(.egg), ingredientNames.localizedCaseInsensitiveContains(BakingTerms.lowGlutenFlour) {
            return .chiffon
        }
        if ingredientNames.localizedCaseInsensitiveContains(BakingTerms.wholeWheatFlour)
            || ingredientNames.localizedCaseInsensitiveContains(BakingTerms.oliveOil) {
            return .countryBread
        }
        if tags.contains(.butter), tags.contains(.sugar), tags.contains(.yeast) {
            return .toast
        }
        return .custom
    }
}

struct SavedRecipe: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: RecipeKind
    var overallNotes: String
    var stepText: String
    var items: [RecipeItem]
    var steps: [JournalStep]
    var workflowState: RecipeWorkflowState
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        name: String,
        kind: RecipeKind,
        overallNotes: String = "",
        stepText: String = "",
        items: [RecipeItem],
        steps: [JournalStep],
        workflowState: RecipeWorkflowState,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.overallNotes = overallNotes
        self.stepText = stepText
        self.items = items
        self.steps = steps
        self.workflowState = workflowState
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case overallNotes
        case stepText
        case items
        case steps
        case workflowState
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decode([RecipeItem].self, forKey: .items)
        kind = try container.decodeIfPresent(RecipeKind.self, forKey: .kind) ?? RecipeKind.inferred(name: name, items: items)
        overallNotes = try container.decodeIfPresent(String.self, forKey: .overallNotes) ?? ""
        stepText = try container.decodeIfPresent(String.self, forKey: .stepText) ?? ""
        steps = try container.decode([JournalStep].self, forKey: .steps)
        workflowState = try container.decodeIfPresent(RecipeWorkflowState.self, forKey: .workflowState) ?? .draft
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct BakeStepTiming: Identifiable, Codable, Equatable {
    var id: UUID
    var stepID: UUID?
    var stepName: String
    var startedAt: Date
    var completedAt: Date?
}

struct BakeRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var recipeID: UUID?
    var recipeName: String
    var recipeSnapshotName: String
    var startedAt: Date
    var completedAt: Date?
    var notes: String
    var stepCount: Int
    var stepTimings: [BakeStepTiming]

    init(
        id: UUID,
        recipeID: UUID?,
        recipeName: String,
        recipeSnapshotName: String,
        startedAt: Date,
        completedAt: Date?,
        notes: String,
        stepCount: Int,
        stepTimings: [BakeStepTiming] = []
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeName = recipeName
        self.recipeSnapshotName = recipeSnapshotName
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
        self.stepCount = stepCount
        self.stepTimings = stepTimings
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case recipeID
        case recipeName
        case recipeSnapshotName
        case startedAt
        case completedAt
        case notes
        case stepCount
        case stepTimings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipeID = try container.decodeIfPresent(UUID.self, forKey: .recipeID)
        recipeName = try container.decode(String.self, forKey: .recipeName)
        recipeSnapshotName = try container.decodeIfPresent(String.self, forKey: .recipeSnapshotName) ?? recipeName
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        stepCount = try container.decodeIfPresent(Int.self, forKey: .stepCount) ?? 0
        stepTimings = try container.decodeIfPresent([BakeStepTiming].self, forKey: .stepTimings) ?? []
    }
}

struct CookState: Codable, Equatable {
    var checked: [UUID: Set<UUID>] = [:]
    var completedStepIDs: Set<UUID> = []
    var completedAt: Date?
    var currentIndex: Int = 0
    var stepStartedAt: Date?
    var timerEndsAt: Date?
    var timerStepId: UUID?
    var totalStartedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case checked
        case completedStepIDs
        case completedAt
        case currentIndex
        case stepStartedAt
        case timerEndsAt
        case timerStepId
        case totalStartedAt
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        checked = try container.decodeIfPresent([UUID: Set<UUID>].self, forKey: .checked) ?? [:]
        completedStepIDs = try container.decodeIfPresent(Set<UUID>.self, forKey: .completedStepIDs) ?? []
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        currentIndex = try container.decodeIfPresent(Int.self, forKey: .currentIndex) ?? 0
        stepStartedAt = try container.decodeIfPresent(Date.self, forKey: .stepStartedAt)
        timerEndsAt = try container.decodeIfPresent(Date.self, forKey: .timerEndsAt)
        timerStepId = try container.decodeIfPresent(UUID.self, forKey: .timerStepId)
        totalStartedAt = try container.decodeIfPresent(Date.self, forKey: .totalStartedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(checked, forKey: .checked)
        try container.encode(completedStepIDs, forKey: .completedStepIDs)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(currentIndex, forKey: .currentIndex)
        try container.encodeIfPresent(stepStartedAt, forKey: .stepStartedAt)
        try container.encodeIfPresent(timerEndsAt, forKey: .timerEndsAt)
        try container.encodeIfPresent(timerStepId, forKey: .timerStepId)
        try container.encodeIfPresent(totalStartedAt, forKey: .totalStartedAt)
    }
}

enum StarterFeedingRatio: String, Codable, CaseIterable, Identifiable {
    case oneToOneToOne = "1:1:1"
    case oneToTwoToTwo = "1:2:2"
    case oneToThreeToThree = "1:3:3"
    case oneToFourToFour = "1:4:4"

    var id: String { rawValue }
    var label: String { rawValue }

    var feedMultiplier: Double {
        switch self {
        case .oneToOneToOne: 1
        case .oneToTwoToTwo: 2
        case .oneToThreeToThree: 3
        case .oneToFourToFour: 4
        }
    }
}

struct StarterProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isContainerWeightEnabled: Bool
    var containerWeight: Double
    var measuredWeight: Double
    var lastFedAt: Date
    var feedingRatio: StarterFeedingRatio
    var feedFlourWeight: Double
    var feedWaterWeight: Double
    var isReminderEnabled: Bool
    var nextFeedingDate: Date

    init(
        id: UUID = UUID(),
        name: String = BakingTerms.starterProfileDefaultName,
        isContainerWeightEnabled: Bool = false,
        containerWeight: Double = 0,
        measuredWeight: Double = 100,
        lastFedAt: Date = Date(),
        feedingRatio: StarterFeedingRatio = .oneToOneToOne,
        feedFlourWeight: Double? = nil,
        feedWaterWeight: Double? = nil,
        isReminderEnabled: Bool = false,
        nextFeedingDate: Date = Date()
    ) {
        let starterWeight = max(0, measuredWeight - containerWeight)
        let defaultFeedWeight = starterWeight * feedingRatio.feedMultiplier
        self.id = id
        self.name = name
        self.isContainerWeightEnabled = isContainerWeightEnabled
        self.containerWeight = containerWeight
        self.measuredWeight = measuredWeight
        self.lastFedAt = lastFedAt
        self.feedingRatio = feedingRatio
        self.feedFlourWeight = max(0, feedFlourWeight ?? defaultFeedWeight)
        self.feedWaterWeight = max(0, feedWaterWeight ?? defaultFeedWeight)
        self.isReminderEnabled = isReminderEnabled
        self.nextFeedingDate = nextFeedingDate
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isContainerWeightEnabled
        case containerWeight
        case measuredWeight
        case lastFedAt
        case feedingRatio
        case feedFlourWeight
        case feedWaterWeight
        case isReminderEnabled
        case nextFeedingDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        isContainerWeightEnabled = try container.decode(Bool.self, forKey: .isContainerWeightEnabled)
        containerWeight = try container.decode(Double.self, forKey: .containerWeight)
        measuredWeight = try container.decode(Double.self, forKey: .measuredWeight)
        lastFedAt = try container.decode(Date.self, forKey: .lastFedAt)
        feedingRatio = try container.decode(StarterFeedingRatio.self, forKey: .feedingRatio)
        let defaultFeedWeight = max(0, measuredWeight - containerWeight) * feedingRatio.feedMultiplier
        feedFlourWeight = try container.decodeIfPresent(Double.self, forKey: .feedFlourWeight) ?? defaultFeedWeight
        feedWaterWeight = try container.decodeIfPresent(Double.self, forKey: .feedWaterWeight) ?? defaultFeedWeight
        isReminderEnabled = try container.decode(Bool.self, forKey: .isReminderEnabled)
        nextFeedingDate = try container.decode(Date.self, forKey: .nextFeedingDate)
    }
}
