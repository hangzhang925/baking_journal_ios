# Baking Journal Roadmap

## Purpose

This roadmap is a planning document for sequencing product features without losing the app's core direction: a warm, native iOS baking journal that helps users plan formulas, execute bakes, and build a personal baking knowledge base over time.

Use this document to decide what to build next, what depends on earlier foundations, and what should stay out of scope until the product is ready.

## Product Principles

- Keep the app local-first, fast, and offline-friendly.
- Prefer native iOS navigation, forms, lists, sheets, menus, and safe-area actions.
- Keep the warm Baking visual language, but express it through shared design-system primitives.
- Make formula editing, step planning, cooking, and bake history feel like one connected workflow.
- Move reusable baking data out of one-off screen state and into durable models.
- Avoid backend, account, and sync work until local persistence and product behavior are stable.

## Planning Lanes

| Lane | Goal | Examples |
| --- | --- | --- |
| Recipe Authoring | Make it easy to create and adjust formulas | Formula editor, ingredients, starter, eggs, import/export |
| Workflow Planning | Turn formulas into usable bake plans | Steps, material allocation, timing, temperatures |
| Baking Session | Support live baking in the kitchen | Cook mode, timers, checklist state, completion flow |
| Journal & Learning | Help users learn from repeated bakes | Bake history, notes, ratings, result comparison |
| Data Foundation | Make app data durable and extensible | Persistence, repositories, migration, import/export |
| Design System | Keep UI consistent as features grow | Buttons, cards, fields, dropdowns, gestures, localization |

## Near-Term Roadmap

### Phase 0: Stabilize Current App Shape

Goal: make the current recipe workflow feel reliable before adding large new product surfaces.

- [ ] Confirm recipe tab, workflow navigation, formula editor, steps, preview, and cook mode share one clear information architecture.
- [ ] Finish active theme/design-system consistency work from `docs/theme-redesign-plan-may-29.md`.
- [ ] Remove remaining one-off button, card, field, chip, and popover treatments from feature views.
- [ ] Audit localization coverage for all visible labels, empty states, alerts, and accessibility labels.
- [ ] Verify global navigation gestures do not interfere with vertical scrolling or local swipe actions.
- [ ] Keep `FormulaView.swift` as a screen-level orchestrator per `FORMULA_REFACTOR_PLAN.md`.

Exit criteria:

- Core workflow screens build cleanly and follow shared Baking UI primitives.
- No known feature screen depends on local-only visual treatments that should be in `SharedUI`.
- The current app is stable enough to use as the baseline for new feature work.

### Phase 1: Ingredient Library

Goal: turn hardcoded ingredients into reusable user-owned baking data.

- [ ] Define ingredient categories for flour, water, starter, egg, yeast, sugar, butter, salt, enrichments, inclusions, and other.
- [ ] Convert existing default ingredients into editable ingredient records.
- [ ] Add a native category-first add-ingredient flow.
- [ ] Move category-specific settings, such as starter ratios and egg unit weight, into ingredient editing.
- [ ] Keep formula editing focused on recipe composition, weights, percentages, ordering, and workflow assignment.
- [ ] Preserve compatibility with existing saved recipes.

Dependencies:

- Local data model decisions from `docs/INGREDIENT_LIBRARY_AND_SYNC_PLAN.md`.
- Shared form, dropdown, field, and list-row primitives from the design system.

Exit criteria:

- Users can create and edit ingredients outside a single recipe.
- Formula ingredients can reference reusable ingredient data where appropriate.
- Existing recipes continue to load correctly.

### Phase 2: Local Persistence Foundation

Goal: prepare the app for durable personal baking data before adding sync.

- [ ] Choose the local persistence path, likely SwiftData unless migration needs push toward Core Data.
- [ ] Introduce repository boundaries for recipes, ingredients, and bake history.
- [ ] Move persistence details out of `RecipeStore` gradually.
- [ ] Add explicit migration handling for existing `UserDefaults` data.
- [ ] Keep transient UI state in views or focused view models, not durable stores.
- [ ] Add import/export or backup hooks only where they support user trust and migration safety.

Dependencies:

- Stable model boundaries for recipes, ingredients, steps, and bake history.
- Buildable migration path from current persisted data.

Exit criteria:

- App data is loaded and saved through repository boundaries.
- Current user data migrates without loss.
- Future CloudKit or backend sync can be added without rewriting feature views.

### Phase 3: Bake History as a Learning System

Goal: make bake history useful for learning, not just record keeping.

- [ ] Add structured bake result notes, such as crumb, crust, rise, flavor, handling, and overall outcome.
- [ ] Let users attach process notes to specific steps or time windows.
- [ ] Support comparing a bake result with the recipe formula and planned steps.
- [ ] Add quick repeat or duplicate-from-history flows.
- [ ] Surface previous outcomes when starting a familiar recipe.

Dependencies:

- Durable recipe and bake history storage.
- Clear relationship between recipe versions and bake records.

Exit criteria:

- Users can understand what changed between bakes.
- A completed bake becomes useful input for the next bake.

### Phase 4: Live Baking Improvements

Goal: make the kitchen workflow calmer and more useful during an active bake.

- [ ] Expand cook mode around active step state, timers, checkoffs, and progress.
- [ ] Support multiple timers when the recipe needs parallel timing.
- [ ] Make material usage and remaining quantities easy to scan during execution.
- [ ] Add completion flow that saves bake history with minimal friction.
- [ ] Consider notifications only after timer and session behavior are stable.

Dependencies:

- Step planning data must be reliable.
- Timer behavior and notification permissions must be localized and tested.

Exit criteria:

- Cook mode can guide a user through a full recipe session.
- Completing a session creates useful history without duplicate entry.

### Phase 5: Sync, Backup, and Sharing

Goal: add cross-device safety only after local-first data is trustworthy.

- [ ] Decide whether the product remains Apple-first.
- [ ] Prefer CloudKit for private personal sync if the app stays iOS-first.
- [ ] Consider Supabase, Firebase, or a custom backend only if web, Android, public sharing, collaboration, or community features become core.
- [ ] Define account, privacy, export, and conflict-resolution behavior before implementation.

Dependencies:

- Repository boundaries.
- Stable local persistence.
- Clear product reason for sync or sharing.

Exit criteria:

- Sync has a user-facing purpose beyond technical convenience.
- Local app behavior remains useful without network access.

## Feature Backlog

### High Confidence

- [ ] Ingredient library and category-first ingredient creation.
- [ ] Recipe duplication and versioning behavior.
- [ ] Bake history improvements with structured result notes.
- [ ] Cook mode completion flow into bake history.
- [ ] Persistence migration away from raw `UserDefaults`.
- [ ] Shared UI cleanup for cards, fields, dropdowns, buttons, and material chips.

### Needs Product Decision

- [ ] Recipe version history versus simple duplication.
- [ ] Whether preview/export should look like a normal app workflow screen or a document-style output.
- [ ] Whether ingredient categories need custom editors in the first pass or can start with shared forms.
- [ ] Whether starter feeding belongs inside the same ingredient library or remains a dedicated workflow.
- [ ] Whether notifications are essential for the first polished kitchen flow.

### Later

- [ ] CloudKit sync.
- [ ] Recipe sharing.
- [ ] Public recipe import sources.
- [ ] Photo attachments for bake history.
- [ ] Advanced analytics across repeated bakes.
- [ ] Multi-device conflict resolution.

## Feature Planning Template

Copy this section when planning a new feature.

### Feature Name

Problem:

- What user problem does this solve?

Scope:

- What is included?
- What is explicitly not included?

User Flow:

- Where does the user start?
- What native iOS pattern should this use?
- What is the success state?

Data:

- What models are affected?
- Is the data transient or durable?
- Does it require migration?

UI System:

- Which existing shared components should be reused?
- Does this require a new shared primitive?
- Are all strings and accessibility labels localized?

Verification:

- What manual path should be tested?
- What build/test command should be run?
- What old data should be checked for compatibility?

## Build Verification

For code changes, run:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme BakingJournal -project BakingJournal.xcodeproj -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

For documentation-only changes, a full app build is not required unless the docs describe or depend on generated code.
