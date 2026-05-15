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
