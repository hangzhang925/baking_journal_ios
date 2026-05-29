# Ingredient Library and Sync Plan

## Background

The app is moving from a single-recipe editor toward a personal baking data system. Once users can create and maintain their own ingredients, categories, starter settings, egg settings, and reusable preferences, that data becomes more important than temporary screen state.

Today the app does not have a server. That is acceptable for the current product stage, but continuing to grow `RecipeStore` plus `UserDefaults` as the primary state container will make the app harder to scale, migrate, back up, and eventually sync.

## Product Direction

- Users should be able to add any ingredient they want.
- Adding an ingredient should start by choosing a category, such as flour, starter, water, egg, yeast, sugar, butter, or other.
- Existing hardcoded ingredients should become editable ingredients managed through the ingredient page.
- Formula editing should focus on recipe composition, weights, percentages, ordering, and workflow assignment.
- Category-specific details, such as starter ratios or egg count/unit weight, should live in ingredient editing rather than being configured directly inside the formula page.
- Future category-specific screens can be added gradually when each category needs a richer editing flow.

## Backend Decision

We should not rush into building a backend just for the first version of the ingredient library.

The better near-term move is to strengthen the local data layer first. This keeps the app fast, offline-friendly, and simpler to ship while still preparing the codebase for future sync.

Recommended direction:

- Phase 1: Move important app data out of `UserDefaults` into a real local persistence layer.
- Phase 2: Introduce repository boundaries so UI and product logic do not care whether data comes from local storage or cloud sync.
- Phase 3: Add sync only when cross-device usage, backup, sharing, or account-based workflows become product requirements.

## Local Persistence Direction

Prefer a native iOS local-first approach before adding a custom server.

Good candidates:

- `SwiftData` for a modern Apple-native persistence layer.
- Core Data if we need more mature migration control.
- File-based JSON only for import/export or backups, not as the main app database.

The local persistence layer should own durable user data:

- Recipes
- Ingredient library items
- Recipe ingredients
- Steps and material allocations
- Bake history
- User defaults that are truly product preferences

Transient UI state should stay in views or view models:

- Open sheets
- Expanded rows
- Drag state
- Focus state
- Temporary editor drafts before saving

## Repository Boundary

Before adding sync, introduce explicit data access boundaries.

Possible repository shape:

- `RecipeRepository`
- `IngredientRepository`
- `BakeHistoryRepository`

`RecipeStore` can remain the observable app-facing state object, but it should stop being the owner of persistence details over time. It should coordinate product behavior and call repositories for loading, saving, and migration.

This makes future backends easier to add:

- Local-only implementation first
- CloudKit-backed implementation later
- Supabase/Firebase/custom API only if the product expands beyond Apple-only sync

## Ingredient Library Phase 1

Scope for the first implementation:

1. Expand ingredient categories so they represent the user-facing ingredient creation choices.
2. Convert existing default ingredients into editable ingredient records.
3. Add a native iOS add-ingredient flow where the user chooses category first.
4. Route ingredient-specific configuration through the ingredient editing page.
5. Keep formula page focused on recipe-level composition.
6. Preserve compatibility with existing saved recipe data.

Non-goals for Phase 1:

- No custom backend.
- No account system.
- No cross-device sync.
- No global community ingredient database.
- No full rewrite of recipe models unless needed for compatibility.

## Future Sync Options

If sync becomes necessary, choose based on product direction.

CloudKit is the preferred first option if the app remains Apple-first:

- Native iOS integration
- No custom server to maintain
- Good fit for private personal data
- Works naturally with iCloud

Supabase, Firebase, or a custom backend become more attractive if we need:

- Web or Android clients
- Public sharing
- Community recipes
- Account-based collaboration
- Server-side search, recommendations, or analytics

## Implementation Notes For Later

- Do the persistence refactor before growing the ingredient library too far.
- Keep migrations explicit and test old persisted data.
- Avoid coupling category-specific screens directly to formula editing.
- Preserve native iOS patterns: `NavigationStack`, `List`, `Form`, `Section`, `ToolbarItem`, sheets, menus, and confirmation dialogs.
- Keep UI primitives in `BakingDesignSystem.swift`.
- Do not introduce one-off visual styles inside feature views.

## Suggested Sequence

1. Introduce local persistence abstractions while keeping current behavior unchanged.
2. Move recipe and bake history loading/saving behind repositories.
3. Add ingredient library models and local storage.
4. Refactor formula ingredients to reference editable ingredient data where appropriate.
5. Add category-first ingredient creation.
6. Add category-specific ingredient editor screens incrementally.
7. Revisit sync once the local model is stable.
