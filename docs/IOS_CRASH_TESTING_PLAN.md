# iOS Crash Testing Plan

## Goal

Build a repeatable way to catch random SwiftUI crashes, freezes, gesture conflicts, and scroll lockups before we ship changes.

This is not unit testing. The first layer should be UI / E2E stress testing because the current failures are caused by the interaction between SwiftUI views, gestures, popovers, navigation, scrolling, drag/drop, and app state.

## Testing Layers

- Unit tests: Validate pure logic, such as converting `300 g` water into an allocation percentage.
- Integration tests: Validate store/model/data flow, such as saving and reloading recipes.
- UI / E2E stress tests: Drive the app like a user and repeat fragile flows until crashes or hangs appear.
- Crash reporting: Capture real-device crash stack traces and breadcrumbs after the app is used outside Xcode.

## Recommended First Step

Start with XCUITest UI stress tests.

Reasons:

- The current bugs are random UI hangs, scroll failures, popover issues, and gesture conflicts.
- Unit tests will not catch SwiftUI gesture/layout instability.
- Crash reporting is useful later, but it does not prevent regressions locally.
- XCUITest can repeatedly perform the same risky flows and make random bugs easier to reproduce.

## Proposed UI Stress Scenarios

### Steps Page Scroll Stability

Open a seeded recipe with many steps, enter the steps page, and repeatedly swipe up/down from the middle of step cards.

Acceptance criteria:

- The list scrolls from top to bottom and back.
- The app does not freeze.
- Step cards do not steal vertical scroll.
- No crash occurs.

### Tab Switching Stability

Repeatedly switch between home tabs: recipes, bake history, starter.

Acceptance criteria:

- Navigation titles appear immediately.
- No blank title delay.
- No layout freeze or crash.

### Material Assignment Popover

Open the material assignment popover, choose a material, edit the gram amount directly, confirm, close, reopen.

Acceptance criteria:

- Gram input updates percentage correctly.
- Confirming saves the allocation.
- Reopening shows the expected state.
- No invalid layout crash or freeze occurs.

### Repeated Popover Open / Close

Repeatedly open and close duration, material, and notes controls.

Acceptance criteria:

- Popovers dismiss correctly.
- Keyboard does not trap scroll.
- No `Invalid frame dimension` crash.
- No UI lockup.

## Test Data Setup

Add UI-test-only launch arguments later:

- `UITEST_RESET_STATE`: clears persisted app state at launch.
- `UITEST_SEED_STRESS_RECIPE`: creates a deterministic recipe with many materials and steps.

These must only run during UI tests and must not affect normal user launches.

## Future Test Command

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project BakingJournal.xcodeproj \
  -scheme BakingJournal \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BakingJournalUITests
```

For random crash reproduction:

```bash
for i in {1..20}; do
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
    -project BakingJournal.xcodeproj \
    -scheme BakingJournal \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:BakingJournalUITests || break
done
```

## Simulator Log Triage

Likely simulator/system noise:

- `IOSurfaceClientSetSurfaceNotify failed`
- `Failed to send CA Event for app launch measurements`
- `UIAccessibilityLoaderWebShared is implemented in both...`
- keyboard haptic pattern library missing

App-owned issues to investigate:

- Custom UTType warnings, such as missing `com.openbakery.toastmark.step-material`.
- `Invalid frame dimension`
- Scroll locking after gestures/popovers.
- App freezes or crashes during repeatable user flows.

## Assumptions

- We are not implementing the tests yet.
- We are not adding Crashlytics, Sentry, or MetricKit yet.
- The first implementation should prioritize local reproducibility of UI hangs and random SwiftUI crashes.
