#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)

#Include source\v2-generated-data.ahk

global NeoBase := BuildNeoData()
NeoBase["sc02B"] := [0, "", "", "", "", "", "", "", ""]
AddCoreKeys(NeoBase)
AddPseudoNavigation(NeoBase)
global Layout := CloneLayout(NeoBase)
global VariantMeta := BuildVariantMetadata()
global ComposeData := BuildComposeData()
global ComposePrefixes := ComposeData[1]
global ComposeExact := ComposeData[2]
global ComposeBuffer := ""
global CurrentVariant := "Neo"
global ShiftLDown := false, ShiftRDown := false, ShiftLock := false
global Mod3LDown := false, Mod3RDown := false
global Mod4LDown := false, Mod4RDown := false, Mod4Lock := false
global NonModifierUsed := false, IsPaused := false
global DualKeyRoles := Map()
global IniPath := A_AppData "\Neo2\Neo2.ini"
global PauseOsdGui := 0, PauseOsdPicture := 0, PauseOsdStart := 0

if HasArg("--self-test")
    RunSelfTest()

SetCapsLockState("AlwaysOff")
LoadPreference()
InstallTray()
InstallHotkeys()
OnExit(ReleaseAll)
if HasArg("--smoke-test")
    SetTimer((*) => ExitApp(0), -500)
return

#SuspendExempt True
^End::TogglePause()
#SuspendExempt False

HasArg(wanted) {
    for arg in A_Args
        if arg = wanted
            return true
    return false
}

CloneLayout(source) {
    target := Map()
    for key, row in source
        target[key] := [row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9]]
    return target
}

AddCoreKeys(data) {
    data["space"] := [0, " ", " ", " ", "S__N__0", " ", " ", "", ""]
    data["esc"] := [0, "S____Esc", "S____Esc", "", "S____Esc", "S____Esc", "S____Esc", "", ""]
    data["tab"] := [0, "S___Tab", "S___Tab", "S__Comp", "S___Tab", "S___Tab", "S___Tab", "", ""]
    data["enter"] := [0, "S__Entr", "S__Entr", "S__Entr", "S__NEnt", "S__Entr", "S__Entr", "", ""]
    loop 12 {
        token := A_Index < 10 ? "S____F" A_Index : "S___F" A_Index
        data["F" A_Index] := [0, token, token, "", token, "", "", "", ""]
    }
}

AddPseudoNavigation(data) {
    shifted := Map("047", "S_SNHom", "048", "S_SN_Up", "049", "S_SNPUp",
        "04B", "S_SN_Le", "04C", "S_SNClr", "04D", "S_SN_Ri",
        "04F", "S_SNEnd", "050", "S_SN_Dn", "051", "S_SNPDn",
        "052", "S_SNIns", "053", "S_SNDel")
    for sc, token in shifted
        data["sc" sc][8] := token
}

InstallHotkeys() {
    global NeoBase
    for key, unused in NeoBase {
        if key != "sc028" && key != "sc02B"
            Hotkey("*" key, KeyDown.Bind(key))
    }
    for key in ["sc028", "sc02B"] {
        Hotkey("*" key, DualKeyDown.Bind(key))
        Hotkey("*" key " up", DualKeyUp.Bind(key))
    }
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

DualKeyDown(key, *) {
    global CurrentVariant, DualKeyRoles
    if DualKeyRoles.Has(key)
        return
    isModifier := DualRoleForVariant(key, CurrentVariant) = "mod3R"
    DualKeyRoles[key] := isModifier ? "mod3R" : "key"
    if isModifier
        ModifierDown("mod3R")
    else
        KeyDown(key)
}

DualRoleForVariant(key, variant) {
    return ((variant = "Noted") ? key = "sc028" : key = "sc02B") ? "mod3R" : "key"
}

DualKeyUp(key, *) {
    global DualKeyRoles
    if !DualKeyRoles.Has(key)
        return
    role := DualKeyRoles[key]
    DualKeyRoles.Delete(key)
    if role = "mod3R"
        ModifierUp("mod3R")
}

ModifierDown(which, *) {
    global ShiftLDown, ShiftRDown, ShiftLock, Mod3LDown, Mod3RDown
    global Mod4LDown, Mod4RDown, Mod4Lock, NonModifierUsed
    switch which {
        case "shiftL":
            if !ShiftLDown && ShiftRDown && !NonModifierUsed
                ShiftLock := !ShiftLock
            ShiftLDown := true
        case "shiftR":
            if !ShiftRDown && ShiftLDown && !NonModifierUsed
                ShiftLock := !ShiftLock
            ShiftRDown := true
        case "mod3L":
            if !Mod3LDown && Mod3RDown && !NonModifierUsed
                StartCompose()
            Mod3LDown := true
        case "mod3R":
            if !Mod3RDown && Mod3LDown && !NonModifierUsed
                StartCompose()
            Mod3RDown := true
        case "mod4L":
            if !Mod4LDown && Mod4RDown && !NonModifierUsed
                Mod4Lock := !Mod4Lock
            Mod4LDown := true
        case "mod4R":
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
    if HandleVariantShortcut(key, layer)
        return
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

HandleVariantShortcut(key, layer) {
    global CurrentVariant
    if layer = 3 && key = "F7" {
        SwitchVariant(CurrentVariant = "Noted" ? "Neo" : "Noted")
        return true
    }
    if layer = 4 && key = "F7" {
        SaveVariant()
        return true
    }
    if layer = 3 && key = "F6" {
        SwitchVariant(CurrentVariant = "QWERTZ" ? "Neo" : "QWERTZ")
        return true
    }
    if layer = 4 && key = "F6" {
        SaveVariant()
        return true
    }
    if layer = 3 && key = "F12" {
        static order := ["Neo", "NordTast", "AdNW", "DIEgO", "K.O,Y"]
        index := 1
        for i, name in order
            if name = CurrentVariant
                index := i
        SwitchVariant(order[Mod(index, order.Length) + 1])
        return true
    }
    if layer = 4 && key = "F12" {
        SaveVariant()
        return true
    }
    return false
}

SwitchVariant(name, notify := true) {
    global Layout, NeoBase, CurrentVariant, ComposeBuffer
    Layout := CloneLayout(NeoBase)
    if name = "Noted"
        ApplyNoted(Layout)
    else if name != "Neo"
        ApplyLetterVariant(Layout, name)
    CurrentVariant := name
    ComposeBuffer := ""
    if notify
        TrayTip("Aktive Belegung: " name, "Neo/Noted")
}

ApplyLetterVariant(layout, name) {
    global VariantMeta
    strings := Map(
        "QWERTZ", "ßqwertzuiopüasdfghjklöäyxcvbnm,.-",
        "NordTast", "-äuobpkglmfxaietchdnrsß.,üöqyzwvj",
        "AdNW", "-kuü.ävgcljfhieaodtrnsßxyö,qbpwmz",
        "DIEgO", "-puü.äjclhxzdieaogtrnsßkyö,qmvwbf",
        "K.O,Y", "-k.o,yvgclßzhaeiudtrnsfxqäüöbpwmj")
    chars := StrSplit(strings[name])
    properties := Map()
    for row in VariantMeta
        properties[row[3]] := row
    for index, destination in VariantMeta {
        source := properties[chars[index]]
        item := layout["sc" destination[1]]
        item[1] := source[2] + 0, item[2] := source[3], item[3] := source[4]
        item[6] := source[5], item[7] := source[6]
    }
}

ApplyNoted(layout) {
    rows := NotedRows()
    for sc, override in rows {
        base := layout["sc" sc]
        base[1] := override[1]
        loop 8
            if override[A_Index + 1] != "="
                base[A_Index + 1] := override[A_Index + 1]
    }
}

NotedRows() {
    m := Map()
    AddNoted(m,"010",1,"z","Z","=","=","ζ","ℤ","=","=")
    AddNoted(m,"011",1,"y","Y","=","=","υ","ℵ","=","=")
    AddNoted(m,"012",1,"u","U","=","=","","×","=","=")
    AddNoted(m,"013",1,"a","A","=","=","α","∀","=","=")
    AddNoted(m,"014",1,"q","Q","=","=","ϕ","ℚ","=","=")
    AddNoted(m,"015",1,"p","P","=","=","π","Π","=","=")
    AddNoted(m,"016",1,"b","B","=","=","β","∂","=","=")
    AddNoted(m,"017",1,"m","M","=","=","μ","↦","=","=")
    AddNoted(m,"018",1,"l","L","=","=","λ","Λ","=","=")
    AddNoted(m,"019",1,"f","F","=","=","φ","Φ","=","=")
    AddNoted(m,"01A",1,"j","J","@","−","θ","Θ","=","=")
    AddNoted(m,"01B",1,"ß","ẞ","ſ",";","ς","∘","=","=")
    AddNoted(m,"01E",1,"c","C","=","=","χ","ℂ","=","=")
    AddNoted(m,"01F",1,"s","S","=","=","σ","Σ","=","=")
    AddNoted(m,"020",1,"i","I","=","=","ι","∫","=","=")
    AddNoted(m,"021",1,"e","E","=","=","ε","∃","=","=")
    AddNoted(m,"022",1,"o","O","=","=","ο","∈","=","=")
    AddNoted(m,"023",1,"d","D","=","=","δ","Δ","=","=")
    AddNoted(m,"024",1,"t","T","=","=","τ","∇","=","=")
    AddNoted(m,"025",1,"n","N","=","=","ν","ℕ","=","=")
    AddNoted(m,"026",1,"r","R","=","=","ρ","ℝ","=","=")
    AddNoted(m,"027",1,"h","H","=",".","ψ","Ψ","S__NDot","=")
    AddNoted(m,"02B",0,"T__acut","T__tlde","T__strk","T__dbac","T_psili","T__brve","","=")
    AddNoted(m,"02C",1,"v","V","=","=","","√","=","=")
    AddNoted(m,"02D",1,"x","X","=","=","ξ","Ξ","=","=")
    AddNoted(m,"02E",1,"ü","Ü","=","=","","∪","=","=")
    AddNoted(m,"02F",1,"ä","Ä","=","=","η","∩","=","=")
    AddNoted(m,"030",1,"ö","Ö","=","=","ϵ","⊂","=","=")
    AddNoted(m,"031",1,"w","W","=","=","ω","Ω","=","=")
    AddNoted(m,"032",1,"g","G","=","=","γ","Γ","=","=")
    AddNoted(m,"033",0,",","–","=","=","ϱ","⇐","=","=")
    AddNoted(m,"034",0,".","•","=","=","ϑ","⇔","=","=")
    AddNoted(m,"035",1,"k","K","=","S__NDot","κ","⇒",",","=")
    return m
}

AddNoted(map, sc, caps, e1,e2,e3,e4,e5,e6,e7,e8) {
    map[sc] := [caps,e1,e2,e3,e4,e5,e6,e7,e8]
}

LoadPreference() {
    global IniPath
    explicit := IniRead(IniPath, "Global", "LayoutVariant", "")
    noted := IniRead(IniPath, "Global", "isNoted", "0")
    qwertz := IniRead(IniPath, "Global", "isQwertz", "0")
    nord := IniRead(IniPath, "Global", "isNordTast", "0")
    SwitchVariant(VariantFromPreferences(explicit, noted, qwertz, nord), false)
}

VariantFromPreferences(explicit, noted, qwertz, nord) {
    for name in ["Neo","Noted","QWERTZ","NordTast","AdNW","DIEgO","K.O,Y"]
        if explicit = name
            return name
    if noted = "1"
        return "Noted"
    if qwertz = "1"
        return "QWERTZ"
    index := nord + 0
    if index >= 1 && index <= 4
        return ["NordTast","AdNW","DIEgO","K.O,Y"][index]
    return "Noted"
}

SaveVariant() {
    global IniPath, CurrentVariant
    DirCreate(A_AppData "\Neo2")
    IniDelete(IniPath, "Global", "isNoted")
    IniDelete(IniPath, "Global", "isQwertz")
    IniDelete(IniPath, "Global", "isNordTast")
    IniWrite(CurrentVariant, IniPath, "Global", "LayoutVariant")
    if CurrentVariant = "Noted"
        IniWrite(1, IniPath, "Global", "isNoted")
    else if CurrentVariant = "QWERTZ"
        IniWrite(1, IniPath, "Global", "isQwertz")
    else {
        values := Map("NordTast",1,"AdNW",2,"DIEgO",3,"K.O,Y",4)
        if values.Has(CurrentVariant)
            IniWrite(values[CurrentVariant], IniPath, "Global", "isNordTast")
    }
    TrayTip("Auswahl gespeichert: " CurrentVariant, "Neo/Noted")
}

InstallTray() {
    SetTrayIcon(true)
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Kompakthilfe", ShowHelp)
    A_TrayMenu.Add("Pausieren (Strg+Ende)", TogglePause)
    A_TrayMenu.Add("Neu laden", (*) => Reload())
    A_TrayMenu.Add("Beenden", (*) => ExitApp())
    A_TrayMenu.Default := "Kompakthilfe"
}

SetTrayIcon(enabled) {
    TraySetIcon(A_ScriptDir "\neo_" (enabled ? "enabled" : "disabled") ".ico",, true)
}

ShowHelp(*) {
    global CurrentVariant
    MsgBox("Aktiv: " CurrentVariant "`n`nMod3: CapsLock + rechte Mod3-Taste`nMod4: ISO-Taste (<>) + Right Alt`n"
        . "Mod3+F7: Neo/Noted  |  Mod4+F7: speichern`nMod3+F6: QWERTZ`nMod3+F12: NordTast/AdNW/DIEgO/K.O,Y`n"
        . "Beide Shift: Shift-Lock  |  beide Mod4: Mod4-Lock", "Neo/Noted – Hilfe")
}

TogglePause(*) {
    global IsPaused
    IsPaused := !IsPaused
    ClearTrackedState()
    Suspend(IsPaused)
    SetTrayIcon(!IsPaused)
    if !IsPaused {
        SetCapsLockState("AlwaysOff")
        SyncPhysicalState()
    }
    ShowPauseOsd(!IsPaused)
}

ShowPauseOsd(enabled) {
    global PauseOsdGui, PauseOsdPicture, PauseOsdStart
    static iconSize := 128
    activeWindow := WinExist("A")
    if !PauseOsdGui {
        PauseOsdGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale")
        PauseOsdGui.MarginX := 0, PauseOsdGui.MarginY := 0
        PauseOsdGui.BackColor := "010203"
        PauseOsdPicture := PauseOsdGui.AddPicture("x0 y0 w" iconSize " h" iconSize)
    }
    SetTimer(AnimatePauseOsd, 0)
    PauseOsdPicture.Value := A_ScriptDir "\neo_" (enabled ? "enabled" : "disabled") ".ico"
    monitor := MonitorForWindow(activeWindow)
    x := monitor[1] + ((monitor[3] - monitor[1] - iconSize) // 2)
    y := monitor[2] + ((monitor[4] - monitor[2] - iconSize) // 2)
    PauseOsdStart := A_TickCount
    WinSetTransColor("010203 1", PauseOsdGui)
    PauseOsdGui.Show("NA x" x " y" y " w" iconSize " h" iconSize)
    SetTimer(AnimatePauseOsd, 16)
}

AnimatePauseOsd() {
    global PauseOsdGui, PauseOsdStart
    static duration := 2000, fade := 180
    elapsed := A_TickCount - PauseOsdStart
    if elapsed >= duration {
        SetTimer(AnimatePauseOsd, 0)
        PauseOsdGui.Hide()
        return
    }
    opacity := elapsed < fade ? Round(255 * elapsed / fade)
        : elapsed > duration - fade ? Round(255 * (duration - elapsed) / fade) : 255
    WinSetTransColor("010203 " Max(1, opacity), PauseOsdGui)
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

ClearTrackedState(*) {
    global ShiftLDown, ShiftRDown, Mod3LDown, Mod3RDown, Mod4LDown, Mod4RDown, ComposeBuffer, DualKeyRoles
    ShiftLDown := false, ShiftRDown := false, Mod3LDown := false, Mod3RDown := false
    Mod4LDown := false, Mod4RDown := false, ComposeBuffer := ""
    DualKeyRoles := Map()
}

SyncPhysicalState() {
    global ShiftLDown, ShiftRDown, Mod3LDown, Mod4LDown, Mod4RDown
    ShiftLDown := GetKeyState("LShift", "P"), ShiftRDown := GetKeyState("RShift", "P")
    Mod3LDown := GetKeyState("CapsLock", "P")
    Mod4LDown := GetKeyState("sc056", "P"), Mod4RDown := GetKeyState("RAlt", "P")
}

ReleaseAll(*) {
    ClearTrackedState()
}

RunSelfTest() {
    global NeoBase, ComposePrefixes, ComposeExact, Layout, CurrentVariant, DualKeyRoles
    failures := []
    Check(failures, NeoBase.Count >= 86, "Neo table/core keys incomplete")

    normalBits := "12123535444466664444353512126666"
    letterBits := "12213535444466664444353512216666"
    layer7Bits := "00000000010100000101000000000000"
    layer8Bits := "00000000000001010000000000000101"
    plainRow := [0,"1","2","3","4","5","6","",""], letterRow := [1,"1","2","3","4","5","6","",""]
    loop 32 {
        pos := A_Index - 1
        shift := pos & 1, shiftLock := (pos >> 1) & 1, mod3 := (pos >> 2) & 1
        mod4 := (pos >> 3) & 1, mod4Lock := (pos >> 4) & 1
        Check(failures, ResolveLayer(0, plainRow, shift, mod3, mod4, shiftLock, mod4Lock)
            = SubStr(normalBits, A_Index, 1) + 0, "normal level bit " A_Index)
        Check(failures, ResolveLayer(1, letterRow, shift, mod3, mod4, shiftLock, mod4Lock)
            = SubStr(letterBits, A_Index, 1) + 0, "caps level bit " A_Index)
        pseudoRow := [0,"1","2","3","4","5","6","seven","eight"]
        expected := SubStr(layer7Bits, A_Index, 1) = "1" ? 7
            : (SubStr(layer8Bits, A_Index, 1) = "1" ? 8 : SubStr(normalBits, A_Index, 1) + 0)
        Check(failures, ResolveLayer(0, pseudoRow, shift, mod3, mod4, shiftLock, mod4Lock) = expected,
            "pseudo level bit " A_Index)
    }
    fallback := [0,"1","2","3","four","5","six","",""]
    Check(failures, ResolveLayer(0, fallback, true, false, true, false, false) = 4, "pseudo-7 empty fallback")
    Check(failures, ResolveLayer(0, fallback, true, true, true, false, false) = 6, "pseudo-8 empty layer-6 fallback")
    Check(failures, ResolveValue(NeoBase["sc008"], true, true, true) = "→", "math layer-6 resolver")

    noted := CloneLayout(NeoBase), ApplyNoted(noted)
    Check(failures, noted["sc010"][2] = "z" && noted["sc010"][6] = "ζ", "Noted AD01 layers")
    Check(failures, noted["sc01B"][2] = "ß" && noted["sc01B"][3] = "ẞ", "Noted sharp-s")
    Check(failures, noted["sc02B"][2] = "T__acut" && noted["sc012"][6] = "", "dead/VoidSymbol")
    Check(failures, noted["sc027"][8] = "S__NDot" && noted["sc035"][8] = ",", "shifted layer 4")
    Check(failures, noted["sc013"][4] = NeoBase["sc013"][4], "NoSymbol inheritance")
    q := CloneLayout(NeoBase), ApplyLetterVariant(q, "QWERTZ")
    Check(failures, q["sc010"][2] = "q", "QWERTZ dispatch")
    Check(failures, ComposePrefixes.Has("S__Comp") && ComposeExact.Has("T__acutU000061"), "compose indexes")
    first := ComposeFeed("", "T__acut"), second := ComposeFeed(first[1], "U000061")
    Check(failures, first[1] = "T__acut" && second[2] = "U0000E1", "acute compose")
    Layout := noted, CurrentVariant := "Noted"
    DualKeyRoles := Map("sc028", DualRoleForVariant("sc028", CurrentVariant))
    SwitchVariant("Neo", false)
    Check(failures, CurrentVariant = "Neo" && Layout["sc010"][2] = "x", "mode transition")
    Check(failures, DualKeyRoles["sc028"] = "mod3R" && DualRoleForVariant("sc028", CurrentVariant) = "key",
        "held right Mod3 role cache")

    loop 12 {
        token := A_Index < 10 ? "S____F" A_Index : "S___F" A_Index
        spec := ActionSpec(token)
        Check(failures, spec[1] = "key" && spec[2] = "F" A_Index, "F-key action " A_Index)
    }
    for token in ["S__NHom","S__N_Up","S__NPUp","S__N_Le","S__NClr","S__N_Ri",
            "S__NEnd","S__N_Dn","S__NPDn","S__NIns","S__NDel"]
        Check(failures, ActionSpec(token)[1] = "key", "numpad navigation " token)
    for token in ["S_SNHom","S_SN_Up","S_SNPUp","S_SN_Le","S_SNClr","S_SN_Ri",
            "S_SNEnd","S_SN_Dn","S_SNPDn","S_SNIns","S_SNDel"]
        Check(failures, ActionSpec(token)[1] = "key" && ActionSpec(token)[3], "shift navigation " token)
    for key, row in NeoBase
        loop 8
            if SubStr(row[A_Index + 1], 1, 2) = "S_"
                Check(failures, ActionSpec(row[A_Index + 1])[1] != "none", "reachable action " row[A_Index + 1])
    Check(failures, ShortcutOutputSpec("c") = "{Blind}{c}"
        && ShortcutOutputSpec("c", true) = "{Blind}+{c}"
        && ShortcutOutputSpec("{") = "{Blind}{{}", "shifted shortcut spec/escaping/Blind modifiers")
    actionRow := [1,"c","C","S__Left","S__Back","",Chr(9),"S___Del",Chr(13)]
    Check(failures, ShortcutOutputSpec(ModifiedShortcutValue(actionRow, "S__Back")) = "{Blind}{Backspace}",
        "Ctrl+Backspace action shortcut spec")
    Check(failures, ShortcutOutputSpec(ModifiedShortcutValue(actionRow, "S___Del")) = "{Blind}{Delete}"
        && ShortcutOutputSpec(ModifiedShortcutValue(actionRow, Chr(9))) = "{Blind}{Tab}"
        && ShortcutOutputSpec(ModifiedShortcutValue(actionRow, Chr(13))) = "{Blind}{Enter}"
        && ShortcutOutputSpec(ModifiedShortcutValue(actionRow, "S__Left")) = "{Blind}{Left}",
        "modified delete/tab/enter/navigation action specs")
    Check(failures, ShortcutOutputSpec(Chr(8)) = "{Blind}{Backspace}"
        && ShortcutOutputSpec(Chr(10)) = "{Blind}{Enter}"
        && ShortcutOutputSpec(Chr(27)) = "{Blind}{Escape}", "native control action specs")
    Check(failures, ModifiedShortcutValue(actionRow, "C") = "c"
        && ShortcutOutputSpec(ModifiedShortcutValue(actionRow, "C")) = "{Blind}{c}",
        "Ctrl+C logical-letter shortcut unchanged")
    Check(failures, VariantFromPreferences("", "0", "0", "0") = "Noted"
        && VariantFromPreferences("invalid", "0", "0", "0") = "Noted", "no-preference Noted fallback")
    Check(failures, VariantFromPreferences("Neo", "1", "1", "4") = "Neo"
        && VariantFromPreferences("Noted", "0", "0", "0") = "Noted", "explicit Neo/Noted save-load")
    Check(failures, VariantFromPreferences("QWERTZ", "0", "0", "0") = "QWERTZ"
        && VariantFromPreferences("NordTast", "0", "0", "0") = "NordTast"
        && VariantFromPreferences("AdNW", "0", "0", "0") = "AdNW"
        && VariantFromPreferences("DIEgO", "0", "0", "0") = "DIEgO"
        && VariantFromPreferences("K.O,Y", "0", "0", "0") = "K.O,Y", "explicit other variants")
    Check(failures, VariantFromPreferences("", "0", "0", "1") = "NordTast"
        && VariantFromPreferences("", "0", "0", "2") = "AdNW"
        && VariantFromPreferences("", "0", "0", "3") = "DIEgO"
        && VariantFromPreferences("", "0", "0", "4") = "K.O,Y", "preference migration variants")
    Check(failures, VariantFromPreferences("", "1", "1", "4") = "Noted"
        && VariantFromPreferences("", "0", "1", "4") = "QWERTZ", "legacy preference precedence")
    if failures.Length {
        report := ""
        for failure in failures
            report .= "FAIL: " failure "`n"
        WriteSelfTestReport(report)
        ExitApp(1)
    }
    WriteSelfTestReport("PASS: 32 level states, pseudo fallback, layer 6, actions, shortcuts, variants, preferences and held-role transitions`n")
    ExitApp(0)
}

Check(failures, condition, message) {
    if !condition
        failures.Push(message)
}

WriteSelfTestReport(report) {
    output := A_ScriptDir "\neo20-self-test.txt"
    if FileExist(output)
        FileDelete(output)
    FileAppend(report, output, "UTF-8")
    FileAppend(report, "*")
}
