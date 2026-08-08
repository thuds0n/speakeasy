# Speakeasy — Codebase Structure

A map of the repository. Start here before editing unfamiliar areas. For in-flight work and the roadmap, see [PLAN.md](PLAN.md).

## Layout

```
hidden/
├── Application/              — App entry point + AppDelegate
│   ├── SpeakeasyApp.swift        SwiftUI @main, declares the Settings scene
│   └── AppDelegate.swift         Owns SettingsStore, coordinator, and services
│
├── Core/                     — Framework-agnostic logic (no AppKit in Core/Settings)
│   ├── Settings/
│   │   ├── SettingsStore.swift               @Published state + UserDefaults persistence
│   │   └── GlobalKeybindingPreferences.swift Codable shortcut model
│   └── Services/
│       ├── ApplicationActivationService.swift  Switches between menu-extra-only and full-menu-bar modes
│       ├── HotKeyService.swift               Wraps soffes/HotKey. Exposes HotKeyServicing protocol
│       └── LaunchAtLoginService.swift        Wraps SMAppService. Exposes LaunchAtLoginControlling protocol
│
├── Features/                 — User-facing feature modules
│   ├── Preferences/              SwiftUI settings pane
│   │   ├── PreferencesView.swift             TabView container
│   │   ├── GeneralSettingsView.swift         Startup / Menu Bar / Auto-Collapse / Shortcut sections
│   │   ├── AboutView.swift                   Version info + credits
│   │   ├── MenuBarDiagramView.swift          Illustrative graphic for the always-hidden section
│   │   └── ShortcutRecorderView.swift        AppKit NSViewRepresentable for key capture
│   └── StatusBar/                Menu bar items and orchestration
│       ├── StatusBarCoordinator.swift        Orchestrator — listens to settings, drives items
│       ├── StatusBarItemManager.swift        Pure NSStatusItem plumbing (collapse/expand/separator)
│       └── AutoCollapseTimer.swift           One-shot Timer wrapper
│
└── Shared/                   — Cross-cutting utilities
    ├── Assets.swift                          RTL-aware image lookup
    └── Extensions/
        ├── Bundle+Extension.swift            releaseVersionNumber / buildVersionNumber
        ├── String+Extension.swift            .localized helper
        ├── UserDefault+Extension.swift       Type-safe UserDefaults.Key enum (+ Legacy)
        ├── NSApplication+Settings.swift      openSettingsWindow() — centralises private selector
        └── GlobalKeybindPreferences+NSEvent.swift  Factory from NSEvent (kept out of Core)
```

External dependencies (Swift Package Manager):
- [soffes/HotKey](https://github.com/soffes/HotKey) — global hotkey registration via Carbon.
- `ServiceManagement` (system) — `SMAppService` for launch-at-login.

## Entry-point trace

```
SpeakeasyApp (@main, SwiftUI App)
  └─ NSApplicationDelegateAdaptor → AppDelegate
       ├─ SettingsStore                 (state + UserDefaults)
       ├─ HotKeyService : HotKeyServicing
       ├─ LaunchAtLoginService : LaunchAtLoginControlling
       └─ StatusBarCoordinator          (binds to SettingsStore via Combine)
            ├─ StatusBarItemManager    (NSStatusBar items)
            └─ AutoCollapseTimer
  └─ Settings scene
       └─ PreferencesView(settings:)
```

## Where to add…

| Need | File(s) to touch |
|------|------------------|
| A new persisted setting | `SettingsStore` (property + default + `persist(_:to:)` call) and `UserDefaults+Extension.swift` (key). Bind from `StatusBarCoordinator` if it affects the menu bar. |
| A new preference pane | New SwiftUI view in `hidden/Features/Preferences/`, wire into `PreferencesView`'s `TabView`. |
| A new status-bar behaviour | `StatusBarCoordinator` (orchestration) and/or `StatusBarItemManager` (NSStatusItem mechanics). Keep AppKit plumbing in the manager; keep settings/state reactions in the coordinator. |
| A new service (external system integration) | New file under `Core/Services/` behind a protocol; inject into `AppDelegate`. Mirror `LaunchAtLoginControlling` / `HotKeyServicing`. |
| A utility used by multiple features | `Shared/` — extension files under `Shared/Extensions/`, other helpers at the top level. Do not introduce AppKit imports into `Core/`. |

## Rules of the road

- **`Core/Settings` must not import AppKit or SwiftUI.** If you need an NSEvent/NSColor helper on a Core type, put it in `Shared/Extensions/` (see `GlobalKeybindPreferences+NSEvent.swift`).
- **`@MainActor` everything that touches `NSStatusBar`, `NSApplication`, or SwiftUI state.** The coordinator and its collaborators are already `@MainActor`; keep it that way.
- **Services are protocol-based.** `ApplicationActivationControlling`, `HotKeyServicing`, `LaunchAtLoginControlling`. Add a protocol before adding a new service.
- **Keep the Settings scene free of business logic.** All reactions to state changes live in `StatusBarCoordinator.bindSettings()`.
