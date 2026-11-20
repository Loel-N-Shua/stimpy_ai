#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; 800x480 USB TOUCHSCREEN MACRO PAD
; AutoHotkey v2
; ============================================================

; ------------------------------------------------------------
; CONFIGURATION
; ------------------------------------------------------------

PAD_WIDTH  := 800
PAD_HEIGHT := 480
TARGET_MONITOR := "\\.\DISPLAY5"
PadIsVisible := false

; Optional PowerShell scripts.
PowerShellScripts := Map(
    "New Password", "C:\Users\LoelNelson\OneDrive - Seaga\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
    "PAX Tools",   "C:\Scripts\PAX-Troubleshooting.ps1",
    "Device Info", "C:\Scripts\Get-DeviceInfo.ps1"
)

; Messages copied by the Lunch Status button.
LunchMessages := [
    "🚒 Stepping away unless lunch itself escalates.",
    "🔥 Currently extinguishing a hunger incident.",
    "🚨 Critical ticket: Hunger. Response in progress.",
    "🧯 Mitigating a high-priority lunch outage.",
    "🚨 Critical Incident Response: Hunger. ETA unknown. 🍔",
    "⚙️ Performing emergency maintenance on my biological infrastructure. Back shortly. 🍕",
    "📈 Participating in a lunch optimization initiative.",
    "🤝 In negotiations with a turkey club.",
    "🎯 Aligning key performance indicators with grilled cheese objectives.",
    "📊 Conducting an ROI analysis on today's lunch selection.",
    "💡 Strategic nourishment session underway.",
    "🔄 User is AFK for scheduled caloric intake.",
    "⚙️ Performing maintenance on biological systems.",
    "🛠️ Rebooting with food.",
    "💾 Downloading nutrients...",
    "🤖 Human requires fuel. Back shortly.",
    "🔋 Battery critically low. Refueling in progress.",
    "🍔 Out for critical sandwich maintenance.",
    "🌯 Performing routine burrito updates.",
    "🍕 In a strategic meeting with pizza.",
    "🌮 Engaged in taco-driven development.",
    "🍜 Running lunch.exe...",
    "🥪 Currently patching hunger vulnerability.",
    "🦖 Feeding the office dinosaur.",
    "🐿️ Foraging. Back soon.",
    "🌎 Out exploring local food ecosystems.",
    "🍟 Pursuing fries and happiness.",
    "🥷 Gone ninja. Probably eating.",
    "🚀 Lunch mission in progress."
]

; ------------------------------------------------------------
; GLOBAL VARIABLES
; ------------------------------------------------------------

global MyPad
global CurrentPage := 1
global PageControls := Map()
global MatrixButtons := Map()
global PageTitle
global AudioButton
global StatusDisplay
global MouseJiggleButton
global MouseJiggleEnabled := false
global TouchMouseHook := 0, TouchMouseCallback := 0
global LastPhysicalMouseX := 0, LastPhysicalMouseY := 0, LastPhysicalMouseKnown := false
global PasswordDisplay, PasswordPID := 0, PasswordReceived := false

; ------------------------------------------------------------
; CREATE GUI
; ------------------------------------------------------------

; E0x08000000 adds WS_EX_NOACTIVATE. Prevents macro pad from stealing focus.
MyPad := Gui(
    "+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000",
    "The PAD"
)

MyPad.BackColor := "000000"
MyPad.MarginX := 0
MyPad.MarginY := 0
MyPad.SetFont("s14 c00FF41", "Consolas")

MyPad.OnEvent("Close", (*) => ExitApp())

; ------------------------------------------------------------
; HEADER
; ------------------------------------------------------------

PageTitle := MyPad.Add(
    "Text",
    "x10 y6 w780 h36 Center Background000000",
    "EVERYDAY TOOLS"
)
PageTitle.SetFont("s17 Bold c00FF41", "Consolas")

; Clicking and dragging the header moves the window.
PageTitle.OnEvent("Click", (*) => PostMessage(0xA1, 2))

; ------------------------------------------------------------
; CREATE PAGES
; ------------------------------------------------------------

CreateEverydayPage()
CreateStatusPage()
CreateSupportPage()

; ------------------------------------------------------------
; NAVIGATION BAR
; ------------------------------------------------------------

MyPad.SetFont("s12 Bold c00FF41", "Consolas")

BtnPage1 := AddMatrixButton("x10 y370 w170 h100", "EVERYDAY")
BtnPage1.OnEvent("Click", (*) => ShowPage(1))

BtnPage2 := AddMatrixButton("x190 y370 w170 h100", "STATUS")
BtnPage2.OnEvent("Click", (*) => ShowPage(2))

BtnPage3 := AddMatrixButton("x370 y370 w170 h100", "SUPPORT")
BtnPage3.OnEvent("Click", (*) => ShowPage(3))

BtnReload := AddMatrixButton("x550 y370 w115 h100", "RELOAD")
BtnReload.OnEvent("Click", (*) => Reload())

BtnExit := AddMatrixButton("x675 y370 w115 h100", "EXIT")
BtnExit.OnEvent("Click", (*) => ExitApp())

; ------------------------------------------------------------
; SHOW GUI AT STARTUP ON MONITOR 5
; ------------------------------------------------------------

OnMessage(0x004A, ReceiveFastPassword)
OnMessage(0x007E, (*) => SetTimer(RepositionVisiblePad, -1000))
ShowPage(1)
ShowPadOnTouchscreen()
SetTimer(RetryTouchscreenPlacement, 1000)

; Update the speaker-mute indicator once per second.
SetTimer(UpdateStatusIndicators, 1000)

; Restore the mouse cursor after Windows-generated touchscreen mouse clicks.
InstallTouchMouseRestore()
OnExit(UninstallTouchMouseRestore)

; ------------------------------------------------------------
; GLOBAL HOTKEYS
; ------------------------------------------------------------

^!r::Reload()        ; Ctrl+Alt+R reloads the script.
^!q::ExitApp()       ; Ctrl+Alt+Q exits the script.
^!m::ToggleMacroPad() ; Ctrl+Alt+M shows or hides the macro pad.

; ============================================================
; PAGE 1: EVERYDAY TOOLS
; ============================================================

CreateEverydayPage() {
    global PageControls, MyPad, PasswordDisplay
    PageControls[1] := []
    AddPageButton(1, "x10 y50 w253 h130", "ChatGPT", OpenChatGPT)
    AddPageButton(1, "x273 y50 w254 h130", "FIREFOX", OpenFirefox)
    AddPageButton(1, "x537 y50 w253 h130", "FASTPASS", GenerateFastPassword)
    AddPageButton(1, "x10 y190 w253 h130", "OUTLOOK", OpenOutlook)
    AddPageButton(1, "x273 y190 w254 h130", "NOTEPAD++", OpenNotepad)
    AddPageButton(1, "x537 y190 w253 h130", "FILE`nEXPLORER", OpenExplorer)
    PasswordDisplay := MyPad.Add("Text", "x10 y328 w780 h32 Center +0x200 Background000000", "")
    PasswordDisplay.SetFont("s14 Bold c00FF41", "Consolas")
    RegisterPageControl(1, PasswordDisplay)
}

; ============================================================
; PAGE 2: STATUS AND COMMUNICATION
; ============================================================

CreateStatusPage() {
    global PageControls, AudioButton, StatusDisplay
    PageControls[2] := []

    AudioButton := AddPageButton(2, "x10 y50 w253 h150", "SPEAKERS", ToggleAudioMute)
    AddPageButton(2, "x273 y50 w254 h150", "OPEN`nTEAMS", OpenTeams)
    AddPageButton(2, "x537 y50 w253 h150", "LUNCH`nSTATUS", SetLunchStatus)
    AddPageButton(2, "x10 y210 w253 h150", "AVAILABLE", SetAvailableStatus)
    AddPageButton(2, "x273 y210 w254 h150", "BUSY`nMESSAGE", CopyBusyMessage)
    AddPageButton(2, "x537 y210 w253 h150", "BACK SOON", CopyBackSoonMessage)

    StatusDisplay := MyPad.Add("Text", "x10 y320 w780 h38 Center Background000000", "")
    StatusDisplay.SetFont("s11 c00FF41", "Segoe UI")
    RegisterPageControl(2, StatusDisplay)
}

; ============================================================
; PAGE 3: SUPPORT TOOLS
; ============================================================

CreateSupportPage() {
    global PageControls, MouseJiggleButton
    PageControls[3] := []

    AddPageButton(3, "x10 y50 w253 h150", "ONENOTE", OpenOneNote)
    AddPageButton(3, "x273 y50 w254 h150", "GRAYLOG", (*) => OpenFirefoxLink("https://graylog.32market.com/dashboards/69d4753a994b3b81940a972f"))
    AddPageButton(3, "x537 y50 w253 h150", "PULSEWAY", (*) => OpenFirefoxLink("https://32market.pulseway.com/app/main/systems/search"))
    MouseJiggleButton := AddPageButton(3, "x10 y210 w253 h150", "MOUSE JIGGLER: OFF", ToggleMouseJiggle)
    AddPageButton(3, "x273 y210 w254 h150", "TIER 3", OpenTier3)
    AddPageButton(3, "x537 y210 w253 h150", "TASK`nMANAGER", OpenTaskManager)
}

; ============================================================
; PAGE MANAGEMENT & MONITOR PLACEMENT
; ============================================================

; Colored text panels avoid Windows overriding native button colors.
AddMatrixButton(Options, ButtonText) {
    global MyPad, MatrixButtons
    BorderControl := MyPad.Add("Text", Options " Background00FF41", "")
    BorderControl.GetPos(&X, &Y, &Width, &Height)
    ButtonControl := MyPad.Add("Text", "x" (X + 1) " y" (Y + 1)
        " w" (Width - 2) " h" (Height - 2)
        " Center +0x200 Background000000 c00FF41", StrReplace(ButtonText, "`n", " "))
    MatrixButtons[ButtonControl.Hwnd] := BorderControl
    return ButtonControl
}

AddPageButton(PageNumber, Options, ButtonText, Callback) {
    global MyPad
    ButtonControl := AddMatrixButton(Options, ButtonText)
    ButtonControl.SetFont("s17 Bold c00FF41", "Consolas")
    ButtonControl.OnEvent("Click", Callback)
    RegisterPageControl(PageNumber, ButtonControl)
    return ButtonControl
}

RegisterPageControl(PageNumber, ControlObject) {
    global PageControls
    PageControls[PageNumber].Push(ControlObject)
    global MatrixButtons
    if MatrixButtons.Has(ControlObject.Hwnd)
        PageControls[PageNumber].Push(MatrixButtons[ControlObject.Hwnd])
}

ShowPage(PageNumber) {
    global PageControls, CurrentPage, PageTitle
    CurrentPage := PageNumber
    
    ; Update header title based on page
    if (PageNumber == 1)
        PageTitle.Value := "EVERYDAY TOOLS"
    else if (PageNumber == 2)
        PageTitle.Value := "STATUS AND COMMUNICATION"
    else if (PageNumber == 3)
        PageTitle.Value := "SUPPORT TOOLS"

    ; Show/Hide objects based on active page
    for CurrentPageNumber, Controls in PageControls {
        for ControlObject in Controls {
            if (CurrentPageNumber == PageNumber)
                ControlObject.Visible := true
            else
                ControlObject.Visible := false
        }
    }
}

ToggleMacroPad() {
    global MyPad, PadIsVisible
    if PadIsVisible {
        MyPad.Hide()
        PadIsVisible := false
    } else {
        ShowPadOnTouchscreen()
    }
}

FindTouchscreen() {
    global TARGET_MONITOR
    loop MonitorGetCount() {
        if MonitorGetName(A_Index) = TARGET_MONITOR
            return A_Index
    }
    ; Fallback if Windows renumbers the USB display.
    loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if R - L = 800 && B - T = 480
            return A_Index
    }
    return 0
}

ShowPadOnTouchscreen() {
    global MyPad, PAD_WIDTH, PAD_HEIGHT, PadIsVisible
    MonitorNumber := FindTouchscreen()
    if !MonitorNumber
        MonitorNumber := MonitorGetPrimary()
    MonitorGet(MonitorNumber, &Left, &Top, &Right, &Bottom)
    CenterX := Round(Left + (Right - Left - PAD_WIDTH) / 2)
    CenterY := Round(Top + (Bottom - Top - PAD_HEIGHT) / 2)
    MyPad.Show("NA x" CenterX " y" CenterY " w" PAD_WIDTH " h" PAD_HEIGHT)
    ; Apply physical coordinates after Windows has created the window.
    DllCall("SetWindowPos", "Ptr", MyPad.Hwnd, "Ptr", 0,
        "Int", CenterX, "Int", CenterY, "Int", PAD_WIDTH, "Int", PAD_HEIGHT,
        "UInt", 0x0014)
    PadIsVisible := true
}

RepositionVisiblePad() {
    global PadIsVisible
    if PadIsVisible
        ShowPadOnTouchscreen()
}

RetryTouchscreenPlacement() {
    static Attempts := 0
    Attempts += 1
    if FindTouchscreen() {
        RepositionVisiblePad()
        SetTimer(RetryTouchscreenPlacement, 0)
    } else if Attempts >= 30 {
        SetTimer(RetryTouchscreenPlacement, 0)
    }
}

; ============================================================
; FUNCTIONAL ROUTINES FOR STATUS PAGE BUTTONS
; ============================================================

; 1. TOGGLE SPEAKER MUTE
; Windows can reject SoundSetMute, so sending the physical media key is 100% reliable
ToggleAudioMute(*) {
    Send "{Volume_Mute}"
    
    ; Optional: Visual feedback on your StatusDisplay line if it's currently on screen
    global StatusDisplay
    try {
        if SoundGetMute()
            StatusDisplay.Value := "SYSTEM AUDIO: MUTED"
        else
            StatusDisplay.Value := "SYSTEM AUDIO: UNMUTED"
    }
}

; 2. LAUNCH MICROSOFT TEAMS
; This target tries the modern Teams App first, falling back to classic if needed
OpenTeams(*) {
    global StatusDisplay
    StatusDisplay.Value := "Opening Microsoft Teams..."
    
   try {
        Run("msteams:")
        return
    }
    catch {
	MsgBox("Could not find Microsoft Teams path automatically. Please verify your Teams installation.")
            StatusDisplay.Value := "Teams Launch Failed"
    }

    try {
        Run("ms-teams:")
        return
    }
    catch {
	MsgBox("Could not find Microsoft Teams path automatically. Please verify your Teams installation.")
            StatusDisplay.Value := "Teams Launch Failed"
    }

    MsgBox(
        "Microsoft Teams could not be opened.",
        "The PAD",
        "Icon!"
    )
}

; 3. LUNCH STATUS (Picks a random message from your LunchMessages array)
SetLunchStatus(*) {
    global LunchMessages, StatusDisplay
    
    ; Pick a random index number from the array
    randomIndex := Random(1, LunchMessages.Length)
    selectedMessage := LunchMessages[randomIndex]
    
    ; Clear clipboard, assign the text, and wait for Windows to process it
    A_Clipboard := ""
    A_Clipboard := selectedMessage
    ClipWait(1)
    
    StatusDisplay.Value := "Copied to Clipboard: " selectedMessage
}

; 4. AVAILABLE STATUS
SetAvailableStatus(*) {
    global StatusDisplay
    A_Clipboard := ""
    A_Clipboard := "I am currently available and back at my desk."
    ClipWait(1)
    StatusDisplay.Value := "Copied: Available Status Message"
}

; 5. BUSY MESSAGE
CopyBusyMessage(*) {
    global StatusDisplay
    A_Clipboard := ""
    A_Clipboard := "Currently focused on a task. If this is urgent, please call me; otherwise, I will reply as soon as I break."
    ClipWait(1)
    StatusDisplay.Value := "Copied: Busy Message"
}

; 6. BACK SOON MESSAGE
CopyBackSoonMessage(*) {
    global StatusDisplay
    A_Clipboard := ""
    A_Clipboard := "Stepping away from my desk briefly. Will be right back!"
    ClipWait(1)
    StatusDisplay.Value := "Copied: Back Soon Message"
}


; ============================================================
; REMAINING CORE SYSTEM ACTIONS
; ============================================================

UpdateStatusIndicators() {
    ; Runs once per second via your timer. You can use this to update the display if desired.
}

; Everyday page and Support page application launchers.
OpenChatGPT(*) {
    try {
        Apps := ComObject("Shell.Application").NameSpace("shell:AppsFolder")
        for App in Apps.Items {
            if StrLower(App.Name) = "chatgpt" {
                App.InvokeVerb("open")
                return
            }
        }
        MsgBox("ChatGPT desktop was not found in Windows installed apps. Please install the desktop app first.", "The PAD", "Icon!")
    } catch Error as LaunchError {
        MsgBox("Could not open ChatGPT desktop.`n`n" LaunchError.Message, "The PAD", "Icon!")
    }
}
OpenFirefox(*) => LaunchPadApp('"' FindFirefox() '"', "Firefox")

OpenOutlook(*) {
    for hwnd in WinGetList("ahk_exe olk.exe") {
        if WinGetMinMax("ahk_id " hwnd) = -1
            WinRestore("ahk_id " hwnd)
        WinActivate("ahk_id " hwnd)
        return
    }

    ; Keep the existing AppsFolder lookup and launch code below.
    try {
        Apps := ComObject("Shell.Application")
            .NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}")

        for App in Apps.Items {
            if InStr(StrLower(App.Path), "microsoft.outlookforwindows") {
                App.InvokeVerb("open")
                return
            }
        }

        MsgBox("New Outlook was not found in the Windows app list.", "The PAD", "Icon!")
    } catch Error as LaunchError {
        MsgBox("Could not open Outlook (New).`n`n" LaunchError.Message, "The PAD", "Icon!")
    }
}
OpenOneNote(*) => LaunchPadApp("onenote.exe", "OneNote")

LaunchPadApp(Target, AppName) {
    try Run(Target)
    catch Error as LaunchError {
        MsgBox("Could not open " AppName ".`n`n" LaunchError.Message, "The PAD", "Icon!")
    }
}

FindFirefox() {
    ; Reuse the running executable, including Microsoft Store installations.
    try {
        FirefoxPath := ProcessGetPath("firefox.exe")
        if FirefoxPath != ""
            return FirefoxPath
    }
    for RegistryRoot in ["HKCU", "HKLM"] {
        try {
            FirefoxPath := RegRead(RegistryRoot "\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe")
            if FileExist(FirefoxPath)
                return FirefoxPath
        }
    }
    for FirefoxPath in [A_ProgramFiles "\Mozilla Firefox\firefox.exe",
        EnvGet("ProgramFiles(x86)") "\Mozilla Firefox\firefox.exe",
        EnvGet("LOCALAPPDATA") "\Mozilla Firefox\firefox.exe",
        EnvGet("LOCALAPPDATA") "\Microsoft\WindowsApps\firefox.exe"] {
        if FileExist(FirefoxPath)
            return FirefoxPath
    }
    ; Windows can also resolve a registered executable or app execution alias.
    return "firefox.exe"
}


OpenFirefoxLink(URL) {
    LaunchPadApp('"' FindFirefox() '" -new-tab "' URL '"', "Firefox link")
}
OpenNotepad(*) => Run("notepad++.exe")
OpenExplorer(*) => Run("explorer.exe")
OpenPowerShell(*) => Run("powershell.exe -NoProfile")

InstallTouchMouseRestore() {
    global TouchMouseHook, TouchMouseCallback
    global LastPhysicalMouseX, LastPhysicalMouseY, LastPhysicalMouseKnown

    MouseGetPos(&LastPhysicalMouseX, &LastPhysicalMouseY)
    LastPhysicalMouseKnown := true

    TouchMouseCallback := CallbackCreate(TouchMouseHookProc, "Fast", 3)
    ModuleHandle := DllCall("GetModuleHandleW", "Ptr", 0, "Ptr")
    TouchMouseHook := DllCall("user32\SetWindowsHookExW",
        "Int", 14, "Ptr", TouchMouseCallback, "Ptr", ModuleHandle, "UInt", 0, "Ptr")

    if !TouchMouseHook {
        CallbackFree(TouchMouseCallback)
        TouchMouseCallback := 0
        MsgBox("Could not install the touchscreen mouse-position restore hook.", "The PAD", "Icon!")
    }
}

UninstallTouchMouseRestore(*) {
    global TouchMouseHook, TouchMouseCallback
    if TouchMouseHook {
        DllCall("user32\UnhookWindowsHookEx", "Ptr", TouchMouseHook)
        TouchMouseHook := 0
    }
    if TouchMouseCallback {
        CallbackFree(TouchMouseCallback)
        TouchMouseCallback := 0
    }
}

TouchMouseHookProc(nCode, wParam, lParam) {
    global TouchMouseHook
    global LastPhysicalMouseX, LastPhysicalMouseY, LastPhysicalMouseKnown

    if (nCode >= 0) {
        MouseX := NumGet(lParam, 0, "Int")
        MouseY := NumGet(lParam, 4, "Int")
        MouseFlags := NumGet(lParam, 12, "UInt")
        ExtraInfoOffset := (A_PtrSize = 8) ? 24 : 20
        ExtraInfo := NumGet(lParam, ExtraInfoOffset, "UPtr")

        ; Windows tags touch-generated compatibility mouse events with this signature.
        if ((ExtraInfo & 0xFFFFFF00) = 0xFF515700) {
            if (wParam = 0x0202 || wParam = 0x0205
                || wParam = 0x0208 || wParam = 0x020C)
                SetTimer(RestoreMouseAfterTouch, -75)
        } else if !(MouseFlags & 0x1) {
            ; Track only physical mouse events, not AHK's simulated jiggle movement.
            LastPhysicalMouseX := MouseX
            LastPhysicalMouseY := MouseY
            LastPhysicalMouseKnown := true
        }
    }

    return DllCall("user32\CallNextHookEx", "Ptr", TouchMouseHook,
        "Int", nCode, "UPtr", wParam, "Ptr", lParam, "Ptr")
}

RestoreMouseAfterTouch() {
    global LastPhysicalMouseX, LastPhysicalMouseY, LastPhysicalMouseKnown
    if LastPhysicalMouseKnown
        DllCall("user32\SetCursorPos", "Int", LastPhysicalMouseX, "Int", LastPhysicalMouseY)
}

ToggleMouseJiggle(*) {
    global MouseJiggleEnabled, MouseJiggleButton
    MouseJiggleEnabled := !MouseJiggleEnabled

    if MouseJiggleEnabled {
        MouseJiggleButton.Value := "MOUSE JIGGLER: ON"
        SetTimer(MouseJiggleTick, 30000)
    } else {
        SetTimer(MouseJiggleTick, 0)
        MouseJiggleButton.Value := "MOUSE JIGGLER: OFF"
    }
}

MouseJiggleTick() {
    global MouseJiggleEnabled, MyPad
    if !MouseJiggleEnabled
        return

    MouseGetPos(&MouseX, &MouseY)
    WinGetPos(&PadX, &PadY, &PadW, &PadH, "ahk_id " MyPad.Hwnd)
    if (MouseX >= PadX && MouseX < PadX + PadW
        && MouseY >= PadY && MouseY < PadY + PadH)
        return

    MouseMove(MouseX + 1, MouseY, 0)
    Sleep(50)
    MouseMove(MouseX, MouseY, 0)
}

GenerateFastPassword(*) {
    global MyPad, PasswordDisplay, PasswordPID, PasswordReceived
    if PasswordPID
        return
    ScriptPath := A_ScriptDir "\Get-FastPass.ps1"
    if !FileExist(ScriptPath) {
        PasswordDisplay.Value := "Missing Get-FastPass.ps1 in the macro pad folder."
        return
    }
    PasswordReceived := false
    PasswordDisplay.Value := "Generating password..."
    try {
        Run('powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "' ScriptPath '" -WindowHandle ' MyPad.Hwnd,
            A_ScriptDir, "Hide", &PasswordPID)
        SetTimer(CheckPasswordProcess, 200)
    } catch Error as LaunchError {
        PasswordPID := 0
        PasswordDisplay.Value := "Could not start password generator."
    }
}

ReceiveFastPassword(wParam, lParam, msg, hwnd) {
    global MyPad, PasswordDisplay, PasswordPID, PasswordReceived
    if hwnd != MyPad.Hwnd || !PasswordPID
        return 0
    if NumGet(lParam, 0, "UPtr") != 0x46504153
        return 0
    ByteCount := NumGet(lParam, A_PtrSize, "UInt")
    DataPointer := NumGet(lParam, 2 * A_PtrSize, "Ptr")
    if !DataPointer || ByteCount < 4 || ByteCount > 4096 || Mod(ByteCount, 2)
        return 0
    Result := StrGet(DataPointer, ByteCount // 2 - 1, "UTF-16")
    PasswordReceived := true
    if SubStr(Result, 1, 3) = "OK:" {
        Password := SubStr(Result, 4)
        if StrLen(Password) != 20 || !RegExMatch(Password, "^[0-9][A-Za-z]+[.!@:,?+=_%$#^&*\-][A-Za-z]+$") {
            PasswordDisplay.Value := "Generator returned an invalid password. Try again."
            return 1
        }
        try {
            A_Clipboard := Password
            PasswordDisplay.Value := "Copied: " Password
        } catch {
            PasswordDisplay.Value := "Clipboard unavailable. Try FastPass again."
        }
    } else {
        PasswordDisplay.Value := "Password generation failed. Please try again."
    }
    return 1
}

CheckPasswordProcess() {
    global PasswordPID, PasswordReceived, PasswordDisplay
    if PasswordPID && ProcessExist(PasswordPID)
        return
    SetTimer(CheckPasswordProcess, 0)
    PasswordPID := 0
    if !PasswordReceived
        PasswordDisplay.Value := "Password generator stopped. Please try again."
}

OpenTier3(*) {
    Folder := "C:\Users\LoelNelson\OneDrive - Seaga\Desktop\Tier 2"
    if !DirExist(Folder) {
        MsgBox("Folder not found:`n" Folder, "The PAD", "Icon!")
        return
    }
    LaunchPadApp('explorer.exe "' Folder '"', "Tier 3 folder")
}
OpenTaskManager(*) => Run("taskmgr.exe")
; ============================================================
; POWERSHELL EXECUTION HELPER
; ============================================================

RunConfiguredPowerShell(ScriptName) {
    global PowerShellScripts
    if PowerShellScripts.Has(ScriptName) {
        ; Launches PowerShell bypassing local execution restrictions to run your specific profile/script
        Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' PowerShellScripts[ScriptName] '"')
    } else {
        MsgBox("Script configuration name '" ScriptName "' was not found in the PowerShellScripts Map.")
    }
}

