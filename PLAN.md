# Speakeasy — Roadmap

Living document. Phases are appended; completed work stays for context. See [STRUCTURE.md](STRUCTURE.md) for the codebase map.

## Phase 1 — Rebrand & restructure  ✅ shipped

Landed in commits `69ee069` (rebrand + SwiftUI preferences + modularisation) and `2f90500` (drop hardcoded user/team refs).

- Forked Hidden Bar → renamed to Speakeasy.
- Migrated preferences from XIB-based AppKit to SwiftUI (`@main App` + `Settings` scene).
- Split flat source layout into `Application/` / `Core/` / `Features/` / `Shared/`.
- Replaced `StatusBarController` with `StatusBarCoordinator` + `StatusBarItemManager` + `AutoCollapseTimer`.

## Phase 2 — Modernisation polish  ✅ shipped with this pass

Goal: fix defects left by the restructure and finish modernising patterns within the macOS 13 deployment target.

- **Defects** — URL force-unwrap in `AboutView`, `isShowPreferences` string typo (with legacy-key migration), missing `@MainActor` on `StatusBarItemManager`, `NSLog` → `os.Logger` in `LaunchAtLoginService`, stringly-typed `showSettingsWindow:` selector centralised into `NSApplication+Settings.swift`.
- **Patterns** — `DispatchQueue.main.asyncAfter` replaced with `Task` + `Task.sleep(for:)` in `StatusBarCoordinator`; `SettingsStore` persistence boilerplate collapsed into a generic `persist(_:to:)` helper; `HotKeyServicing` protocol introduced for parity with `LaunchAtLoginControlling`; `GlobalKeybindPreferences.from(event:...)` factory extracted to remove duplication in `ShortcutRecorderView`; magic constants in `StatusBarItemManager.Lengths` documented with rationale.
- **Docs** — `STRUCTURE.md` and this file created.
- **Tests** — source files in `SpeakeasyTests/` cover `SettingsStore` (persistence, migration), `GlobalKeybindPreferences` (description + Codable), and the `HotKeyServicing` protocol.

## Phase 3 — Test foundation & activation stability  ✅ completed 2026-08-08

- Registered the `SpeakeasyTests` unit-test bundle and added it to the shared scheme's test action.
- Introduced `ApplicationActivationControlling` so activation-policy changes are explicit and testable.
- Fixed full-menu-bar mode remaining active after its setting was disabled while expanded.
- Fixed auto-collapse and activation subscribers reading the previous `@Published` value.
- Made legacy preference migration distinguish persisted values from registered defaults.
- Added activation-policy and auto-collapse regression coverage; the suite now contains 19 passing tests.

Local and CI verification command:
```
set -o pipefail && xcodebuild -project "Speakeasy.xcodeproj" -scheme "Speakeasy" \
  -destination 'platform=macOS' test | xcbeautify
```

## Phase 4 — Complete Xcode rebrand  ✅ completed 2026-08-08

- Renamed the Xcode project, application target, shared scheme, app product, and Swift module to `Speakeasy`.
- Renamed and corrected the application entitlement path to `hidden/Speakeasy.entitlements`.
- Removed the obsolete launcher scheme, unreferenced storyboard localisation files, and dangling framework references.
- Updated test imports and developer build instructions for the renamed module and scheme.
- Verified all 19 tests pass and the unsigned arm64 Debug build produces `Speakeasy.app`.

## Backlog

Deliberately deferred, with context so future contributors know why each one is parked rather than forgotten.

- **`@Observable` migration for `SettingsStore`.** Blocked by macOS 13 target (requires macOS 14+). Revisit when the deployment target is raised.
- **SwiftUI rewrite of `ShortcutRecorderView`.** Blocked on macOS 14+ `KeyPress` modifier; the current `NSViewRepresentable` is the right call for macOS 13.
- **Broader `StatusBarCoordinator` timing tests.** Activation-policy transitions are covered. Cooldown and auto-collapse timing still require injecting a `Clock` / test scheduler and replacing `Task.sleep` with `clock.sleep`.
- **Continuous integration.** Add an arm64 macOS workflow that runs the shared scheme's build and test actions.
- **Launch-at-login reconciliation.** Read `SMAppService.status`, reflect approval/failure states in settings, and avoid treating the persisted toggle as authoritative.
- **`NSApp.activate(ignoringOtherApps:)` → `NSApp.activate()`.** The new API is macOS 14+. Swap when the target moves.
- **Replace `openSettingsWindow:` private selector with `SettingsLink`.** Same macOS 14+ block; centralised in `NSApplication+Settings.swift` so the migration is one edit.
- **App-wide DI container / service registry.** Not needed at current scale — `AppDelegate` is a clear composition root. Revisit if the service list grows past ~5.
- **UI snapshot tests for the preferences pane.** Out of scope for now; the SwiftUI layer is thin and changes rarely. Consider `swift-snapshot-testing` if preference UX becomes a regression hotspot.
- Configurable presets (e.g. Development shows coding related ones)
- Set a default configuration of menu bar items that the system returns to when speakeasy is closed.

## Updating this doc

When a phase ships, mark it complete with the date/commit and move any deferred items into Backlog with a one-line reason. Keep the file scannable — if it grows past ~150 lines, split earlier phases into an `ARCHIVE.md`.
