#Requires AutoHotkey v2
#SingleInstance Force

MyPad.OnEvent("Click", (*) => PostMessage(0xA1, 2))

; Create the GUI window
MyPad := Gui("+AlwaysOnTop -Caption +ToolWindow", "USB Macro Pad")
MyPad.BackColor := "1E1E1E" ; Dark background

; Set button text color to white
MyPad.SetFont("s12 cWhite cFFFFFF", "Segoe UI")

; Add a 2x2 grid of touch-friendly buttons
; Row 1
Btn1 := MyPad.Add("Button", "w100 h80", "Copy")
Btn1.OnEvent("Click", (*) => Send("^c"))

Btn2 := MyPad.Add("Button", "x+10 w100 h80", "Paste")
Btn2.OnEvent("Click", (*) => Send("#v"))

; Row 2
Btn3 := MyPad.Add("Button", "xm y+10 w100 h80", "Mute Mic")
Btn3.OnEvent("Click", (*) => Send("{Volume_Mute}"))

Btn4 := MyPad.Add("Button", "x+10 w100 h80", "Calc")
Btn4.OnEvent("Click", (*) => Run("calc.exe"))

; Show the pad (You can drag or position this onto your smaller screen)
MyPad.Show("x100 y100")

Btn5 := MyPad.Add("Button", "xm y+10 w210 h40", "Reload Script")
Btn5.OnEvent("Click", (*) => Reload())

^!r::Reload()  ; Ctrl+Alt+R

^!q::ExitApp() ; Ctrl+Alt+Q
