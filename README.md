# AS Pixel Color v2.5

[![AutoHotkey](https://img.shields.io/badge/Language-AutoHotkey_v2-green.svg)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-GPL_v3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.5-brightgreen.svg)](https://github.com/akcansoft/Pixel-Color/releases) 

![GitHub stars](https://img.shields.io/github/stars/akcansoft/Pixel-Color?style=social)
![GitHub forks](https://img.shields.io/github/forks/akcansoft/Pixel-Color?style=social)
![GitHub issues](https://img.shields.io/github/issues/akcansoft/Pixel-Color)
[![Downloads](https://img.shields.io/github/downloads/akcansoft/Pixel-Color/total)](https://github.com/akcansoft/Pixel-Color/releases)

**AS Pixel Color** is a professional, open-source real-time pixel color analysis tool built with [AutoHotkey](https://www.autohotkey.com) v2. It provides detailed pixel inspection, multiple color formats, and practical tools for designers, developers, and digital artists.

![App Screen Shot](/docs/app_screen_shot_1.png)

## 🌟 Key Features

- **Integrated Color Palette:** Save sampled colors to a persistent palette. Supports up to 52 colors with automatic persistence across sessions.
- **Smart Palette Management:** Automatically prevents duplicate colors and includes a "Sort" feature to organize colors by perceptual luminance (dark to light).
- **Modern Menu Bar Interface:** Quick access to all features via a structured menu system (File, Settings, Palette, Help).
- **GDI+ Pixel Zoom Preview:** Inspect screen pixels in detail with a real-time zoom preview from **2x to 72x**.
- **DPI-Aware Sampling:** Uses per-monitor DPI awareness and physical-coordinate capture for precise color picking on mixed-DPI multi-monitor setups.
- **Active Pixel Highlighting:** The center pixel is marked with a high-contrast double border (black + white) for clear visibility.
- **Flexible UI Controls:** Toggle Zoom, Grid lines, and Auto-Update via checkboxes or the menu bar.
- **Extensive Color Format Support:** HEX, DEC, RGB, RGB (%), RGBA, BGR, CMYK, HSL, and HSV.
- **Color Name Recognition:** Detects standard named colors (e.g., AliceBlue, Crimson) instantly.
- **Detailed RGB Analysis:** Displays channel values numerically and with visual progress bars that change color based on intensity.
- **Configurable Hotkeys:** F1/F2 shortcut keys can be customized via `settings.ini`.
- **Unified Settings Persistence:** All settings (zoom, grid, auto-update, always-on-top) and the palette are saved and restored from a single `settings.ini` file.
- **Keyboard Shortcuts Dialog:** View all active shortcuts at a glance via Help → Keyboard Shortcuts.
- **Precision Shortcuts:** Custom hotkeys for micro-movements and quick actions, scoped to the main window to avoid conflicts.

## ⌨️ Shortcuts and Usage

1. **Track Motion:** Move the mouse anywhere on screen to inspect the current pixel in real time.
2. **Pause/Resume Updates:** Press <kbd>F1</kbd> to toggle live updates (or use the Update checkbox/menu).
3. **Save Color to Palette:** Press <kbd>F2</kbd> (or use the Add button/menu) to save the current color.
4. **Precision Mouse Move** *(main window must be active)*:
   - <kbd>Ctrl</kbd> + <kbd>Arrow Keys</kbd>: Move the cursor by **1 pixel**.
   - <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Arrow Keys</kbd>: Move the cursor by **10 pixels**.
5. **Adjust Zoom:**
   - Use the **Mouse Wheel** to increase/decrease zoom.
   - Use the **Zoom Slider** for direct level selection.
6. **Toggle Zoom/Grid:**
   - Use the **Zoom** checkbox/menu to show/hide zoom preview.
   - Use **Grid lines** checkbox/menu to switch grid overlay on/off.
7. **Copy Values:** Click any `Copy` button to send the selected value to clipboard.
8. **View Shortcuts:** Use **Help → Keyboard Shortcuts** to see all active key bindings.

> **Note:** F1 and F2 hotkeys are configurable via `settings.ini` (`[Hotkeys]` section). They are scoped to the main window and do not conflict with other applications.

## 🛠️ Technical Setup

### Standalone Version (.exe)

Download and run the `.exe` file for your system from the [releases](https://github.com/akcansoft/Pixel-Color/releases) page.

### Running from Source

1. Install [AutoHotkey v2](https://www.autohotkey.com).
2. Download the source `AS Pixel Color.ahk`, `color_names.ahk` and `app_icon.ico` files from the [src/](https://github.com/akcansoft/Pixel-Color/tree/main/src) folder.
3. Place required files in the same directory.
4. Run the script by double-clicking the `AS Pixel Color.ahk` file.

## 📝 Version History

- **v2.5 (2026-02-20):**
  - Replaced `palette.txt` with a unified `settings.ini` file that persists **all** application state: zoom level, zoom/grid/auto-update/always-on-top toggles, and the color palette.
  - Added **configurable hotkeys**: F1 (Toggle Update) and F2 (Add Color) can now be reassigned via `settings.ini` under the `[Hotkeys]` section.
  - Added **Keyboard Shortcuts** dialog (Help → Keyboard Shortcuts) showing all active key bindings.
  - Scoped F1/F2 hotkeys to the main window only (no longer global), preventing conflicts with other applications.
  - Arrow-key precision movement hotkeys also scoped to main window active state.

- **v2.4 (2026-02-17):**
  - Added **Color Palette system** with persistence (`palette.txt`).
  - Implemented **Duplicate Prevention** and **Luminance Sorting** for the palette.
  - Added a **Comprehensive Menu Bar** for better feature accessibility.
  - Expanded UI layout to accommodate the palette and improved control grouping.
  - Added <kbd>F2</kbd> shortcut for adding colors to the palette.
  - Refactored technical core with a centralized `CONFIG` object.
- **v2.3 (2026-02-16):**
  - Added DPI-aware capture flow with physical cursor/pixel sampling support.
  - Refactored screen capture and zoom rendering to a bitmap-based, nearest-neighbor pipeline.
  - Improved edge behavior by capturing an extra ring and safely filling out-of-screen regions.
  - Updated zoom step set to **2x-72x** with refined progression.
  - Updated UI controls: dedicated `Zoom` toggle placement and `About` button.
  - Kept refresh performance optimized with change-driven updates and render locking.
- **v2.2 (2026-02-14):**
  - Added a `Grid lines` toggle for the zoom preview.
  - Reworked zoom system with predefined zoom steps and improved slider/mouse-wheel behavior.
  - Improved preview logic to keep an adaptive visible area and more stable centering.
  - Improved multi-monitor and screen-edge capture safety.
  - Refactored update flow with centralized APP/State objects and render lock.
  - Optimized refresh behavior to redraw only when position/color/zoom changes.
  - Improved color conversion flow by reusing shared HSX calculations.
- **v2.1 (2026-02-13):**
  - Added high-contrast active pixel highlighting.
  - Added precision keyboard shortcuts for 1px and 10px cursor movement.
  - Refactored grid updates for smoother performance.
- **v2.0 (2026-02-12):**
  - Introduced GDI+ advanced zoom grid.
  - Added HSL, HSV, and CMYK color formats.
  - Added color name identification.
  - Redesigned and modernized UI.
  - Added mouse wheel zoom control.
- **v1.4 (2025-05-04):**
  - Code optimization and performance improvements.
- **v1.3 (2024-04-18):**
  - Added `Always on Top` option and tray icon adjustments.
- **v1.0 (2024-03-20):**
  - Initial release.

## 👤 Author

**Mesut Akcan**  
Email: [makcan@gmail.com](mailto:makcan@gmail.com)  
Blog: [akcanSoft Blog](https://akcansoft.blogspot.com) | [Mesut Akcan Blog](https://mesutakcan.blogspot.com)\
YouTube: [YouTube Channel](https://www.youtube.com/mesutakcan)

## 🤝 Contributing

Contributions are welcome. Open a [pull request](https://github.com/akcansoft/Pixel-Color/pulls) or submit an [issue](https://github.com/akcansoft/Pixel-Color/issues) to suggest features or report bugs.
