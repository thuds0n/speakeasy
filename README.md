# Speakeasy

A lightweight macOS utility that hides menu bar items — keeping your menu bar clean without giving anything up.

Built for Macs with a notch, or anyone who just has too many menu bar icons.

---

## How it works

Speakeasy inserts invisible separators into your menu bar that push items off to the left. A small chevron button lets you reveal or collapse them at any time.

```
[ always-hidden ] | [ hidden items ] › [ visible items ]    wifi  9:41
```

- **Shown** — always visible to the right of the collapse button
- **Hidden** — collapse/expand with one click or a global shortcut
- **Always Hidden** — permanently hidden; reveal with a right-click

---

## Requirements

macOS 13 Ventura or later · Apple Silicon or Intel

---

## Installation

Clone and build in Xcode:

```
git clone https://github.com/thuds0n/speakeasy.git
cd speakeasy
open "Speakeasy.xcodeproj"
```

Build and run the **Speakeasy** scheme. The app lives in your menu bar — no dock icon.

---

## Usage

| Action | How |
|--------|-----|
| Collapse / expand hidden items | Click the **›** button in your menu bar |
| Toggle via keyboard | Set a global shortcut in **Preferences → General** |
| Move items between sections | Hold **⌘** and drag icons in the menu bar |
| Hide an item permanently | ⌘-drag it to the left of the always-hidden separator |
| Auto-collapse after a delay | Enable in **Preferences → Auto-Collapse** |

---

## Preferences

Open with **›** right-click → Preferences, or via your configured global shortcut.

- **Startup** — launch at login, show preferences on launch
- **Menu Bar** — enable always-hidden section, use full menu bar when expanded
- **Auto-Collapse** — automatically collapse after 5 s – 1 min of inactivity
- **Global Shortcut** — set a system-wide keyboard shortcut to toggle hidden items

---

## Credits

Speakeasy is a fork of [Hidden Bar](https://github.com/dwarvesf/hidden) by [Dwarves Foundation](https://github.com/dwarvesf), used under the MIT license.
