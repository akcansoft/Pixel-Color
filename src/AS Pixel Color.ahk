; AS Pixel Color
; 14/02/2026

; Mesut Akcan
; -----------
; github.com/akcansoft
; mesutakcan.blogspot.com
; youtube.com/mesutakcan

; TODO:
; - Implement 'Add to Favorites' feature for colors

#Requires AutoHotkey v2+
#SingleInstance Force

; ========== COMPILER DIRECTIVES ==========
;@Ahk2Exe-SetName AS Pixel Color
;@Ahk2Exe-SetDescription AS Pixel Color
;@Ahk2Exe-SetFileVersion 2.2
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
	Ver: "2.2",
	Interval: 100,          ; Update interval (ms)
	Size: 216,              ; Grid display size (px)
	MinCells: 3,            ; Keep at least 3x3 cells visible
	DefIdx: 6,              ; Default zoom index -> 15x
	GridCol: 0xFFBCBCBC,    ; Grid and border color
	EditBg: "BackgroundFFFFF0", ; Edit controls background color
	ZoomSteps: [2, 3, 4, 5, 7, 9, 11, 15, 20, 25, 30, 37, 45, 55, 65, 70] ; Zoom levels (x) corresponding to slider positions
}

global State := {
	ZoomIdx: APP.DefIdx,                ; Current zoom index in the ZoomSteps array
	ZoomLvl: APP.ZoomSteps[APP.DefIdx], ; Current zoom level (e.g., 15x)
	ZoomEnabled: true,                  ; Whether zoom preview is enabled
	GridEnabled: true,                  ; Whether grid lines are enabled
	IsRendering: false,                 ; Flag to prevent updates while rendering is in progress
	; Mouse position, color, and zoom level from the last update cycle
	LastX: -1, LastY: -1, LastC: -1, LastZ: -1
}

; Screen-based coordinates for mouse and pixel sampling
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ========================================
; GUI CREATION
; ========================================
mGui := Gui("+AlwaysOnTop", APP.Name)
mGui.SetFont("s9", "Segoe UI")
mGui.MarginX := 10
mGui.MarginY := 10

; Left panel
; Color preview
mGui.AddText("x10 y10", "Color Preview:")
pb_Color := mGui.AddProgress("x10 y30 w216 h135 Border")

; Grid lines
chk_GridLines := mGui.AddCheckBox("x10 y180 Checked", "Grid lines")
chk_GridLines.OnEvent("Click", ToggleGridLines)

; Zoom
gridDisplay := GDIPlusGrid(mGui, 10, 200, APP.Size, APP.GridCol)

; Zoom slider
sld_Zoom := mGui.AddSlider("x10 y420 w216 Range1-" APP.ZoomSteps.Length " ToolTip", State.ZoomIdx)
sld_Zoom.OnEvent("Change", (ctrl, *) => ChangeZoom(ctrl.Value, true))

; Zoom checkbox
chk_Zoom := mGui.AddCheckBox("x10 y465 Checked", "Zoom")
chk_Zoom.OnEvent("Click", ToggleZoom)

; Zoom level
txt_ZoomLevel := mGui.AddText("x+5 yp w90 Center", "Zoom: " State.ZoomLvl "x")
mGui.AddButton("x+5 yp-5 w60 h25", "Reset").OnEvent("Click", (*) => ChangeZoom(APP.DefIdx, true))

; Right panel
rX := 240, gbW := 280
chk_Upd := mGui.AddCheckBox("x" rX " y10 +Checked", "Update (F1)")
mGui.AddCheckBox("x+15 yp +Checked", "Always on Top").OnEvent("Click", (ctrl, *) => WinSetAlwaysOnTop(ctrl.Value ? 1 :
	0, mGui.Hwnd))

; Source info
mGui.AddGroupBox("x" rX " y35 w" gbW " h130", "Source Info")
txt_Position := mGui.AddText("x" rX + 10 " y55 w150", "Position: 0, 0")

; RGB color codes
rgbTags := ["Red", "Grn", "Blu"], rgbLabels := ["Red:", "Green:", "Blue:"], rgbColors := ["cRed", "cLime", "cBlue"]
rgbCtl := Map() ; Store RGB control references for easy updates

; RGB color code boxes
loop 3 {
	yPos := 75 + (A_Index - 1) * 27
	mGui.AddText("x" rX + 10 " y" yPos, rgbLabels[A_Index])
	rgbCtl[rgbTags[A_Index] "Hex"] := mGui.AddEdit("x" rX + 50 " y" yPos - 3 " w35 " APP.EditBg)
	rgbCtl[rgbTags[A_Index] "Dec"] := mGui.AddEdit("x+5 yp w35 " APP.EditBg)
	rgbCtl[rgbTags[A_Index] "Pb"] := mGui.AddProgress("x+10 yp w130 BackgroundDDDDDD Range0-255 h22 " rgbColors[A_Index])
}

; Color codes group box
mGui.AddGroupBox("x" rX " y170 w" gbW " h280", "Color Codes")
fields := ["Hex", "Dec", "Rgb", "RgbPercent", "Rgba", "Bgr", "Cmyk", "Hsl", "Hsv"]
labels := ["HEX:", "DEC:", "RGB:", "RGB%:", "RGBA:", "BGR:", "CMYK:", "HSL:", "HSV:"]
txtCtl := Map() ; Store color code control references for easy updates

; Color code boxes
loop fields.Length {
	yPos := 190 + (A_Index - 1) * 25
	mGui.AddText("x" rX + 10 " y" yPos, labels[A_Index])
	txtCtl[fields[A_Index]] := mGui.AddEdit("x" rX + 50 " w160 y" yPos - 3 " " APP.EditBg)
	mGui.AddButton("x+5 yp-1 w50 V" fields[A_Index], "Copy").OnEvent("Click", CopyToClipboard)
}

; Color name
mGui.AddText("x" rX + 10 " y415", "Color Name:")
txt_Cn := mGui.AddEdit("x" rX + 80 " y412 w130 " APP.EditBg)
; Buttons
mGui.AddButton("x+5 yp-1 w50 VCn", "Copy").OnEvent("Click", CopyToClipboard)
mGui.AddButton("x" rX + 110 " y460 w80 h25", "About").OnEvent("Click", About)
mGui.AddButton("x+5 yp w80 h25", "Close").OnEvent("Click", (*) => ExitApp())

mGui.OnEvent("Close", (*) => ExitApp())
OnMessage(0x020A, WM_MOUSEWHEEL) ; Mouse wheel zoom
mGui.Show("w530 h500")

SetTimer(UpdateLoop, APP.Interval) ; Update loop

; ========================================
; Main loop that checks for mouse movement or color changes and updates the UI accordingly.
UpdateLoop() {
	if (!chk_Upd.Value)
		return

	; Don't update while rendering is in progress
	if (State.IsRendering)
		return

	MouseGetPos(&mX, &mY)
	currZ := State.ZoomLvl

	try currC := Integer(PixelGetColor(mX, mY))
	catch {
		if (State.LastC < 0)
			return
		currC := State.LastC
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
		MouseGetPos(&x, &y)

	z := IsSet(z) ? z : State.ZoomLvl
	txt_ZoomLevel.Value := "Zoom: " z "x"

	try colors := GetScreenColors(x, y, z, APP.Size)
	catch
		return

	; Always release render lock, even if draw fails
	State.IsRendering := true
	try {
		gridDisplay.Draw(colors, z, State.GridEnabled)
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
	txtCtl["Hsl"].Value := Format("hsl({}, {}%, {}%)", hsl.h, hsl.s, hsl.l)

	hsv := RGBtoHSVFromHSX(hsxRes)
	txtCtl["Hsv"].Value := Format("hsv({}, {}%, {}%)", hsv.h, hsv.s, hsv.v)

	txt_Cn.Value := GetColorName(colorHex)
}

; ========================================
; TOOLS
; ========================================
; Toggles the zoom functionality on or off.
ToggleZoom(ctrl, *) {
	State.ZoomEnabled := ctrl.Value
	gridDisplay.ctrl.Visible := ctrl.Value
}

; Toggles the visibility of grid lines in the zoom preview.
ToggleGridLines(ctrl, *) {
	State.GridEnabled := ctrl.Value
	RefreshGrid()
}

; Changes the zoom level
ChangeZoom(val, absolute := false) {
	newIdx := absolute ? Round(val) : State.ZoomIdx + val
	newIdx := Max(1, Min(APP.ZoomSteps.Length, newIdx))

	if (newIdx != State.ZoomIdx) {
		State.ZoomIdx := newIdx
		State.ZoomLvl := APP.ZoomSteps[State.ZoomIdx]
		RefreshGrid()
	}

	txt_ZoomLevel.Value := "Zoom: " State.ZoomLvl "x"
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

; Moves the mouse cursor relative to its current position and updates the display.
MoveMouse(x, y) {
	MouseMove(x, y, 0, "R")
	UpdateLoop()
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
GetVisibleCellCount(frameSize, zoomFactor, minCells := APP.MinCells) {
	count := Floor((frameSize - 2) / zoomFactor) ; Calculate the number of visible cells in the grid
	count := Max(minCells, count) ; Set the minimum number of visible cells
	return Mod(count, 2) = 0 ? count - 1 : count ; Return the number of visible cells
}

; Captures the screen pixels around the cursor slightly larger than the visible area for the grid display.
GetScreenColors(cX, cY, zoom, frameSize) {
	count := GetVisibleCellCount(frameSize, zoom) ; Calculate the number of visible cells in the grid
	half := count // 2 ; Calculate the half of the visible cells

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

	; If completely outside, return an empty grid (all cells invalid)
	if (validX1 > validX2 || validY1 > validY2) {
		res := []
		loop count {
			row := []
			loop count
				row.Push(-1)
			res.Push(row)
		}
		return res
	}

	bltW := validX2 - validX1 + 1
	bltH := validY2 - validY1 + 1
	dstX := validX1 - srcX
	dstY := validY1 - srcY
	validColStart := dstX + 1
	validColEnd := validColStart + bltW - 1
	validRowStart := dstY + 1
	validRowEnd := validRowStart + bltH - 1

	hDC := DllCall("GetDC", "Ptr", 0, "Ptr") ; Get desktop window handle
	mDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr") ; Create a compatible DC
	hBM := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", count, "Int", count, "Ptr") ; Create a compatible bitmap
	oBM := DllCall("SelectObject", "Ptr", mDC, "Ptr", hBM, "Ptr") ; Select the bitmap into the DC

	DllCall("BitBlt", "Ptr", mDC, "Int", dstX, "Int", dstY, "Int", bltW, "Int", bltH, "Ptr", hDC, "Int", validX1, "Int",
		validY1, "UInt", 0x00CC0020) ; Copy only the valid source pixels

	bi := Buffer(40, 0) ; Create a buffer to store the bitmap information
	NumPut("UInt", 40, "Int", count, "Int", -count, "UShort", 1, "UShort", 32, bi) ; Set the bitmap information
	pixelBuf := Buffer(count * count * 4) ; Create a buffer to store the pixel data
	DllCall("GetDIBits", "Ptr", mDC, "Ptr", hBM, "UInt", 0, "UInt", count, "Ptr", pixelBuf, "Ptr", bi, "UInt", 0) ; Get the pixel data from the bitmap

	DllCall("SelectObject", "Ptr", mDC, "Ptr", oBM) ; Select the original bitmap back into the DC
	DllCall("DeleteObject", "Ptr", hBM) ; Delete the bitmap
	DllCall("DeleteDC", "Ptr", mDC) ; Delete the DC
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC) ; Release the DC

	res := [] ; Create an array to store the pixel data
	stride := count * 4

	loop count {
		rIdx := A_Index ; Get the current row index
		row := [] ; Create an array to store the pixel data for the current row
		baseOffset := (rIdx - 1) * stride

		loop count {
			cIdx := A_Index
			if (rIdx >= validRowStart && rIdx <= validRowEnd && cIdx >= validColStart && cIdx <= validColEnd) {
				off := baseOffset + (cIdx - 1) * 4
				bgrx := NumGet(pixelBuf, off, "UInt") ; Get the pixel data from the buffer
				row.Push(((bgrx >> 16) & 0xFF) << 16 | ((bgrx >> 8) & 0xFF) << 8 | (bgrx & 0xFF))
			} else {
				row.Push(-1)
			}
		}
		res.Push(row) ; Add the row to the result array
	}
	return res ; Return the result array
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
		"F0F8FF", "AliceBlue", "FAEBD7", "AntiqueWhite", "00FFFF", "Aqua", "7FFFD4", "Aquamarine",
		"F0FFFF", "Azure", "F5F5DC", "Beige", "FFE4C4", "Bisque", "000000", "Black", "FFEBCD", "BlanchedAlmond",
		"0000FF", "Blue", "8A2BE2", "BlueViolet", "A52A2A", "Brown", "DEB887", "BurlyWood", "5F9EA0", "CadetBlue",
		"7FFF00", "Chartreuse", "D2691E", "Chocolate", "FF7F50", "Coral", "6495ED", "CornflowerBlue",
		"FFF8DC", "Cornsilk", "DC143C", "Crimson", "00FFFF", "Cyan", "00008B", "DarkBlue", "008B8B", "DarkCyan",
		"B8860B", "DarkGoldenRod", "A9A9A9", "DarkGray", "006400", "DarkGreen", "BDB76B", "DarkKhaki",
		"8B008B", "DarkMagenta", "556B2F", "DarkOliveGreen", "FF8C00", "DarkOrange", "9932CC", "DarkOrchid",
		"8B0000", "DarkRed", "E9967A", "DarkSalmon", "8FBC8F", "DarkSeaGreen", "483D8B", "DarkSlateBlue",
		"2F4F4F", "DarkSlateGray", "00CED1", "DarkTurquoise", "9400D3", "DarkViolet", "FF1493", "DeepPink",
		"00BFFF", "DeepSkyBlue", "696969", "DimGray", "1E90FF", "DodgerBlue", "B22222", "FireBrick",
		"FFFAF0", "FloralWhite", "228B22", "ForestGreen", "FF00FF", "Fuchsia", "DCDCDC", "Gainsboro",
		"F8F8FF", "GhostWhite", "FFD700", "Gold", "DAA520", "GoldenRod", "808080", "Gray", "008000", "Green",
		"ADFF2F", "GreenYellow", "F0FFF0", "HoneyDew", "FF69B4", "HotPink", "CD5C5C", "IndianRed",
		"4B0082", "Indigo", "FFFFF0", "Ivory", "F0E68C", "Khaki", "E6E6FA", "Lavender", "FFF0F5", "LavenderBlush",
		"7CFC00", "LawnGreen", "FFFACD", "LemonChiffon", "ADD8E6", "LightBlue", "F08080", "LightCoral",
		"E0FFFF", "LightCyan", "FAFAD2", "LightGoldenRodYellow", "D3D3D3", "LightGray", "90EE90", "LightGreen",
		"FFB6C1", "LightPink", "FFA07A", "LightSalmon", "20B2AA", "LightSeaGreen", "87CEFA", "LightSkyBlue",
		"778899", "LightSlateGray", "B0C4DE", "LightSteelBlue", "FFFFE0", "LightYellow", "00FF00", "Lime",
		"32CD32", "LimeGreen", "FAF0E6", "Linen", "FF00FF", "Magenta", "800000", "Maroon",
		"66CDAA", "MediumAquaMarine", "0000CD", "MediumBlue", "BA55D3", "MediumOrchid", "9370DB", "MediumPurple",
		"3CB371", "MediumSeaGreen", "7B68EE", "MediumSlateBlue", "00FA9A", "MediumSpringGreen", "48D1CC",
		"MediumTurquoise", "C71585", "MediumVioletRed", "191970", "MidnightBlue", "F5FFFA", "MintCream",
		"FFE4E1", "MistyRose", "FFE4B5", "Moccasin", "FFDEAD", "NavajoWhite", "000080", "Navy",
		"FDF5E6", "OldLace", "808000", "Olive", "6B8E23", "OliveDrab", "FFA500", "Orange", "FF4500", "OrangeRed",
		"DA70D6", "Orchid", "EEE8AA", "PaleGoldenRod", "98FB98", "PaleGreen", "AFEEEE", "PaleTurquoise",
		"DB7093", "PaleVioletRed", "FFEFD5", "PapayaWhip", "FFDAB9", "PeachPuff", "CD853F", "Peru",
		"FFC0CB", "Pink", "DDA0DD", "Plum", "B0E0E6", "PowderBlue", "800080", "Purple", "663399", "RebeccaPurple",
		"FF0000", "Red", "BC8F8F", "RosyBrown", "4169E1", "RoyalBlue", "8B4513", "SaddleBrown",
		"FA8072", "Salmon", "F4A460", "SandyBrown", "2E8B57", "SeaGreen", "FFF5EE", "SeaShell",
		"A0522D", "Sienna", "C0C0C0", "Silver", "87CEEB", "SkyBlue", "6A5ACD", "SlateBlue", "708090", "SlateGray",
		"FFFAFA", "Snow", "00FF7F", "SpringGreen", "4682B4", "SteelBlue", "D2B48C", "Tan", "008080", "Teal",
		"D8BFD8", "Thistle", "FF6347", "Tomato", "40E0D0", "Turquoise", "EE82EE", "Violet", "F5DEB3", "Wheat",
		"FFFFFF", "White", "F5F5F5", "WhiteSmoke", "FFFF00", "Yellow", "9ACD32", "YellowGreen"
	)
	return colorNames.Has(hexColor) ? colorNames[hexColor] : ""
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

		this.ctrl := guiObj.AddPicture("x" x " y" y " w" size " h" size " BackgroundTrans 0xE")
		this.hPic := this.ctrl.Hwnd

		DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", this.pSize, "Int", this.pSize, "Int", 0, "Int", 0x26200A,
			"Ptr", 0, "Ptr*", &pBM := 0)
		this.pBM := pBM
		DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBM, "Ptr*", &pG := 0)
		this.pG := pG

		DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pG, "Int", 0)
		DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pG, "Int", 0)

		DllCall("gdiplus\GdipCreateSolidFill", "UInt", gridCol, "Ptr*", &pB := 0)
		this.gridBrush := pB
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000, "Ptr*", &pCB := 0)
		this.cellBrush := pCB
	}

	; Draws the grid of pixels using GDI+.
	Draw(colors, zoom, showGrid) {
		; Clear previous frame
		DllCall("gdiplus\GdipGraphicsClear", "Ptr", this.pG, "UInt", this.bgCol)

		count := colors.Length
		if (count < 1)
			return

		cellSize := zoom * this.scale
		actSize := cellSize * count
		off := Max(0, (this.pSize - actSize) / 2)

		bThick := Max(1, Floor(this.scale))
		DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.gridBrush, "Float", off - bThick, "Float", off -
			bThick, "Float", actSize + 2 * bThick, "Float", actSize + 2 * bThick)

		gap := (showGrid && cellSize >= 5 * this.scale) ? Max(1, Floor(this.scale)) : 0

		loop count {
			r := A_Index
			y := (r - 1) * cellSize + off
			h := Max(1, cellSize - gap)
			loop count {
				cellColor := colors[r][A_Index]
				if (cellColor < 0)
					continue
				DllCall("gdiplus\GdipSetSolidFillColor", "Ptr", this.cellBrush, "UInt", 0xFF000000 | cellColor)
				DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pG, "Ptr", this.cellBrush, "Float", (A_Index - 1) *
					cellSize + off, "Float", y, "Float", Max(1, cellSize - gap), "Float", h)
			}
		}

		; Center marker: black outer border + white inner border
		mid := (count // 2) + 1
		hx := (mid - 1) * cellSize + off
		hy := (mid - 1) * cellSize + off
		hw := Max(1, cellSize - gap)
		hh := Max(1, cellSize - gap)

		t := bThick
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

; Displays the 'About' dialog box with version and author information.
About(*) {
	msg := Format("
(
{} v{}`n
©2026 Mesut Akcan 
makcan@gmail.com
github.com/akcansoft
mesutakcan.blogspot.com
youtube.com/mesutakcan
)", APP.Name, APP.Ver)

	MsgBox(msg, APP.Name, "Icon 64 Owner" mGui.Hwnd)
}

; ========================================
; HOTKEYS
; ========================================
F1:: chk_Upd.Value := !chk_Upd.Value

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
