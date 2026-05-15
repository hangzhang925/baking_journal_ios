import Foundation

enum StepType: String, Codable, CaseIterable, Identifiable {
    case prep
    case mixing
    case fermentation
    case rest
    case shaping
    case baking

    var id: String { rawValue }

    var label: String {
        switch self {
        case .prep: "准备"
        case .mixing: "打面"
        case .fermentation: "发酵"
        case .rest: "松弛"
        case .shaping: "整形"
        case .baking: "烘烤"
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
        case .flour: "面粉"
        case .starter: "种面"
        case .basic: "材料"
        case .other: "其他"
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
        case .flour: "面粉"
        case .starter: "种面"
        case .water: "水"
        case .salt: "盐"
        case .sugar: "糖"
        case .butter: "黄油"
        case .yeast: "酵母"
        case .egg: "鸡蛋"
        case .other: "自定义"
        }
    }
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
    var waterContentPct: Double?
    var eggCount: Double?
    var eggUnitWeight: Double?
    var eggType: String?
    var starterType: String?
    var yeastType: String?
}

struct JournalStep: Identifiable, Codable, Equatable {
    var id: UUID
    var type: StepType
    var name: String
    var notes: String
    var itemIds: [UUID]
    var timeValue: Double?
    var timeUnit: TimeUnit?
    var temperature: Double?
    var temperatureUnit: TemperatureUnit?
}

struct RecipeSummary: Equatable {
    var doughWeight: Double
    var flourWeight: Double
    var waterWeight: Double
    var hydration: Double
}

struct SavedRecipe: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var items: [RecipeItem]
    var steps: [JournalStep]
    var createdAt: Date
    var updatedAt: Date
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
}

struct CookState: Codable, Equatable {
    var checked: [UUID: Set<UUID>] = [:]
    var completedAt: Date?
    var currentIndex: Int = 0
    var stepStartedAt: Date?
    var timerEndsAt: Date?
    var timerStepId: UUID?
    var totalStartedAt: Date?
}
