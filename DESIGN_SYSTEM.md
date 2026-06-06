# Baking Journal Design System

This app is an iOS-native baking tool. The visual language is warm, quiet, handmade, and utility-first. It should feel like a native iPhone app for repeated recipe work, not a web dashboard or marketing surface.

## Principles

- Use native SwiftUI structure first: `NavigationStack`, `List`, `Section`, `Form`, `Picker`, toolbar items, sheets, popovers, and confirmation dialogs.
- Preserve the warm brand palette and hand-drawn icon language.
- Keep command buttons icon-only. Visible button text is not part of the command-button style.
- Use text where iOS expects text: tab labels, segmented pickers, form labels, menus, system alerts, section headers, field labels, and content rows.
- Favor dense but readable workflow screens over decorative cards or landing-page composition.

## Tokens

- Colors: use semantic `Color.brand*`, `Color.water*`, semantic (`Color.semantic*`), and material palettes only. The foundation is the Claude Design **"Baking Journal — Design System"** (direction *Honey Gold*): a bright golden-wheat primary (`#F2A20C`) that stays vivid in light and warm-black dark mode, a water-blue secondary, and a white-canvas → warm-cream-card surface model with no cold grey. Full `goldenWheat*` / `waterBlue*` (50–900) scales and `semanticSuccess/Warning/Error/Info` tokens live in `BakingThemeColors.swift`.
- On accent: filled primary controls take white text (`Color.brandOnPrimary`); gold field fills mean "editable".
- Spacing: use `BakingSpace` values.
- Radius: use `BakingRadius` values.
- Motion: use `BakingMotion.quick` or `BakingMotion.standard`.
- Touch targets: icon buttons must reserve at least `BakingTouchTarget.iconButton` points.

## Components

- Action buttons: `BakingToolbarIconButton` for hand-drawn baking icons, `BakingSystemIconButtonLabel` only when no app-specific icon exists.
- Icon badges: `BakingMaterialIconBadge`.
- Cards: `bakingCard(...)`.
- Inline fields: `bakingFieldSurface(...)`.
- Dropdowns: `BakingDropdownTrigger`, `BakingDropdownPopover`, `BakingDropdownRow`.
- Custom layout: `BakingFlowLayout`.
- Custom swipe delete: `BakingSwipeToDeleteRow`.

## Approval Rule

Before adding a new component style, color token, radius, shadow, button treatment, card treatment, or layout helper, ask for approval and document why the existing system cannot cover it.

## Current Review Notes

- `FormulaView.swift` is still too large and should be split by domain in future work: formula screen, material card, starter editor, egg editor, compact fields, and import/export.
- Prefer moving shared compact metric and chip components out of feature files as they are reused.
- Continue replacing one-off `RoundedRectangle(cornerRadius:)`, raw opacity values, and ad-hoc SF Symbol buttons with design-system tokens during feature work.
