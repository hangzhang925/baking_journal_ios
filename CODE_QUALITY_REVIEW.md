# Code Quality Review

## Summary

The app has a good native SwiftUI foundation, but the early UI layer had several scalability risks: shared visuals lived inside feature files, custom row/card styles were repeated, and action buttons mixed raw SF Symbols, text buttons, and branded icons.

This pass establishes a single component contract and starts migrating the app toward it.

## Issues Found

- Before the refactor, `FormulaView.swift` was too large and owned too many concerns: screen state, import/export, dropdown positioning, material cards, starter editor, egg editor, compact fields, and numeric UIKit bridging.
- `SwipeToDeleteRow` and flow layout behavior were duplicated or scattered instead of being shared.
- Rounded rectangles, radii, surface opacities, field strokes, and card styles were repeated across screens.
- Command buttons used inconsistent visible styles: raw SF Symbols, text buttons, icon+text labels, and bordered button styles.
- The project did not have a written approval rule for new style primitives, which makes random UI additions likely during future coding.

## Changes Made

- Added `BakingDesignSystem.swift` as the single source for UI tokens, shared card/field modifiers, icon-only action labels, flow layout, and swipe delete.
- Updated `AGENTS.md` with code quality, component, and approval rules.
- Added `DESIGN_SYSTEM.md` as a human-readable design system reference.
- Migrated major command buttons to icon-only labels with `accessibilityLabel`.
- Replaced duplicated `SwipeToDeleteRow` and `FlowLayout` code with shared components.
- Started replacing ad-hoc card and field treatment with `bakingCard(...)` and `bakingFieldSurface(...)`.
- Split `FormulaView.swift` into domain files for material cards, starter editor, egg editor, dropdowns, compact fields, and import/export.

## Next Refactor Targets

- Keep `FormulaView.swift` under 500 lines and follow `FORMULA_REFACTOR_PLAN.md` when adding formula workflow UI.
- Move preview metric cards and compact chips into shared components when reused.
- Continue replacing direct `RoundedRectangle(cornerRadius:)` and raw opacity combinations with design-system tokens as nearby code changes.
- Add UI snapshot or view-level tests once the project has a test target.
