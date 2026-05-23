# Repo Memory

## Product UI Direction

- Treat this app as an iOS-native product, not a web app wrapped in SwiftUI.
- Prefer native iOS components and interaction patterns everywhere:
  - `NavigationStack`, `NavigationLink`, `List`, `Section`, `Form`, `ToolbarItem`
  - system sheets, menus, confirmation dialogs, swipe actions, segmented controls
  - standard safe-area bottom actions for primary workflow buttons
- Avoid dashboard-style layouts, marketing-style cards, and web-like landing-page composition unless the user explicitly asks for that direction.
- When redesigning screens, default to Apple HIG-aligned structure, spacing, hierarchy, and navigation behavior.
- Keep the current warm color palette unless the user asks to change it, but apply it through native iOS UI patterns instead of webpage-style surfaces.
- Icon buttons should be icon-only in visible UI. Do not add explanatory text inside buttons; use `accessibilityLabel` for VoiceOver instead.
- Use the app's own warm, hand-drawn `BakingIconView` / branded button styling for primary and toolbar actions. Avoid raw system button visuals or bare SF Symbols unless there is no app-specific icon yet.
- Keep spacing rhythm and card density consistent across screens that belong to the same workflow. If `配方编辑`, `制作步骤`, preview, or adjacent recipe pages use the same card/list language, match their vertical spacing, horizontal insets, and section cadence unless the user explicitly asks for a different pattern.

## Code Quality Direction

- Keep UI primitives centralized in `BakingJournal/Views/BakingDesignSystem.swift`.
- Do not introduce new one-off colors, radii, shadows, spacing scales, button styles, card styles, or layout helpers directly inside feature views.
- Do not reinvent the wheel. Before adding a new UI primitive, helper, layout, interaction, formatting path, or store behavior, first search for an existing native SwiftUI control, design-system component, shared helper, or established feature pattern that already solves it. Reuse or extend the existing pattern unless there is a clear product reason not to.
- Do not introduce a new design style without explicit user approval. New visual languages, layout paradigms, animation styles, button treatments, card treatments, icon systems, color directions, or navigation patterns must be proposed and approved before implementation. Small refinements inside the current warm iOS-native Baking design system are fine when they reuse approved tokens and components.
- Never hard-code user-visible magic strings in feature, model, or store code. All UI labels, accessibility labels, empty states, alerts, default display names, and formatted copy must go through `BakingJournal/Localization/L10n.swift` / `BakingTerms` and have entries in every supported `Localizable.strings` file.
- When adding or changing user-facing text, add stable localization keys instead of relying on Chinese source text as a key. Raw persisted enum IDs or internal identifiers may remain nonlocalized, but display text must be localized at the boundary.
- Feature views should compose existing native SwiftUI primitives plus the shared Baking components. If a screen needs a new visual primitive, ask for approval before adding it.
- Prefer small reusable components when the same surface, input treatment, metric cell, dropdown row, flow layout, or swipe behavior appears more than once.
- Keep model/store logic outside views. Views may bind to `RecipeStore`, but calculations that can be named as product behavior belong in the store or model helpers.
- Avoid growing large feature files by adding unrelated helper components at the bottom. New reusable components go into the design system or a clearly named shared component file.
- Keep `FormulaView.swift` as a screen-level orchestrator. Follow `FORMULA_REFACTOR_PLAN.md` for formula workflow file ownership.

## Verification

- After making code changes, always run a real project build before finishing the task.
- Prefer `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme BakingJournal -project BakingJournal.xcodeproj -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build` for repo-level verification.
- Do not stop at `swiftc -parse`, `plutil`, or reasoning-only checks if a full build is available.
- If the full build cannot be run, explicitly say why and report the best verification you were able to complete.

## Component Contract

- `Color.brand*`, `Color.water*`, and material palettes are the only approved semantic colors.
- `BakingSpace`, `BakingRadius`, `BakingMotion`, and `BakingTouchTarget` are the approved spacing, radius, motion, and touch-size tokens.
- `BakingToolbarIconButton` and `BakingSystemIconButtonLabel` are the approved action-button labels. Action buttons must be icon-only in visible UI and must set an `accessibilityLabel`.
- Bottom navigation and app navigation controls must be icon-only in visible UI. Do not add explanatory tab/button text; use localization-backed `accessibilityLabel` text for VoiceOver.
- Do not introduce visible top back/home navigation for app-managed routes unless the user explicitly approves an exception. Use the global swipe-history pattern for back/forward navigation.
- Text may appear inside native controls when the control is inherently textual, such as `Picker`, `TextField`, `LabeledContent`, `Section`, tab labels, menus, system alerts, or form rows. Do not use text, icon+text, or custom pill buttons for commands unless explicitly approved.
- `bakingCard(...)` is the approved card/surface treatment. `bakingFieldSurface(...)` is the approved editable inline field treatment.
- `BakingDropdownTrigger`, `BakingDropdownPopover`, and `BakingDropdownRow` are the approved dropdown pattern.
- `BakingFlowLayout` and `BakingSwipeToDeleteRow` are the approved custom layout and custom swipe-delete helpers.
- Vertical scrolling is the highest-priority gesture across the app. Custom horizontal swipes, slide actions, long-press reordering, or drag interactions must use `BakingGesturePolicy` so vertical scroll intent cancels local gestures before they update UI state.
- Global history swipe must not be implemented as a hit-testing SwiftUI overlay or root `DragGesture`, because that can steal touches from nested `ScrollView`s. Use the existing non-hit-testing UIKit pan observer pattern so vertical scroll remains fluid.
- Existing approved tokens and shared components are the source of truth. Global consistency fixes should update the shared design system first, then migrate feature screens to the shared API instead of patching each screen independently.
- Reuse the established recipe-workflow spacing values before introducing new ones. Treat `14pt` horizontal card inset and the existing formula-page card stack rhythm as the default reference for sibling workflow screens.
