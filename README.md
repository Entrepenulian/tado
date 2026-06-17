<div align="center">

# tado

**A native macOS menu-bar to-do list, built with Liquid Glass.**

Capture a task, check it off, get on with your day — all from the menu bar, never leaving what you're doing.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-MenuBarExtra-blue)
![Liquid Glass](https://img.shields.io/badge/design-Liquid%20Glass-FF6A1A)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

## Screenshots

> Coming soon.

<!--
![tado panel](docs/panel.png)
![tado menu bar](docs/menubar.png)
-->

## Features

- **Quick capture** — the input auto-focuses the moment you open the panel; type, hit Return, done.
- **Satisfying check-off** — the checkmark fills and the title strikes through in place, then the row glides down into Completed a beat later.
- **Drag to reorder** — press and drag any active task; a floating glass copy follows your cursor and an accent line shows where it'll land.
- **Completed shelf** — finished tasks collapse into their own section, sorted by when you finished them. Clear them in one tap.
- **Live menu-bar count** — the number of tasks still to do sits right next to the icon and ticks down as you go.
- **Persistent** — everything is saved locally, so your list survives quits and restarts.
- **Menu-bar only** — no dock icon, no clutter (`LSUIElement`).

## Liquid Glass

Every surface — the add field, the list, the empty state — renders with Apple's **Liquid Glass** (`glassEffect`) on macOS 26, with an automatic `.regularMaterial` fallback on earlier systems. The whole UI is native SwiftUI with **zero third-party dependencies**: SF Symbols, SF Pro Rounded, system materials, and a single accent color (`#FF6A1A`).

## Requirements

- macOS 14.0 or later (Liquid Glass visuals light up on macOS 26+)
- Xcode 26 to build

## Build & Run

```bash
git clone https://github.com/Entrepenulian/tado.git
cd tado
open LiquidTodo.xcodeproj
```

Then press **⌘R** in Xcode. The checklist icon appears in your menu bar — click it to open tado.

Prefer the command line:

```bash
xcodebuild -project LiquidTodo.xcodeproj -scheme LiquidTodo -configuration Release build
```

## How it works

| File | Responsibility |
| --- | --- |
| `LiquidTodoApp.swift` | App entry point — the `MenuBarExtra` scene and its icon + live count |
| `MenuView.swift` | The panel: header, list, drag-and-drop, completed section, footer |
| `TodoRow.swift` | A single task row with hover, press, and check states |
| `AddBar.swift` | The auto-focusing glass input |
| `GlassEffect.swift` | The `liquidGlass(cornerRadius:)` surface modifier |
| `TodoStore.swift` | State + ordering + persistence (`UserDefaults`, JSON) |
| `TodoItem.swift` | The task model |

## Privacy

tado stores your tasks locally in `UserDefaults` on your Mac. Nothing leaves your machine — no accounts, no network, no analytics.

## License

[MIT](LICENSE)
