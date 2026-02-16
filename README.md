# AS Pixel Color v2.3

[![AutoHotkey](https://img.shields.io/badge/Language-AutoHotkey_v2-green.svg)](https://www.autohotkey.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-GPL_v3-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.3-brightgreen.svg)](https://github.com/akcansoft/Pixel-Color/releases) 

![GitHub stars](https://img.shields.io/github/stars/akcansoft/Pixel-Color?style=social)
![GitHub forks](https://img.shields.io/github/forks/akcansoft/Pixel-Color?style=social)
![GitHub issues](https://img.shields.io/github/issues/akcansoft/Pixel-Color)
[![Downloads](https://img.shields.io/github/downloads/akcansoft/Pixel-Color/total)](https://github.com/akcansoft/Pixel-Color/releases)

**AS Pixel Color** is a professional, open-source real-time pixel color analysis tool built with [AutoHotkey](https://www.autohotkey.com) v2. It provides detailed pixel inspection, multiple color formats, and practical tools for designers, developers, and digital artists.

![App Screen Shot](/docs/app_screen_shot_1.png)

## 🌟 Key Features

- **GDI+ Pixel Zoom Preview:** Inspect screen pixels in detail with a real-time zoom preview from **2x to 72x**.
- **DPI-Aware Sampling:** Uses per-monitor DPI awareness and physical-coordinate capture for more reliable color picking on mixed-DPI multi-monitor setups.
- **Active Pixel Highlighting:** The center pixel is marked with a high-contrast double border (black + white) for clear visibility.
- **Grid Control:** Enable or disable grid lines in the zoom preview with a single checkbox.
- **Extensive Color Format Support:** HEX, DEC, RGB, RGB (%), RGBA, BGR, CMYK, HSL, and HSV.
- **Color Name Recognition:** Detects standard named colors (for example, AliceBlue, Crimson) instantly.
- **Detailed RGB Analysis:** Displays channel values in both numeric form and visual progress bars.
- **Fast, Efficient Rendering:** Refresh logic updates only when position, color, or zoom changes, with a bitmap-based capture/render pipeline.
- **User-Friendly Controls:**
  - One-click copy buttons for every color format.
  - `Update (F1)` toggle to pause/resume real-time tracking.
  - `Zoom` toggle to quickly show/hide zoom-related controls.
  - `Always on Top`, `About`, and `Close` controls.

## ⌨️ Shortcuts and Usage

1. **Track Motion:** Move the mouse anywhere on screen to inspect the current pixel in real time.
2. **Pause/Resume Updates:** Press <kbd>F1</kbd> to toggle live updates.
3. **Precision Mouse Move:**
   - <kbd>Ctrl</kbd> + <kbd>Arrow Keys</kbd>: move the cursor by **1 pixel**.
   - <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Arrow Keys</kbd>: move the cursor by **10 pixels**.
4. **Adjust Zoom:**
   - Use the **Mouse Wheel** to increase/decrease zoom.
   - Use the **Zoom Slider** for direct level selection.
5. **Toggle Zoom/Grid:**
   - Use the **Zoom** checkbox to show/hide zoom preview and controls.
   - Use **Grid lines** to switch grid overlay on/off.
6. **Copy Values:** Click any `Copy` button to send the selected value to clipboard.
7. **Exit:** Use **Close** (or close the window) to terminate the app.

## 🛠️ Technical Setup

### Standalone Version (.exe)

Download and run the `.exe` file for your system from the [releases](https://github.com/akcansoft/Pixel-Color/releases) page.

### Running from Source

1. Install [AutoHotkey v2](https://www.autohotkey.com).
2. Download the source `.ahk` file and `app_icon.ico` from the [src/](https://github.com/akcansoft/Pixel-Color/tree/main/src) folder.
3. Place required files in the same directory.
4. Run the script by double-clicking the `.ahk` file.

## 📝 Version History

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
