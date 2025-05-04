/*
Pixel Color
Get pixel color at mouse position

Mesut Akcan
makcan@gmail.com
mesutakcan.blogspot.com

v1.4 04/05/2025
codes improved and optimised
*/

#Requires AutoHotkey v2+
#SingleInstance Force
#NoTrayIcon

; Global constants
updateInterval := 200
appTitle := "Pixel color v1.4"
pBarHeight := 22

gui1 := Gui("+AlwaysOnTop", appTitle)

; Color display section
CreateColorDisplay("Hex:", 40, &txtColorHex)
CreateColorDisplay("Decimal:", 55, &txtColorDec, "x+20")

gui1.AddButton("x+15 y6", "?").OnEvent("Click", About)

; RGB sections
CreateColorSection("Red", 40, "Red", &edRedHex, &edRedDec, &pbRed)
CreateColorSection("Green", 70, "Lime", &edGrnHex, &edGrnDec, &pbGrn)
CreateColorSection("Blue", 100, "Blue", &edBluHex, &edBluDec, &pbBlu)

; Color preview
pbColor := gui1.AddProgress("x220 y40 w85 h85")

; Controls
chkUpd := gui1.AddCheckBox("x10 y130 +Checked", "Update (F1)")
chkAot := gui1.AddCheckBox("x+10 y130 +Checked", "Always on Top")
chkAot.OnEvent("Click", (*) => WinSetAlwaysOnTop(-1, "A"))

gui1.OnEvent("Close", (*) => ExitApp())
gui1.OnEvent("Escape", (*) => ExitApp())
gui1.Show()
SetTimer(UpdatePixelColor, updateInterval)

; Hotkeys
F1:: chkUpd.Value := !chkUpd.Value

CreateColorDisplay(label, width, &control, xPos := "x10") {
  gui1.AddText(xPos " y10", label)
  control := gui1.AddText("x+5 w" width " h15 cBlue BackgroundWhite")
  gui1.AddButton("x+2 y6", "Copy").OnEvent("Click", (*) => CopyToClipboard(control))
}

CreateColorSection(label, yPos, color, &hexEdit, &decEdit, &progressBar) {
  y := yPos + 3
  gui1.AddText("x10 y" y, label ":")
  hexEdit := gui1.AddText("x50 y" y " w20 cBlue BackgroundWhite")
  decEdit := gui1.AddText("x+5 y" y " w25 cBlue BackgroundWhite")
  progressBar := gui1.AddProgress("x+5 y" yPos " w100 h" pBarHeight " c" color " BackGroundWhite Range0-255")
}

CopyToClipboard(control, *) {
  A_Clipboard := control.Value
}

UpdatePixelColor() {
  if (!chkUpd.Value) {
    return
  }

  MouseGetPos(&MouseX, &MouseY)
  color := PixelGetColor(MouseX, MouseY)
  colorHex := SubStr(color, 3)

  ; Update main color displays
  txtColorHex.Value := colorHex
  txtColorDec.Value := Format("{:d}", color)
  pbColor.opt("Background" colorHex)

  ; Update RGB components
  UpdateColorComponent(SubStr(color, 3, 2), edRedHex, edRedDec, pbRed)
  UpdateColorComponent(SubStr(color, 5, 2), edGrnHex, edGrnDec, pbGrn)
  UpdateColorComponent(SubStr(color, -2), edBluHex, edBluDec, pbBlu)
}

UpdateColorComponent(hexValue, hexEdit, decEdit, progressBar) {
  hexEdit.Value := hexValue
  decValue := Format("{:d}", "0x" hexValue)
  decEdit.Value := decValue
  progressBar.Value := decValue
}

About(*) {
  MsgBox("Mesut Akcan`nmakcan@gmail.com`nmesutakcan.blogspot.com`nyoutube.com/mesutakcan ", appTitle, "Owner" gui1.Hwnd)
}
