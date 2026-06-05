# Theme Redesign Phase 1 Spec - Recipe Tab

## Scope

Phase 1 covers the full recipe tab editing experience: formula, steps, and preview.

Included:

- `BakingJournal/Features/RecipeFormula/FormulaView.swift`
- `BakingJournal/Features/RecipeFormula/FormulaMaterialComponents.swift`
- `BakingJournal/Features/RecipeFormula/FormulaDropdowns.swift`
- `BakingJournal/Features/RecipeFormula/FormulaEggEditor.swift`
- `BakingJournal/Features/RecipeFormula/FormulaStarterEditor.swift`
- `BakingJournal/Features/RecipeFormula/FormulaCompactFields.swift`
- `BakingJournal/Features/RecipeFormula/ItemEditorView.swift`
- `BakingJournal/Features/RecipeSteps/StepsView.swift`
- `BakingJournal/Features/RecipeSteps/StepSharedComponents.swift`
- `BakingJournal/Features/RecipePreview/RecipePreviewView.swift`
- Shared APIs needed in `BakingJournal/SharedUI`
- Localization keys needed by the recipe tab workflow

Excluded:

- Cook page material mini cards.
- Starter page outside the formula mini starter editor.
- Workspace stage navigation.
- Any product behavior changes.

## Goal

Make the recipe tab the first implementation target for the new design component consistency system.

The tab should continue to feel like the current warm, iOS-native Baking app, but feature-level visual recipes should move into SharedUI semantic components.

## Non-Goals

- Do not redesign navigation.
- Do not change formula math, item editing behavior, step editing behavior, material assignment behavior, drag/reorder behavior, import/export behavior, or sheet presentation behavior.
- Do not redesign preview/export as a separate document style. In Phase 1, preview follows the same recipe-tab surface hierarchy.
- Do not migrate cooking flow or starter tab.

## Current Recipe Tab Findings

The design component diagnostic script currently flags recipe-tab issues in these groups:

- Feature-local primary opacity surfaces:
  - `FormulaEggEditor.swift`
  - `FormulaMaterialComponents.swift`
  - `FormulaView.swift`
  - `StepsView.swift`
  - `StepSharedComponents.swift`
  - `RecipePreviewView.swift`
- Feature-local background/card opacity surfaces:
  - `FormulaDropdowns.swift`
  - `FormulaEggEditor.swift`
  - `FormulaMaterialComponents.swift`
  - `FormulaStarterEditor.swift`
  - `FormulaView.swift`
  - `StepsView.swift`
  - `StepSharedComponents.swift`
  - `RecipePreviewView.swift`
- Hard-coded localized strings:
  - file error alert
  - OK button
  - toolbar accessibility label
  - empty ingredients state
  - baker percentage tooltip title/body/accessibility label
  - preview section titles and export error alert
  - temperature unit picker accessibility labels
- Custom card and field styling:
  - formula title field
  - formula item rows/cards
  - item editor card
  - category table card
  - steps table card
  - remaining material card
  - assignment material chips
  - preview section list containers
- Hard-coded radius and metrics:
  - dropdown trigger
  - egg editor controls
  - starter mini editor controls
  - material icon badges
  - tooltip/popover widths
  - assignment chip size/radius
  - preview list row/inset radius
- Local popover shadow:
  - baker percentage tooltip

## Phase 1 Design Decisions

### Surface Roles To Add Or Formalize

Add semantic roles to `BakingSurfaceKind` or equivalent SharedUI API.

Required for recipe-tab phase:

| Role | Purpose | Recipe Tab Usage |
| --- | --- | --- |
| `sectionCard` | Main recipe-tab sections | recipe header, formula category cards, steps overview/materials/step table, preview cards |
| `insetSurface` | Group inside section card | empty states, preview list containers, advanced editor grouped body |
| `inputSurface` | Editable inline field | recipe name field, inline numeric fields where applicable |
| `readOnlySurface` | Calculated/non-editable values | read-only inline metrics |
| `nestedChip` | Small compact badges/chips | compact info badges, dropdown trigger-like chips, assignment material chips |
| `selectedSurface` | Selected/active option | selected dropdown/option chips |
| `waterSurface` | Water semantic badge/field | water contribution badge, water-bearing rows |
| `popoverSurface` | Popovers and tooltips | baker percentage tooltip, egg count popover, material percentage popover |
| `destructiveSurface` | Destructive action buttons | remove material buttons in expanded editors |

Naming may be adjusted during implementation, but the semantic roles must exist before feature migration.

### Component Metrics To Add Or Formalize

Add formula-safe metrics in SharedUI instead of local magic numbers.

Proposed home:

- `BakingComponentMetrics`
- or focused enums such as `BakingFieldMetrics`, `BakingChipMetrics`, `BakingPopoverMetrics`

Required metrics:

| Metric | Proposed Value | Formula Usage |
| --- | ---: | --- |
| `titleInputMinHeight` | 44 | recipe name row |
| `compactFieldHeight` | 36-40 | compact numeric fields |
| `optionChipHeight` | 38-42 | egg count / dropdown trigger |
| `dropdownTriggerWidth` | 104 or content-configurable 96-112 | item/starter/egg dropdowns |
| `weightFieldWidth` | 48 | inline gram values |
| `percentFieldWidth` | 34 | inline percentage values |
| `percentTotalWidth` | 58-62 | percent columns/fields |
| `weightTotalWidth` | 76 | weight columns/fields |
| `inlineIconCornerRadius` | shared token | material icon badge |
| `popoverCompactWidth` | 220-260 | tooltip |
| `popoverMediumWidth` | 292-304 | picker popovers |

Implementation can keep current visual dimensions if they are approved, but they must move to named metrics.

### Shadow Tokens

Add shared shadow/elevation tokens if formula phase touches popovers:

- `BakingShadow.popover`
- `BakingShadow.modal`
- `BakingShadow.lifted`

Recipe-tab phase needs `popover` for baker percentage tooltip and material percentage popovers unless existing dropdown surfaces already cover them.

## Shared Components To Introduce Or Tighten

### 1. Recipe Section Card

Purpose:

- Replace feature-local `bakingCard(background: Color.brandSurface.opacity(...), stroke: ...)`.

Possible API:

```swift
extension View {
    func bakingSectionCard() -> some View
    func bakingInsetSurface() -> some View
}
```

Recipe-tab migration targets:

- `recipeHeader`
- category table container
- empty category surface
- steps overview card if needed
- remaining materials card
- steps table container
- preview summary/ingredients/steps cards
- drag overlay surface if needed

### 2. Formula Title Input Surface

Purpose:

- Replace recipe name field local `bakingFieldSurface(background: ..., stroke: ..., radius: ...)`.

Possible API:

```swift
struct BakingTitleInputSurface<Content: View>: View { ... }
```

or:

```swift
extension View {
    func bakingTitleInputSurface() -> some View
}
```

Formula migration target:

- `FormulaView.recipeHeader`

### 3. Compact Field / Badge Surface

Purpose:

- Replace `RectangularDropdownTrigger`, `CompactInfoBadge`, egg count, egg weight, starter mini fields, and water info surfaces using local color/radius.

Possible API:

```swift
enum BakingCompactSurfaceRole {
    case dropdown
    case input
    case readOnly
    case selected
    case water
    case disabled
}
```

Formula migration targets:

- `RectangularDropdownTrigger`
- `CompactInfoBadge`
- `EggWeightInputBadge`
- `EggCountSelector`
- `StarterPartEntry`
- `StarterTapAddInRow`
- `OtherMiniRecipeEditor`

### 4. Formula Material Row/Card Surface

Purpose:

- Keep formula item rows/cards visually consistent and make material card surfaces distinct from parent surfaces.

Possible API:

```swift
enum BakingMaterialPresentation {
    case formulaRow
    case formulaEditorCard
}
```

or:

```swift
extension RecipeItem {
    func materialSurface(for presentation: BakingMaterialPresentation, state: BakingComponentState) -> BakingSurfaceTheme
}
```

Formula migration targets:

- `FormulaItemDisplayRow`
- `EditableFormulaItemCard` or equivalent in `FormulaMaterialComponents.swift`
- `CompactItemEditorCard` in `ItemEditorView.swift`

Steps migration targets:

- `RemainingMaterialChip`
- `AssignmentMaterialChip`

Important:

- Steps assignment chips are included in Phase 1 because they are the visible parent/child surface collision.
- Cook mini cards remain out of scope, but shared APIs should not block future cook variants.

### 5. Popover Surface

Purpose:

- Replace local tooltip background/shadow and popover backgrounds.

Possible API:

```swift
extension View {
    func bakingPopoverSurface(width: CGFloat? = nil) -> some View
}
```

Recipe-tab migration targets:

- `BakerPercentageTooltip`
- `EggCountWheelPopover`
- `MaterialPercentagePopover`
- formula dropdown popovers only if existing `BakingDropdownPopover` does not already satisfy the contract

### 6. Destructive Icon Action

Purpose:

- Remove destructive actions using `background: .brandPrimary`.

Possible API:

```swift
BakingIconButton(
    icon: .delete,
    accessibilityLabel: BakingTerms.formulaDeleteMaterial,
    role: .destructive
) { ... }
```

or update existing `BakingSystemIconButtonLabel` role handling.

Formula migration targets:

- delete button inside expanded formula item editor
- delete button inside `OtherMiniRecipeEditor`

## Localization Work

Add stable localization keys for recipe-tab hard-coded copy touched in Phase 1.

Required keys:

- file operation failed alert title
- OK / confirm acknowledgement if no existing key is suitable
- toolbar more actions accessibility label
- export JSON
- import JSON
- empty ingredients state
- baker percentage info accessibility label
- baker percentage tooltip title
- baker percentage tooltip body
- preview ingredients section title if not reusing `formulaTableIngredient`
- preview steps section title if not reusing `stepsSectionTitle`
- preview export failure title
- temperature unit picker label if not already covered

Files to update:

- `BakingJournal/Localization/L10n.swift`
- `BakingJournal/zh-Hans.lproj/Localizable.strings`
- `BakingJournal/en.lproj/Localizable.strings`

## Implementation Order

### Step 1: Shared Surface Contract

Files:

- `BakingJournal/SharedUI/BakingDesignSystem.swift`
- optionally `BakingJournal/SharedUI/BakingThemeColors.swift`

Add:

- formula-needed semantic surface roles
- named metrics
- popover shadow token if needed

No feature migration yet.

### Step 2: Formula Header And Category Containers

Files:

- `FormulaView.swift`

Migrate:

- recipe title input surface
- category table card
- empty ingredients surface
- baker percentage tooltip surface
- localized strings in this file

Acceptance:

- recipe header still has same hierarchy
- title input remains clearly editable
- category sections have clear parent/inset contrast
- no local hard-coded user-facing copy remains in this file

### Step 3: Formula Dropdowns And Compact Badges

Files:

- `FormulaDropdowns.swift`
- `FormulaCompactFields.swift`

Migrate:

- dropdown trigger surface
- compact info badge surface
- inline percentage/number fields only where covered by new shared metrics

Acceptance:

- dropdown triggers keep touch target and fit localized text
- water badges stay visually distinct from primary badges
- no local hard-coded radii for compact surfaces

### Step 4: Egg And Starter Mini Editors

Files:

- `FormulaEggEditor.swift`
- `FormulaStarterEditor.swift`

Migrate:

- egg editor container
- egg weight input badge
- egg count selector
- egg count popover surface
- starter mini editor container
- starter part entry metrics/surfaces
- starter add-in row surface/toggle treatment

Acceptance:

- egg/starter expanded editors look like one family
- numeric controls keep current usability
- disabled/off rows use shared disabled/read-only state

### Step 5: Formula Material Rows And Item Editor Card

Files:

- `FormulaMaterialComponents.swift`
- `ItemEditorView.swift`
- `MaterialPalette.swift` only if needed for formula-specific material presentation

Migrate:

- material icon badge corner radius/surface
- formula item row edit indicator
- formula editable item card surface
- compact item editor card surface
- destructive delete icon treatment

Acceptance:

- formula rows remain dense and scannable
- expanded material cards are distinct from category/card containers
- destructive actions no longer use primary as destructive fill

### Step 6: Build And Visual Check

Before build, migrate the highest-impact steps and preview surfaces:

- steps table empty/container surfaces
- remaining material card child chips
- assignment material chips
- preview ingredients/steps list inset surfaces
- preview section title localization

Run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme BakingJournal -project BakingJournal.xcodeproj -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Visual check:

- formula page empty state
- formula page with flour/basic categories populated
- steps page with remaining materials card
- steps page with assignment material section expanded
- expanded starter material
- expanded egg material
- expanded other material with water percentage
- item editor sheet
- import/export toolbar popover
- delete confirmation
- preview page ingredients and steps cards

## Files Expected To Change In Phase 1

Expected:

- `BakingJournal/SharedUI/BakingDesignSystem.swift`
- `BakingJournal/SharedUI/BakingThemeColors.swift` if new semantic colors are needed
- `BakingJournal/SharedUI/MaterialPalette.swift` if material presentation roles are added
- `BakingJournal/Features/RecipeFormula/FormulaView.swift`
- `BakingJournal/Features/RecipeFormula/FormulaMaterialComponents.swift`
- `BakingJournal/Features/RecipeFormula/FormulaDropdowns.swift`
- `BakingJournal/Features/RecipeFormula/FormulaEggEditor.swift`
- `BakingJournal/Features/RecipeFormula/FormulaStarterEditor.swift`
- `BakingJournal/Features/RecipeFormula/FormulaCompactFields.swift`
- `BakingJournal/Features/RecipeFormula/ItemEditorView.swift`
- `BakingJournal/Features/RecipeSteps/StepsView.swift`
- `BakingJournal/Features/RecipeSteps/StepSharedComponents.swift`
- `BakingJournal/Features/RecipePreview/RecipePreviewView.swift`
- `BakingJournal/Localization/L10n.swift`
- `BakingJournal/zh-Hans.lproj/Localizable.strings`
- `BakingJournal/en.lproj/Localizable.strings`

Not expected:

- `BakingJournal/Features/Cooking/CookView.swift`
- `BakingJournal/Features/Home/RecipeWorkspaceView.swift`
- Store/model behavior files, unless a compile error reveals an existing shared dependency issue

## Acceptance Criteria

Phase 1 is complete when:

- Formula page uses shared semantic surfaces for header, category containers, compact controls, popovers, and formula material rows/cards.
- Steps page uses shared semantic surfaces for overview/materials/step containers and material assignment chips.
- Preview page uses shared semantic section/inset surfaces for summary, ingredients, and steps.
- Formula page no longer has feature-local card/input/chip/popover visual recipes except layout-only `Color.clear`.
- Formula page hard-coded user-facing strings are localized.
- Touched steps/preview hard-coded user-facing strings are localized.
- Formula material rows remain at current or better density and readability.
- Assignment material chips are visually distinct from their parent card and still show normal, selected, and used-up states clearly.
- Expanded starter/egg/other editors use consistent compact field and badge treatments.
- Destructive formula item actions use destructive semantics, not primary brand semantics.
- Full Xcode build passes.

## Approval Checkpoint

Before implementation, confirm:

1. The semantic role names are acceptable, or provide preferred names.
2. Phase 1 includes `ItemEditorView.swift` sheet styling.
3. Phase 1 includes import/export toolbar popover localization.
4. Phase 1 includes steps assignment chips and preview list surfaces.
