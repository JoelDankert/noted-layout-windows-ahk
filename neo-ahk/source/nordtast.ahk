; -*- encoding:utf-8 -*-
; NordTast. Belegung von Ulf Bro, http://www.nordtast.org/
; Aus der Neo-Welt (AdNW) von Andreas Wettstein, http://wettstae.home.solnet.ch/
; (c) 2010 Matthias Wächter

CharProcNordTt() {
  global
  ; Custom Layout togglen
  if (isNordTast == 0) {
    isNordTast := 1
    CharProcNordT1()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Die Belegungsvariante NT wurde aktiviert. Zum Umschalten`, Mod3+F12 drücken.,10,1
  } else if (isNordTast == 1) {
    isNordTast := 2
    CharProcNordT2()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Die Belegungsvariante AdNW wurde aktiviert. Zum Umschalten`, Mod3+F12 drücken.,10,1
  } else if (isNordTast == 2) {
    isNordTast := 3
    CharProcNordT3()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Die Belegungsvariante DIEgO wurde aktiviert. Zum Umschalten`, Mod3+F12 drücken.,10,1
  } else if (isNordTast == 3) {
    isNordTast := 4
    CharProcNordT4()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Die Belegungsvariante K.O`,Y wurde aktiviert. Zum Umschalten`, Mod3+F12 drücken.,10,1
  } else if (isNordTast == 4) {
    isNordTast := 5
    CharProcNordT5()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Noted wurde aktiviert. Zum Umschalten`, Mod3+F12 drücken.,10,1
  } else {
    isNordTast := 0
    CharProcNordT0()
    if (zeigeModusBox)
      TrayTip,NordTast-Belegungsvariante,Die Belegungsvariante wurde deaktiviert.,10,1
  }
}

CharProcNordT1() {
  RestoreNotedKeys()
  ; Tastaturbelegungsvariante NordTast aktivieren
  Change1256Layout("-äuobpkglmfxaietchdnrsß.,üöqyzwvj")
}

CharProcNordT2() {
  RestoreNotedKeys()
  ; Tastaturbelegungsvariante Aus der Neo-Welt (AdNW) aktivieren
  Change1256Layout("-kuü.ävgcljfhieaodtrnsßxyö,qbpwmz")
}

CharProcNordT3() {
  RestoreNotedKeys()
  ; Tastaturbelegungsvariante DIEgO aktivieren
  Change1256Layout("-puü.äjclhxzdieaogtrnsßkyö,qmvwbf")
}

CharProcNordT4() {
  RestoreNotedKeys()
  ; Tastaturbelegungsvariante K.O,Y aktivieren
  Change1256Layout("-k.o,yvgclßzhaeiudtrnsfxqäüöbpwmj")
}

; Noted: https://github.com/dariogoetz/noted-layout/blob/20f43c1a27736a5f894f6fe32620d41e629a5aab/xkb/noted
; Die 33er-Tabelle hat fuer AC11 ein Platzhalter-ß. In Noted ist AC11 Mod3,
; ß liegt auf AD12 und die Akzenttaste auf AC12. Ebene 3/4 bleiben sonst
; positionsgebunden, waehrend griechische/mathematische Zeichen den Buchstaben folgen.
CharProcNordT5() {
  global
  Change1256Layout("-zyuaqpbmlfjcsieodtnrhßvxüäöwg,.k")
  EDS("01A",1,"j","J","@","−","θ","Θ")
  EDS("01B",1,"ß","ẞ","ſ",";","ς","∘")
  EDS("027",1,"h","H",":",".","ψ","Ψ")
  EDS("035",1,"k","K",";","S__NDot","κ","⇒")
  EDS("02B",0,"T__acut","T__tlde","T__strk","T__dbac","T_psili","T__brve")
  ED1S("028","P__M3RD")
  isNotedActive := 1
}

RestoreNotedKeys() {
  global
  if (!isNotedActive)
    return
  ; Der generische Layoutwechsel setzt nur 1/2/5/6 zurueck.
  ; Auch die verlegten Mod3-, Akzent- und Sonder-Ebenen zuruecksetzen.
  Change1256LayoutNeo20()
  EDS("01A",1,"ß","ẞ","ſ","−","ς","∘")
  EDS("01B",0,"T__acut","T__tlde","T__strk","T__dbac","T_psili","T__brve")
  EDS("027",1,"d","D",":","S__NDot","δ","Δ")
  EDS("028",1,"y","Y","@",".","υ","∇")
  EDS("035",1,"j","J",";",";","θ","Θ")
  ED1S("02B","P__M3RD")
  isNotedActive := 0
}

CharProcNordT0() {
  RestoreNotedKeys()
  ; Tastaturbelegungsvariante deaktivieren
  Change1256LayoutNeo20()
}

CharProcNordTs() {
  global

  if (isNordTast == 0)
    IniDelete,%ini%,Global,isNordTast
  else
    IniWrite,%isNordTast%,%ini%,Global,isNordTast

  if ErrorLevel
    TrayTip,NordTast-Belegungsvariante,Beim Speichern der Variante ist ein Fehler aufgetreten.,10,1    
  else if (zeigeModusBox)
    TrayTip,NordTast-Belegungsvariante,Variante gespeichert.,10,1    
}

ActivateNordTast() {
  global

  CP3F12  := "PNordTt"                   ; M3+F12: Aktiviere/Deaktiviere NordTast
  CP4F12  := "PNordTs"                   ; M4+F12: Speichere NordTast

  IniRead,isNordTast,%ini%,Global,isNordTast,0
  ; Einmalig fuer den portablen Noted-Starter; gespeicherte Auswahl bleibt erhalten.
  if (A_Args.Length() > 0 && A_Args[1] == "noted")
    isNordTast := 5
  if (isNordTast == 1)
    CharProcNordT1()
  else if (isNordTast == 2)
    CharProcNordT2()
  else if (isNordTast == 3)
    CharProcNordT3()
  else if (isNordTast == 4)
    CharProcNordT4()
  else if (isNordTast == 5)
    CharProcNordT5()
}

ActivateNordTast()
