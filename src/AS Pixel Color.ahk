/*
AS Pixel Color
20/02/2026

AS Pixel Color is a sophisticated, lightweight color sampling utility designed for developers
and digital artists who require pixel-perfect precision.
It features a high-performance GDI+ zoom preview with a customizable grid, allowing users to
capture screen colors in real-time across multiple formats including HEX, RGB, CMYK, and HSL.
The application includes advanced features such as perceptual luminance-based palette sorting,
integrated color naming, and full DPI awareness, providing a seamless and professional workflow
for managing and organizing color data directly from any Windows display.

Mesut Akcan
-----------
github.com/akcansoft
mesutakcan.blogspot.com
youtube.com/mesutakcan
*/

#Requires AutoHotkey v2+
#SingleInstance Force

; ========================================
; COMPILER DIRECTIVES
; ========================================
;@Ahk2Exe-SetName AS Pixel Color
;@Ahk2Exe-SetDescription AS Pixel Color
;@Ahk2Exe-SetFileVersion 2.5
;@Ahk2Exe-SetCompanyName AkcanSoft
;@Ahk2Exe-SetCopyright ©2026 Mesut Akcan
;@Ahk2Exe-SetMainIcon app_icon.ico

; ========================================
; IMPORTS
; ========================================
#Include "color_names.ahk"

; ========================================
; TRAY ICON
; ========================================
; Set tray icon while running as script (ignored in compiled EXE)
;@Ahk2Exe-IgnoreBegin
try TraySetIcon(A_ScriptDir "\app_icon.ico")
;@Ahk2Exe-IgnoreEnd

; ========================================
; SETTINGS AND STATE
; ========================================
global APP := {
    Name: "AS Pixel Color",
    Ver: "2.5",
    Interval: 100,          ; Update interval (ms)
    DefIdx: 6,              ; Default zoom index
    IniFile: A_ScriptDir "\settings.ini"
}

global CONFIG := {
    Hotkeys: {
        Update: "F1", ; Default Update keyboad shortcut
        AddColor: "F2" ; Default Add color to palette keyboad shortcut
    },
    Ctl: {
        X: 10,  ; Control X position
        Y: 10,  ; Control Y position
        W: 216, ; Control Width
        H: 135  ; Control Height
    },
    Colors: {
        Grid: 0xFFBCBCBC,           ; Grid line color
        edtBg: "BackgroundFFFFF0" ; Edit background color
    },
    Zoom: [2, 3, 4, 5, 6, 7, 8, 11, 14, 17, 22, 28, 35, 45, 57, 72], ; Zoom levels (multipliers)
    Palette: {
        CellSize: 25, ; Palette cell size
        Gap: 2,       ; Palette cell gap
        Cols: 4       ; Palette columns
    },
    Layout: {
        MidX: 240,    ; Middle panel X offset
        MidW: 280,    ; Middle panel / Group box width
        RightX: 530,  ; Right panel X offset
        RightW: 130,    ; Right panel / Palette width
        palStartX: 540, ; Starting X position for palette cells
        palStartY: 95   ; Starting Y position for palette cells
    }
}

global State := {
    AutoUpdate: true,                   ; Whether to automatically update color info based on mouse movement
    AlwaysOnTop: true,                  ; Whether the window should stay on top of others
    ZoomIdx: APP.DefIdx,                ; Current zoom index in the ZoomSteps array
    ZoomLvl: CONFIG.Zoom[APP.DefIdx],   ; Current zoom level
    ZoomEnabled: true,                  ; Whether zoom preview is enabled
    GridEnabled: true,                  ; Whether grid lines are enabled
    IsRendering: false,                 ; Flag to prevent updates while rendering is in progress
    PaletteMax: 52,                     ; Maximum number of colors in the palette
    Palette: [],                        ; Palette color list (HEX without #)
    PaletteChanged: false,              ; Whether palette content changed since last save
    SortDescending: true,               ; Sorting direction toggle
    SelectedPalIdx: 0,                  ; Index of the last right-clicked palette cell
    ; Mouse position, color, and zoom level from the last update cycle
    LastX: -1, LastY: -1, LastC: -1, LastZ: -1,
    PalCtl: []                          ; Store palette swatch control references
}

global g_UsePhysicalCoords := false ; Whether to use physical coordinates for mouse/pixel capture (DPI-aware)

; Screen-based coordinates for mouse and pixel sampling
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; DPI awareness to keep mouse/pixel coordinates aligned across mixed-scale monitors.
InitDpiAwareness()

LoadSettings() ; Load settings on startup
OnExit((*) => SaveSettings()) ; Save everything on exit

; ========================================
; HOTKEYS
; ========================================

#HotIf WinActive("ahk_id " mGui.Hwnd)
; Ctrl + Arrow Keys: Move mouse 1 pixel
; Ctrl + Shift + Arrow Keys: Move mouse 10 pixels
^Up:: MoveMouse(0, -1)
^Down:: MoveMouse(0, 1)
^Left:: MoveMouse(-1, 0)
^Right:: MoveMouse(1, 0)

^+Up:: MoveMouse(0, -10)
^+Down:: MoveMouse(0, 10)
^+Left:: MoveMouse(-10, 0)
^+Right:: MoveMouse(10, 0)
#HotIf

; ========================================
; GUI CREATION
; ========================================
mGui := Gui((State.AlwaysOnTop ? "+AlwaysOnTop" : "-AlwaysOnTop"), APP.Name)
mGui.SetFont("s9", "Segoe UI")
mGui.MarginX := 10
mGui.MarginY := 10

; ==============================
; MENU
; ==============================
menuText := {
    File: "&File",
    Settings: "&Settings",
    Palette: "&Palette",
    Help: "&Help",
    Exit: "&Exit`tAlt+F4",
    ZoomPreview: "&Zoom Preview",
    GridLines: "&Grid Lines",
    AutoUpdate: "&Auto Update`t" CONFIG.Hotkeys.Update,
    AlwaysOnTop: "&Always on Top",
    AddToPalette: "&Add to palette`t" CONFIG.Hotkeys.AddColor,
    SortColors: "&Sort colors",
    Shortcuts: "&Keyboard shortcuts",
    About: "&About",
    Website: "&Website",
    GitHubRepo: "&GitHub repo"
}

; File menu
mnu_File := Menu()
mnu_File.Add(menuText.Exit, (*) => ExitApp())

; Settings menu
mnu_Settings := Menu()
mnu_Settings.Add(menuText.AlwaysOnTop, ToggleAlwaysOnTop)
mnu_Settings.Add(menuText.AutoUpdate, ToggleUpdate)
mnu_Settings.Add() ; Separator
mnu_Settings.Add(menuText.ZoomPreview, ToggleZoom)
mnu_Settings.Add(menuText.GridLines, ToggleGridLines)

; Palette menu
mnu_Palette := Menu()
mnu_Palette.Add(menuText.AddToPalette, (*) => AddColorToPalette())
mnu_Palette.Add(menuText.SortColors, (*) => SortPalette())

; Set initial checkmarks from settings
for k, v in Map(
    "ZoomEnabled", menuText.ZoomPreview,
    "GridEnabled", menuText.GridLines,
    "AutoUpdate", menuText.AutoUpdate,
    "AlwaysOnTop", menuText.AlwaysOnTop
) {
    State.%k% ? mnu_Settings.Check(v) : mnu_Settings.Uncheck(v)
}

; Help menu
mnu_Help := Menu()
mnu_Help.Add(menuText.About, About)
mnu_Help.Add(menuText.Shortcuts, ShowShortcuts)
mnu_Help.Add() ; Separator
mnu_Help.Add(menuText.Website, (*) => Run("https://mesutakcan.blogspot.com"))
mnu_Help.Add(menuText.GitHubRepo, (*) => Run("https://github.com/akcansoft/Pixel-Color"))

; Main menu
mnu_Main := MenuBar()
mnu_Main.Add(menuText.File, mnu_File)
mnu_Main.Add(menuText.Settings, mnu_Settings)
mnu_Main.Add(menuText.Palette, mnu_Palette)
mnu_Main.Add(menuText.Help, mnu_Help)
mGui.MenuBar := mnu_Main

; Palette Context Menu
mnu_PalContextMenu := Menu()
mnu_PalContextMenu.Add("Remove", RemovePaletteColor)
mnu_PalContextMenu.Add("Copy Hex Code", CopyPaletteHex)

; ==============================
; LEFT PANEL
; ==============================
; Color preview
mGui.AddText("x" CONFIG.Ctl.X " y" CONFIG.Ctl.Y, "Color Preview:")
pb_Color := mGui.AddProgress("x" CONFIG.Ctl.X " y" (CONFIG.Ctl.Y + 20) " w" CONFIG.Ctl.W " h" CONFIG.Ctl.H " Border")

; Zoom preview
txt_Zoom := mGui.AddText("x" CONFIG.Ctl.X " y+15", "Zoom Preview:")

; Zoom
gridDisplay := GDIPlusGrid(mGui, CONFIG.Ctl.X, 200, CONFIG.Ctl.W, CONFIG.Colors.Grid)

; Zoom level
txt_ZoomLevel := mGui.AddText("x" CONFIG.Ctl.X " y422 w" CONFIG.Ctl.W " Center", "Zoom : " State.ZoomLvl "x"
)

; Zoom slider
sld_Zoom := mGui.AddSlider("x" CONFIG.Ctl.X " y442 w" CONFIG.Ctl.W " Range1-" CONFIG.Zoom.Length " ToolTip",
    State.ZoomIdx)
sld_Zoom.OnEvent("Change", (ctrl, *) => ChangeZoom(ctrl.Value, true))

; ==============================
; MIDDLE PANEL
; ==============================
; Options
chk_Zoom := mGui.AddCheckBox("x" CONFIG.Layout.MidX " y10" (State.ZoomEnabled ? " Checked" : ""), "Zoom")
chk_Zoom.OnEvent("Click", ToggleZoom)
chk_GridLines := mGui.AddCheckBox("x+10 yp" (State.GridEnabled ? " Checked" : ""), "Grid lines")
chk_GridLines.OnEvent("Click", ToggleGridLines)
chk_Upd := mGui.AddCheckBox("x+15 yp" (State.AutoUpdate ? " Checked" : ""), "Update (" CONFIG.Hotkeys.Update ")")
chk_Upd.OnEvent("Click", ToggleUpdate)
chk_AlwaysOnTop := mGui.AddCheckBox("x+15 yp" (State.AlwaysOnTop ? " Checked" : ""), "Always on Top")
chk_AlwaysOnTop.OnEvent("Click", ToggleAlwaysOnTop)

; Apply initial zoom visibility if disabled
if (!State.ZoomEnabled) {
    gridDisplay.ctrl.Visible := false
    sld_Zoom.Visible := false
    txt_ZoomLevel.Visible := false
    chk_GridLines.Visible := false
    txt_Zoom.Visible := false
}

; Source info
mGui.AddGroupBox("x" CONFIG.Layout.MidX " y35 w" CONFIG.Layout.MidW " h130", "Source Info")
txt_Position := mGui.AddText("x" CONFIG.Layout.MidX + 10 " y55 w150", "Position: 0, 0")

; RGB color codes
rgbTags := ["Red", "Grn", "Blu"], rgbLabels := ["Red:", "Green:", "Blue:"], rgbColors := ["cRed", "cLime", "cBlue"]
rgbCtl := Map() ; Store RGB control references for easy updates

; RGB color code boxes
loop 3 {
    yPos := 75 + (A_Index - 1) * 27
    AddRGBRow(mGui, CONFIG.Layout.MidX, yPos, rgbLabels[A_Index], rgbTags[A_Index], rgbColors[A_Index], rgbCtl)
}

; Color codes group box
mGui.AddGroupBox("x" CONFIG.Layout.MidX " y170 w" CONFIG.Layout.MidW " h280", "Color Codes")
fields := ["Hex", "Dec", "Rgb", "RgbPercent", "Rgba", "Bgr", "Cmyk", "Hsl", "Hsv"]
labels := ["HEX:", "DEC:", "RGB:", "RGB%:", "RGBA:", "BGR:", "CMYK:", "HSL:", "HSV:"]
txtCtl := Map()

; Color code boxes
loop fields.Length {
    yPos := 190 + (A_Index - 1) * 25
    AddColorRow(mGui, CONFIG.Layout.MidX, yPos, labels[A_Index], fields[A_Index], txtCtl)
}

; Color name
mGui.AddText("x" CONFIG.Layout.MidX + 10 " y415", "Color Name:")
txt_Cn := mGui.AddEdit("x" CONFIG.Layout.MidX + 80 " y412 w140 " CONFIG.Colors.edtBg)
mGui.AddButton("x+5 yp-1 VCn", "Copy").OnEvent("Click", CopyToClipboard)

; ==============================
; RIGHT PANEL
; ==============================
; Palette group box
mGui.AddGroupBox("x" CONFIG.Layout.RightX " y35 w" CONFIG.Layout.RightW " h420", "Palette")

; Add color button
btn_AddColor := mGui.AddButton("x" CONFIG.Layout.RightX + 10 " y60 h25", "Add (" CONFIG.Hotkeys.AddColor ")")
btn_AddColor.OnEvent("Click", AddColorToPalette)

; Sort colors button
btn_SortColors := mGui.AddButton("x+5 yp h25", "Sort " (State.SortDescending ? "▼" : "▲"))
btn_SortColors.OnEvent("Click", SortPalette)

; Palette cells
loop State.PaletteMax {
    row := (A_Index - 1) // CONFIG.Palette.Cols
    col := Mod(A_Index - 1, CONFIG.Palette.Cols)
    x := CONFIG.Layout.palStartX + col * (CONFIG.Palette.CellSize + CONFIG.Palette.Gap)
    y := CONFIG.Layout.palStartY + row * (CONFIG.Palette.CellSize + CONFIG.Palette.Gap)
    State.PalCtl.Push(mGui.AddProgress("x" x " y" y " w" CONFIG.Palette.CellSize " h" CONFIG.Palette.CellSize " Border BackgroundF0F0F0"
    ))
    State.PalCtl[A_Index].OnEvent("ContextMenu", ShowPaletteContextMenu.Bind(A_Index))
}

mGui.OnEvent("Close", (*) => ExitApp())
OnMessage(0x020A, WM_MOUSEWHEEL) ; Mouse wheel zoom

; Register dynamic hotkeys from settings
RegisterHotkeys()
mGui.Show("w670 h480") ; Show window

SetTimer(UpdateLoop, APP.Interval) ; Update loop
RenderPalette()

; ========================================
; FUNCTIONS
; ========================================
; Main loop that checks for mouse movement or color changes and updates the UI accordingly.
UpdateLoop() {
    if (!chk_Upd.Value)
        return

    ; Don't update while rendering is in progress
    if (State.IsRendering)
        return

    oldDpiCtx := EnterDpiCaptureContext()
    try {
        GetCursorPosForCapture(&mX, &mY)
        currZ := State.ZoomLvl

        currC := GetColorAtPhysical(mX, mY)
        if (currC < 0) {
            if (State.LastC < 0)
                return
            currC := State.LastC
        }
    } finally {
        LeaveDpiCaptureContext(oldDpiCtx)
    }

    ; Check what changed
    posChanged := (mX != State.LastX || mY != State.LastY)
    colorChanged := (currC != State.LastC)
    zoomChanged := (currZ != State.LastZ)

    ; Update color info if color changed
    if (colorChanged)
        RefreshColorInfo(mX, mY, currC)
    else if (posChanged)
        UpdatePositionInfo(mX, mY)

    ; Only redraw zoom preview when relevant data changed.
    if (posChanged || colorChanged || zoomChanged)
        RefreshGrid(mX, mY, currZ)

    State.LastX := mX, State.LastY := mY, State.LastC := currC, State.LastZ := currZ
}

; Refreshes the zoomed grid display based on the current mouse position and zoom level.
RefreshGrid(x?, y?, z?) {
    if (!State.ZoomEnabled)
        return

    if (State.IsRendering)
        return
    State.IsRendering := true

    try {
        if (!IsSet(x) || !IsSet(y))
            GetCursorPosForCapture(&x, &y)

        z := IsSet(z) ? z : State.ZoomLvl

        try capture := GetScreenColors(x, y, z, CONFIG.Ctl.W)
        catch
            return
        gridDisplay.Draw(capture, z, State.GridEnabled)
    } finally {
        State.IsRendering := false
    }
}

; Updates only the position display.
UpdatePositionInfo(x, y) {
    txt_Position.Value := Format("Position: {:4}, {:4}", x, y)
}

; Updates the color information display (Hex, RGB, CMYK, etc.) for the current pixel.
RefreshColorInfo(x, y, c) {
    UpdatePositionInfo(x, y)

    colorHex := Format("{:06X}", c) ; Color hex
    txtCtl["Hex"].Value := "#" colorHex ; Hex
    txtCtl["Dec"].Value := String(c) ; Dec
    pb_Color.Opt("Background" colorHex) ; Color

    r := (c >> 16) & 0xFF ; Red
    g := (c >> 8) & 0xFF ; Green
    b := c & 0xFF ; Blue

    UpdateColorComponent(r, "Red", rgbCtl) ; Red
    UpdateColorComponent(g, "Grn", rgbCtl) ; Green
    UpdateColorComponent(b, "Blu", rgbCtl) ; Blue

    txtCtl["Rgb"].Value := Format("rgb({}, {}, {})", r, g, b) ; RGB
    txtCtl["RgbPercent"].Value := Format("rgb({:.1f}%, {:.1f}%, {:.1f}%)", Round(r / 255 * 100, 1), Round(g / 255 * 100,
        1), Round(b / 255 * 100, 1)) ; RGB%
    txtCtl["Rgba"].Value := Format("rgba({}, {}, {}, 1.0)", r, g, b) ; RGBA
    txtCtl["Bgr"].Value := Format("${:02X}{:02X}{:02X}", b, g, r) ; BGR

    cmyk := RGBtoCMYK(r, g, b) ; CMYK
    txtCtl["Cmyk"].Value := Format("cmyk({}%, {}%, {}%, {}%)", cmyk.c, cmyk.m, cmyk.y, cmyk.k)

    hsxRes := RGBtoHSX(r, g, b)

    hsl := RGBtoHSLFromHSX(hsxRes)
    txtCtl["Hsl"].Value := Format("hsl({}, {}%, {}%)", hsl.h, hsl.s, hsl.l) ; HSL

    hsv := RGBtoHSVFromHSX(hsxRes)
    txtCtl["Hsv"].Value := Format("hsv({}, {}%, {}%)", hsv.h, hsv.s, hsv.v) ; HSV

    txt_Cn.Value := GetColorName(colorHex) ; Color name
}

; Checks or unchecks a menu item based on a boolean state.
SyncMenuCheck(menuObj, itemText, state) {
    state ? menuObj.Check(itemText) : menuObj.Uncheck(itemText)
}

; Toggles the zoom functionality on or off.
ToggleZoom(ctrl := 0, *) {
    ApplyToggle("ZoomEnabled", chk_Zoom, menuText.ZoomPreview, (val) => (
        gridDisplay.ctrl.Visible := val,
        sld_Zoom.Visible := val,
        txt_ZoomLevel.Visible := val,
        chk_GridLines.Visible := val,
        txt_Zoom.Visible := val
    ), ctrl)
}

; Toggles the visibility of grid lines in the zoom preview.
ToggleGridLines(ctrl := 0, *) => ApplyToggle("GridEnabled", chk_GridLines, menuText.GridLines, (*) => RefreshGrid(),
ctrl)

; Toggles auto-update of color preview.
ToggleUpdate(ctrl := 0, *) => ApplyToggle("AutoUpdate", chk_Upd, menuText.AutoUpdate, 0, ctrl)

; Toggles always-on-top state.
ToggleAlwaysOnTop(ctrl := 0, *) {
    ApplyToggle("AlwaysOnTop", chk_AlwaysOnTop, menuText.AlwaysOnTop, (val) => (
        WinSetAlwaysOnTop(val ? 1 : 0, mGui.Hwnd)
    ), ctrl)
}

; Centralized toggle helper to update state, GUI, and menu in one place.
; propName: State property string, ctrlObj: GUI control object, menuName: Menu text string,
; callback: Optional function for side-effects, callCtrl: The control that triggered the event.
ApplyToggle(propName, ctrlObj, menuName, callback := 0, callCtrl := 0) {
    State.%propName% := (IsObject(callCtrl) && HasProp(callCtrl, "Value"))
        ? callCtrl.Value : !State.%propName%
    ctrlObj.Value := State.%propName%
    SyncMenuCheck(mnu_Settings, menuName, State.%propName%)
    if IsObject(callback)
        callback(State.%propName%)
}

; Changes the zoom level
ChangeZoom(val, absolute := false) {
    newIdx := absolute ? Round(val) : State.ZoomIdx + val
    newIdx := Max(1, Min(CONFIG.Zoom.Length, newIdx))

    if (newIdx != State.ZoomIdx) {
        State.ZoomIdx := newIdx
        State.ZoomLvl := CONFIG.Zoom[State.ZoomIdx]
        RefreshGrid()
    }

    txt_ZoomLevel.Value := "Zoom : " State.ZoomLvl "x"
    if (sld_Zoom.Value != State.ZoomIdx)
        sld_Zoom.Value := State.ZoomIdx
}

; Handles mouse wheel events to adjust the zoom level.
WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
    if (!State.ZoomEnabled)
        return

    delta := (wParam << 32 >> 48)
    ChangeZoom(delta > 0 ? 1 : -1)
}

; Copies the text content of the clicked control to the clipboard.
CopyToClipboard(ctrl, *) {
    val := (ctrl.Name = "Cn") ? txt_Cn.Value : txtCtl[ctrl.Name].Value
    if (val != "") {
        A_Clipboard := val
        ToolTip("Copied: " val)
        SetTimer(() => ToolTip(), -1500)
    }
}

; Adds the current sampled color to the palette (newest first in display).
AddColorToPalette(*) {
    if (State.LastC < 0)
        return

    colorHex := Format("{:06X}", State.LastC)

    ; Palette is kept unique; if the color exists, move it to the newest slot.
    for i, existing in State.Palette {
        if (existing = colorHex) {
            State.Palette.RemoveAt(i)
            break
        }
    }

    State.Palette.Push(colorHex)
    if (State.Palette.Length > State.PaletteMax)
        State.Palette.RemoveAt(1)

    State.PaletteChanged := true
    RenderPalette()
}

; Sorts palette colors visually from dark to light using perceptual luminance.
SortPalette(*) {
    if (State.Palette.Length <= 1)
        return

    ; Build a string with luminance values for sorting.
    ; Each line: "Luminance|HexColor"
    sortContent := ""
    for colorHex in State.Palette {
        r := Integer("0x" SubStr(colorHex, 1, 2))
        g := Integer("0x" SubStr(colorHex, 3, 2))
        b := Integer("0x" SubStr(colorHex, 5, 2))

        ; Perceptual luminance formula: (0.299*R + 0.587*G + 0.114*B)
        lum := (0.299 * r) + (0.587 * g) + (0.114 * b)

        ; Pad luminance for consistent sorting (000.000 format)
        sortContent .= Format("{:07.3f}|{}`n", lum, colorHex)
    }

    ; Determine sort direction (N = Numerical, R = Reverse)
    sortOptions := State.SortDescending ? "NR" : "N"
    sorted := Sort(RTrim(sortContent, "`n"), sortOptions)

    ; Rebuild the palette array from the sorted string
    State.Palette := []
    loop parse, sorted, "`n" {
        if (A_LoopField)
            State.Palette.Push(StrSplit(A_LoopField, "|")[2])
    }

    State.SortDescending := !State.SortDescending ; Toggle direction for next call
    btn_SortColors.Text := "Sort " (State.SortDescending ? "▼" : "▲")
    State.PaletteChanged := true
    RenderPalette()
}

; Draws palette cells from newest to oldest.
RenderPalette() {
    static emptyColor := "F0F0F0"
    pCount := State.Palette.Length

    loop State.PaletteMax {
        colorHex := (A_Index <= pCount) ? State.Palette[pCount - A_Index + 1] : emptyColor
        State.PalCtl[A_Index].Opt("Background" colorHex)
    }
}

; Shows context menu for a palette cell.
ShowPaletteContextMenu(idx, *) {
    pCount := State.Palette.Length
    ; Map GUI index (1 to Max) to Palette array index (newest to oldest)
    if (idx > pCount)
        return

    State.SelectedPalIdx := pCount - idx + 1
    mnu_PalContextMenu.Show()
}

; Removes the selected color from the palette.
RemovePaletteColor(*) {
    if (State.SelectedPalIdx > 0 && State.SelectedPalIdx <= State.Palette.Length) {
        State.Palette.RemoveAt(State.SelectedPalIdx)
        State.PaletteChanged := true
        RenderPalette()
    }
}

; Copies the hex code of the selected palette color.
CopyPaletteHex(*) {
    if (State.SelectedPalIdx > 0 && State.SelectedPalIdx <= State.Palette.Length) {
        hex := State.Palette[State.SelectedPalIdx]
        A_Clipboard := "#" hex
        ToolTip("Copied: #" hex)
        SetTimer(() => ToolTip(), -1500)
    }
}

; Moves the mouse cursor relative to its current position and updates the display.
MoveMouse(x, y) {
    MouseMove(x, y, 0, "R")
    UpdateLoop()
}

; Registers dynamic hotkeys
RegisterHotkeys() {
    HotIf (*) => WinActive("ahk_id " mGui.Hwnd)
    try {
        Hotkey(CONFIG.Hotkeys.Update, (*) => ToggleUpdate())
        Hotkey(CONFIG.Hotkeys.AddColor, (*) => AddColorToPalette())
    } finally {
        HotIf
    }
}

; Shows a message box with current keyboard shortcuts
ShowShortcuts(*) {
    msg := "Main Shortcuts:`n"
    msg .= CONFIG.Hotkeys.Update " : Toggle Auto Update`n"
    msg .= CONFIG.Hotkeys.AddColor " : Add Color to Palette`n`n"
    msg .= "Movement:`n"
    msg .= "Ctrl + Arrows : Move 1 pixel`n"
    msg .= "Ctrl + Shift + Arrows : Move 10 pixels`n`n"
    msg .= "Other:`n"
    msg .= "Mouse Wheel : Zoom In/Out"

    MsgBox(msg, "Keyboard Shortcuts", "Iconi Owner" mGui.Hwnd)
}

; Loads application settings from INI file
LoadSettings() {
    ini := APP.IniFile

    ; Hotkeys
    CONFIG.Hotkeys.Update := IniRead(ini, "Hotkeys", "Update", "F1")
    CONFIG.Hotkeys.AddColor := IniRead(ini, "Hotkeys", "AddColor", "F2")

    ; General Settings
    tmpZoomIdx := Integer(IniRead(ini, "Settings", "ZoomIndex", String(APP.DefIdx)))
    State.ZoomIdx := Max(1, Min(CONFIG.Zoom.Length, tmpZoomIdx))
    State.ZoomLvl := CONFIG.Zoom[State.ZoomIdx]

    State.ZoomEnabled := IniRead(ini, "Settings", "ZoomEnabled", "1") = "1"
    State.GridEnabled := IniRead(ini, "Settings", "GridEnabled", "1") = "1"
    State.AutoUpdate := IniRead(ini, "Settings", "AutoUpdate", "1") = "1"
    State.AlwaysOnTop := IniRead(ini, "Settings", "AlwaysOnTop", "1") = "1"

    ; Palette
    rawPalette := IniRead(ini, "Palette", "Colors", "")
    if (rawPalette != "") {
        loaded := []
        seen := Map()
        for _, part in StrSplit(rawPalette, ",") {
            colorHex := StrUpper(Trim(part))
            if (RegExMatch(colorHex, "^[0-9A-F]{6}$") && !seen.Has(colorHex)) {
                seen[colorHex] := true
                loaded.Push(colorHex)
            }
        }
        while (loaded.Length > State.PaletteMax)
            loaded.RemoveAt(1)
        State.Palette := loaded

        serializedLoaded := ""
        for idx, colorHex in loaded
            serializedLoaded .= (idx > 1 ? "," : "") colorHex

        ; If the raw INI value differs from the normalized/deduped result, flag a save on exit
        rawNorm := StrUpper(RegExReplace(rawPalette, "\s+"))
        if (serializedLoaded != rawNorm)
            State.PaletteChanged := true
    }
}

; Saves application settings to INI file
SaveSettings() {
    ini := APP.IniFile

    try {
        IniWrite(CONFIG.Hotkeys.Update, ini, "Hotkeys", "Update")
        IniWrite(CONFIG.Hotkeys.AddColor, ini, "Hotkeys", "AddColor")
        IniWrite(State.ZoomIdx, ini, "Settings", "ZoomIndex")
        IniWrite(State.ZoomEnabled ? "1" : "0", ini, "Settings", "ZoomEnabled")
        IniWrite(State.GridEnabled ? "1" : "0", ini, "Settings", "GridEnabled")
        IniWrite(State.AutoUpdate ? "1" : "0", ini, "Settings", "AutoUpdate")
        IniWrite(State.AlwaysOnTop ? "1" : "0", ini, "Settings", "AlwaysOnTop")

        ; Palette
        if (State.PaletteChanged) {
            serialized := ""
            for idx, colorHex in State.Palette
                serialized .= (idx > 1 ? "," : "") colorHex
            IniWrite(serialized, ini, "Palette", "Colors")
            State.PaletteChanged := false
        }
    }
}

; Gets cursor position in coordinate space matching capture APIs.
GetCursorPosForCapture(&x, &y) {
    global g_UsePhysicalCoords
    pt := Buffer(8, 0)
    if (g_UsePhysicalCoords && DllCall("User32\GetPhysicalCursorPos", "Ptr", pt, "Int")) {
        x := NumGet(pt, 0, "Int")
        y := NumGet(pt, 4, "Int")
        return
    }
    DllCall("User32\GetCursorPos", "Ptr", pt)
    x := NumGet(pt, 0, "Int")
    y := NumGet(pt, 4, "Int")
}

; Forces per-monitor-v2 DPI context for capture/sampling APIs on the current thread.
EnterDpiCaptureContext() {
    global g_UsePhysicalCoords
    if (!g_UsePhysicalCoords)
        return 0
    return DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
}

; Restores previous thread DPI context.
LeaveDpiCaptureContext(oldCtx) {
    if (oldCtx)
        DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", oldCtx, "Ptr")
}

; Reads pixel color using physical coordinates (returns RGB 0xRRGGBB, -1 on failure).
GetColorAtPhysical(x, y) {
    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    if (!hDC)
        return -1
    bgr := DllCall("GetPixel", "Ptr", hDC, "Int", x, "Int", y, "UInt")
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
    if (bgr = 0xFFFFFFFF)
        return -1
    return ((bgr & 0xFF) << 16) | (bgr & 0x00FF00) | ((bgr >> 16) & 0xFF)
}

; Updates the GUI controls for a specific color component (Red, Green, or Blue).
UpdateColorComponent(val, tag, controls) {
    controls[tag "Hex"].Value := Format("{:02X}", val)
    controls[tag "Dec"].Value := String(val)
    controls[tag "Pb"].Value := val

    ; Bit-shift amount per channel to build a full RGB value from one component
    static shifts := Map("Red", 16, "Grn", 8, "Blu", 0)
    controls[tag "Pb"].Opt(Format("c{:06X}", val << shifts[tag]))
}

; Returns the capture cell count: visible cells + 2 extra (one per side) so the zoomed view
; fully fills the frame after centering. Always returns an odd number.
GetCaptureCellCount(frameSize, zoomFactor) {
    count := Floor(frameSize / zoomFactor)
    count := Mod(count, 2) = 0 ? count - 1 : count  ; ensure odd
    count += 2
    return Mod(count, 2) = 0 ? count + 1 : count
}

; Captures the source area into a bitmap for single-pass nearest-neighbor scaling in Draw().
GetScreenColors(cX, cY, zoom, frameSize) {
    oldDpiCtx := EnterDpiCaptureContext()
    try {
        count := GetCaptureCellCount(frameSize, zoom) ; Capture one extra ring for edge crop fill
        half := count // 2

        ; Virtual screen bounds (all monitors)
        vLeft := DllCall("GetSystemMetrics", "Int", 76, "Int")
        vTop := DllCall("GetSystemMetrics", "Int", 77, "Int")
        vW := DllCall("GetSystemMetrics", "Int", 78, "Int")
        vH := DllCall("GetSystemMetrics", "Int", 79, "Int")
        vRight := vLeft + vW - 1
        vBottom := vTop + vH - 1

        srcX := cX - half
        srcY := cY - half

        ; Intersect requested capture region with virtual screen
        validX1 := Max(srcX, vLeft)
        validY1 := Max(srcY, vTop)
        validX2 := Min(srcX + count - 1, vRight)
        validY2 := Min(srcY + count - 1, vBottom)
        hasValid := !(validX1 > validX2 || validY1 > validY2)

        hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
        if (!hDC)
            return { hBM: 0, count: count }

        mDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
        if (!mDC) {
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
            return { hBM: 0, count: count }
        }

        hBM := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", count, "Int", count, "Ptr")
        if (!hBM) {
            DllCall("DeleteDC", "Ptr", mDC)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
            return { hBM: 0, count: count }
        }

        oBM := DllCall("SelectObject", "Ptr", mDC, "Ptr", hBM, "Ptr")
        if (!oBM) {
            DllCall("DeleteObject", "Ptr", hBM)
            DllCall("DeleteDC", "Ptr", mDC)
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
            return { hBM: 0, count: count }
        }

        ; Fill full capture area with window background color to keep out-of-screen regions blank.
        sysCol := DllCall("GetSysColor", "Int", 15, "UInt")
        hBr := DllCall("CreateSolidBrush", "UInt", sysCol, "Ptr")
        if (hBr) {
            rc := Buffer(16, 0)
            NumPut("Int", 0, "Int", 0, "Int", count, "Int", count, rc)
            DllCall("FillRect", "Ptr", mDC, "Ptr", rc, "Ptr", hBr)
            DllCall("DeleteObject", "Ptr", hBr)
        }

        if (hasValid) {
            bltW := validX2 - validX1 + 1
            bltH := validY2 - validY1 + 1
            dstX := validX1 - srcX
            dstY := validY1 - srcY
            DllCall("BitBlt", "Ptr", mDC, "Int", dstX, "Int", dstY, "Int", bltW, "Int", bltH, "Ptr", hDC, "Int",
                validX1,
                "Int", validY1, "UInt", 0x00CC0020)
        }

        DllCall("SelectObject", "Ptr", mDC, "Ptr", oBM)
        DllCall("DeleteDC", "Ptr", mDC)
        DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)
        return { hBM: hBM, count: count }
    } finally {
        LeaveDpiCaptureContext(oldDpiCtx)
    }
}

; ========================================
; COLOR CONVERSIONS
; ========================================
; Converts RGB color values to CMYK color space.
RGBtoCMYK(r, g, b) {
    rf := r / 255.0, gf := g / 255.0, bf := b / 255.0
    k := 1 - Max(rf, gf, bf)

    if (k = 1)
        return { c: 0, m: 0, y: 0, k: 100 }

    return {
        c: Round((1 - rf - k) / (1 - k) * 100),
        m: Round((1 - gf - k) / (1 - k) * 100),
        y: Round((1 - bf - k) / (1 - k) * 100),
        k: Round(k * 100)
    }
}

; Shared pre-calculation helper: returns Hue, Max, Min, and Delta used by both HSL and HSV conversions.
RGBtoHSX(r, g, b) {
    r /= 255, g /= 255, b /= 255
    mx := Max(r, g, b), mn := Min(r, g, b)
    d := mx - mn
    h := 0
    if (d != 0) {
        switch mx {
            case r: h := (g - b) / d + (g < b ? 6 : 0)
            case g: h := (b - r) / d + 2
            case b: h := (r - g) / d + 4
        }
        h /= 6
    }
    return { h: Round(h * 360), mx: mx, mn: mn, d: d }
}

; Convert from cached HSX result to HSL
RGBtoHSLFromHSX(res) {
    l := (res.mx + res.mn) / 2
    s := (res.d = 0) ? 0 : (l > 0.5 ? res.d / (2 - res.mx - res.mn) : res.d / (res.mx + res.mn))
    return { h: res.h, s: Round(s * 100), l: Round(l * 100) }
}

; Convert from cached HSX result to HSV
RGBtoHSVFromHSX(res) {
    s := (res.mx = 0) ? 0 : res.d / res.mx
    return { h: res.h, s: Round(s * 100), v: Round(res.mx * 100) }
}

; Displays the 'About' dialog box
About(*) {
    msg := Format("
	(
		{} v{}`n
		©2026 Mesut Akcan 
		makcan@gmail.com
		github.com/akcansoft
		mesutakcan.blogspot.com
		youtube.com/mesutakcan
	)",
        APP.Name, APP.Ver)

    MsgBox(msg, APP.Name, "Iconi Owner" mGui.Hwnd)
}

; Initializes the DPI awareness for the application to ensure correct scaling and coordinate handling on high-DPI displays.
InitDpiAwareness() {
    global g_UsePhysicalCoords
    ; Windows 10+: Per-monitor v2 awareness.
    if DllCall("User32\SetProcessDpiAwarenessContext", "ptr", -4, "int")
        g_UsePhysicalCoords := true
    else {
        ; Windows 8.1 fallback: Per-monitor awareness.
        if (DllCall("Shcore\SetProcessDpiAwareness", "int", 2, "int") = 0)
            g_UsePhysicalCoords := true
        else
        ; Legacy fallback: System DPI awareness.
            DllCall("User32\SetProcessDPIAware")
    }

    ; Some hosts/launchers lock process awareness. Verify thread PMv2 support explicitly.
    prevCtx := DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", -4, "Ptr")
    if (prevCtx) {
        DllCall("User32\SetThreadDpiAwarenessContext", "Ptr", prevCtx, "Ptr")
        g_UsePhysicalCoords := true
    } else {
        g_UsePhysicalCoords := false
    }
}

; Adds a row of RGB controls (Label, Hex edit, Dec edit, Progress bar)
AddRGBRow(guiObj, x, y, label, tag, color, controls) {
    guiObj.AddText("x" x + 10 " y" y, label)
    controls[tag "Hex"] := guiObj.AddEdit("x" x + 50 " y" y - 3 " w35 " CONFIG.Colors.edtBg)
    controls[tag "Dec"] := guiObj.AddEdit("x+5 yp w35 " CONFIG.Colors.edtBg)
    controls[tag "Pb"] := guiObj.AddProgress("x+10 yp w130 BackgroundDDDDDD Range0-255 h22 " color)
}

; Adds a row of color code controls (Label, Edit box, Copy button)
AddColorRow(guiObj, x, y, label, field, controls) {
    guiObj.AddText("x" x + 10 " y" y, label)
    controls[field] := guiObj.AddEdit("x" x + 50 " w170 y" y - 3 " " CONFIG.Colors.edtBg)
    guiObj.AddButton("x+5 yp-1 V" field, "Copy").OnEvent("Click", CopyToClipboard)
}

; ========================================
; GDI+ RENDERING CLASS
; ========================================
class GDIPlusGrid {
    ; Initializes the GDI+ grid object.
    __New(guiObj, x, y, size, gridCol) {
        this.scale := A_ScreenDPI / 96
        this.pSize := Round(size * this.scale)

        ; GUI background color (for proper clearing)
        sysCol := DllCall("GetSysColor", "Int", 15)
        this.bgCol := 0xFF000000 | (sysCol & 0xFF) << 16 | (sysCol & 0xFF00) | (sysCol >> 16) & 0xFF

        if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
            this.hMod := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")

        si := Buffer(24, 0), NumPut("UInt", 1, si)
        DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken := 0, "Ptr", si, "Ptr", 0)
        this.pToken := pToken

        this.ctrl := guiObj.AddPicture("x" x " y" y " w" size " h" size " Border BackgroundTrans 0xE")
        this.hPic := this.ctrl.Hwnd

        DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", this.pSize, "Int", this.pSize, "Int", 0, "Int", 0x26200A,
            "Ptr", 0, "Ptr*", &pBM := 0)
        this.pBM := pBM
        DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBM, "Ptr*", &pG := 0)
        this.pG := pG

        DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pG, "Int", 0)
        DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pG, "Int", 4) ; PixelOffsetModeNone (avoid half-pixel shifts)
        DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pG, "Int", 5) ; Nearest-neighbor for crisp pixel zoom

        DllCall("gdiplus\GdipCreateSolidFill", "UInt", gridCol, "Ptr*", &pB := 0)
        this.gridBrush := pB
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000, "Ptr*", &pCB := 0)
        this.cellBrush := pCB
    }

    ; Draws one captured bitmap frame, scales it by zoom, then overlays optional grid and center marker.
    Draw(capture, zoom, showGrid) {
        ; Clear previous frame
        DllCall("gdiplus\GdipGraphicsClear", "Ptr", this.pG, "UInt", this.bgCol)

        if (!IsObject(capture))
            return

        count := capture.count
        hSrcBM := capture.hBM
        if (count < 1 || !hSrcBM)
            return

        cellSize := Max(1, Round(zoom * this.scale))
        actSize := cellSize * count
        off := Floor((this.pSize - actSize) / 2) ; Integer align to keep image and grid on same pixel boundaries

        pSrc := 0
        if (DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hSrcBM, "Ptr", 0, "Ptr*", &pSrc := 0, "Int") = 0 &&
        pSrc
        ) {
            DllCall("gdiplus\GdipDrawImageRectRect", "Ptr", this.pG, "Ptr", pSrc, "Float", off, "Float", off, "Float",
                actSize, "Float", actSize, "Float", 0.0, "Float", 0.0, "Float", count, "Float", count, "Int", 2, "Ptr",
                0, "Ptr", 0, "Ptr", 0)
            DllCall("gdiplus\GdipDisposeImage", "Ptr", pSrc)
        }
        DllCall("DeleteObject", "Ptr", hSrcBM)

        if (showGrid && cellSize >= 5 * this.scale && count > 1) {
            gThick := Max(1, Floor(this.scale))
            loop count - 1 {
                vx := off + A_Index * cellSize - Floor(gThick / 2)
                hy := off + A_Index * cellSize - Floor(gThick / 2)
                DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.gridBrush, "Float", vx, "Float", off,
                    "Float", gThick, "Float", actSize)
                DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.gridBrush, "Float", off, "Float", hy,
                    "Float", actSize, "Float", gThick)
            }
        }

        ; Center marker: black outer border + white inner border
        mid := (count // 2) + 1
        hx := (mid - 1) * cellSize + off
        hy := (mid - 1) * cellSize + off
        hw := Max(1, cellSize)
        hh := Max(1, cellSize)

        t := Max(1, Floor(this.scale))
        DllCall("gdiplus\GdipSetSolidFillColor", "Ptr", this.cellBrush, "UInt", 0xFF000000)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx - t, "Float", hy - t,
            "Float", hw + 2 * t, "Float", t)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx - t, "Float", hy + hh,
            "Float", hw + 2 * t, "Float", t)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx - t, "Float", hy,
            "Float", t, "Float", hh)
        DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx + hw, "Float", hy,
            "Float", t, "Float", hh)

        if (hw > 2 * t && hh > 2 * t) {
            DllCall("gdiplus\GdipSetSolidFillColor", "Ptr", this.cellBrush, "UInt", 0xFFFFFFFF)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx, "Float", hy,
                "Float",
                hw, "Float", t)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx, "Float", hy + hh -
                t, "Float", hw, "Float", t)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx, "Float", hy + t,
                "Float", t, "Float", hh - 2 * t)
            DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", hx + hw - t, "Float",
                hy
                + t, "Float", t, "Float", hh - 2 * t)
        }

        DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", this.pBM, "Ptr*", &hBM := 0, "UInt", this.bgCol)
        oBM := DllCall("SendMessage", "Ptr", this.hPic, "UInt", 0x172, "Ptr", 0, "Ptr", hBM, "Ptr")
        if (oBM)
            DllCall("DeleteObject", "Ptr", oBM)
    }

    ; Cleans up GDI+ resources when the object is destroyed.
    __Delete() {
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", this.gridBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", this.cellBrush)
        DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this.pG)
        DllCall("gdiplus\GdipDisposeImage", "Ptr", this.pBM)
        DllCall("gdiplus\GdiplusShutdown", "Ptr", this.pToken)
        if this.HasProp("hMod")
            DllCall("FreeLibrary", "Ptr", this.hMod)
    }
}
