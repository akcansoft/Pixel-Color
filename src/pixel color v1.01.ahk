/****************************
Pixel Color
Get pixel color at mouse position
v1.0  20/03/2024
v1.01 22/03/2024

Mesut Akcan
makcan@gmail.com
mesutakcan.blogspot.com
*****************************/

#Requires AutoHotkey v2+
#SingleInstance Force

SetTimer(PixelColor, 200)

form := Gui(,"Pixel color") ; GUI
form.OnEvent("Close", (*) => ExitApp()) ; if gui close, end
form.OnEvent("Escape",(*) => ExitApp()) ; if press esc key, end

form.AddText("x10 y10","Mouse pixel color:")
edColorHex := form.AddEdit("x100 y10 w55")
form.AddButton("vButton1 x+2","Copy").OnEvent("Click", Button_Click) ;button 1

edColorDec := form.AddEdit("x+20 w60")
form.AddButton("vButon2 x+2","Copy").OnEvent("Click", Button_Click) ;button 2

form.AddText("x10 y40","Red:")
edRedHex := form.AddEdit("x50 y40 w25")
edRedDec := form.AddEdit("x+5 w30")
pbRed := form.AddProgress("x+5 w100 h22 cRed BackGroundFFFFFF Range0-255") ;red progress bar

pbColor := form.AddProgress("x+20 w80 h80") ;progres bar for pixel color

form.AddText("x10 y70","Green:")
edGrnHex := form.AddEdit("x50 y70 w25")
edGrnDec := form.AddEdit("x+5 w30")
pbGrn := form.AddProgress("x+5 w100 h22 cGreen BackGroundFFFFFF Range0-255") ;green progress bar

form.AddText("x10 y100","Blue:")
edBluHex := form.AddEdit("x50 y100 w25")
edBluDec := form.AddEdit("x+5 w30")
pbBlu := form.AddProgress("x+5 w100 h22 cBlue BackGroundFFFFFF Range0-255") ;blue progress bar

form.AddText("xm", "[F1] Update:")
txtUpd := form.AddText("x+5 w25",)
form.AddText("x+120", "Mesut Akcan`nmakcan@gmail.com")

form.Show()

upd := true

; Keyboard shortcut
F1:: ;update
{
	global upd := !upd
}
return

PixelColor() {
	global upd
	if (upd = true)	{
		txtUpd.value := "Yes"
		MouseGetPos &MouseX, &MouseY
		color := PixelGetColor(MouseX, MouseY)
		c16 := SubStr(color, 3) ;Color(Hex)
		edColorHex.Value := c16 ;Edit Color Hex

		edColorDec.Value := Format("{:d}", color)
		pbColor.opt("background" c16)

		R := SubStr(color, 3, 2) ; Red
		edRedHex.Value := R
		edRedDec.Value := Fmt(R)
		pbRed.value := edRedDec.Value

		G := SubStr(color, 5, 2) ; Green
		edGrnHex.Value := G
		edGrnDec.Value := Fmt(G)
		pbGrn.value := edGrnDec.Value

		B := SubStr(color, -2) ; Blue
		edBluHex.Value := B
		edBluDec.Value :=  Fmt(B)
		pbBlu.value := edBluDec.Value
	}
	else {
		txtUpd.value := "No"
	}

    Fmt(n) { ; Decimal format function
        return Format("{:d}" , "0x" n)
    }
}

; Copy buttons click
Button_Click(Button,*) {
	if (Button.Name = "Button1"){
		A_Clipboard := edColorHex.Value
	}
	else {
		A_Clipboard := edColorDec.Value
	}
}
