# Baking Design Component Consistency Instructions

Use this instruction whenever changing Baking Journal UI, design-system code, SwiftUI feature views, localization, or workflow screens that affect design components.

## Non-Negotiable Direction

Baking Journal is an iOS-native app with a warm Baking visual system. Do not introduce a new visual language. Do not make feature-local card, input, chip, button, popover, color, radius, spacing, or shadow treatments.

Feature code should express product semantics. Shared UI decides the visual treatment.

## Source Of Truth

Check these files before changing UI:

1. `AGENTS.md` repo instructions.
2. `docs/design-system/BAKING_COMPONENT_CONVENTION.md`.
3. `docs/theme-redesign-plan-may-29.md`.
4. `BakingJournal/SharedUI/BakingDesignSystem.swift`.
5. `BakingJournal/SharedUI/BakingThemeColors.swift`.
6. `BakingJournal/SharedUI/MaterialPalette.swift`.
7. `BakingJournal/Localization/L10n.swift` and every `Localizable.strings`.

## Required Design-System Flow

Before editing a feature view:

1. Search for an existing SwiftUI native control, shared Baking component, surface role, button role, layout helper, formatter, or localization key.
2. Reuse it when it fits.
3. If the needed component style does not exist, add or extend a shared API in `BakingJournal/SharedUI`.
4. Migrate the feature to that shared API.
5. Do not patch the feature with local colors, radii, shadows, or ad hoc opacity values.

## Surface Rules

Use semantic surface roles, not raw visual composition.

Expected hierarchy:

- Page background: `Color.brandBackground`.
- Main workflow section: shared section/card surface.
- Card-in-card group: shared inset surface.
- Small chips/mini cards: shared nested chip/material component.
- Editable fields: shared input/field surface.
- Read-only values: shared read-only surface.
- Selected/current state: shared selected surface.
- Success/completion state: shared success surface.
- Water state: shared water semantic surface.
- Popovers/dropdowns/tooltips: shared popover surface.
- Safe-area bottom bars: shared bottom bar surface.
- Destructive actions: shared destructive role.

Do not use `brandPrimary` as an ordinary card fill. It is for action, accent, selected, focus, and light state layers.

Do not use the same visual surface for parent card and child chip/card.

## Feature-Level Anti-Patterns

Avoid these in `BakingJournal/Features`:

- `.background(Color.brandBackground.opacity(...))`
- `.background(Color.brandSurface.opacity(...))`
- `.background(Color.brandPrimary.opacity(...))`
- `.fill(Color.brandPrimary...)` for non-action/non-selected surfaces
- `.stroke(Color.brandPrimary.opacity(...))` outside shared components
- `.clipShape(RoundedRectangle(cornerRadius: <number>...))`
- `.cornerRadius(<number>)`
- `.shadow(color: ...)`
- local fixed field/chip widths unless they are defined as shared metrics
- icon+text command pills unless implemented as an approved shared component
- user-visible `Text("...")`, `Button("...")`, `alert("...")`, or `accessibilityLabel("...")`

Allowed exceptions:

- Temporary layout measurement with `Color.clear`.
- Numeric text interpolation, such as `Text("\(index)")`, when the value is not copy.
- SharedUI implementation internals.
- Native controls that require labels, provided labels come from localization-backed terms.

## Input And Field Rules

Inputs must be visually consistent and clearly editable.

- Title inputs fill available width and use the shared title input treatment.
- Weight, percentage, duration, temperature, and count fields use shared numeric input metrics.
- Numeric values use monospaced digits.
- Units are visually quieter than values.
- Labels are visible and localization-backed.
- Editable fields and read-only values must not share the same visual strength.
- Disabled fields use shared disabled/read-only state, not local opacity hacks.

## Material Component Rules

Material UI must share one visual language across formula, steps, cook, and preview.

Use shared variants instead of local composition:

- compact material chip
- assignment material chip
- material mini card
- ingredient list row

Required states:

- normal
- selected/allocated
- unavailable/used-up
- checked/completed
- water-bearing

Material child components must contrast with their parent section card.

## Button Rules

- Toolbar and top actions are icon-only in visible UI.
- Every icon-only button must have a localization-backed accessibility label.
- Primary actions use shared button roles and approved `brandPrimary` treatment.
- Success uses `brandSage`.
- Destructive actions use destructive semantics, not `brandPrimary`.
- Do not build local button backgrounds, shadows, radii, or text pills inside feature views.

## Popover, Dropdown, Sheet Rules

Use shared popover/dropdown/sheet surfaces.

Keep consistent:

- width rules
- padding
- radius
- stroke
- shadow
- compact adaptation behavior

## Localization Rules

No hard-coded user-facing strings in feature, model, store, or SharedUI code.

This includes:

- visible labels
- button titles
- alert titles
- empty states
- helper text
- accessibility labels
- confirmation dialog text
- default display names

Use stable keys in `L10n.swift` and add entries to every supported `Localizable.strings` file.

## Review Checklist

Before finishing any UI change:

- Feature code chooses semantic components/roles instead of raw style.
- Parent and child surfaces are visibly distinct.
- Inputs have consistent height, width, radius, label, and unit treatment.
- Buttons use shared Baking button primitives.
- Destructive UI is not colored with primary brand semantics.
- No new feature-local shadows or magic radii.
- No hard-coded user-facing strings.
- Full project build passes.

## Verification Command

Run after code changes:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme BakingJournal -project BakingJournal.xcodeproj -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```
