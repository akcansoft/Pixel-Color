# AS Pixel Color v2.1

**AS Pixel Color** is a professional, open-source real-time pixel color analysis tool developed with [AutoHotkey](https://www.autohotkey.com) v2. It provides a comprehensive set of color formats and analysis tools for designers, developers, and digital artists.

![App Screen Shot](/docs/app_screen_shot_1.png)

## 🌟 Key Features

- **GDI+ Powered Pixel Zoom:** Examine pixels in detail with a zoom grid ranging from 3x3 to 45x45.
- **Active Pixel Highlighting:** The center pixel is highlighted with a high-contrast double border (Black & White) for optimal visibility on any background.
- **Extensive Color Format Support:**
  - HEX, DEC, RGB, RGB (Percentage), RGBA, BGR
  - CMYK (Print-ready format)
  - HSL and HSV (Digital design formats)
- **Color Name Recognition:** Instantly identifies the name of the color (e.g., AliceBlue, Crimson) using an extensive color library.
- **Detailed RGB Analysis:** View Red, Green, and Blue components with both numerical values and visual progress bars.
- **Advanced Zoom Controls:**
  - Precision slider for zoom adjustment.
  - Mouse Wheel support for quick zooming.
  - One-click 'Reset' to the default 15x15 level.
- **User-Centric Interface:**
  - One-click copying for all color formats to the clipboard.
  - "Always on Top" mode to keep the tool visible.
  - "Update" toggle to pause/resume real-time tracking.

## ⌨️ Shortcuts and Usage

1. **Track Motion:** Move your mouse over any part of the screen to see real-time color data.
2. **Toggle Update:** Press <kbd>F1</kbd> to pause or resume the real-time color tracking.
3. **Precision Mouse Control:**
    - <kbd>Ctrl</kbd> + <kbd>Arrow Keys</kbd>: Move mouse by **1 pixel**.
    - <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Arrow Keys</kbd>: Move mouse by **10 pixels**.
4. **Zoom Controls:**
    - Rotate the **Mouse Wheel** up/down to change the zoom level.
    - Use the **Slider** for manual adjustment.
    - **Keyboard Shortcuts** (when Slider is focused):
        - <kbd>Arrow Keys</kbd>: Fine adjustment (+/- 1 step).
        - <kbd>PageUp</kbd> / <kbd>PageDown</kbd>: Coarse adjustment (+/- one large step).
        - <kbd>Home</kbd> / <kbd>End</kbd>: Jump to Min/Max zoom.
    - Click **Reset** to return to 15x15 zoom.
5. **Copy to Clipboard:** Click the `Copy` button next to any format to copy its value instantly.
6. **Exit:** Click the `Close` button or close the window to exit.

## 🛠️ Technical Setup

### Standalone Version (.exe)

Download and run the `.exe` file appropriate for your system from the [releases](https://github.com/akcansoft/Pixel-Color/releases) page.

### Running from Source

To use the source code:

1. Ensure [AutoHotkey v2](https://www.autohotkey.com) is installed on your system.
2. Download `AS Pixel Color.ahk` and `app_icon.ico` from the [src/](https://github.com/akcansoft/Pixel-Color/tree/main/src) folder and place them in the same directory.
3. Run the script by double-clicking the `.ahk` file.

## 📝 Version History

- **v2.1 (2026-02-13):**
  - **Active Pixel Highlighting:** Added a high-contrast double border to the center pixel.
  - **Precision Control:** Added keyboard shortcuts for 1px and 10px mouse movement.
  - **Performance:** Refactored grid update logic for smoother performance.
- **v2.0 (2026-02-12):**
  - Implementation of GDI+ advanced zoom grid.
  - Added HSL, HSV, and CMYK color formats.
  - Added Color Name identification feature.
  - Completely redesigned and modernized UI.
  - Added Mouse Wheel support for zoom control.
- **v1.4 (2025-05-04):**
  - Code optimization and performance improvements.
- **v1.3 (2024-04-18):**
  - Added "Always on Top" checkbox and tray icon adjustments.
- **v1.0 (2024-03-20):**
  - Initial release.

## 👤 Author

**Mesut Akcan**  
📧 [makcan@gmail.com](mailto:makcan@gmail.com)  
🌐 [akcanSoft Blog](https://akcansoft.blogspot.com)  
🎥 [YouTube Channel](https://www.youtube.com/mesutakcan)  

## 🤝 Contributing

Contributions are welcome! Feel free to open a [pull request](https://github.com/akcansoft/Pixel-Color/pulls) or submit an [issue](https://github.com/akcansoft/Pixel-Color/issues) on GitHub to suggest features or report bugs.
