# Codex Agent Design Guide

This guide is the working contract for Codex or any coding agent changing Baking Journal UI.

The short version: feature code describes product behavior; shared Baking components decide how it looks.

## Required Before Any UI Change

1. Read `AGENTS.md`.
2. Read `docs/design-system/BAKING_COMPONENT_CONVENTION.md`.
3. Read `docs/design-system/BAKING_DESIGN_COMPONENT_CONSISTENCY_INSTRUCTIONS.md`.
4. Inspect the relevant shared APIs in `BakingJournal/SharedUI/BakingDesignSystem.swift`.
5. Search for an existing native SwiftUI control, Baking component, semantic role, token, layout helper, formatter, or localization key before adding anything new.

## Non-Negotiable Rule

Do not create feature-local design primitives.

Feature files must not introduce new:

- colors
- opacity recipes for visual styling
- radii
- shadows
- button treatments
- card treatments
- input treatments
- chip treatments
- popover/dropdown treatments
- spacing scales
- layout helpers
- icon treatments

If the existing design system cannot express the needed UI, stop and ask for permission before implementing the new treatment.

## Allowed Implementation Path

When a screen needs UI:

1. Prefer native iOS structure: `NavigationStack`, `List`, `Section`, `Form`, `Picker`, `Toggle`, `Menu`, sheets, confirmation dialogs, toolbar items, and safe-area bottom actions.
2. Compose existing Baking shared components.
3. Pass semantic intent: `role`, `state`, `surfaceKind`, `BakingIcon`, localized title/accessibility label.
4. Let SharedUI choose color, radius, stroke, shadow, spacing, font, hit target, and motion.
5. If a reusable visual primitive is truly missing, ask for approval, then add it to `BakingJournal/SharedUI` first and migrate the feature to that shared API.

## Permission Required

Ask the user before:

- adding a new visual language or layout paradigm
- adding a new shared component style
- adding a new color token, radius token, shadow, animation style, icon style, or button style
- bypassing a shared component because it does not fit
- creating a feature-local workaround for a design-system gap
- using SF Symbols where an app-specific `BakingIconView` icon should exist
- changing navigation behavior or adding visible back/home controls to app-managed routes

Small refinements are allowed without a separate approval only when they reuse existing Baking tokens and shared components.

## Button Contract

- Toolbar, top, navigation, and app action buttons are icon-only in visible UI.
- Every icon-only button has a localization-backed `accessibilityLabel`.
- Use shared button primitives such as `BakingIconButton`, `BakingToolbarIconButton`, `BakingSystemIconButton`, `BakingActionButton`, or `BakingBottomActionButton`.
- Primary filled actions use the shared primary action treatment and `Color.brandOnPrimary` for text/icons on the fill.
- Destructive actions use destructive semantics only.
- Do not build buttons in feature files with local `.background`, `.clipShape`, `.cornerRadius`, `.shadow`, or one-off foreground colors.

## Surface Contract

- Use approved semantic surfaces: `bakingCard(...)`, `bakingFieldSurface(...)`, `BakingSurfaceTheme`, and `bakingSurface(...)`.
- Parent sections, nested chips, editable fields, read-only values, selected states, focused states, success states, warning states, destructive states, and popovers must use distinct shared semantic roles.
- Do not make card-in-card layouts with the same visual strength for parent and child surfaces.
- Do not use `Color.brandPrimary` as a general card fill.

## Localization Contract

No hard-coded user-facing text in feature, model, store, or SharedUI code.

This includes visible labels, button titles, alerts, empty states, helper text, accessibility labels, default display names, and formatted copy.

Use stable `L10n.swift` / `BakingTerms` keys and add entries to every supported `Localizable.strings` file.

## Review Checklist

Before finishing a UI change, confirm:

- Feature code uses shared components or native SwiftUI controls.
- Feature code expresses semantics instead of raw styling.
- No new feature-local color, radius, shadow, button, card, input, chip, popover, spacing, or icon treatment was introduced.
- Any new reusable visual behavior lives in `BakingJournal/SharedUI`.
- Any design-system exception was approved by the user.
- Buttons follow the shared button contract.
- All visible and accessibility text is localization-backed.
- A real Xcode build was run after code changes.
