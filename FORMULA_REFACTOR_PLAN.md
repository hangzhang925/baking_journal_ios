# Formula Refactor Plan

`FormulaView.swift` should stay a screen-level orchestrator. It owns screen state, navigation, import/export presentation state, category ordering, and top-level layout only.

## File Ownership

- `FormulaView.swift`: formula screen composition, toolbar, file importer/exporter wiring, dropdown overlay placement.
- `FormulaMaterialComponents.swift`: material category controls, draggable material rows, material cards, and material-specific advanced editor routing.
- `FormulaStarterEditor.swift`: starter-specific editing UI and starter part rows.
- `FormulaEggEditor.swift`: egg-specific editing UI, egg type picker, and whole-egg count picker.
- `FormulaDropdowns.swift`: custom dropdown presenter, menu item models, dropdown trigger, and compact info badges.
- `FormulaCompactFields.swift`: reusable compact rows, inline text/number fields, read-only metrics, numeric UIKit bridge, and formula metric cells.
- `FormulaImportExport.swift`: `FileDocument` support for recipe backup import/export.

## Rules For Future Work

- Add a new material type in `FormulaMaterialComponents.swift` only when it affects the material row/card.
- Add a new advanced material editor as a dedicated file if it grows beyond a small inline block.
- Keep reusable compact input controls in `FormulaCompactFields.swift`; do not define another field surface inside a feature file.
- Keep dropdown behavior centralized in `FormulaDropdowns.swift`; do not create another presenter or menu model.
- Keep `FormulaView.swift` below 500 lines. If it grows past that, split the new responsibility before merging.
