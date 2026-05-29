# Baking Component Convention

This document defines the core UI component contract for Baking Journal. Feature screens should compose these components and semantic tokens instead of creating local colors, fonts, radii, shadows, button treatments, or row/table layouts.

## Design Principles

- Build native iOS workflows first: use SwiftUI controls such as `NavigationStack`, `List`, `Section`, `Form`, `Picker`, `Toggle`, `DatePicker`, `Menu`, sheets, confirmation dialogs, and safe-area bottom actions.
- Use semantic APIs instead of visual APIs. Callers choose `role`, `state`, and `kind`; components choose fonts, colors, surfaces, spacing, hit targets, and animation.
- Separate editable from non-editable:
  - Editable input uses a clear field surface and focused/editing state.
  - Read-only calculated values use quieter surfaces or no field chrome.
  - Helper text is always weaker than labels and values.
- Labels are left aligned. Numeric values are right aligned. Units are smaller and quieter than values.
- All numeric values use monospaced digits. Weight, percent, duration, temperature, clock time, and counts use `BakingNumericValue`.
- Top, toolbar, and navigation actions are icon-only in visible UI and must include localization-backed accessibility labels.
- Light and dark mode are handled by semantic `Color.brand*` tokens, not by feature-local branching.

## Taxonomy

### Action

Use for commands.

- `BakingIconButton`: icon-only toolbar/top/inline action with a 44pt or approved hit target.
- `BakingSystemIconButton`: temporary SF Symbol fallback inside the shared button primitive.
- `BakingActionButton`: textual command button for approved native workflow areas.
- `BakingBottomActionButton`: safe-area bottom command wrapper.
- `BakingSlideActionBar`: high-confidence gesture action, especially when accidental taps would be costly.

Allowed roles: `.primary`, `.secondary`, `.tertiary`, `.success`, `.destructive`.

### Label

Use `BakingLabel` or `.bakingLabelStyle(...)` for all non-value text.

- `.sectionHeader`: section titles such as "材料" or "喂养方法".
- `.fieldLabel`: form labels.
- `.inputLabel`: names of editable entities, such as ingredient names.
- `.readOnlyLabel`: labels above calculated values or metrics.
- `.helperText`: hints, detail text, and explanations.
- `.iconCaption`: only when the caption adds information not already present nearby.
- `.tableHeader`: table/list column labels.

### Input

Inputs must make editability obvious.

- `BakingTextInputRow`: text value row.
- `BakingNumberInputRow`: numeric value row with optional unit.
- `BakingPickerRow`: menu/popover trigger row.
- `BakingToggleRow`: boolean row using native `Toggle`.
- `BakingDateTimeRow`: native date/time row using `DatePicker`.
- `BakingPercentageField`: compact percent input.

Editable rows use `.field` or `.focused` surfaces. Disabled rows use `.readOnly`.

### Value

Values display data and do not imply editing by themselves.

- `BakingNumericValue`: canonical number + optional unit display.
- `BakingReadOnlyValue`: labeled calculated value.
- `BakingMetricValue`: compact summary metric.
- `BakingQuantityColumn` and `BakingPercentColumn`: table-aligned numeric columns.

Units must be visually de-emphasized relative to the value.

### Surface

Use `bakingSurface(_:)` for semantic surfaces.

- `.card`: normal grouped content.
- `.compactCard`: dense grouped content.
- `.field`: editable field.
- `.readOnly`: calculated or disabled value.
- `.selected`: selected item.
- `.focused`: active editing or focus.
- `.warning`: warning state.
- `.success`: success/completion state.

Feature screens must not create new one-off card, field, or state surfaces.

### Table/List

Use table components when scanning across rows matters.

- `BakingTable`: table container.
- `BakingTableHeader`: column header row.
- `BakingTableRow`: row surface.
- `BakingTableColumn`: trailing column definition.
- `BakingSwipeToDeleteRow`: custom swipe delete when native swipe is not sufficient.
- `BakingEmptyState`: empty table/list state.

Column rules:

- Text labels are left aligned.
- Percent, weight, time, temperature, and count columns are right aligned.
- Numeric columns have fixed widths per table.
- Units are smaller and lighter than numbers.
- Repeated text under icons is not allowed unless it provides distinct information.

## States

Use `BakingComponentState` for shared state language:

- `.normal`: default.
- `.selected`: selected tab, row, segment, or option.
- `.focused`: active input focus.
- `.editing`: edit/reorder mode.
- `.disabled`: unavailable but visible.
- `.warning`: non-destructive problem.
- `.success`: saved, completed, or confirmed.
- `.destructive`: destructive action or confirmation.
- `.empty`: no content state.

Do not encode states through local opacity, local backgrounds, or feature-specific colors when a shared state exists.

## SwiftUI API Examples

```swift
BakingIconButton(
    icon: .save,
    accessibilityLabel: BakingTerms.save,
    role: .primary
) {
    save()
}
```

```swift
BakingNumberInputRow(
    title: BakingTerms.formulaFieldWeight,
    value: $weight,
    unit: BakingTerms.unitGram,
    fractionDigits: 0...1,
    state: isEnabled ? .normal : .disabled
)
```

```swift
BakingReadOnlyValue(
    title: BakingTerms.formulaTableWeight,
    value: BakingFormat.number(weight, precision: 0),
    unit: BakingTerms.unitGram
)
```

```swift
BakingTable {
    BakingTableHeader(
        title: BakingTerms.formulaTableIngredient,
        columns: [
            BakingTableColumn(title: BakingTerms.formulaTablePercentage, width: 54),
            BakingTableColumn(title: BakingTerms.formulaTableWeight, width: 65)
        ]
    )
} rows: {
    ingredientRows
}
```

## Accessibility

- Every icon-only action requires a localization-backed `accessibilityLabel`.
- Numeric value components should combine value and unit for VoiceOver.
- Picker rows expose the current value through `accessibilityValue`.
- Toggle and date/time rows must use native controls so VoiceOver receives standard behavior.
- Decorative icons should be accessibility-hidden unless they are the only semantic affordance.

## Migration Order

1. Formula table and input surfaces.
2. Starter form.
3. Steps editor.
4. Cooking flow.
5. Preview/read-only pages.

For each migration, replace local fonts/colors/surfaces first, then replace local row/button/table composition. Avoid changing product behavior during visual migration.

## Review Checklist

- Editable vs read-only is visually obvious.
- Numeric columns scan cleanly and use monospaced digits.
- Units are de-emphasized.
- Labels use named roles, not local fonts.
- Buttons are icon-only where required.
- All visible text comes from localization-backed terms.
- Light/dark mode uses semantic colors only.
- Feature files do not introduce new colors, radii, shadows, spacing scales, or button treatments.
