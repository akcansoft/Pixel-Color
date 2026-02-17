; AS Pixel Color
; 17/02/2026

; Mesut Akcan
; -----------
; github.com/akcansoft
; mesutakcan.blogspot.com
; youtube.com/mesutakcan

#Requires AutoHotkey v2+
#SingleInstance Force

; ========== COMPILER DIRECTIVES ==========
;@Ahk2Exe-SetName AS Pixel Color
;@Ahk2Exe-SetDescription AS Pixel Color
;@Ahk2Exe-SetFileVersion 2.4
;@Ahk2Exe-SetCompanyName AkcanSoft
;@Ahk2Exe-SetCopyright ©2026 Mesut Akcan
;@Ahk2Exe-SetMainIcon app_icon.ico

; Set tray icon while running as script (ignored in compiled EXE)
;@Ahk2Exe-IgnoreBegin
try TraySetIcon(A_ScriptDir "\app_icon.ico")
;@Ahk2Exe-IgnoreEnd

; ========================================
; SETTINGS AND STATE
; ========================================
global APP := {
	Name: "AS Pixel Color",
	Ver: "2.4",
	Interval: 100,          ; Update interval (ms)
	MinCells: 3,            ; Keep at least 3x3 cells visible
	DefIdx: 6,              ; Default zoom index
	PaletteFile: A_ScriptDir "\palette.txt"
}

global CONFIG := {
	Ctl: {
		X: 10,  ; Control X position
		Y: 10,  ; Control Y position
		W: 216, ; Control Width
		H: 135  ; Control Height
	},
	Colors: {
		Grid: 0xFFBCBCBC,           ; Grid line color
		edtBg: "BackgroundFFFFF0"   ; Edit background color
	},
	Zoom: [2, 3, 4, 5, 6, 7, 8, 11, 14, 17, 22, 28, 35, 45, 57, 72], ; Zoom levels (multipliers)
	Palette: {
		CellSize: 25, ; Palette cell size
		Gap: 2,       ; Palette cell gap
		Cols: 4       ; Palette columns
	}
}

global State := {
	ZoomIdx: APP.DefIdx,                ; Current zoom index in the ZoomSteps array
	ZoomLvl: CONFIG.Zoom[APP.DefIdx],   ; Current zoom level
	ZoomEnabled: true,                  ; Whether zoom preview is enabled
	GridEnabled: true,                  ; Whether grid lines are enabled
	IsRendering: false,                 ; Flag to prevent updates while rendering is in progress
	PaletteMax: 52,                     ; Maximum number of colors in the palette
	Palette: [],                        ; Palette color list (HEX without #)
	PaletteChanged: false,              ; Whether palette content changed since last save
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

LoadPaletteFromDisk() ; Load saved palette on startup
OnExit(SavePaletteToDisk) ; Save palette on exit

; ========================================
; HOTKEYS
; ========================================
F1:: ToggleUpdate()
F2:: AddColorToPalette()

; Ctrl + Arrow Keys: Move mouse 1 pixel
; Ctrl + Shift + Arrow Keys: Move mouse 10 pixels
#HotIf !WinActive("ahk_class #32770")
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
mGui := Gui("+AlwaysOnTop", APP.Name)
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
	AutoUpdate: "&Auto Update`tF1",
	AlwaysOnTop: "&Always on Top",
	AddToPalette: "&Add to palette`tF2",
	SortColors: "&Sort colors",
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

; Set initial checkmarks
mnu_Settings.Check(menuText.ZoomPreview)
mnu_Settings.Check(menuText.GridLines)
mnu_Settings.Check(menuText.AutoUpdate)
mnu_Settings.Check(menuText.AlwaysOnTop)

; Help menu
mnu_Help := Menu()
mnu_Help.Add(menuText.About, About)
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
midX := 240 ; Middle panel X offset
gbW := 280 ; Group box width

; Options
chk_Zoom := mGui.AddCheckBox("x" midX " y10 Checked", "Zoom")
chk_Zoom.OnEvent("Click", ToggleZoom)
chk_GridLines := mGui.AddCheckBox("x+10 yp Checked", "Grid lines")
chk_GridLines.OnEvent("Click", ToggleGridLines)
chk_Upd := mGui.AddCheckBox("x+15 yp +Checked", "Update (F1)")
chk_Upd.OnEvent("Click", ToggleUpdate)
chk_AlwaysOnTop := mGui.AddCheckBox("x+15 yp +Checked", "Always on Top")
chk_AlwaysOnTop.OnEvent("Click", ToggleAlwaysOnTop)

; Source info
mGui.AddGroupBox("x" midX " y35 w" gbW " h130", "Source Info")
txt_Position := mGui.AddText("x" midX + 10 " y55 w150", "Position: 0, 0")

; RGB color codes
rgbTags := ["Red", "Grn", "Blu"], rgbLabels := ["Red:", "Green:", "Blue:"], rgbColors := ["cRed", "cLime", "cBlue"]
rgbCtl := Map() ; Store RGB control references for easy updates

; RGB color code boxes
loop 3 {
	yPos := 75 + (A_Index - 1) * 27
	AddRGBRow(mGui, midX, yPos, rgbLabels[A_Index], rgbTags[A_Index], rgbColors[A_Index], rgbCtl)
}

; Color codes group box
mGui.AddGroupBox("x" midX " y170 w" gbW " h280", "Color Codes")
fields := ["Hex", "Dec", "Rgb", "RgbPercent", "Rgba", "Bgr", "Cmyk", "Hsl", "Hsv"]
labels := ["HEX:", "DEC:", "RGB:", "RGB%:", "RGBA:", "BGR:", "CMYK:", "HSL:", "HSV:"]
txtCtl := Map()

; Color code boxes
loop fields.Length {
	yPos := 190 + (A_Index - 1) * 25
	AddColorRow(mGui, midX, yPos, labels[A_Index], fields[A_Index], txtCtl)
}

; Color name
mGui.AddText("x" midX + 10 " y415", "Color Name:")
txt_Cn := mGui.AddEdit("x" midX + 80 " y412 w140 " CONFIG.Colors.edtBg)
mGui.AddButton("x+5 yp-1 VCn", "Copy").OnEvent("Click", CopyToClipboard)

; ==============================
; RIGHT PANEL
; ==============================
rpX := 530 ; Right panel X offset
palW := 130 ; Palette panel width

mGui.AddGroupBox("x" rpX " y35 w" palW " h420", "Palette")
btn_AddColor := mGui.AddButton("x" rpX + 10 " y60 h25", "Add (F2)")
btn_AddColor.OnEvent("Click", AddColorToPalette)
btn_SortColors := mGui.AddButton("x+5 yp h25", "Sort")
btn_SortColors.OnEvent("Click", SortPalette)

; Palette cells
palStartX := rpX + 10 ; Starting X position for palette cells
palStartY := 95 ; Starting Y position for palette cells

loop State.PaletteMax {
	row := (A_Index - 1) // CONFIG.Palette.Cols
	col := Mod(A_Index - 1, CONFIG.Palette.Cols)
	x := palStartX + col * (CONFIG.Palette.CellSize + CONFIG.Palette.Gap)
	y := palStartY + row * (CONFIG.Palette.CellSize + CONFIG.Palette.Gap)
	State.PalCtl.Push(mGui.AddProgress("x" x " y" y " w" CONFIG.Palette.CellSize " h" CONFIG.Palette.CellSize " Border BackgroundF0F0F0"))
}

mGui.OnEvent("Close", (*) => ExitApp())
OnMessage(0x020A, WM_MOUSEWHEEL) ; Mouse wheel zoom
mGui.Show("w670 h480")

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

	; Only refresh what actually changed
	if (posChanged || colorChanged) {
		RefreshColorInfo(mX, mY, currC)
		RefreshGrid(mX, mY, currZ)
	} else if (zoomChanged) {
		RefreshGrid(mX, mY, currZ)
	}

	State.LastX := mX, State.LastY := mY, State.LastC := currC, State.LastZ := currZ
}

; Refreshes the zoomed grid display based on the current mouse position and zoom level.
RefreshGrid(x?, y?, z?) {
	if (!State.ZoomEnabled)
		return

	if (!IsSet(x) || !IsSet(y))
		GetCursorPosForCapture(&x, &y)

	z := IsSet(z) ? z : State.ZoomLvl

	try capture := GetScreenColors(x, y, z, CONFIG.Ctl.W)
	catch
		return

	; Always release render lock, even if draw fails
	State.IsRendering := true
	try {
		gridDisplay.Draw(capture, z, State.GridEnabled)
	} finally {
		State.IsRendering := false
	}
}

; Updates the color information display (Hex, RGB, CMYK, etc.) for the current pixel.
RefreshColorInfo(x, y, c) {
	txt_Position.Value := Format("Position: {:4}, {:4}", x, y) ; Position

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
	txtCtl["RgbPercent"].Value := Format("rgb({:.1f}%, {:.1f}%, {:.1f}%)", r / 2.55, g / 2.55, b / 2.55) ; RGB%
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

; Toggles the zoom functionality on or off.
ToggleZoom(ctrl, *) {
	if IsObject(ctrl) && HasProp(ctrl, "Value") ; From Gui
		State.ZoomEnabled := ctrl.Value
	else { ; From Menu
		State.ZoomEnabled := !State.ZoomEnabled
		chk_Zoom.Value := State.ZoomEnabled
	}

	if (State.ZoomEnabled)
		mnu_Settings.Check(menuText.ZoomPreview)
	else
		mnu_Settings.Uncheck(menuText.ZoomPreview)

	gridDisplay.ctrl.Visible := State.ZoomEnabled
	sld_Zoom.Visible := State.ZoomEnabled
	txt_ZoomLevel.Visible := State.ZoomEnabled
	chk_GridLines.Visible := State.ZoomEnabled
	txt_Zoom.Visible := State.ZoomEnabled
}

; Toggles the visibility of grid lines in the zoom preview.
ToggleGridLines(ctrl, *) {
	if IsObject(ctrl) && HasProp(ctrl, "Value")
		State.GridEnabled := ctrl.Value
	else {
		State.GridEnabled := !State.GridEnabled
		chk_GridLines.Value := State.GridEnabled
	}

	if (State.GridEnabled)
		mnu_Settings.Check(menuText.GridLines)
	else
		mnu_Settings.Uncheck(menuText.GridLines)

	RefreshGrid()
}

; Toggles auto-update of color preview.
ToggleUpdate(ctrl := 0, *) {
	if !(IsObject(ctrl) && HasProp(ctrl, "Value"))
		chk_Upd.Value := !chk_Upd.Value

	if (chk_Upd.Value)
		mnu_Settings.Check(menuText.AutoUpdate)
	else
		mnu_Settings.Uncheck(menuText.AutoUpdate)
}

; Toggles always-on-top state.
ToggleAlwaysOnTop(ctrl, *) {
	if IsObject(ctrl) && HasProp(ctrl, "Value")
		val := ctrl.Value
	else {
		chk_AlwaysOnTop.Value := !chk_AlwaysOnTop.Value
		val := chk_AlwaysOnTop.Value
	}

	WinSetAlwaysOnTop(val ? 1 : 0, mGui.Hwnd)

	if (val)
		mnu_Settings.Check(menuText.AlwaysOnTop)
	else
		mnu_Settings.Uncheck(menuText.AlwaysOnTop)
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

	; Search and remove all existing instances of this color to ensure uniqueness.
	; This also ensures that an existing color moves to the "newest" position.
	i := 1
	while i <= State.Palette.Length {
		if (State.Palette[i] = colorHex)
			State.Palette.RemoveAt(i)
		else
			i++
	}

	State.Palette.Push(colorHex)
	if (State.Palette.Length > State.PaletteMax)
		State.Palette.RemoveAt(1)

	State.PaletteChanged := true
	RenderPalette()
}

; Sorts palette colors visually from dark to light using perceptual luminance.
SortPalette(*) {
	if (State.Palette.Length <= 1) ; If palette has 0 or 1 color, do nothing
		return

	; Create a list of objects with hex and brightness (luminance)
	colorData := []
	for colorHex in State.Palette {
		r := Integer("0x" SubStr(colorHex, 1, 2))
		g := Integer("0x" SubStr(colorHex, 3, 2))
		b := Integer("0x" SubStr(colorHex, 5, 2))

		; Perceptual luminance formula: Human eye is most sensitive to green
		lum := (0.299 * r) + (0.587 * g) + (0.114 * b)
		colorData.Push({ hex: colorHex, lum: lum })
	}

	; Bubble sort for descending luminance (Brightest colors at the end of the array)
	loop colorData.Length - 1 {
		i := A_Index
		loop colorData.Length - i {
			j := A_Index
			if (colorData[j].lum < colorData[j + 1].lum) {
				temp := colorData[j]
				colorData[j] := colorData[j + 1]
				colorData[j + 1] := temp
			}
		}
	}

	; Rebuild the palette array
	newPalette := []
	for item in colorData
		newPalette.Push(item.hex)

	State.Palette := newPalette
	State.PaletteChanged := true
	RenderPalette()
}

; Draws palette cells from newest to oldest.
RenderPalette() {
	emptyColor := "F0F0F0"
	pCount := State.Palette.Length

	loop State.PaletteMax {
		if (A_Index <= pCount) {
			colorHex := State.Palette[pCount - A_Index + 1]
		} else {
			colorHex := emptyColor
		}
		State.PalCtl[A_Index].Opt("Background" colorHex)
	}
}

LoadPaletteFromDisk() {
	try raw := FileRead(APP.PaletteFile)
	catch
		raw := ""

	raw := Trim(raw, " `t`r`n")
	if (raw = "")
		return

	loaded := []
	seen := Map()
	for _, part in StrSplit(raw, ",") {
		colorHex := StrUpper(Trim(part))
		if (!RegExMatch(colorHex, "^[0-9A-F]{6}$"))
			continue
		if (seen.Has(colorHex))
			continue
		seen[colorHex] := true
		loaded.Push(colorHex)
	}

	while (loaded.Length > State.PaletteMax)
		loaded.RemoveAt(1)

	State.Palette := loaded
}

SavePaletteToDisk(*) {
	if (!State.PaletteChanged) ; No changes since last save, skip writing to disk
		return

	serialized := ""
	for idx, colorHex in State.Palette
		serialized .= (idx > 1 ? "," : "") colorHex

	try {
		f := FileOpen(APP.PaletteFile, "w")
		if IsObject(f) {
			f.Write(serialized)
			f.Close()
		}
	}
}

; Moves the mouse cursor relative to its current position and updates the display.
MoveMouse(x, y) {
	MouseMove(x, y, 0, "R")
	UpdateLoop()
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

	; Dynamic bar color by current channel intensity
	if (tag = "Red")
		cColor := (val << 16)
	else if (tag = "Grn")
		cColor := (val << 8)
	else
		cColor := val

	controls[tag "Pb"].Opt(Format("c{:06X}", cColor))
}

; Calculates the number of visible cells in the grid based on frame size and zoom factor.
GetVisibleCellCount(frameSize, zoomFactor) {
	count := Floor(frameSize / zoomFactor) ; Calculate how many cells fit without cropping
	count := Max(APP.MinCells, count) ; Set the minimum number of visible cells
	return Mod(count, 2) = 0 ? count - 1 : count ; Return the number of visible cells
}

; Captures one extra pixel from each side (visible + 2) so the zoom view always fully fills after centered crop.
GetCaptureCellCount(frameSize, zoomFactor) {
	count := GetVisibleCellCount(frameSize, zoomFactor) + 2
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

; Shared RGB pre-calculation for HSL and HSV
; Helper function to calculate common values (Hue, Max, Min, Delta) for HSL and HSV conversions.
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

; Retrieves the standard color name
GetColorName(hexColor) {
	static colorNames := Map(
		"000000", "Black", "000080", "Navy", "00008B", "DarkBlue", "0000CD", "MediumBlue",
		"0000FF", "Blue", "006400", "DarkGreen", "008000", "Green", "008080", "Teal",
		"008B8B", "DarkCyan", "00BFFF", "DeepSkyBlue", "00CED1", "DarkTurquoise", "00FA9A", "MediumSpringGreen",
		"00FF00", "Lime", "00FF7F", "SpringGreen", "00FFFF", "Cyan",
		"191970", "MidnightBlue", "1E90FF", "DodgerBlue", "20B2AA", "LightSeaGreen", "228B22", "ForestGreen",
		"2E8B57", "SeaGreen", "2F4F4F", "DarkSlateGray", "32CD32", "LimeGreen", "3CB371", "MediumSeaGreen",
		"40E0D0", "Turquoise", "4169E1", "RoyalBlue", "4682B4", "SteelBlue", "483D8B", "DarkSlateBlue",
		"48D1CC", "MediumTurquoise", "4B0082", "Indigo", "556B2F", "DarkOliveGreen", "5F9EA0", "CadetBlue",
		"6495ED", "CornflowerBlue", "663399", "RebeccaPurple", "66CDAA", "MediumAquaMarine", "696969", "DimGray",
		"6A5ACD", "SlateBlue", "6B8E23", "OliveDrab", "708090", "SlateGray", "778899", "LightSlateGray",
		"7B68EE", "MediumSlateBlue", "7CFC00", "LawnGreen", "7FFF00", "Chartreuse", "7FFFD4", "Aquamarine",
		"800000", "Maroon", "800080", "Purple", "808000", "Olive", "808080", "Gray",
		"87CEEB", "SkyBlue", "87CEFA", "LightSkyBlue", "8A2BE2", "BlueViolet", "8B0000", "DarkRed",
		"8B008B", "DarkMagenta", "8B4513", "SaddleBrown", "8FBC8F", "DarkSeaGreen", "90EE90", "LightGreen",
		"9370DB", "MediumPurple", "9400D3", "DarkViolet", "98FB98", "PaleGreen", "9932CC", "DarkOrchid",
		"9ACD32", "YellowGreen", "A0522D", "Sienna", "A52A2A", "Brown", "A9A9A9", "DarkGray",
		"ADD8E6", "LightBlue", "ADFF2F", "GreenYellow", "AFEEEE", "PaleTurquoise", "B0C4DE", "LightSteelBlue",
		"B0E0E6", "PowderBlue", "B22222", "FireBrick", "B8860B", "DarkGoldenRod", "BA55D3", "MediumOrchid",
		"BC8F8F", "RosyBrown", "BDB76B", "DarkKhaki", "C0C0C0", "Silver", "C71585", "MediumVioletRed",
		"CD5C5C", "IndianRed", "CD853F", "Peru", "D2691E", "Chocolate", "D2B48C", "Tan",
		"D3D3D3", "LightGray", "D8BFD8", "Thistle", "DA70D6", "Orchid", "DAA520", "GoldenRod",
		"DB7093", "PaleVioletRed", "DC143C", "Crimson", "DCDCDC", "Gainsboro", "DDA0DD", "Plum",
		"DEB887", "BurlyWood", "E0FFFF", "LightCyan", "E6E6FA", "Lavender", "E9967A", "DarkSalmon",
		"EE82EE", "Violet", "EEE8AA", "PaleGoldenRod", "F08080", "LightCoral", "F0E68C", "Khaki",
		"F0F8FF", "AliceBlue", "F0FFF0", "HoneyDew", "F0FFFF", "Azure", "F4A460", "SandyBrown",
		"F5DEB3", "Wheat", "F5F5DC", "Beige", "F5F5F5", "WhiteSmoke", "F5FFFA", "MintCream",
		"F8F8FF", "GhostWhite", "FA8072", "Salmon", "FAEBD7", "AntiqueWhite", "FAF0E6", "Linen",
		"FAFAD2", "LightGoldenRodYellow", "FDF5E6", "OldLace", "FF0000", "Red", "FF00FF", "Magenta",
		"FF1493", "DeepPink", "FF4500", "OrangeRed", "FF6347", "Tomato",
		"FF69B4", "HotPink", "FF7F50", "Coral", "FF8C00", "DarkOrange", "FFA07A", "LightSalmon",
		"FFA500", "Orange", "FFB6C1", "LightPink", "FFC0CB", "Pink", "FFD700", "Gold",
		"FFDAB9", "PeachPuff", "FFDEAD", "NavajoWhite", "FFE4B5", "Moccasin", "FFE4C4", "Bisque",
		"FFE4E1", "MistyRose", "FFEBCD", "BlanchedAlmond", "FFEFD5", "PapayaWhip", "FFF0F5", "LavenderBlush",
		"FFF5EE", "SeaShell", "FFF8DC", "Cornsilk", "FFFACD", "LemonChiffon", "FFFAF0", "FloralWhite",
		"FFFAFA", "Snow", "FFFF00", "Yellow", "FFFFE0", "LightYellow", "FFFFF0", "Ivory",
		"FFFFFF", "White"
	)
	return colorNames.Has(hexColor) ? colorNames[hexColor] : ""
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

	MsgBox(msg, APP.Name, "Icon 64 Owner" mGui.Hwnd)
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
