# Theme Redesign Plan - May 29

## Goal

Create a repo-level app style contract for Baking Journal so feature screens cannot drift into inconsistent card, background, input, button, chip, popover, or color treatments.

This is not a new visual direction. The app should keep its warm iOS-native Baking style, but the design system must become stricter and more semantic.

## Current Problem

The repo already has useful tokens such as `Color.brandBackground`, `Color.brandSurface`, `Color.brandPrimary`, `BakingSurface.cardBackground`, `bakingCard(...)`, and `bakingFieldSurface(...)`.

The inconsistency comes from feature files directly composing:

- `Color.brandBackground.opacity(...)`
- `Color.brandSurface.opacity(...)`
- `Color.brandPrimary.opacity(...)`
- local `RoundedRectangle(cornerRadius: ...)`
- local stroke opacity
- local shadow values
- local fixed widths and heights for fields/chips

Because these choices are made per feature, nested surfaces can collapse into each other. The visible example is the step ingredient assignment card: material chips use nearly the same surface as the parent card, so card and background layers overlap visually.

## Design Principles

1. The app is iOS-native, not web-style.
2. Feature views choose semantic roles, not raw colors.
3. `brandPrimary` is an accent/action/focus/selected color, not a general card background.
4. App page background, section card, nested surface, field, selected state, and disabled state must be visually distinct.
5. Feature files must not invent one-off backgrounds, radii, strokes, shadows, or button surfaces.
6. Shared UI and design-system components are the source of truth.
7. All user-visible strings and accessibility labels must use localization keys.
8. Every migration must preserve Dynamic Type, 44pt touch targets, and native iOS interaction patterns.

## Surface Hierarchy Redesign

Define a stricter surface contract in `BakingDesignSystem.swift`.

Proposed semantic roles:

| Role | Purpose | Notes |
| --- | --- | --- |
| `pageBackground` | Full screen/page background | Maps to `brandBackground` |
| `sectionCard` | Main content cards and workflow sections | Maps to `brandSurface` plus light brand stroke |
| `insetSurface` | A grouped surface inside a section card | Must contrast with `sectionCard` |
| `nestedChip` | Small chip/card inside a card | Used for material chips, badges, compact metrics |
| `inputSurface` | Editable fields and inline editors | Clear editable affordance |
| `readOnlySurface` | Read-only values and static cells | Subordinate to editable fields |
| `selectedSurface` | Selected/current state | Uses low-opacity `brandPrimary` |
| `successSurface` | Completed/success state | Uses low-opacity `brandSage` |
| `waterSurface` | Water-related semantic state | Uses water tokens, not primary |
| `popoverSurface` | Popovers, dropdowns, tooltips | Shared radius, stroke, shadow |
| `bottomBarSurface` | Safe-area bottom action bars | Shared top divider and background |
| `destructiveSurface` | Destructive action affordance | Separate from primary brand color |

Implementation direction:

- Add semantic surface tokens or expand `BakingSurfaceKind`.
- Prefer `.bakingSurface(.role)` over `.bakingCard(background: ...)` in feature files.
- Keep escape hatches private or limited to SharedUI.

## Color Contract

| Scenario | Background | Foreground | Stroke |
| --- | --- | --- | --- |
| Page | `brandBackground` | `brandText` | none |
| Section card | `brandSurface` | `brandText` | low-opacity `brandPrimary` |
| Nested chip/card | new semantic inset/chip surface | `brandText` | low-opacity `brandPrimary` |
| Input field | new semantic input surface | `brandText` | focus uses `brandPrimary` |
| Read-only field | new semantic read-only surface | `brandSecondaryText` | very light stroke |
| Selected state | low-opacity `brandPrimary` | `brandPrimary` | stronger low-opacity `brandPrimary` |
| Success state | low-opacity `brandSage` | `brandSage` | low-opacity `brandSage` |
| Water state | `waterSurface` / `waterSurfaceStrong` | `waterText` | `brandSea` where needed |
| Destructive state | destructive semantic token | destructive foreground | destructive stroke |

Rules:

- Do not use `brandPrimary` as a large ordinary card fill.
- Do not use `brandBackground` as a nested card fill unless the role is explicitly read-only/inset.
- Do not use material surface and section card surface as the same visible layer.
- Do not hard-code opacity values in feature views.

## Component Systems To Redesign

### 1. Card and Nested Surface System

Needs redesign.

Affected examples:

- `StepsView` remaining material chips and assignment material chips.
- `CookView` material mini cards.
- `RecipePreviewView` ingredient rows and list containers.
- Formula and steps list sections using local `brandSurface.opacity(...)`.

Target:

- Main workflow cards use `sectionCard`.
- Card-in-card rows use `insetSurface`.
- Small selectable chips use `nestedChip` or a material-specific component.

### 2. Input and Field System

Needs redesign.

Affected examples:

- Recipe name input.
- Starter name input.
- Starter numeric fields.
- Egg weight and count controls.
- Starter part entries.
- Step compact value buttons.
- Temperature option buttons.
- Dropdown triggers.

Target:

- Create shared field metrics for title input, numeric input, compact field, dropdown trigger, and option chip.
- Field widths should be semantic, not ad hoc.
- Editable, read-only, selected, disabled, and water styles should be roles.

Proposed field metrics:

| Field Type | Width | Height | Notes |
| --- | --- | --- | --- |
| Title input | fill | min 44 | Recipe/starter names |
| Weight input | 72-86 | min 40 | Gram values |
| Percent input | 54-64 | min 40 | Percent values |
| Compact value | 72-82 | 40-44 | Timer/temperature compact display |
| Dropdown trigger | 96-112 | min 38 | Must support localized labels |
| Option chip | 52-64 | 40-44 | Temperature/count pickers |

### 3. Material Chip and Ingredient Mini Card System

Needs redesign.

Affected examples:

- `RemainingMaterialChip`
- `AssignmentMaterialChip`
- `CookMaterialMiniCard`
- `CompactIngredientRow`

Target:

- Shared material visual language.
- One semantic material surface for normal state.
- Clear selected/allocated/used-up/checked states.
- Consistent icon badge size, chip width, radius, stroke, and text hierarchy.
- Different density variants are allowed, but must be defined in SharedUI.

Proposed variants:

- `compactChip`: formula/assignment chip.
- `miniCard`: cook material grid item.
- `listRow`: preview/formula list row.

### 4. Workflow Stage Navigation

Needs redesign.

Affected example:

- `RecipeWorkspaceView` stage buttons.

Target:

- Replace local selected/unselected fill/stroke with shared workflow segmented control or shared stage button style.
- Decide whether this is a native segmented control, a branded stage switcher, or a tab-like workflow control.

### 5. Popover, Dropdown, Tooltip, and Sheet Surfaces

Needs redesign.

Affected examples:

- Baker percentage tooltip.
- Dropdown popover.
- Temperature popover.
- Egg count popover.
- Material percentage popover.

Target:

- Shared `BakingPopoverSurface`.
- Shared width rules.
- Shared radius, stroke, and shadow.
- Shared content padding.

### 6. Button Role System

Needs redesign.

Affected examples:

- Local toggle chips.
- Local stage buttons.
- Confirmation modal text buttons.
- Swipe delete using primary color.
- Feature-level command pills.

Target:

- Shared button roles: toolbar icon, primary action, secondary action, toggle chip, destructive action, confirmation action.
- Toolbar and top actions stay icon-only.
- Destructive actions must not reuse `brandPrimary` as their semantic color.

### 7. Preview and Export Style

Needs product decision.

`RecipePreviewView` currently behaves like a separate read-only/export layout. That may be valid, but it must be explicit.

Options:

1. Treat preview as a normal app workflow screen and migrate it to the same card/inset system.
2. Treat preview/export as a distinct document style, then define that style in SharedUI and keep it consistent.

## Items That Do Not Need Redesign

These need cleanup, not product redesign:

- Hardcoded Chinese strings and accessibility labels.
- Magic radius/opacity/lineWidth values.
- Local shadow values.
- Minor spacing drift.
- Existing design-system APIs that are too flexible.

## Migration Plan

### Phase 1: Add Contracts

- Add semantic surface roles.
- Add semantic color helpers for nested/inset/input/destructive states.
- Add component metrics for fields, chips, popovers, and bottom bars.
- Add `BakingShadow` tokens.
- Add stricter shared button roles if needed.

### Phase 2: Fix Most Visible Bug

- Migrate step material assignment and remaining material chips.
- Ensure parent section card and child chips have visible layer contrast.
- Verify selected, used-up, and unavailable states.

### Phase 3: Migrate Input System

- Recipe title input.
- Starter title input.
- Starter numeric fields.
- Egg editor fields.
- Starter formula mini fields.
- Step compact value buttons.
- Temperature and percentage popovers.

### Phase 4: Migrate Material Components

- Shared material chip/card/row variants.
- Formula rows.
- Step assignment chips.
- Cook mini cards.
- Preview ingredient rows.

### Phase 5: Migrate Popovers and Workflow Controls

- Dropdowns.
- Tooltips.
- Temperature and egg count popovers.
- Material percentage popover.
- Workspace stage navigation.

### Phase 6: Localization and Lint

- Move hardcoded user-visible strings to `L10n.swift` and all `Localizable.strings` files.
- Add a lightweight consistency check script or documented grep checks for forbidden feature-level patterns.

## Acceptance Criteria

- Feature files do not directly invent card/input/chip/popover backgrounds.
- Feature files do not hard-code new radii, shadows, or stroke opacity for reusable components.
- Nested cards/chips are visually distinct from parent cards.
- Input fields have consistent height, radius, label treatment, and width rules.
- Material chips/cards share one visual system across formula, steps, cook, and preview.
- Destructive actions use destructive semantics, not primary brand color.
- All user-facing text and accessibility labels are localized.
- A full project build passes after each implementation phase.

## Verification

After code changes, run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme BakingJournal -project BakingJournal.xcodeproj -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

For visual changes, also capture screenshots for:

- Recipe formula screen.
- Recipe steps screen with material assignment expanded.
- Cook screen.
- Recipe preview/export screen.
- Starter screen.

## Initial Fix Priority

1. Surface hierarchy contract.
2. Material assignment chip redesign.
3. Input/field contract.
4. Material component variants.
5. Popover/dropdown surfaces.
6. Button role cleanup.
7. Preview/export style decision.
8. Localization cleanup.

## Phase Specs

- Phase 1 recipe-tab implementation spec: `docs/theme-redesign-phase-1-recipe-tab-spec-may-29.md`
