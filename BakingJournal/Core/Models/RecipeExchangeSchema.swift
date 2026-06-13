import Foundation

enum RecipeExchangeError: LocalizedError {
    case invalidJSON
    case invalidSchema
    case unsupportedVersion(Int)
    case emptyRecipe
    case invalidNumber(String)
    case missingIngredientReference(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return BakingTerms.recipeImportErrorInvalidJSON
        case .invalidSchema:
            return BakingTerms.recipeImportErrorInvalidSchema
        case .unsupportedVersion(let version):
            return BakingTerms.recipeImportErrorUnsupportedVersion(version)
        case .emptyRecipe:
            return BakingTerms.recipeImportErrorEmptyRecipe
        case .invalidNumber(let field):
            return BakingTerms.recipeImportErrorInvalidNumber(field)
        case .missingIngredientReference(let ingredientId):
            return BakingTerms.recipeImportErrorMissingIngredientReference(ingredientId)
        }
    }
}

struct RecipeExchangeDocumentV1: Codable, Equatable {
    static let schemaName = "bready.recipe"
    static let currentVersion = 1

    var schema: String
    var schemaVersion: Int
    var recipe: RecipeExchangeRecipeV1

    private enum CodingKeys: String, CodingKey {
        case schema
        case schemaVersion
        case recipe
    }

    init(recipe: RecipeExchangeRecipeV1) {
        self.schema = Self.schemaName
        self.schemaVersion = Self.currentVersion
        self.recipe = recipe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schema = try container.decode(String.self, forKey: .schema)
        schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        recipe = try container.decode(RecipeExchangeRecipeV1.self, forKey: .recipe)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schema, forKey: .schema)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(recipe, forKey: .recipe)
    }

    static func decode(from data: Data) throws -> RecipeExchangeDocumentV1 {
        let decoder = JSONDecoder()
        let normalizedData = data.removingUTF8ByteOrderMark()
        let envelope = try decoder.decode(RecipeExchangeEnvelope.self, from: normalizedData)
        guard envelope.schema == schemaName else {
            throw RecipeExchangeError.invalidSchema
        }
        guard envelope.schemaVersion == currentVersion else {
            throw RecipeExchangeError.unsupportedVersion(envelope.schemaVersion)
        }
        return try decoder.decode(RecipeExchangeDocumentV1.self, from: normalizedData)
    }

    static func data(fromJSONString text: String) throws -> Data {
        let trimmed = extractJSON(from: text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8), !data.isEmpty else {
            throw RecipeExchangeError.invalidJSON
        }
        return data
    }

    static func document(
        name: String,
        kind: RecipeKind,
        overallNotes: String,
        items: [RecipeItem],
        steps: [JournalStep]
    ) -> RecipeExchangeDocumentV1 {
        let ingredients = items.map(RecipeExchangeIngredientV1.init(item:))
        let exchangeSteps = steps.map { step in
            RecipeExchangeStepV1(step: step, items: items)
        }
        return RecipeExchangeDocumentV1(
            recipe: RecipeExchangeRecipeV1(
                name: name,
                kind: kind.rawValue,
                overallNotes: overallNotes.isEmpty ? nil : overallNotes,
                ingredients: ingredients,
                steps: exchangeSteps
            )
        )
    }

    @MainActor
    func makeSavedRecipe(now: Date = Date()) throws -> SavedRecipe {
        try validateEnvelope()
        let ingredients = try recipe.validatedIngredients()
        let itemsByExchangeID = Dictionary(uniqueKeysWithValues: ingredients.map { ingredient -> (String, RecipeItem) in
            let item = ingredient.makeRecipeItem()
            return (ingredient.ingredientId, item)
        })
        let orderedItems = ingredients.compactMap { itemsByExchangeID[$0.ingredientId] }
        let importedSteps = try recipe.steps.map { step in
            try step.makeJournalStep(itemsByExchangeID: itemsByExchangeID)
        }

        guard !orderedItems.isEmpty, !importedSteps.isEmpty else {
            throw RecipeExchangeError.emptyRecipe
        }

        let kind = RecipeKind(rawValue: recipe.kind ?? "") ?? RecipeKind.inferred(name: recipe.name, items: orderedItems)
        let customSteps = RecipeStore.stepsForRecipeExchangeImport(importedSteps, kind: kind)
        let simpleStep = RecipeStore.simpleStepForRecipeExchangeImport(steps: customSteps, items: orderedItems)
        return SavedRecipe(
            id: UUID(),
            name: recipe.normalizedName,
            kind: kind,
            overallNotes: recipe.overallNotes ?? "",
            stepText: "",
            items: orderedItems,
            steps: customSteps,
            stepsMode: .custom,
            simpleStep: simpleStep,
            customSteps: customSteps,
            formulaIngredientLockMode: .weight,
            workflowState: .draft,
            createdAt: now,
            updatedAt: now
        )
    }

    private func validateEnvelope() throws {
        guard schema == Self.schemaName else {
            throw RecipeExchangeError.invalidSchema
        }
        guard schemaVersion == Self.currentVersion else {
            throw RecipeExchangeError.unsupportedVersion(schemaVersion)
        }
    }

    private static func extractJSON(from text: String) -> String {
        let pattern = #"(?s)```(?:json)?\s*(.*?)\s*```"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return text
        }
        return String(text[range])
    }

    private struct RecipeExchangeEnvelope: Decodable {
        let schema: String
        let schemaVersion: Int
    }
}

struct RecipeExchangeRecipeV1: Codable, Equatable {
    var name: String
    var kind: String?
    var overallNotes: String?
    var ingredients: [RecipeExchangeIngredientV1]
    var steps: [RecipeExchangeStepV1]

    var normalizedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.defaultRecipeName : trimmed
    }

    func validatedIngredients() throws -> [RecipeExchangeIngredientV1] {
        guard !ingredients.isEmpty, !steps.isEmpty else {
            throw RecipeExchangeError.emptyRecipe
        }
        var seenIDs = Set<String>()
        return try ingredients.map { ingredient in
            let normalized = try ingredient.validated()
            guard !seenIDs.contains(normalized.ingredientId) else {
                throw RecipeExchangeError.invalidSchema
            }
            seenIDs.insert(normalized.ingredientId)
            return normalized
        }
    }
}

struct RecipeExchangeIngredientV1: Codable, Equatable {
    var ingredientId: String
    var name: String
    var category: String
    var tag: String
    var weightGrams: Double
    var hydrationPct: Double?
    var starterEggCount: Double?
    var starterEggUnitWeight: Double?
    var starterFlour: Double?
    var starterRatio: String?
    var starterWater: Double?
    var starterYeastWeight: Double?
    var starterEditMode: String?
    var waterContentPct: Double?
    var eggCount: Double?
    var eggUnitWeight: Double?
    var eggType: String?
    var starterType: String?
    var yeastType: String?

    init(
        ingredientId: String,
        name: String,
        category: String,
        tag: String,
        weightGrams: Double,
        hydrationPct: Double? = nil,
        starterEggCount: Double? = nil,
        starterEggUnitWeight: Double? = nil,
        starterFlour: Double? = nil,
        starterRatio: String? = nil,
        starterWater: Double? = nil,
        starterYeastWeight: Double? = nil,
        starterEditMode: String? = nil,
        waterContentPct: Double? = nil,
        eggCount: Double? = nil,
        eggUnitWeight: Double? = nil,
        eggType: String? = nil,
        starterType: String? = nil,
        yeastType: String? = nil
    ) {
        self.ingredientId = ingredientId
        self.name = name
        self.category = category
        self.tag = tag
        self.weightGrams = weightGrams
        self.hydrationPct = hydrationPct
        self.starterEggCount = starterEggCount
        self.starterEggUnitWeight = starterEggUnitWeight
        self.starterFlour = starterFlour
        self.starterRatio = starterRatio
        self.starterWater = starterWater
        self.starterYeastWeight = starterYeastWeight
        self.starterEditMode = starterEditMode
        self.waterContentPct = waterContentPct
        self.eggCount = eggCount
        self.eggUnitWeight = eggUnitWeight
        self.eggType = eggType
        self.starterType = starterType
        self.yeastType = yeastType
    }

    init(item: RecipeItem) {
        self.init(
            ingredientId: item.id.uuidString,
            name: RecipeExchangeLocalization.exportIngredientName(for: item),
            category: item.category.rawValue,
            tag: item.tag.rawValue,
            weightGrams: item.weight,
            hydrationPct: item.hydrationPct,
            starterEggCount: item.starterEggCount,
            starterEggUnitWeight: item.starterEggUnitWeight,
            starterFlour: item.starterFlour,
            starterRatio: item.starterRatio,
            starterWater: item.starterWater,
            starterYeastWeight: item.starterYeastWeight,
            starterEditMode: item.starterEditMode?.rawValue,
            waterContentPct: item.waterContentPct,
            eggCount: item.eggCount,
            eggUnitWeight: item.eggUnitWeight,
            eggType: RecipeExchangeLocalization.exportEggType(item.eggType),
            starterType: RecipeExchangeLocalization.exportStarterType(item.starterType),
            yeastType: RecipeExchangeLocalization.exportYeastType(item.yeastType)
        )
    }

    func validated() throws -> RecipeExchangeIngredientV1 {
        var next = self
        next.ingredientId = ingredientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !next.ingredientId.isEmpty else {
            throw RecipeExchangeError.invalidSchema
        }
        try Self.validateNumber(weightGrams, field: "ingredient.weightGrams")
        try Self.validateOptionalNumber(hydrationPct, field: "ingredient.hydrationPct")
        try Self.validateOptionalNumber(starterEggCount, field: "ingredient.starterEggCount")
        try Self.validateOptionalNumber(starterEggUnitWeight, field: "ingredient.starterEggUnitWeight")
        try Self.validateOptionalNumber(starterFlour, field: "ingredient.starterFlour")
        try Self.validateOptionalNumber(starterWater, field: "ingredient.starterWater")
        try Self.validateOptionalNumber(starterYeastWeight, field: "ingredient.starterYeastWeight")
        try Self.validateOptionalNumber(waterContentPct, field: "ingredient.waterContentPct")
        try Self.validateOptionalNumber(eggCount, field: "ingredient.eggCount")
        try Self.validateOptionalNumber(eggUnitWeight, field: "ingredient.eggUnitWeight")
        return next
    }

    func makeRecipeItem() -> RecipeItem {
        let itemTag = ItemTag(rawValue: tag) ?? .other
        let itemCategory = ItemCategory(rawValue: category) ?? defaultCategory(for: itemTag)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedName = RecipeExchangeLocalization.importIngredientName(
            trimmedName,
            category: itemCategory,
            tag: itemTag
        )
        let normalizedEggType = RecipeExchangeLocalization.importEggType(eggType)
        let normalizedStarterType = RecipeExchangeLocalization.importStarterType(starterType)
        let normalizedYeastType = RecipeExchangeLocalization.importYeastType(yeastType)
        return RecipeItem(
            id: UUID(),
            category: itemCategory,
            tag: itemTag,
            name: normalizedName.isEmpty ? itemTag.label : normalizedName,
            weight: max(0, weightGrams),
            hydrationPct: hydrationPct,
            starterEggCount: starterEggCount,
            starterEggUnitWeight: starterEggUnitWeight,
            starterFlour: starterFlour,
            starterRatio: starterRatio,
            starterWater: starterWater,
            starterYeastWeight: starterYeastWeight,
            starterEditMode: StarterEditMode(rawValue: starterEditMode ?? ""),
            waterContentPct: waterContentPct,
            eggCount: eggCount,
            eggUnitWeight: eggUnitWeight,
            eggType: normalizedEggType,
            starterType: normalizedStarterType,
            yeastType: normalizedYeastType
        )
    }

    private func defaultCategory(for tag: ItemTag) -> ItemCategory {
        switch tag {
        case .flour:
            return .flour
        case .starter:
            return .starter
        case .other:
            return .other
        default:
            return .basic
        }
    }

    fileprivate static func validateNumber(_ value: Double, field: String) throws {
        guard value.isFinite, value >= 0 else {
            throw RecipeExchangeError.invalidNumber(field)
        }
    }

    fileprivate static func validateOptionalNumber(_ value: Double?, field: String) throws {
        guard let value else { return }
        try validateNumber(value, field: field)
    }
}

struct RecipeExchangeStepV1: Codable, Equatable {
    var name: String
    var type: String
    var notes: String?
    var duration: RecipeExchangeDurationV1?
    var temperature: RecipeExchangeTemperatureV1?
    var productionMethod: String?
    var shapingPieceCount: Double?
    var foldPlan: RecipeExchangeFoldPlanV1?
    var materialAllocations: [RecipeExchangeMaterialAllocationV1]?

    init(
        name: String,
        type: String,
        notes: String? = nil,
        duration: RecipeExchangeDurationV1? = nil,
        temperature: RecipeExchangeTemperatureV1? = nil,
        productionMethod: String? = nil,
        shapingPieceCount: Double? = nil,
        foldPlan: RecipeExchangeFoldPlanV1? = nil,
        materialAllocations: [RecipeExchangeMaterialAllocationV1]? = nil
    ) {
        self.name = name
        self.type = type
        self.notes = notes
        self.duration = duration
        self.temperature = temperature
        self.productionMethod = productionMethod
        self.shapingPieceCount = shapingPieceCount
        self.foldPlan = foldPlan
        self.materialAllocations = materialAllocations
    }

    init(step: JournalStep, items: [RecipeItem]) {
        let allocations = step.materialAllocations.compactMap { allocation -> RecipeExchangeMaterialAllocationV1? in
            guard items.contains(where: { $0.id == allocation.itemId }) else { return nil }
            return RecipeExchangeMaterialAllocationV1(
                ingredientId: allocation.itemId.uuidString,
                percentage: allocation.percentage
            )
        }
        self.init(
            name: step.name,
            type: step.type.rawValue,
            notes: step.notes.isEmpty ? nil : step.notes,
            duration: RecipeExchangeDurationV1(value: step.timeValue, unit: step.timeUnit),
            temperature: RecipeExchangeTemperatureV1(value: step.temperature, unit: step.temperatureUnit),
            productionMethod: step.productionMethod?.rawValue,
            shapingPieceCount: step.shapingPieceCount,
            foldPlan: step.foldPlan.map(RecipeExchangeFoldPlanV1.init(foldPlan:)),
            materialAllocations: allocations.isEmpty ? nil : allocations
        )
    }

    func makeJournalStep(itemsByExchangeID: [String: RecipeItem]) throws -> JournalStep {
        try validate()
        let allocations = try (materialAllocations ?? []).map { allocation -> StepMaterialAllocation in
            guard let item = itemsByExchangeID[allocation.ingredientId] else {
                throw RecipeExchangeError.missingIngredientReference(allocation.ingredientId)
            }
            return StepMaterialAllocation(
                id: UUID(),
                itemId: item.id,
                percentage: min(max(0, allocation.percentage), 100)
            )
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return JournalStep(
            id: UUID(),
            type: StepType(rawValue: type) ?? .other,
            name: trimmedName.isEmpty ? BakingTerms.customStepName : trimmedName,
            notes: notes ?? "",
            materialAllocations: allocations,
            timeValue: duration?.value,
            timeUnit: TimeUnit(rawValue: duration?.unit ?? ""),
            temperature: temperature?.value,
            temperatureUnit: TemperatureUnit(rawValue: temperature?.unit ?? ""),
            productionMethod: ProductionMethod(rawValue: productionMethod ?? ""),
            shapingPieceCount: shapingPieceCount,
            foldPlan: foldPlan.map { StepFoldPlan(targetCount: $0.targetCount, intervalMinutes: $0.intervalMinutes) }
        )
    }

    private func validate() throws {
        try duration?.validate()
        try temperature?.validate()
        try RecipeExchangeIngredientV1.validateOptionalNumber(shapingPieceCount, field: "step.shapingPieceCount")
        try foldPlan?.validate()
        try (materialAllocations ?? []).forEach { try $0.validate() }
    }
}

struct RecipeExchangeDurationV1: Codable, Equatable {
    var value: Double
    var unit: String

    init?(value: Double?, unit: TimeUnit?) {
        guard let value else { return nil }
        self.value = value
        self.unit = unit?.rawValue ?? TimeUnit.min.rawValue
    }

    init(value: Double, unit: String) {
        self.value = value
        self.unit = unit
    }

    func validate() throws {
        try RecipeExchangeIngredientV1.validateNumber(value, field: "step.duration.value")
    }
}

struct RecipeExchangeTemperatureV1: Codable, Equatable {
    var value: Double
    var unit: String

    init?(value: Double?, unit: TemperatureUnit?) {
        guard let value else { return nil }
        self.value = value
        self.unit = unit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue
    }

    init(value: Double, unit: String) {
        self.value = value
        self.unit = unit
    }

    func validate() throws {
        try RecipeExchangeIngredientV1.validateNumber(value, field: "step.temperature.value")
    }
}

struct RecipeExchangeFoldPlanV1: Codable, Equatable {
    var targetCount: Int
    var intervalMinutes: Int

    init(foldPlan: StepFoldPlan) {
        targetCount = foldPlan.targetCount
        intervalMinutes = foldPlan.intervalMinutes
    }

    init(targetCount: Int, intervalMinutes: Int) {
        self.targetCount = targetCount
        self.intervalMinutes = intervalMinutes
    }

    func validate() throws {
        guard targetCount > 0 else {
            throw RecipeExchangeError.invalidNumber("step.foldPlan.targetCount")
        }
        guard intervalMinutes > 0 else {
            throw RecipeExchangeError.invalidNumber("step.foldPlan.intervalMinutes")
        }
    }
}

struct RecipeExchangeMaterialAllocationV1: Codable, Equatable {
    var ingredientId: String
    var percentage: Double

    func validate() throws {
        let normalizedID = ingredientId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedID.isEmpty else {
            throw RecipeExchangeError.invalidSchema
        }
        guard percentage.isFinite, percentage >= 0, percentage <= 100 else {
            throw RecipeExchangeError.invalidNumber("step.materialAllocations.percentage")
        }
    }
}

private enum RecipeExchangeLocalization {
    private struct Term {
        let aliases: [String]
        let localizedValue: () -> String
        let canonicalValue: String

        init(_ aliases: [String], canonicalValue: String? = nil, localizedValue: @escaping () -> String) {
            self.aliases = aliases
            self.localizedValue = localizedValue
            self.canonicalValue = canonicalValue ?? aliases[0]
        }

        func matches(_ value: String) -> Bool {
            let normalizedValue = Self.normalize(value)
            return aliases.contains { Self.normalize($0) == normalizedValue }
        }

        private static func normalize(_ value: String) -> String {
            value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        }
    }

    private static let ingredientTerms: [Term] = [
        Term(["Flour", "面粉"], localizedValue: { BakingTerms.flour }),
        Term(["Bread Flour", "High Gluten Flour", "高粉", "高筋面粉"], localizedValue: { BakingTerms.highGlutenFlour }),
        Term(["Cake Flour", "Low Gluten Flour", "低粉", "低筋面粉"], localizedValue: { BakingTerms.lowGlutenFlour }),
        Term(["Whole Wheat Flour", "全麦粉", "全麦面粉"], localizedValue: { BakingTerms.wholeWheatFlour }),
        Term(["Water", "水"], localizedValue: { BakingTerms.water }),
        Term(["Salt", "盐"], localizedValue: { BakingTerms.salt }),
        Term(["Sugar", "糖"], localizedValue: { BakingTerms.sugar }),
        Term(["Granulated Sugar", "细砂糖"], localizedValue: { BakingTerms.granulatedSugar }),
        Term(["Butter", "黄油"], localizedValue: { BakingTerms.butter }),
        Term(["Cream", "奶油"], localizedValue: { BakingTerms.cream }),
        Term(["Yeast", "酵母"], localizedValue: { BakingTerms.yeast }),
        Term(["Egg", "Whole Egg", "鸡蛋"], localizedValue: { BakingTerms.egg }),
        Term(["Milk", "牛奶"], localizedValue: { BakingTerms.milk }),
        Term(["Corn Oil", "玉米油"], localizedValue: { BakingTerms.cornOil }),
        Term(["Olive Oil", "橄榄油"], localizedValue: { BakingTerms.oliveOil }),
        Term(["Other", "其他"], localizedValue: { BakingTerms.custom })
    ]

    private static let starterTerms: [Term] = [
        Term(["Levain", "鲁邦种"], canonicalValue: BakingTerms.levainStarter, localizedValue: { BakingTerms.starterDisplayName(BakingTerms.levainStarter) }),
        Term(["Liquid Starter", "液种"], canonicalValue: BakingTerms.liquidStarter, localizedValue: { BakingTerms.starterDisplayName(BakingTerms.liquidStarter) }),
        Term(["Tangzhong", "汤种"], canonicalValue: BakingTerms.tangzhongStarter, localizedValue: { BakingTerms.starterDisplayName(BakingTerms.tangzhongStarter) }),
        Term(["Scalded Dough", "烫种"], canonicalValue: BakingTerms.scaldedStarter, localizedValue: { BakingTerms.starterDisplayName(BakingTerms.scaldedStarter) }),
        Term(["Poolish", "波兰种"], canonicalValue: BakingTerms.poolishStarter, localizedValue: { BakingTerms.starterDisplayName(BakingTerms.poolishStarter) })
    ]

    private static let yeastTerms: [Term] = [
        Term(["Dry Yeast", "干酵母"], canonicalValue: BakingTerms.dryYeast, localizedValue: { BakingTerms.yeastDisplayName(BakingTerms.dryYeast) }),
        Term(["Fresh Yeast", "鲜酵母"], canonicalValue: BakingTerms.freshYeast, localizedValue: { BakingTerms.yeastDisplayName(BakingTerms.freshYeast) }),
        Term(["Yeast Water", "酵液"], canonicalValue: BakingTerms.liquidYeast, localizedValue: { BakingTerms.yeastDisplayName(BakingTerms.liquidYeast) })
    ]

    private static let eggTerms: [Term] = [
        Term(["Whole Egg", "Egg", "鸡蛋"], canonicalValue: BakingTerms.wholeEgg, localizedValue: { BakingTerms.eggDisplayName(BakingTerms.wholeEgg) }),
        Term(["Beaten Egg", "全蛋液"], canonicalValue: BakingTerms.beatenEgg, localizedValue: { BakingTerms.eggDisplayName(BakingTerms.beatenEgg) }),
        Term(["Yolk", "Egg Yolk", "蛋黄"], canonicalValue: BakingTerms.yolk, localizedValue: { BakingTerms.eggDisplayName(BakingTerms.yolk) }),
        Term(["White", "Egg White", "蛋白"], canonicalValue: BakingTerms.white, localizedValue: { BakingTerms.eggDisplayName(BakingTerms.white) })
    ]

    static func exportIngredientName(for item: RecipeItem) -> String {
        importIngredientName(item.name, category: item.category, tag: item.tag)
    }

    static func importIngredientName(_ name: String, category: ItemCategory, tag: ItemTag) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let term = ingredientTerms.first(where: { $0.matches(trimmedName) }) {
            return term.localizedValue()
        }
        if category == .starter,
           let term = starterTerms.first(where: { $0.matches(trimmedName) }) {
            return term.localizedValue()
        }
        if tag == .yeast,
           let term = yeastTerms.first(where: { $0.matches(trimmedName) }) {
            return term.localizedValue()
        }
        if tag == .egg,
           let term = eggTerms.first(where: { $0.matches(trimmedName) }) {
            return term.localizedValue()
        }
        return trimmedName
    }

    static func exportEggType(_ value: String?) -> String? {
        value.flatMap { localizedValue($0, in: eggTerms) }
    }

    static func exportStarterType(_ value: String?) -> String? {
        value.flatMap { localizedValue($0, in: starterTerms) }
    }

    static func exportYeastType(_ value: String?) -> String? {
        value.flatMap { localizedValue($0, in: yeastTerms) }
    }

    static func importEggType(_ value: String?) -> String? {
        value.flatMap { canonicalValue($0, in: eggTerms) }
    }

    static func importStarterType(_ value: String?) -> String? {
        value.flatMap { canonicalValue($0, in: starterTerms) }
    }

    static func importYeastType(_ value: String?) -> String? {
        value.flatMap { canonicalValue($0, in: yeastTerms) }
    }

    private static func localizedValue(_ value: String, in terms: [Term]) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return terms.first { $0.matches(trimmedValue) }?.localizedValue() ?? trimmedValue
    }

    private static func canonicalValue(_ value: String, in terms: [Term]) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return terms.first { $0.matches(trimmedValue) }?.canonicalValue ?? trimmedValue
    }
}

extension Data {
    static let utf8ByteOrderMark = Data([0xEF, 0xBB, 0xBF])

    func addingUTF8ByteOrderMark() -> Data {
        guard !starts(with: Self.utf8ByteOrderMark) else { return self }
        var data = Self.utf8ByteOrderMark
        data.append(self)
        return data
    }

    func removingUTF8ByteOrderMark() -> Data {
        guard starts(with: Self.utf8ByteOrderMark) else { return self }
        return Data(dropFirst(Self.utf8ByteOrderMark.count))
    }
}
