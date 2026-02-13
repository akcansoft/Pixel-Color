;@Ahk2Exe-SetName AS Pixel Color
;@Ahk2Exe-SetDescription AS Pixel Color
;@Ahk2Exe-SetFileVersion 2.1
;@Ahk2Exe-SetCompanyName AkcanSoft
;@Ahk2Exe-SetCopyright ©2026 Mesut Akcan
;@Ahk2Exe-SetMainIcon app_icon.ico

; AS Pixel Color
; 13/02/2026

; Mesut Akcan
; -----------
; mesutakcan.blogspot.com
; github.com/akcansoft
; youtube.com/mesutakcan

; TODO:
; - Implement 'Add to Favorites' feature for colors
; - Option to toggle grid lines visibility

#Requires AutoHotkey v2+
#SingleInstance Force

; ========== TRAY ICON ==========
; Set tray icon for source code (ignored in compiled EXE)
;@Ahk2Exe-IgnoreBegin
try TraySetIcon(A_ScriptDir "\app_icon.ico")
;@Ahk2Exe-IgnoreEnd

; Set coordinate mode to Screen
CoordMode("Mouse", "Screen")
CoordMode("Pixel", "Screen")

; ========================================
; GLOBAL CONSTANTS
; ========================================
A_ScriptName := "AS Pixel Color"
updateInterval := 100 ; Update interval in milliseconds
zoomEnabled := true ; Zoom enabled by default
defaultZoom := 15 ; Default zoom level
zoomLevel := defaultZoom ; Current zoom level
maxZoom := 45 ; Maximum zoom level
minZoom := 3  ; Minimum zoom level
gridColor := 0xFFBCBCBC ; Grid Color
edtBgColor := "BackgroundFFFFF0" ; EditBox Background Color

; ========================================
; CREATE GUI
; ========================================
mGui := Gui("+AlwaysOnTop", A_ScriptName)
mGui.SetFont("s9", "Segoe UI")
mGui.MarginX := 10
mGui.MarginY := 10

; ========================================
; LEFT SIDE CONTROLS
; ========================================

; 1. Color Preview
mGui.AddText("x10 y10", "Color Preview:")
pb_Color := mGui.AddProgress("x10 y30 w216 h135 Border")

; 2. Grid Settings
totalGridSize := 216  ; Fixed total size
startX := 10 ; Starting X coordinate for grid
startY := 180 ; Starting Y coordinate for grid

; Create Background Border (Container)
pb_GridBorder := mGui.AddProgress("x" startX - 1 " y" startY - 1 " w" totalGridSize + 2 " h" totalGridSize + 2)

; Initialize GDI+ Grid
gridDisplay := GDIPlusGrid(mGui, startX, startY, totalGridSize, gridColor)

; 3. Zoom controls
; Slider (Range 0-21 maps to zoom 3-45: zoom = val * 2 + 3)
sld_Zoom := mGui.AddSlider("x10 y400 w216 Range0-" (maxZoom - minZoom) // 2 " ToolTip", (zoomLevel - minZoom) // 2)
sld_Zoom.OnEvent("Change", (ctrl, *) => ChangeZoom(ctrl.Value * 2 + minZoom, true))

chk_Zoom := mGui.AddCheckBox("x10 y440 Checked", "Zoom")
chk_Zoom.OnEvent("Click", ToggleZoom)

txt_ZoomLevel := mGui.AddText("x+5 yp w40 Center", Format("{}x{}", zoomLevel, zoomLevel))

btn_ZoomDefault := mGui.AddButton("x+5 yp-5 w60 h25", "Reset")
btn_ZoomDefault.OnEvent("Click", (*) => ChangeZoom(defaultZoom, true))

; Add Mouse Wheel Support
OnMessage(0x020A, WM_MOUSEWHEEL) ; 0x020A = WM_MOUSEWHEEL

; ========================================
; RIGHT SIDE CONTROLS
; ========================================
rightX := 240 ; Starting X coordinate for right side controls
gbW := 280 ; groupbox width

; App Controls (Right Side Top)
chk_Upd := mGui.AddCheckBox("x" rightX " y10 +Checked", "Update (F1)")
chk_Aot := mGui.AddCheckBox("x+15 yp +Checked", "Always on Top")
chk_Aot.OnEvent("Click", (*) => WinSetAlwaysOnTop(-1, "A"))

; GroupBox 1: Source Info
mGui.AddGroupBox("x" rightX " y35 w" gbW " h130", "Source Info")

; 1. Position display (Inside GB1)
txt_Position := mGui.AddText("x" rightX + 10 " y55 w150", "Position: 0, 0")

; 2. RGB Components (Inside GB1)
rgbY := 75 ; rgb y position
txtW := 35 ; textbox width

rgbTags := ["Red", "Grn", "Blu"]
rgbLabels := ["Red:", "Green:", "Blue:"]
rgbColors := ["cRed", "cLime", "cBlue"]
rgbControls := Map()

; RGB Component Controls
loop 3 {
	i := A_Index
	yPos := rgbY + (i - 1) * 27
	mGui.AddText("x" rightX + 10 " y" yPos, rgbLabels[i])
	rgbControls[rgbTags[i] "Hex"] := mGui.AddEdit("x" rightX + 50 " y" yPos - 3 " w" txtW " " edtBgColor)
	rgbControls[rgbTags[i] "Dec"] := mGui.AddEdit("x+5 yp w" txtW " " edtBgColor)
	rgbControls[rgbTags[i] "Pb"] := mGui.AddProgress("x+10 yp w130 BackgroundDDDDDD Range0-255 h22 " rgbColors[i])
}

; GroupBox 2: Color Codes
mGui.AddGroupBox("x" rightX " y170 w" gbW " h280", "Color Codes")

; Text Formats (Inside GroupBox 2)
fmtY := 190 ; text format y position

fields := ["Hex", "Dec", "Rgb", "RgbPercent", "Rgba", "Bgr", "Cmyk", "Hsl", "Hsv"]
labels := ["HEX:", "DEC:", "RGB:", "RGB%:", "RGBA:", "BGR:", "CMYK:", "HSL:", "HSV:"]
txtControls := Map()

loop fields.Length {
	i := A_Index
	yPos := fmtY + (i - 1) * 25
	mGui.AddText("x" rightX + 10 " y" yPos, labels[i])
	txtControls[fields[i]] := mGui.AddEdit("x" rightX + 50 " w160 y" yPos - 3 " " edtBgColor)
	mGui.AddButton("x+5 yp-1 w50 V" fields[i], "Copy").OnEvent("Click", CopyToClipboard)
}

mGui.AddText("x" rightX + 10 " y" fmtY + 225, "Color Name:")
txt_Cn := mGui.AddEdit("x" rightX + 80 " y" fmtY + 222 " w130 " edtBgColor)
mGui.AddButton("x+5 yp-1 w50 VCn", "Copy").OnEvent("Click", CopyToClipboard)

; App Controls (Right Side Bottom)
btn_About := mGui.AddButton("x" rightX " y455 w80 h25", "About")
btn_About.OnEvent("Click", About)

btn_Close := mGui.AddButton("x+5 yp w80 h25", "Close")
btn_Close.OnEvent("Click", (*) => ExitApp())

mGui.OnEvent("Close", (*) => ExitApp())

; ========================================
; HOTKEYS
; ========================================
F1:: chk_Upd.Value := !chk_Upd.Value

; --- Mouse Movement Hotkeys ---
; Ctrl + Arrow Keys: Move mouse 1 pixel
; Ctrl + Shift + Arrow Keys: Move mouse 10 pixels
#HotIf !WinActive("ahk_class #32770") ; Do not run when dialogs are open
^Up:: MoveMouse(0, -1) ; Ctrl+Up
^Down:: MoveMouse(0, 1) ; Ctrl+Down
^Left:: MoveMouse(-1, 0) ; Ctrl+Left
^Right:: MoveMouse(1, 0) ; Ctrl+Right

^+Up:: MoveMouse(0, -10) ; Ctrl+Shift+Up
^+Down:: MoveMouse(0, 10) ; Ctrl+Shift+Down
^+Left:: MoveMouse(-10, 0) ; Ctrl+Shift+Left
^+Right:: MoveMouse(10, 0) ; Ctrl+Shift+Right
#HotIf

; ========================================
; START APPLICATION
; ========================================
mGui.Show("w530 h490")
SetTimer(UpdatePixelColor, updateInterval)

; Zoom Control Functions
ToggleZoom(*) {
	global zoomEnabled, chk_Zoom
	zoomEnabled := chk_Zoom.Value
	gridDisplay.ctrl.Visible := zoomEnabled
}

ChangeZoom(value, isAbsolute := false, *) {
	global zoomLevel, txt_ZoomLevel, sld_Zoom

	; Calculate new zoom level
	newZoom := isAbsolute ? ((value // 2) * 2 + 1) : zoomLevel + value

	if (newZoom >= minZoom && newZoom <= maxZoom) {
		zoomLevel := newZoom
		txt_ZoomLevel.Value := Format("{}x{}", zoomLevel, zoomLevel)
		if (IsSet(sld_Zoom)) {
			sldVal := (zoomLevel - minZoom) // 2
			if (sld_Zoom.Value != sldVal)
				sld_Zoom.Value := sldVal
		}
		RefreshGrid()
	}
}

; Mouse Wheel Support
WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
	if (!chk_Zoom.Value)
		return

	; Wheel direction
	delta := (wParam << 32 >> 48) ; 120 or -120

	; Use step of 2 to keep zoomLevel odd (3, 5, 7...)
	if (delta > 0)
		ChangeZoom(2, false)
	else
		ChangeZoom(-2, false)
}

; Copy to Clipboard
CopyToClipboard(ctrl, *) {
	global txtControls, txt_Cn
	textToCopy := ""

	if (ctrl.Name = "Cn")
		textToCopy := txt_Cn.Value
	else if txtControls.Has(ctrl.Name)
		textToCopy := txtControls[ctrl.Name].Value

	if (textToCopy != "") {
		A_Clipboard := textToCopy
		ToolTip("Copied: " textToCopy)
		SetTimer(() => ToolTip(), -1500)
	}
}

; RGB to CMYK Color Conversion
RGBtoCMYK(r, g, b) {
	r := r / 255.0, g := g / 255.0, b := b / 255.0
	k := 1 - Max(r, g, b)

	if (k = 1)  ; Black
		return { c: 0, m: 0, y: 0, k: 100 }

	c := (1 - r - k) / (1 - k)
	m := (1 - g - k) / (1 - k)
	y := (1 - b - k) / (1 - k)

	return {
		c: Round(c * 100),
		m: Round(m * 100),
		y: Round(y * 100),
		k: Round(k * 100)
	}
}

; Helper function for HSL/HSV shared logic
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

; RGB to HSL Color Conversion
RGBtoHSL(r, g, b) {
	res := RGBtoHSX(r, g, b)
	l := (res.mx + res.mn) / 2
	s := (res.d == 0) ? 0 : (l > 0.5 ? res.d / (2 - res.mx - res.mn) : res.d / (res.mx + res.mn))
	return { h: res.h, s: Round(s * 100), l: Round(l * 100) }
}

; RGB to HSV Color Conversion
RGBtoHSV(r, g, b) {
	res := RGBtoHSX(r, g, b)
	s := (res.mx == 0) ? 0 : res.d / res.mx
	return { h: res.h, s: Round(s * 100), v: Round(res.mx * 100) }
}

; Get Color Name
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

	return colorNames.Has(hexColor) ? colorNames[hexColor] : "" ; Unknown
}

; Update Pixel Color
UpdatePixelColor() {
	static lastX := -1, lastY := -1, lastZoom := -1, lastRGB := -1

	if (!chk_Upd.Value)
		return

	MouseGetPos(&mX, &mY)
	currZ := zoomLevel
	try currC := Integer(PixelGetColor(mX, mY))
	catch
		currC := lastRGB

	; Detect changes
	posChanged := (mX != lastX || mY != lastY)
	zoomChanged := (currZ != lastZoom)
	colorChanged := (currC != lastRGB)

	if (posChanged || colorChanged) {
		RefreshColorInfo(mX, mY, currC)
		RefreshGrid(mX, mY, currZ)
	} else if (zoomChanged) {
		RefreshGrid(mX, mY, currZ)
	}

	lastX := mX, lastY := mY, lastZoom := currZ, lastRGB := currC
}

; Move mouse and update UI immediately
MoveMouse(x, y) {
	MouseMove(x, y, 0, "R")
	RefreshColorInfo()
	RefreshGrid()
}

; Refresh Grid and Zoom labels only
RefreshGrid(x?, y?, z?) {
	global startX, startY, totalGridSize
	if (!IsSet(x)) MouseGetPos(&x, &y)
		if (!IsSet(z)) z := zoomLevel
			txt_ZoomLevel.Value := Format("{}x{}", z, z)
	if (zoomEnabled) {
		gridColors := GetScreenColors(x, y, z)
		gridDisplay.Draw(gridColors, z, pb_GridBorder, startX, startY, totalGridSize)
	}
}

; Refresh Position and Color Codes only
RefreshColorInfo(x?, y?, c?) {
	if (!IsSet(x)) MouseGetPos(&x, &y)
		if (!IsSet(c)) {
			try c := Integer(PixelGetColor(x, y))
			catch
				return
		}

	txt_Position.Value := Format("Position: {:4}, {:4}", x, y)

	colorHex := Format("{:06X}", c)
	txtControls["Hex"].Value := "#" colorHex
	txtControls["Dec"].Value := String(c)
	pb_Color.Opt("Background" colorHex)

	r := (c >> 16) & 0xFF, g := (c >> 8) & 0xFF, b := c & 0xFF
	UpdateColorComponent(r, "Red", rgbControls)
	UpdateColorComponent(g, "Grn", rgbControls)
	UpdateColorComponent(b, "Blu", rgbControls)

	rP := Round(r / 2.55, 1), gP := Round(g / 2.55, 1), bP := Round(b / 2.55, 1)
	txtControls["RgbPercent"].Value := Format("rgb({:.1f}%, {:.1f}%, {:.1f}%)", rP, gP, bP)
	txtControls["Rgb"].Value := Format("rgb({}, {}, {})", r, g, b)
	txtControls["Rgba"].Value := Format("rgba({}, {}, {}, 1.0)", r, g, b)
	txtControls["Bgr"].Value := Format("${:02X}{:02X}{:02X}", b, g, r)

	cmyk := RGBtoCMYK(r, g, b)
	txtControls["Cmyk"].Value := Format("cmyk({}%, {}%, {}%, {}%)", cmyk.c, cmyk.m, cmyk.y, cmyk.k)
	hsl := RGBtoHSL(r, g, b)
	txtControls["Hsl"].Value := Format("hsl({}, {}%, {}%)", hsl.h, hsl.s, hsl.l)
	hsv := RGBtoHSV(r, g, b)
	txtControls["Hsv"].Value := Format("hsv({}, {}%, {}%)", hsv.h, hsv.s, hsv.v)
	txt_Cn.Value := GetColorName(colorHex)
}

; Update Color Component
UpdateColorComponent(val, tag, controls) {
	controls[tag "Hex"].Value := Format("{:02X}", val)
	controls[tag "Dec"].Value := String(val)
	controls[tag "Pb"].Value := val

	; Determine dynamic color based on tag
	if (tag == "Red")
		cColor := (val << 16)
	else if (tag == "Grn")
		cColor := (val << 8)
	else if (tag == "Blu")
		cColor := val

	controls[tag "Pb"].Opt(Format("c{:06X}", cColor))
}

; Screen Capture
GetScreenColors(centerX, centerY, count) {
	half := count // 2
	left := centerX - half
	top := centerY - half

	; Capture screen area to memory bitmap
	hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
	hMemDC := DllCall("CreateCompatibleDC", "Ptr", hDC, "Ptr")
	hBM := DllCall("CreateCompatibleBitmap", "Ptr", hDC, "Int", count, "Int", count, "Ptr")
	hOldBM := DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hBM, "Ptr")

	DllCall("BitBlt", "Ptr", hMemDC, "Int", 0, "Int", 0, "Int", count, "Int", count, "Ptr", hDC, "Int", left, "Int",
		top, "UInt", 0x00CC0020)

	; Setup BITMAPINFO for GetDIBits
	bi := Buffer(40, 0)
	NumPut("UInt", 40, bi, 0)  ; biSize
	NumPut("Int", count, bi, 4)  ; biWidth
	NumPut("Int", -count, bi, 8) ; biHeight (negative for top-down)
	NumPut("UShort", 1, bi, 12)  ; biPlanes
	NumPut("UShort", 32, bi, 14) ; biBitCount
	NumPut("UInt", 0, bi, 16)    ; biCompression (BI_RGB)

	bufSize := count * count * 4
	pixelBuf := Buffer(bufSize)

	DllCall("GetDIBits", "Ptr", hMemDC, "Ptr", hBM, "UInt", 0, "UInt", count, "Ptr", pixelBuf, "Ptr", bi, "UInt", 0)

	; Cleanup GDI
	DllCall("SelectObject", "Ptr", hMemDC, "Ptr", hOldBM)
	DllCall("DeleteObject", "Ptr", hBM)
	DllCall("DeleteDC", "Ptr", hMemDC)
	DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)

	; Process buffer into array of integers
	colors := []
	loop count {
		rowIdx := A_Index
		row := []
		loop count {
			colIdx := A_Index
			offset := ((rowIdx - 1) * count + (colIdx - 1)) * 4
			; GetDIBits returns BGRX
			bgrx := NumGet(pixelBuf, offset, "UInt")
			; Extract RGB and put into integer 0xRRGGBB
			r := (bgrx >> 16) & 0xFF
			g := (bgrx >> 8) & 0xFF
			b := bgrx & 0xFF
			row.Push((r << 16) | (g << 8) | b)
		}
		colors.Push(row)
	}

	return colors
}

; About Dialog
About(*) {
	msg := A_ScriptName " v2.1`n`n"
	msg .= ("
(
Mesut Akcan
makcan@gmail.com
mesutakcan.blogspot.com
youtube.com/mesutakcan
)")

	MsgBox(msg, A_ScriptName, "Icon 64 Owner" mGui.Hwnd)
}

; GDI+ CLASS
; ========================================
class GDIPlusGrid {
	__New(guiObj, x, y, size, bgColor := 0xFF000000) {
		this.width := size
		this.height := size
		this.bgColor := bgColor

		; Initialize GDI+
		if !DllCall("GetModuleHandle", "Str", "gdiplus", "Ptr")
			this.hModule := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")

		si := Buffer(24, 0)
		NumPut("UInt", 1, si)
		DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken := 0, "Ptr", si, "Ptr", 0)
		this.pToken := pToken

		; Create Picture control to hold the bitmap
		this.ctrl := guiObj.AddPicture("x" x " y" y " w" size " h" size " Background000000 0xE") ; 0xE = SS_BITMAP
		this.hPic := this.ctrl.Hwnd

		; Create Bitmap and Graphics context
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", size, "Int", size, "Int", 0, "Int", 0x26200A, "Ptr", 0,
			"Ptr*", &pBitmap := 0)
		this.pBitmap := pBitmap
		DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics := 0)
		this.pGraphics := pGraphics

		; Set smoothing mode to None (for pixel-perfect grid)
		DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 0) ; 0 = Default (None)
		DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 0) ; 0 = Default
		DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pGraphics, "Int", 0) ; 0 = Default (NearestNeighbor)

		; Create Brushes
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", bgColor, "Ptr*", &pBrush := 0)
		this.bgBrush := pBrush
	}

	__Delete() {
		if (this.pGraphics)
			DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this.pGraphics)
		if (this.pBitmap)
			DllCall("gdiplus\GdipDisposeImage", "Ptr", this.pBitmap)
		if (this.bgBrush)
			DllCall("gdiplus\GdipDeleteBrush", "Ptr", this.bgBrush)
		if (this.pToken)
			DllCall("gdiplus\GdiplusShutdown", "Ptr", this.pToken)
		if (this.hModule)
			DllCall("FreeLibrary", "Ptr", this.hModule)
	}

	Draw(colors, zoomLvl, containerBorder, originalX, originalY, totalSize) {
		cellSize := this.width // zoomLvl
		actualSize := cellSize * zoomLvl

		; Calculate offset to center the ENTIRE grid in the original area
		offset := (totalSize - actualSize) // 2
		newX := originalX + offset
		newY := originalY + offset

		; Resize the Picture Control and the Background Border to match actual grid size
		try {
			containerBorder.Move(newX - 1, newY - 1, actualSize + 2, actualSize + 2)
			this.ctrl.Move(newX, newY, actualSize, actualSize)
		}

		; Recreate Bitmap if size changed to ensure 1:1 mapping (no scaling artifacts)
		if (!this.HasProp("currentWidth") || this.currentWidth != actualSize) {
			; Dispose old objects
			if (this.pGraphics)
				DllCall("gdiplus\GdipDeleteGraphics", "Ptr", this.pGraphics)
			if (this.pBitmap)
				DllCall("gdiplus\GdipDisposeImage", "Ptr", this.pBitmap)

			; Create new Bitmap with EXACT size
			DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", actualSize, "Int", actualSize, "Int", 0, "Int",
				0x26200A, "Ptr", 0, "Ptr*", &pBitmap := 0)
			this.pBitmap := pBitmap
			DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &pGraphics := 0)
			this.pGraphics := pGraphics

			; Reset smoothing modes for new graphics
			DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", pGraphics, "Int", 0)
			DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", pGraphics, "Int", 0)
			DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", pGraphics, "Int", 0)

			this.currentWidth := actualSize
			this.currentHeight := actualSize
		}

		; Clear background
		DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pGraphics, "Ptr", this.bgBrush, "Float", 0, "Float", 0,
			"Float", actualSize, "Float", actualSize)

		; Create solid brush specifically for grid drawing
		DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000, "Ptr*", &pCellBrush := 0)

		loop zoomLvl {
			row := A_Index
			if (row > colors.Length)
				break
			y := (row - 1) * cellSize
			h := cellSize - 1

			loop zoomLvl {
				col := A_Index
				if (col > colors[row].Length)
					break
				; colors is 1-indexed
				rgb := colors[row][col]

				; Convert to ARGB (Add Alpha FF)
				argb := 0xFF000000 | rgb

				; Set brush color
				DllCall("gdiplus\GdipSetSolidFillColor", "Ptr", pCellBrush, "UInt", argb)

				; Calculate position with 1px gap (spacing logic: cellSize - 1)
				x := (col - 1) * cellSize
				w := cellSize - 1

				; Fill rectangle
				DllCall("gdiplus\GdipFillRectangle", "Ptr", this.pGraphics, "Ptr", pCellBrush, "Float", x, "Float",
					y, "Float", w, "Float", h)
			}
		}

		; Clean up cell brush
		DllCall("gdiplus\GdipDeleteBrush", "Ptr", pCellBrush)

		; Highlight active pixel (center)
		mid := (zoomLvl // 2) + 1
		hx := (mid - 1) * cellSize
		hy := (mid - 1) * cellSize
		hw := cellSize - 1
		hh := cellSize - 1

		; Double-border for visibility (Black outer, White inner)
		DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF000000, "Float", 1, "Int", 2, "Ptr*", &pPenB := 0)
		DllCall("gdiplus\GdipDrawRectangle", "Ptr", this.pGraphics, "Ptr", pPenB, "Float", hx - 1, "Float", hy - 1,
			"Float", hw + 2, "Float", hh + 2)
		DllCall("gdiplus\GdipDeletePen", "Ptr", pPenB)

		DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFFFFFFFF, "Float", 1, "Int", 2, "Ptr*", &pPenW := 0)
		DllCall("gdiplus\GdipDrawRectangle", "Ptr", this.pGraphics, "Ptr", pPenW, "Float", hx, "Float", hy, "Float", hw,
			"Float", hh)
		DllCall("gdiplus\GdipDeletePen", "Ptr", pPenW)

		; Get HBITMAP from GDI+ Bitmap to display in Picture control
		DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", this.pBitmap, "Ptr*", &hBitmap := 0, "UInt", 0)

		; Set the bitmap to the control
		hOldBitmap := DllCall("SendMessage", "Ptr", this.hPic, "UInt", 0x172, "Ptr", 0, "Ptr", hBitmap, "Ptr")

		if (hOldBitmap)
			DllCall("DeleteObject", "Ptr", hOldBitmap)
	}
}