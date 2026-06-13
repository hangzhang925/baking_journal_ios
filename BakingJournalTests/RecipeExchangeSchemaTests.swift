import XCTest
@testable import BakingJournal

@MainActor
final class RecipeExchangeSchemaTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "baking-journal-ios:state")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "baking-journal-ios:state")
        AppLanguage.english.save()
        super.tearDown()
    }

    func testExportImportRebuildsRecipeWithNewIdentifiers() throws {
        let store = makeStore()
        store.applyTemplate(.countryBread)
        store.setStepsMode(.custom)

        let originalItemIDs = Set(store.items.map(\.id))
        let originalStepIDs = Set(store.steps.map(\.id))
        let data = try store.exportCurrentRecipeExchangeData()
        let document = try RecipeExchangeDocumentV1.decode(from: data)

        XCTAssertEqual(document.schema, RecipeExchangeDocumentV1.schemaName)
        XCTAssertEqual(document.schemaVersion, RecipeExchangeDocumentV1.currentVersion)
        XCTAssertEqual(document.recipe.ingredients.count, store.items.count)
        XCTAssertEqual(document.recipe.steps.count, store.steps.count)

        let imported = try store.importRecipeExchangeData(data)

        XCTAssertEqual(store.currentRecipeID, imported.id)
        XCTAssertEqual(store.savedRecipes.first?.id, imported.id)
        XCTAssertEqual(imported.name, BakingTerms.countryBreadRecipeName)
        XCTAssertEqual(imported.items.count, document.recipe.ingredients.count)
        XCTAssertEqual(imported.steps.count, document.recipe.steps.count)
        XCTAssertTrue(originalItemIDs.isDisjoint(with: Set(imported.items.map(\.id))))
        XCTAssertTrue(originalStepIDs.isDisjoint(with: Set(imported.steps.map(\.id))))
        XCTAssertEqual(imported.stepsMode, .custom)
        XCTAssertEqual(imported.workflowState, .draft)
    }

    func testTemplateRecipeSavesAsReady() {
        let store = makeStore()

        store.applyTemplate(.toast)
        store.saveCurrentRecipe()

        XCTAssertEqual(store.savedRecipes.first?.workflowState, .ready)
        XCTAssertTrue(store.isReadyToBake)
    }

    func testSimpleDraftRecipeCanStartBakeWhenItHasStepContent() throws {
        let store = makeStore()

        store.applyTemplate(.toast)
        store.markDraft()
        store.saveCurrentRecipe()

        let savedRecipe = try XCTUnwrap(store.savedRecipes.first)
        XCTAssertEqual(savedRecipe.workflowState, .draft)
        XCTAssertTrue(store.isReadyToBake(savedRecipe))
        XCTAssertTrue(store.startNewBake())
        XCTAssertNotNil(store.activeBakeRecordID)
    }

    func testImportsStarterEggFoldPlanAndMaterialAllocations() throws {
        let imported = try makeStore().importRecipeExchangeJSONString(Self.richRecipeJSON)

        XCTAssertEqual(imported.name, "AI Country Bread")
        XCTAssertEqual(imported.kind, .countryBread)
        XCTAssertTrue(imported.items.contains { $0.category == .starter && $0.tag == .starter && $0.starterFlour == 50 })
        XCTAssertTrue(imported.items.contains { $0.tag == .egg && $0.eggCount == 1 })

        let foldStep = try XCTUnwrap(imported.steps.first { $0.foldPlan != nil })
        XCTAssertEqual(foldStep.foldPlan?.targetCount, 4)
        XCTAssertEqual(foldStep.foldPlan?.intervalMinutes, 30)
        XCTAssertEqual(foldStep.materialAllocations.count, 2)
        XCTAssertTrue(foldStep.materialAllocations.allSatisfy { allocation in
            imported.items.contains { $0.id == allocation.itemId }
        })
    }

    func testImportsFencedJSONBlock() throws {
        let fenced = """
        ```json
        \(Self.minimalRecipeJSON)
        ```
        """

        let imported = try makeStore().importRecipeExchangeJSONString(fenced)

        XCTAssertEqual(imported.name, "Minimal Bread")
        XCTAssertEqual(imported.items.count, 1)
        XCTAssertEqual(imported.steps.count, 1)
    }

    func testExportWritesUTF8AndLocalizesKnownEnglishIngredientNames() throws {
        AppLanguage.simplifiedChinese.save()
        let store = makeStore()
        store.applyTemplate(.countryBread)
        store.items[0].name = "Bread Flour"

        let data = try store.exportCurrentRecipeExchangeData()
        XCTAssertTrue(data.starts(with: Data.utf8ByteOrderMark))

        let json = try XCTUnwrap(String(data: data.removingUTF8ByteOrderMark(), encoding: .utf8))
        XCTAssertTrue(json.contains("\"name\" : \"高粉\""))
        XCTAssertFalse(json.contains("\"name\" : \"Bread Flour\""))

        let document = try RecipeExchangeDocumentV1.decode(from: data)
        XCTAssertEqual(document.recipe.ingredients.first?.name, "高粉")
    }

    func testImportLocalizesKnownEnglishIngredientNamesForCurrentLanguage() throws {
        AppLanguage.simplifiedChinese.save()

        let imported = try makeStore().importRecipeExchangeJSONString(Self.minimalRecipeJSON)

        XCTAssertEqual(imported.items.first?.name, "高粉")
    }

    func testRejectsUnsupportedVersion() {
        XCTAssertThrowsError(try makeStore().importRecipeExchangeJSONString(Self.minimalRecipeJSON.replacingOccurrences(of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 2"))) { error in
            guard case RecipeExchangeError.unsupportedVersion(2) = error else {
                return XCTFail("Expected unsupportedVersion, got \(error)")
            }
        }
    }

    func testRejectsInvalidJSON() {
        XCTAssertThrowsError(try makeStore().importRecipeExchangeJSONString("not json")) { error in
            guard case RecipeExchangeError.invalidJSON = error else {
                return XCTFail("Expected invalidJSON, got \(error)")
            }
        }
    }

    func testRejectsMissingIngredientReference() {
        let json = Self.minimalRecipeJSON.replacingOccurrences(of: "\"ingredientId\": \"flour-1\", \"percentage\": 100", with: "\"ingredientId\": \"missing\", \"percentage\": 100")

        XCTAssertThrowsError(try makeStore().importRecipeExchangeJSONString(json)) { error in
            guard case RecipeExchangeError.missingIngredientReference("missing") = error else {
                return XCTFail("Expected missingIngredientReference, got \(error)")
            }
        }
    }

    func testRejectsNegativeWeight() {
        let json = Self.minimalRecipeJSON.replacingOccurrences(of: "\"weightGrams\": 500", with: "\"weightGrams\": -1")

        XCTAssertThrowsError(try makeStore().importRecipeExchangeJSONString(json)) { error in
            guard case RecipeExchangeError.invalidNumber("ingredient.weightGrams") = error else {
                return XCTFail("Expected invalidNumber, got \(error)")
            }
        }
    }

    private func makeStore() -> RecipeStore {
        UserDefaults.standard.removeObject(forKey: "baking-journal-ios:state")
        return RecipeStore(notifications: NoopNotifications())
    }

    private static let minimalRecipeJSON = """
    {
      "schema": "bready.recipe",
      "schemaVersion": 1,
      "recipe": {
        "name": "Minimal Bread",
        "kind": "custom",
        "ingredients": [
          {
            "ingredientId": "flour-1",
            "name": "Bread Flour",
            "category": "flour",
            "tag": "flour",
            "weightGrams": 500
          }
        ],
        "steps": [
          {
            "name": "Mix",
            "type": "mixing",
            "notes": "Mix everything.",
            "materialAllocations": [
              { "ingredientId": "flour-1", "percentage": 100 }
            ]
          }
        ]
      }
    }
    """

    private static let richRecipeJSON = """
    {
      "schema": "bready.recipe",
      "schemaVersion": 1,
      "recipe": {
        "name": "AI Country Bread",
        "kind": "countryBread",
        "overallNotes": "Imported from image.",
        "ingredients": [
          {
            "ingredientId": "flour-1",
            "name": "Bread Flour",
            "category": "flour",
            "tag": "flour",
            "weightGrams": 450
          },
          {
            "ingredientId": "starter-1",
            "name": "Levain",
            "category": "starter",
            "tag": "starter",
            "weightGrams": 100,
            "hydrationPct": 100,
            "starterFlour": 50,
            "starterWater": 50,
            "starterRatio": "1:1",
            "starterEditMode": "weight"
          },
          {
            "ingredientId": "egg-1",
            "name": "Egg",
            "category": "basic",
            "tag": "egg",
            "weightGrams": 50,
            "waterContentPct": 75,
            "eggCount": 1,
            "eggUnitWeight": 50,
            "eggType": "Whole Egg"
          }
        ],
        "steps": [
          {
            "name": "Mix dough",
            "type": "mixing",
            "notes": "Combine flour, starter, and egg.",
            "duration": { "value": 15, "unit": "min" },
            "materialAllocations": [
              { "ingredientId": "flour-1", "percentage": 100 },
              { "ingredientId": "starter-1", "percentage": 100 },
              { "ingredientId": "egg-1", "percentage": 100 }
            ]
          },
          {
            "name": "Stretch and fold",
            "type": "fermentation",
            "notes": "拉伸折叠。",
            "duration": { "value": 2, "unit": "hr" },
            "temperature": { "value": 75, "unit": "F" },
            "foldPlan": { "targetCount": 4, "intervalMinutes": 30 },
            "materialAllocations": [
              { "ingredientId": "flour-1", "percentage": 100 },
              { "ingredientId": "starter-1", "percentage": 100 }
            ]
          }
        ]
      }
    }
    """
}

private final class NoopNotifications: BakingNotificationScheduling {
    func schedule(_ event: BakingNotificationEvent) async -> BakingNotificationScheduleResult {
        .failed
    }

    func cancel(_ id: BakingNotificationID) async {}

    func cancel(scope: BakingNotificationScope) async {}

    func openNotificationSettings() {}
}
