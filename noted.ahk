#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
#Include data.ahk

global RuntimeDir := RegExReplace(A_LineFile, "\\[^\\]+$")
global Layout := BuildNotedData()
global ComposeData := BuildComposeData()
global ComposePrefixes := ComposeData[1], ComposeExact := ComposeData[2], ComposeBuffer := ""
global ShiftLDown := false, ShiftRDown := false, ShiftLock := false
global Mod3LDown := false, Mod3RDown := false
global Mod4LDown := false, Mod4RDown := false, Mod4Lock := false
global NonModifierUsed := false, IsPaused := false
global PauseHotkeyLatched := false
global PauseOsdGui := 0, PauseOsdIcons := Map(), PauseOsdIcon := 0, PauseOsdStart := 0
global PauseOsdCenterX := 0, PauseOsdCenterY := 0
global PauseOsdSize := 36, PauseOsdFromSize := 36, PauseOsdGeneration := 0
global PauseOsdDc := 0, PauseOsdBitmap := 0, PauseOsdOldBitmap := 0, PauseOsdBits := 0

if HasArg("--self-test")
    RunSelfTest()
SetCapsLockState("AlwaysOff")
InstallTray()
InstallHotkeys()
OnExit(ReleaseAll)
if HasArg("--smoke-test")
    SetTimer((*) => ExitApp(0), -500)
return

#SuspendExempt True
*End::PauseEndDown()
~*End up::PauseHotkeyUp()
#SuspendExempt False

HasArg(wanted) {
    for arg in A_Args
        if arg = wanted
            return true
    return false
}

InstallHotkeys() {
    global Layout
    for key, unused in Layout
        if key != "sc028" && key != "end"
            Hotkey("*" key, KeyDown.Bind(key))
    Hotkey("*sc028", ModifierDown.Bind("mod3R"))
    Hotkey("*sc028 up", ModifierUp.Bind("mod3R"))
    Hotkey("~*LShift", ModifierDown.Bind("shiftL"))
    Hotkey("~*LShift up", ModifierUp.Bind("shiftL"))
    Hotkey("~*RShift", ModifierDown.Bind("shiftR"))
    Hotkey("~*RShift up", ModifierUp.Bind("shiftR"))
    Hotkey("*CapsLock", ModifierDown.Bind("mod3L"))
    Hotkey("*CapsLock up", ModifierUp.Bind("mod3L"))
    Hotkey("*sc056", ModifierDown.Bind("mod4L"))
    Hotkey("*sc056 up", ModifierUp.Bind("mod4L"))
    Hotkey("*RAlt", ModifierDown.Bind("mod4R"))
    Hotkey("*RAlt up", ModifierUp.Bind("mod4R"))
}

ModifierDown(which, *) {
    global ShiftLDown, ShiftRDown, ShiftLock, Mod3LDown, Mod3RDown
    global Mod4LDown, Mod4RDown, Mod4Lock, NonModifierUsed
    switch which {
        case "shiftL":
            if ShiftLDown
                return
            if !ShiftLDown && ShiftRDown && !NonModifierUsed
                ShiftLock := !ShiftLock
            ShiftLDown := true
        case "shiftR":
            if ShiftRDown
                return
            if !ShiftRDown && ShiftLDown && !NonModifierUsed
                ShiftLock := !ShiftLock
            ShiftRDown := true
        case "mod3L":
            if Mod3LDown
                return
            if !Mod3LDown && Mod3RDown && !NonModifierUsed
                StartCompose()
            Mod3LDown := true
        case "mod3R":
            if Mod3RDown
                return
            if !Mod3RDown && Mod3LDown && !NonModifierUsed
                StartCompose()
            Mod3RDown := true
        case "mod4L":
            if Mod4LDown
                return
            if !Mod4LDown && Mod4RDown && !NonModifierUsed
                Mod4Lock := !Mod4Lock
            Mod4LDown := true
        case "mod4R":
            if Mod4RDown
                return
            if !Mod4RDown && Mod4LDown && !NonModifierUsed
                Mod4Lock := !Mod4Lock
            Mod4RDown := true
    }
    NonModifierUsed := false
}

ModifierUp(which, *) {
    global ShiftLDown, ShiftRDown, Mod3LDown, Mod3RDown, Mod4LDown, Mod4RDown
    switch which {
        case "shiftL": ShiftLDown := false
        case "shiftR": ShiftRDown := false
        case "mod3L": Mod3LDown := false
        case "mod3R": Mod3RDown := false
        case "mod4L": Mod4LDown := false
        case "mod4R": Mod4RDown := false
    }
}

ActiveLayer(caps, row := false) {
    global ShiftLDown, ShiftRDown, ShiftLock, Mod3LDown, Mod3RDown
    global Mod4LDown, Mod4RDown, Mod4Lock
    return ResolveLayer(caps, row, ShiftLDown || ShiftRDown, Mod3LDown || Mod3RDown,
        Mod4LDown || Mod4RDown, ShiftLock, Mod4Lock)
}

ResolveLayer(caps, row, shift, mod3, mod4, shiftLock, mod4Lock) {
    pos := 1 + (mod4Lock << 4) + (mod4 << 3) + (mod3 << 2) + (shiftLock << 1) + shift
    normal := SubStr("12123535444466664444353512126666", pos, 1) + 0
    letter := SubStr("12213535444466664444353512216666", pos, 1) + 0
    layer := caps ? letter : normal
    isLayer7 := SubStr("00000000010100000101000000000000", pos, 1) = "1"
    isLayer8 := SubStr("00000000000001010000000000000101", pos, 1) = "1"
    if isLayer7 && row && row[8] != ""
        layer := 7
    else if isLayer8 && row && row[9] != ""
        layer := 8
    return layer
}

ResolveValue(row, shift, mod3, mod4, shiftLock := false, mod4Lock := false) {
    return row[ResolveLayer(row[1], row, shift, mod3, mod4, shiftLock, mod4Lock) + 1]
}

KeyDown(key, *) {
    global Layout, NonModifierUsed, IsPaused
    if IsPaused
        return
    NonModifierUsed := true
    row := Layout[key]
    layer := ActiveLayer(row[1], row)
    value := row[layer + 1]
    if ShortcutModifierDown() {
        ShortcutOutput(ModifiedShortcutValue(row, value))
        return
    }
    OutputToken(value)
}

ModifiedShortcutValue(row, resolvedValue) {
    return ActionSpec(resolvedValue)[1] != "none" ? resolvedValue : row[2]
}

ShortcutModifierDown() {
    ; RAlt is Mod4/AltGr here, including the synthetic Ctrl Windows reports for AltGr.
    if GetKeyState("RAlt", "P")
        return false
    return GetKeyState("Ctrl", "P") || GetKeyState("LAlt", "P")
        || GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
}

ShortcutOutput(value) {
    if ActionSpec(value)[1] != "none"
        SendAction(value)
    else if StrLen(value) = 1
        Send(ShortcutOutputSpec(value))
}

ShortcutOutputSpec(value, explicitShift := false) {
    action := ActionSpec(value)
    if action[1] = "key"
        return "{Blind}" (explicitShift || action[3] ? "+" : "") "{" action[2] "}"
    if StrLen(value) != 1
        return ""
    if value = "{"
        key := "{{}"
    else if value = "}"
        key := "{}}"
    else
        key := "{" value "}"
    return "{Blind}" (explicitShift ? "+" : "") key
}

OutputToken(value) {
    global ComposeBuffer
    if value = ""
        return
    if SubStr(value, 1, 2) = "S_" {
        SendAction(value)
        return
    }
    token := EncodeToken(value)
    result := ComposeFeed(ComposeBuffer, token)
    ComposeBuffer := result[1]
    if result[2] != ""
        EmitEncoded(result[2])
}

StartCompose() {
    global ComposeBuffer
    ComposeBuffer := "S__Comp"
}

EncodeToken(value) {
    if SubStr(value, 1, 2) = "T_" || value = "S__Comp"
        return value
    if StrLen(value) = 1
        return Format("U{:06X}", Ord(value))
    result := ""
    loop parse value
        result .= Format("U{:06X}", Ord(A_LoopField))
    return result
}

ComposeFeed(buffer, token) {
    global ComposePrefixes, ComposeExact
    candidate := buffer token
    if ComposeExact.Has(candidate)
        return ["", ComposeExact[candidate]]
    if ComposePrefixes.Has(candidate)
        return [candidate, ""]
    if buffer != ""
        return ["", ""]
    return ["", token]
}

EmitEncoded(encoded) {
    pos := 1
    while pos <= StrLen(encoded) {
        token := SubStr(encoded, pos, 7)
        if SubStr(token, 1, 1) = "U"
            SendText(Chr(("0x" SubStr(token, 2)) + 0))
        else if SubStr(token, 1, 2) = "S_"
            SendAction(token)
        pos += 7
    }
}

SendAction(value) {
    spec := ActionSpec(value)
    if spec[1] = "compose" {
        StartCompose()
    } else if spec[1] = "key" {
        Send("{Blind}" (spec[3] ? "+" : "") "{" spec[2] "}")
    }
}

ActionSpec(value) {
    static actions := Map(
        "S__PgUp", "PgUp", "S____Up", "Up", "S___Del", "Delete", "S__PgDn", "PgDn",
        "S__Home", "Home", "S__Left", "Left", "S__Down", "Down", "S__Rght", "Right",
        "S___End", "End", "S___Ins", "Insert", "S__NEnt", "NumpadEnter", "S__NAdd", "NumpadAdd",
        "S__NSub", "NumpadSub", "S__NMul", "NumpadMult", "S__NDiv", "NumpadDiv",
        "S__Back", "Backspace", "S___Tab", "Tab", "S__Entr", "Enter", "S____Esc", "Escape",
        "S__N__0", "Numpad0", "S__N__1", "Numpad1", "S__N__2", "Numpad2", "S__N__3", "Numpad3",
        "S__N__4", "Numpad4", "S__N__5", "Numpad5", "S__N__6", "Numpad6", "S__N__7", "Numpad7",
        "S__N__8", "Numpad8", "S__N__9", "Numpad9", "S__NDot", "NumpadDot",
        "S__NDel", "NumpadDel", "S__NIns", "NumpadIns", "S__N_Up", "NumpadUp",
        "S__N_Dn", "NumpadDown", "S__N_Ri", "NumpadRight", "S__N_Le", "NumpadLeft",
        "S__NPUp", "NumpadPgUp", "S__NPDn", "NumpadPgDn", "S__NHom", "NumpadHome",
        "S__NEnd", "NumpadEnd", "S__NClr", "NumpadClear")
    static controls := Map(Chr(8), "Backspace", Chr(9), "Tab", Chr(10), "Enter",
        Chr(13), "Enter", Chr(27), "Escape")
    if controls.Has(value)
        return ["key", controls[value], false]
    if value = "S__Comp"
        return ["compose", "", false]
    if actions.Has(value)
        return ["key", actions[value], false]
    if RegExMatch(value, "^S____F([1-9])$", &m) || RegExMatch(value, "^S___F(1[0-2])$", &m)
        return ["key", "F" m[1], false]
    if RegExMatch(value, "^S_S(NDel|NIns|N_Up|N_Dn|N_Ri|N_Le|NPUp|NPDn|NHom|NEnd|NClr)$", &m) {
        plain := "S__" m[1]
        if actions.Has(plain)
            return ["key", actions[plain], true]
    }
    return ["none", "", false]
}

MonitorForWindow(window) {
    monitor := window ? DllCall("MonitorFromWindow", "Ptr", window, "UInt", 2, "Ptr") : 0
    if monitor {
        info := Buffer(40, 0)
        NumPut("UInt", 40, info, 0)
        if DllCall("GetMonitorInfoW", "Ptr", monitor, "Ptr", info)
            return [NumGet(info, 4, "Int"), NumGet(info, 8, "Int"),
                NumGet(info, 12, "Int"), NumGet(info, 16, "Int")]
    }
    primary := MonitorGetPrimary()
    MonitorGet(primary, &left, &top, &right, &bottom)
    return [left, top, right, bottom]
}

InstallTray() {
    SetTrayIcon(true)
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Pausieren (Strg+Ende)", TogglePause)
    A_TrayMenu.Add("Neu laden", (*) => Reload())
    A_TrayMenu.Add("Beenden", (*) => ExitApp())
}

SetTrayIcon(enabled) {
    global RuntimeDir
    TraySetIcon(RuntimeDir "\noted_" (enabled ? "enabled" : "disabled") ".ico",, true)
}


TogglePause(*) {
    global IsPaused
    previousCritical := A_IsCritical
    Critical("On")
    try {
        IsPaused := !IsPaused
        ClearTrackedState()
        Suspend(IsPaused)
        SetTrayIcon(!IsPaused)
        if !IsPaused {
            SetCapsLockState("AlwaysOff")
            SyncPhysicalState()
        }
        ShowPauseOsd(!IsPaused)
    } finally {
        Critical(previousCritical ? previousCritical : "Off")
    }
}

PauseHotkeyDown(*) {
    global PauseHotkeyLatched
    if PauseHotkeyLatched
        return
    PauseHotkeyLatched := true
    TogglePause()
}

PauseEndDown(*) {
    global IsPaused, PauseHotkeyLatched
    if PauseHotkeyLatched
        return
    if GetKeyState("Ctrl") && !GetKeyState("Shift") && !GetKeyState("Alt")
            && !GetKeyState("LWin") && !GetKeyState("RWin")
        PauseHotkeyDown()
    else if IsPaused
        Send("{Blind}{End}")
    else
        KeyDown("end")
}

PauseHotkeyUp(*) {
    global PauseHotkeyLatched
    PauseHotkeyLatched := false
}

ShowPauseOsd(enabled) {
    global PauseOsdGui, PauseOsdIcons, PauseOsdIcon, PauseOsdStart
    global PauseOsdCenterX, PauseOsdCenterY, PauseOsdSize, PauseOsdFromSize, PauseOsdGeneration
    previousCritical := A_IsCritical
    Critical("On")
    try {
        activeWindow := WinExist("A")
        InitPauseOsd()
        SetTimer(AnimatePauseOsd, 0)
        visible := DllCall("IsWindowVisible", "Ptr", PauseOsdGui.Hwnd)
        PauseOsdFromSize := visible ? PauseOsdSize : 36
        PauseOsdIcon := PauseOsdIcons[enabled ? "enabled" : "disabled"]
        monitor := MonitorForWindow(activeWindow)
        PauseOsdCenterX := (monitor[1] + monitor[3]) / 2
        PauseOsdCenterY := (monitor[2] + monitor[4]) / 2
        PauseOsdStart := A_TickCount
        PauseOsdGeneration += 1
        DrawPauseOsd(PauseOsdFromSize)
        if !visible
            DllCall("ShowWindow", "Ptr", PauseOsdGui.Hwnd, "Int", 4)
        SetTimer(AnimatePauseOsd, 16)
    } finally {
        Critical(previousCritical ? previousCritical : "Off")
    }
}

InitPauseOsd() {
    global RuntimeDir, PauseOsdGui, PauseOsdIcons
    global PauseOsdDc, PauseOsdBitmap, PauseOsdOldBitmap, PauseOsdBits
    if PauseOsdGui
        return
    PauseOsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08080000 -DPIScale")
    PauseOsdIcons["enabled"] := LoadPicture(RuntimeDir "\noted_enabled.ico", "w256 h256", &imageType)
    PauseOsdIcons["disabled"] := LoadPicture(RuntimeDir "\noted_disabled.ico", "w256 h256", &imageType)
    if !PauseOsdIcons["enabled"] || !PauseOsdIcons["disabled"]
        throw Error("Unable to load OSD icons")
    info := Buffer(40, 0)
    NumPut("UInt", 40, "Int", 256, "Int", -256, "UShort", 1, "UShort", 32, info)
    PauseOsdDc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    PauseOsdBitmap := DllCall("CreateDIBSection", "Ptr", 0, "Ptr", info, "UInt", 0,
        "Ptr*", &PauseOsdBits, "Ptr", 0, "UInt", 0, "Ptr")
    if !PauseOsdDc || !PauseOsdBitmap || !PauseOsdBits
        throw Error("Unable to create OSD frame buffer (Win32 " A_LastError ")")
    PauseOsdOldBitmap := DllCall("SelectObject", "Ptr", PauseOsdDc, "Ptr", PauseOsdBitmap, "Ptr")
    if !PauseOsdOldBitmap
        throw Error("Unable to select OSD frame buffer (Win32 " A_LastError ")")
}

AnimatePauseOsd() {
    global PauseOsdGui, PauseOsdStart, PauseOsdFromSize, PauseOsdGeneration
    static duration := 2000, enter := 480, exitStart := 1450, target := 160
    previousCritical := A_IsCritical
    Critical("On")
    try {
        generation := PauseOsdGeneration
        elapsed := A_TickCount - PauseOsdStart
        if elapsed >= duration {
            if generation = PauseOsdGeneration {
                SetTimer(AnimatePauseOsd, 0)
                PauseOsdGui.Hide()
            }
            return
        }
        if elapsed < enter {
            t := elapsed / enter
            c1 := 1.35, c3 := c1 + 1
            eased := 1 + c3 * ((t - 1) ** 3) + c1 * ((t - 1) ** 2)
            size := Round(PauseOsdFromSize + (target - PauseOsdFromSize) * eased)
        } else if elapsed < exitStart {
            size := target
        } else {
            t := (elapsed - exitStart) / (duration - exitStart)
            size := Round(target * (1 - t ** 3))
        }
        if generation = PauseOsdGeneration
            DrawPauseOsd(Max(1, size))
    } finally {
        Critical(previousCritical ? previousCritical : "Off")
    }
}

DrawPauseOsd(size) {
    global PauseOsdGui, PauseOsdIcon, PauseOsdCenterX, PauseOsdCenterY, PauseOsdSize
    global PauseOsdDc, PauseOsdBits
    size := Min(256, Max(1, Round(size)))
    x := Round(PauseOsdCenterX - size / 2), y := Round(PauseOsdCenterY - size / 2)
    DllCall("RtlZeroMemory", "Ptr", PauseOsdBits, "UPtr", 256 * 256 * 4)
    if !DllCall("DrawIconEx", "Ptr", PauseOsdDc, "Int", 0, "Int", 0, "Ptr", PauseOsdIcon,
            "Int", size, "Int", size, "UInt", 0, "Ptr", 0, "UInt", 3)
        throw Error("Unable to draw OSD icon (Win32 " A_LastError ")")
    destination := Buffer(8), dimensions := Buffer(8), source := Buffer(8, 0), blend := Buffer(4)
    NumPut("Int", x, "Int", y, destination)
    NumPut("Int", size, "Int", size, dimensions)
    NumPut("UChar", 0, "UChar", 0, "UChar", 255, "UChar", 1, blend)
    if !DllCall("UpdateLayeredWindow", "Ptr", PauseOsdGui.Hwnd, "Ptr", 0,
            "Ptr", destination, "Ptr", dimensions, "Ptr", PauseOsdDc, "Ptr", source,
            "UInt", 0, "Ptr", blend, "UInt", 2)
        throw Error("Unable to publish OSD frame (Win32 " A_LastError ")")
    PauseOsdSize := size
}

ClearTrackedState(*) {
    global ShiftLDown, ShiftRDown, Mod3LDown, Mod3RDown, Mod4LDown, Mod4RDown, ComposeBuffer
    ShiftLDown := false, ShiftRDown := false, Mod3LDown := false, Mod3RDown := false
    Mod4LDown := false, Mod4RDown := false, ComposeBuffer := ""
}

SyncPhysicalState() {
    global ShiftLDown, ShiftRDown, Mod3LDown, Mod3RDown, Mod4LDown, Mod4RDown
    ShiftLDown := GetKeyState("LShift", "P"), ShiftRDown := GetKeyState("RShift", "P")
    Mod3LDown := GetKeyState("CapsLock", "P"), Mod3RDown := GetKeyState("sc028", "P")
    Mod4LDown := GetKeyState("sc056", "P"), Mod4RDown := GetKeyState("RAlt", "P")
}

ReleaseAll(*) {
    global PauseOsdGui, PauseOsdIcons, PauseOsdIcon, PauseOsdDc, PauseOsdBitmap, PauseOsdOldBitmap, PauseOsdBits
    SetTimer(AnimatePauseOsd, 0)
    ClearTrackedState()
    if PauseOsdDc && PauseOsdOldBitmap
        DllCall("SelectObject", "Ptr", PauseOsdDc, "Ptr", PauseOsdOldBitmap)
    if PauseOsdBitmap
        DllCall("DeleteObject", "Ptr", PauseOsdBitmap)
    if PauseOsdDc
        DllCall("DeleteDC", "Ptr", PauseOsdDc)
    for unused, icon in PauseOsdIcons
        if icon
            DllCall("DestroyIcon", "Ptr", icon)
    PauseOsdIcons := Map()
    PauseOsdIcon := 0
    PauseOsdOldBitmap := 0, PauseOsdBitmap := 0, PauseOsdDc := 0, PauseOsdBits := 0
    if PauseOsdGui {
        PauseOsdGui.Destroy()
        PauseOsdGui := 0
    }
}

RunSelfTest() {
    global Layout, ComposePrefixes, ComposeExact
    failures := []
    Check(failures, Layout.Count = 91, "resolved Noted table count")
    Check(failures, ComposePrefixes.Count = 1644 && ComposeExact.Count = 7622, "compose counts")
    normalBits := "12123535444466664444353512126666"
    letterBits := "12213535444466664444353512216666"
    loop 32 {
        pos := A_Index - 1
        shift := pos & 1, shiftLock := (pos >> 1) & 1, mod3 := (pos >> 2) & 1
        mod4 := (pos >> 3) & 1, mod4Lock := (pos >> 4) & 1
        Check(failures, ResolveLayer(0, false, shift, mod3, mod4, shiftLock, mod4Lock)
            = SubStr(normalBits, A_Index, 1) + 0, "normal layer " A_Index)
        Check(failures, ResolveLayer(1, false, shift, mod3, mod4, shiftLock, mod4Lock)
            = SubStr(letterBits, A_Index, 1) + 0, "letter layer " A_Index)
    }
    Check(failures, Layout["sc010"][2] = "z" && Layout["sc010"][6] = "ζ", "Noted letters")
    Check(failures, Layout["sc013"][4] = "]" && Layout["sc012"][6] = "", "NoSymbol/VoidSymbol")
    Check(failures, Layout["sc028"][2] = "" && Layout["sc02B"][2] = "T__acut", "fixed Mod3/dead roles")
    Check(failures, Layout["sc027"][8] = "S__NDot" && Layout["sc035"][8] = ",", "shifted layer 4")
    first := ComposeFeed("", "T__acut"), second := ComposeFeed(first[1], "U000061")
    Check(failures, first[1] = "T__acut" && second[2] = "U0000E1", "acute compose")
    loop 12 {
        token := A_Index < 10 ? "S____F" A_Index : "S___F" A_Index
        Check(failures, ActionSpec(token)[1] = "key", "F key " A_Index)
    }
    for token in ["S__NHom","S__N_Up","S__NPUp","S__N_Le","S__NClr","S__N_Ri",
            "S__NEnd","S__N_Dn","S__NPDn","S__NIns","S__NDel"]
        Check(failures, ActionSpec(token)[1] = "key", "numpad navigation " token)
    for key, row in Layout
        loop 8
            if SubStr(row[A_Index + 1], 1, 2) = "S_"
                Check(failures, ActionSpec(row[A_Index + 1])[1] != "none", "action " row[A_Index + 1])
    if failures.Length {
        report := ""
        for failure in failures
            report .= "FAIL: " failure "`n"
        FileAppend(report, "*")
        ExitApp(1)
    }
    FileAppend("PASS: 91 resolved Noted rows; 32 layer states; 7622 compose results; actions and fixed roles`n", "*")
    ExitApp(0)
}

Check(failures, condition, message) {
    if !condition
        failures.Push(message)
}
