; -*- encoding:utf-8 -*-
; Noted letter layout adapted to the original Neo modifier and higher layers.
; Position source: https://github.com/dariogoetz/noted-layout/blob/20f43c1a27736a5f894f6fe32620d41e629a5aab/xkb/noted
; Only AHK layers 1+2 change. Neo's right Mod3, dead key and layers 3-6 stay put.
; ß uses former Neo-y key (SC028) because official Noted uses it as Mod3,
; but moving modifiers would violate the two-layer-only requirement.

CharProcNotedT() {
  global
  if (!isNoted) {
    if (isQwertz || isNordTast)
      Change1256LayoutNeo20()
    isNoted := 1
    isQwertz := 0
    isNordTast := 0
    CharProcNoted1()
    if (zeigeModusBox)
      TrayTip,Noted-Belegungsvariante,Noted wurde aktiviert. Zum Deaktivieren`, Mod3+F7 drücken.,10,1
  } else {
    RestoreNotedKeys()
    if (zeigeModusBox)
      TrayTip,Noted-Belegungsvariante,Noted wurde deaktiviert.,10,1
  }
}

CharProcNoted1() {
  global
  Change12Layout("-zyuaqpbmlfjcsieodtnrhßvxüäöwg,.k")
  isNotedActive := 1
}

RestoreNotedKeys() {
  global
  if (!isNotedActive)
    return
  Change12Layout(neo20layoutstring)
  isNotedActive := 0
  isNoted := 0
}

CharProcNoteds() {
  global
  if (isNoted) {
    IniWrite,1,%ini%,Global,isNoted
    if (!ErrorLevel) {
      IniDelete,%ini%,Global,isQwertz
      IniDelete,%ini%,Global,isNordTast
    }
  } else
    IniDelete,%ini%,Global,isNoted
  if ErrorLevel
    TrayTip,Noted-Belegungsvariante,Beim Speichern der Variante ist ein Fehler aufgetreten.,10,1
  else if (zeigeModusBox)
    TrayTip,Noted-Belegungsvariante,Variante gespeichert.,10,1
}

ActivateNoted() {
  global
  CP3F7 := "PNotedT"              ; M3+F7: Noted / Neo
  CP4F7 := "PNoteds"              ; M4+F7: Variante speichern
  IniRead,isNoted,%ini%,Global,isNoted,0
  if (isNoted == 1) {
    if (isQwertz || isNordTast)
      Change1256LayoutNeo20()
    isQwertz := 0
    isNordTast := 0
    CharProcNoted1()
  }
}

ActivateNoted()
