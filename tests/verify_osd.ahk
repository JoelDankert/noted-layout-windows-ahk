#Requires AutoHotkey v2.0
OnError(OsdError)
CoordMode("Pixel", "Screen")
global OsdFrameTimes := []
OnMessage(0x0046, CountOsdFrame)
SetTimer(VerifyOsd, -400)
#Include ..\noted.ahk

CountOsdFrame(wParam, lParam, message, hwnd) {
    global PauseOsdGui, OsdFrameTimes
    if IsSet(PauseOsdGui) && PauseOsdGui && hwnd = PauseOsdGui.Hwnd
        if !OsdFrameTimes.Length || OsdFrameTimes[-1] != A_TickCount
            OsdFrameTimes.Push(A_TickCount)
}

Assert(value, message) {
    if !value
        throw Error(message)
}

OsdError(err, mode) {
    FileAppend("OSD FAIL: " err.Message " at " err.Line "`n", "*")
    ExitApp(1)
}

VerifyOsd() {
    global PauseOsdGui, PauseOsdIcon, PauseOsdStart, IsPaused, OsdFrameTimes
    target := Gui(, "Noted OSD verification")
    target.BackColor := "222222"
    target.AddEdit("w300 h60", "Focus target")
    target.Show("Center w600 h400")
    WinActivate(target)
    Sleep(100)
    focused := WinExist("A")
    TogglePause()
    Assert(IsPaused && A_IsSuspended, "pause did not suspend")
    Assert(WinExist("A") = focused, "OSD stole focus")
    hwnd := PauseOsdGui.Hwnd, firstIcon := PauseOsdIcon
    Assert(firstIcon && DllCall("IsWindowVisible", "Ptr", hwnd), "OFF icon/window missing")
    style := WinGetExStyle(PauseOsdGui)
    Assert((style & 0x080000A0) = 0x080000A0, "no-activate/tool/click-through styles missing")
    Sleep(600)
    WinGetPos(&x, &y, &w, &h, PauseOsdGui)
    monitor := MonitorForWindow(focused)
    Assert(w >= 150 && h >= 150, "spring entrance did not reach large size")
    DllCall("RedrawWindow", "Ptr", hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x185)
    color := PixelGetColor(x + 5, y + 5)
    Assert(color != 0x222222 && color != 0x010203 && color != 0, "icon erased after WM_PAINT")
    Assert(Abs(x + w / 2 - (monitor[1] + monitor[3]) / 2) <= 1, "not centered horizontally")
    Assert(Abs(y + h / 2 - (monitor[2] + monitor[4]) / 2) <= 1, "not centered vertically")
    Sleep(1100)
    WinGetPos(, , &shrinkingW, , PauseOsdGui)
    Assert(shrinkingW < w, "exit did not shrink")
    Sleep(400)
    Assert(!DllCall("IsWindowVisible", "Ptr", hwnd), "OSD did not hide near two seconds")
    FileAppend("OSD frame updates: " OsdFrameTimes.Length "`n", "*")
    Assert(OsdFrameTimes.Length >= 35, "animation starved by window-operation delays")
    TogglePause()
    firstStart := PauseOsdStart
    Sleep(100)
    TogglePause()
    Assert(PauseOsdGui.Hwnd = hwnd, "rapid toggle created a second GUI")
    Assert(PauseOsdStart > firstStart && PauseOsdIcon != firstIcon, "rapid toggle did not reload/reset state")
    Assert(WinExist("A") = focused, "rapid OSD stole focus")
    FileAppend("PASS: actual scale animation, centered reusable GUI, icon state reload and focus preservation`n", "*")
    ExitApp(0)
}
