#Requires AutoHotkey v2.0
#SingleInstance Force
#InputLevel 0
OnError(OsdError)
CoordMode("Pixel", "Screen")
global PublishedSizes := [], LastPublishedSize := 0
SetTimer(ObservePublishedFrame, 8)
SetTimer(VerifyOsd, -400)
#Include ..\noted.ahk

Assert(value, message) {
    if !value
        throw Error(message)
}

OsdError(err, mode) {
    FileAppend("OSD FAIL: " err.Message " at " err.Line "`n", "*")
    ExitApp(1)
}

ObservePublishedFrame() {
    global PauseOsdGui, PauseOsdSize, PublishedSizes, LastPublishedSize
    if IsSet(PauseOsdGui) && PauseOsdGui && DllCall("IsWindowVisible", "Ptr", PauseOsdGui.Hwnd)
            && PauseOsdSize != LastPublishedSize {
        PublishedSizes.Push([A_TickCount, PauseOsdSize])
        LastPublishedSize := PauseOsdSize
    }
}

InjectKey(vk, up := false) {
    ; keybd_event reaches the registered keyboard hook; these are actual injected events,
    ; unlike the direct handler calls used for tray/timer coverage below.
    flags := (vk = 0x23 ? 1 : 0) | (up ? 2 : 0)
    DllCall("keybd_event", "UChar", vk, "UChar", 0, "UInt", flags, "UPtr", 0)
}

FramePixel(x, y) {
    global PauseOsdBits
    return NumGet(PauseOsdBits + (y * 256 + x) * 4, "UInt")
}

AssertPremultiplied(size) {
    global PauseOsdBits
    opaque := 0, transparent := 0
    loop size {
        y := A_Index - 1
        loop size {
            pixel := FramePixel(A_Index - 1, y)
            a := (pixel >> 24) & 255, r := (pixel >> 16) & 255
            g := (pixel >> 8) & 255, b := pixel & 255
            Assert(r <= a && g <= a && b <= a, "DIB contains non-premultiplied color")
            opaque += a > 0, transparent += a = 0
        }
    }
    Assert(opaque > 100, "DIB alpha plane has no visible pixels")
}

GuiResources(kind) {
    return DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"),
        "UInt", kind, "UInt")
}

VerifyOsd() {
    global PauseOsdGui, PauseOsdIcons, PauseOsdIcon, PauseOsdStart, PauseOsdSize
    global PauseOsdGeneration, PauseOsdDc, PauseOsdBitmap, PauseHotkeyLatched, IsPaused, PublishedSizes
    target := Gui(, "Noted OSD verification")
    target.BackColor := "222222"
    edit := target.AddEdit("w300 h60", "Focus target")
    target.Show("Center w600 h400")
    WinActivate(target)
    Sleep(100)
    focused := WinExist("A")

    ; Entrance, atomic alpha frame, focus/style, and current-size retarget.
    TogglePause("direct")
    Assert(IsPaused && A_IsSuspended, "pause did not suspend")
    Assert(WinExist("A") = focused, "OSD stole focus")
    hwnd := PauseOsdGui.Hwnd
    Assert(PauseOsdIcon = PauseOsdIcons["disabled"], "OFF icon not selected")
    style := WinGetExStyle(PauseOsdGui)
    Assert((style & 0x080800A0) = 0x080800A0, "layered/no-activate/tool/click-through styles missing")
    Sleep(620)
    before := PauseOsdSize
    Assert(before >= 150, "spring entrance did not reach large size")
    offPixel := FramePixel(Floor(before / 2), Floor(before / 2))
    WinGetPos(&offX, &offY, , , PauseOsdGui)
    Assert(PixelGetColor(offX + Floor(before / 2), offY + Floor(before / 2))
        = (offPixel & 0xFFFFFF), "published OFF pixel differs from complete DIB frame")
    AssertPremultiplied(before)
    oldStart := PauseOsdStart
    TogglePause("tray callback")
    Assert(!IsPaused && !A_IsSuspended, "resume did not unsuspend")
    Assert(PauseOsdGui.Hwnd = hwnd, "retarget created a second GUI")
    Assert(Abs(PauseOsdSize - before) <= 1, "visible retarget snapped to tiny size")
    Assert(PauseOsdStart >= oldStart && PauseOsdIcon = PauseOsdIcons["enabled"], "latest icon/start not selected")
    onPixel := FramePixel(Floor(PauseOsdSize / 2), Floor(PauseOsdSize / 2))
    Assert(onPixel != offPixel, "latest ON/OFF frame pixels are indistinguishable")
    WinGetPos(&onX, &onY, , , PauseOsdGui)
    Assert(PixelGetColor(onX + Floor(PauseOsdSize / 2), onY + Floor(PauseOsdSize / 2))
        = (onPixel & 0xFFFFFF), "published ON pixel is not the latest complete frame")
    Assert(WinExist("A") = focused, "rapid OSD stole focus")
    Assert(!GetKeyState("CapsLock", "T"), "CapsLock was not forced off on resume")

    ; Burst parity: every direct/tray-style request is preserved and the HWND stays stable.
    parity := IsPaused
    loop 12 {
        TogglePause(Mod(A_Index, 2) ? "direct" : "tray callback")
        parity := !parity
        Assert(IsPaused = parity, "burst toggle was collapsed")
        Assert(PauseOsdGui.Hwnd = hwnd, "burst replaced the OSD window")
    }

    ; A late activation owns a fresh full lifetime; an older expiry cannot hide it.
    Sleep(1660)
    Assert(DllCall("IsWindowVisible", "Ptr", hwnd), "OSD hid before its exit completed")
    TogglePause("near-expiry direct")
    latestStart := PauseOsdStart, latestGeneration := PauseOsdGeneration
    Sleep(430)
    Assert(DllCall("IsWindowVisible", "Ptr", hwnd), "old timer hid the new OSD")
    Assert(PauseOsdGeneration = latestGeneration && A_TickCount - latestStart < 800,
        "latest activation timing was not retained")
    Sleep(1100)
    Assert(DllCall("IsWindowVisible", "Ptr", hwnd), "latest OSD did not receive a full hold")
    Sleep(550)
    Assert(!DllCall("IsWindowVisible", "Ptr", hwnd), "OSD did not expire two seconds after latest activation")

    ; Actual low-level injected hook events: repeat-down latching, Ctrl-before-End release,
    ; End-up unlatching, then a distinct press-release-press.
    if IsPaused
        TogglePause("normalize")
    InjectKey(0x11)
    Sleep(30)
    InjectKey(0x23)
    Sleep(100)
    Assert(IsPaused && PauseHotkeyLatched, "injected Ctrl+End did not reach registered hook")
    InjectKey(0x23)
    Sleep(100)
    Assert(IsPaused, "repeated End down toggled while held")
    InjectKey(0x11, true)
    InjectKey(0x23)
    Sleep(100)
    Assert(IsPaused && PauseHotkeyLatched, "Ctrl release incorrectly cleared End latch")
    ; Timer/direct callbacks remain usable while the key latch is held.
    SetTimer(TogglePause.Bind("timer callback"), -20)
    Sleep(100)
    Assert(!IsPaused && PauseHotkeyLatched, "timer toggle was blocked by held hotkey")
    InjectKey(0x23, true)
    Sleep(80)
    Assert(!PauseHotkeyLatched, "End-up did not release hotkey latch")
    InjectKey(0x11)
    Sleep(30)
    InjectKey(0x23)
    Sleep(80)
    Assert(IsPaused && PauseHotkeyLatched,
        "second injected press did not toggle: paused=" IsPaused " latch=" PauseHotkeyLatched)
    InjectKey(0x23, true), InjectKey(0x11, true)
    Sleep(80)
    Assert(IsPaused, "distinct press after release was not preserved")

    ; The exempt wildcard dispatcher must preserve ordinary End while paused,
    ; and Ctrl+Shift+End must select text rather than toggle the layout.
    edit.Value := "abcdef"
    edit.Focus()
    SendMessage(0x00B1, 0, 0, edit)
    InjectKey(0x23)
    Sleep(60)
    InjectKey(0x23, true)
    Sleep(60)
    selection := SendMessage(0x00B0, 0, 0, edit)
    Assert((selection & 0xFFFF) = 6 && IsPaused, "ordinary End swallowed while paused")
    SendMessage(0x00B1, 0, 0, edit)
    InjectKey(0x11), InjectKey(0x10)
    Sleep(30)
    InjectKey(0x23)
    Sleep(60)
    InjectKey(0x23, true), InjectKey(0x10, true), InjectKey(0x11, true)
    Sleep(60)
    selection := SendMessage(0x00B0, 0, 0, edit)
    Assert(IsPaused && (selection & 0xFFFF) = 0 && ((selection >> 16) & 0xFFFF) = 6,
        "Ctrl+Shift+End toggled layout or failed native selection")

    ; Successful publications, not requested timer ticks, must show moving cadence.
    moving := 0
    for index, sample in PublishedSizes
        if index > 1 && sample[2] != PublishedSizes[index - 1][2]
            moving += 1
    Assert(moving >= 35, "animation published too few distinct moving frames: " moving)

    ; Cached sources and the one DIB/DC must not grow GDI/USER resources under stress.
    gdiBefore := GuiResources(0), userBefore := GuiResources(1)
    dcBefore := PauseOsdDc, bitmapBefore := PauseOsdBitmap
    enabledBefore := PauseOsdIcons["enabled"], disabledBefore := PauseOsdIcons["disabled"]
    loop 80
        TogglePause(Mod(A_Index, 3) ? "direct stress" : "tray stress")
    Sleep(100)
    gdiAfter := GuiResources(0), userAfter := GuiResources(1)
    if gdiBefore || gdiAfter
        Assert(gdiAfter <= gdiBefore + 1, "GDI resources grew: " gdiBefore " -> " gdiAfter)
    if userBefore || userAfter
        Assert(userAfter <= userBefore + 1, "USER resources grew: " userBefore " -> " userAfter)
    Assert(PauseOsdDc = dcBefore && PauseOsdBitmap = bitmapBefore
            && PauseOsdIcons["enabled"] = enabledBefore && PauseOsdIcons["disabled"] = disabledBefore,
        "stress replaced cached GDI/icon resources")
    Assert(DllCall("GetObjectType", "Ptr", dcBefore) && DllCall("GetObjectType", "Ptr", bitmapBefore),
        "cached GDI resources became invalid")
    Assert(PauseOsdGui.Hwnd = hwnd && WinExist("A") = focused, "stress changed HWND or focus")

    SetTimer(ObservePublishedFrame, 0)
    ReleaseAll()
    Assert(!DllCall("GetObjectType", "Ptr", dcBefore) && !DllCall("GetObjectType", "Ptr", bitmapBefore),
        "OSD DC/bitmap were not released")
    FileAppend("PASS: atomic layered frames; continuity/burst/latest-expiry; injected hook latch; "
        moving " moving frames; cached handles stable/released; GetGuiResources GDI "
        gdiBefore "->" gdiAfter ", USER " userBefore "->" userAfter "`n", "*")
    ExitApp(0)
}
