#SingleInstance force
#MaxHotkeysPerInterval 600
SetKeyDelay, 0
SetWinDelay, 0

;https://www.autohotkey.com/docs/v1/Hotkeys.htm <--for info about hotkeys

;Shameless self promo --> https://www.youtube.com/@Coool_kat

;Thanks to Priffin for making a lot of this script

; Zoom Settings
global hotkey := "*n" ; <-- Change 'n' to whatever hotkey you would like
global zoom := "Thin"

; Zoom Presets
/*
"Default" - 3600 tall, best for normal measuring without boat ~ 0.004 standard deviation
"BoatEye" - 16384 tall ~ 0.0007 standard deviation with boat eye
"Thin" ~ Same as above but smaller width for less GPU usage, recommended if using an OBS Projector
Custom ~ format WxH e.g. "320x8192"
*/

; Projector Settings
global useProjector := True ; Ignore other settings if set to false
global projectorName := "Windowed Projector (Scene) - mag" ; <-- Name of normal magnifying projector OBS Projector
global projectorWidth := -1 ; (-1 = default)

; Projector2 Settings
global useProjector2 := True ; Ignore other settings if set to false
global projectorName2 := "Windowed Projector (Scene) - Pie Chart" ; <-- Name of Pie Chart OBS Projector
global projectorWidth2 := -1 ; (-1 = default)

; Sensitivity Settings
global zoomSensitivity := 1 ; Change Windows sensitivity to this value when zooming in. Set to 0 to disable.

; Window Position Settings (-1 = default)
global zoomXPos := -1 
global zoomYPos := -1
global projectorXPos := -1
global projectorYPos := -1
global projector2XPos := -1
global projector2YPos := -1

; Determine Zoom Dimensions
global zoomWidth := 0
global zoomHeight := 0

if (zoom == "Default") {
    zoomWidth := A_ScreenWidth
    zoomHeight := 3600
} else if (zoom == "BoatEye") {
    zoomWidth := A_ScreenWidth
    zoomHeight := 16384
} else if (zoom == "Thin") {
    zoomWidth := 384
    zoomHeight := 16384
} else if (InStr(zoom, "x")) {
    zoom := StrSplit(zoom, "x")
    zoomWidth := zoom[1]
    zoomHeight := zoom[2]
} else {
    ExitApp
}

; Calculate Default Positions and Dimensions
global projectorWidth := (projectorWidth == -1) ? Floor((A_ScreenWidth - zoomWidth) / 2) : projectorWidth
global projectorHeight := A_ScreenHeight / (A_ScreenWidth / projectorWidth)
global projectorWidth2 := (projectorWidth2 == -1) ? Floor((A_ScreenWidth - zoomWidth) / 2) : projectorWidth2
global projectorHeight2 := A_ScreenHeight / (A_ScreenWidth / projectorWidth2)

global zoomXPos := (zoomXPos == -1) ? Floor((A_ScreenWidth - zoomWidth) / 2) : zoomXPos
global zoomYPos := (zoomYPos == -1) ? Floor((A_ScreenHeight - zoomHeight) / 2) : zoomYPos
global projectorXPos := (projectorXPos == -1) ? 0 : projectorXPos
global projectorYPos := (projectorYPos == -1) ? ((A_ScreenHeight - projectorHeight) / 2) : projectorYPos

global projector2XPos := A_ScreenWidth - projectorWidth2  ; Aligns the right edge of projector2 to the right edge of the screen.
global projector2YPos := (A_ScreenHeight - projectorHeight2) / 2  ; Centers projector2 vertically on the screen.

; Initial Window States
global ix := 0, iy := 0, iw := 0, ih := 0
global initialStyle := 0, initialExStyle := 0, initialSens := 0
DllCall("SystemParametersInfo", "UInt", 0x70, "UInt", 0, "UIntP", initialSens, "UInt", 0)

; Function to check projector state
checkProjector(name) {
    WinGet, state, MinMax, % name
    if (state == -1)
        WinRestore, % name
    WinSet, Style, -0xC40000, % name
    WinSet, AlwaysOnTop, On, % name
}

; Get active window handle for targeting
getActiveHwnd() {
    WinGet, hwnd, ID, A
    WinGet, name, ProcessName, % "ahk_id " hwnd
    return (name == "javaw.exe" || name == "java.exe") ? hwnd : False
}

; Zoom function
Zoom() {
    WinGetPos, x, y, w, h, A
    if (h != zoomHeight) {
        ix := x, iy := y, iw := w, ih := h
        WinGet, initialStyle, Style, A
        WinGet, initialExStyle, ExStyle, A
        WinSet, Style, -0xC40000, A
        activeWindow := getActiveHwnd()
        DllCall("SetWindowPos", "Ptr", activeWindow, "UInt", 0, "Int", zoomXPos, "Int", zoomYPos, "Int", zoomWidth, "Int", zoomHeight, "UInt", 0x0400)

        if (useProjector) {
            checkProjector(projectorName)
            DllCall("SetWindowPos", "Ptr", WinExist(projectorName), "UInt", 0, "Int", projectorXPos, "Int", projectorYPos, "Int", projectorWidth, "Int", projectorHeight, "UInt", 0x0400)
        }

        if (useProjector2) {
            checkProjector(projectorName2)
            DllCall("SetWindowPos", "Ptr", WinExist(projectorName2), "UInt", 0, "Int", projector2XPos, "Int", projector2YPos, "Int", projectorWidth2, "Int", projectorHeight2, "UInt", 0x0400)
        }

        if (zoomSensitivity != 0)
            DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "UInt", zoomSensitivity, "UInt", 0)
    } else {
        ; Reset window to original state
        WinSet, Style, %initialStyle%, A
        WinSet, ExStyle, %initialExStyle%, A
        activeWindow := getActiveHwnd()
        DllCall("SetWindowPos", "Ptr", activeWindow, "UInt", 0, "Int", ix, "Int", iy, "Int", iw, "Int", ih, "UInt", 0x0400)

        if (useProjector)
            DllCall("SetWindowPos", "Ptr", WinExist(projectorName), "UInt", 0, "Int", 0, "Int", -A_ScreenHeight, "Int", 1, "Int", 1, "UInt", 0x0400)

        if (useProjector2)
            DllCall("SetWindowPos", "Ptr", WinExist(projectorName2), "UInt", 0, "Int", 0, "Int", -A_ScreenHeight, "Int", 1, "Int", 1, "UInt", 0x0400)

        DllCall("SystemParametersInfo", "UInt", 0x71, "UInt", 0, "UInt", initialSens, "UInt", 0)
    }
    return
}

#If WinActive("Minecraft") && (WinActive("ahk_exe javaw.exe") || WinActive("ahk_exe java.exe"))
    Hotkey, %hotkey%, Zoom
