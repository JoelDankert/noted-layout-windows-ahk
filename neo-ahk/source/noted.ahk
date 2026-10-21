; -*- encoding:utf-8 -*-
; Full standard Noted layout.
; Source: dariogoetz/noted-layout, xkb/noted at
; 20f43c1a27736a5f894f6fe32620d41e629a5aab.
;
; XKB's eight slots are not Neo's semantic layer order.  The calls below use
; AHK order: layer 1, 2, 3, 4, 5, 6, shifted layer 4, shifted layer 6.
; "=" means XKB NoSymbol (inherit de(neo_base)); "" is VoidSymbol.

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

NotedSaveKey(sc) {
  global
  pos := vksc%sc%
  if (NotedSaved.HasKey(pos))
    return
  saved := {}
  Loop,8
    saved[A_Index] := CP%A_Index%%pos%
  saved["NOC"] := NOC%pos%
  NotedSaved[pos] := saved
}

; Install one resolved Noted key.  Values arrive in AHK semantic order.
NotedKey(sc,caps,e1,e2,e3,e4,e5,e6,e7="=",e8="=") {
  global
  NotedSaveKey(sc)
  pos := vksc%sc%
  Loop,8 {
    value := e%A_Index%
    if (value == "=")
      e%A_Index% := CP%A_Index%%pos%
  }
  EDS(sc,caps,e1,e2,e3,e4,e5,e6,e7,e8)
}

CharProcNoted1() {
  global
  ; Always inherit from Neo, never from the previously selected variant.
  Change1256LayoutNeo20()
  NotedSaved := {}

  ; AD row.  AD11/AD12 are SC01A/SC01B on German QWERTZ hardware.
  NotedKey("010",1,"z","Z","=","=","ζ","ℤ","=","=")
  NotedKey("011",1,"y","Y","=","=","υ","ℵ","=","=")
  NotedKey("012",1,"u","U","=","=","","×","=","=")
  NotedKey("013",1,"a","A","=","=","α","∀","=","=")
  NotedKey("014",1,"q","Q","=","=","ϕ","ℚ","=","=")
  NotedKey("015",1,"p","P","=","=","π","Π","=","=")
  NotedKey("016",1,"b","B","=","=","β","∂","=","=")
  NotedKey("017",1,"m","M","=","=","μ","↦","=","=")
  NotedKey("018",1,"l","L","=","=","λ","Λ","=","=")
  NotedKey("019",1,"f","F","=","=","φ","Φ","=","=")
  NotedKey("01A",1,"j","J","@","−","θ","Θ","=","=")
  NotedKey("01B",1,"ß","ẞ","ſ",";","ς","∘","=","=")

  ; AC row.  Standard Noted uses AC11 (SC028) as right Mod3.
  NotedKey("01E",1,"c","C","=","=","χ","ℂ","=","=")
  NotedKey("01F",1,"s","S","=","=","σ","Σ","=","=")
  NotedKey("020",1,"i","I","=","=","ι","∫","=","=")
  NotedKey("021",1,"e","E","=","=","ε","∃","=","=")
  NotedKey("022",1,"o","O","=","=","ο","∈","=","=")
  NotedKey("023",1,"d","D","=","=","δ","Δ","=","=")
  NotedKey("024",1,"t","T","=","=","τ","∇","=","=")
  NotedKey("025",1,"n","N","=","=","ν","ℕ","=","=")
  NotedKey("026",1,"r","R","=","=","ρ","ℝ","=","=")
  NotedKey("027",1,"h","H","=",".","ψ","Ψ","S__NDot","=")
  NotedSaveKey("028")
  ED1S("028","P__M3RD")

  ; AC12 (SC02B) takes Neo AD12's complete dead-key family.
  NotedKey("02B",0,"T__acut","T__tlde","T__strk","T__dbac","T_psili","T__brve","","=")

  ; AB row.
  NotedKey("02C",1,"v","V","=","=","","√","=","=")
  NotedKey("02D",1,"x","X","=","=","ξ","Ξ","=","=")
  NotedKey("02E",1,"ü","Ü","=","=","","∪","=","=")
  NotedKey("02F",1,"ä","Ä","=","=","η","∩","=","=")
  NotedKey("030",1,"ö","Ö","=","=","ϵ","⊂","=","=")
  NotedKey("031",1,"w","W","=","=","ω","Ω","=","=")
  NotedKey("032",1,"g","G","=","=","γ","Γ","=","=")
  NotedKey("033",0,",","–","=","=","ϱ","⇐","=","=")
  NotedKey("034",0,".","•","=","=","ϑ","⇔","=","=")
  NotedKey("035",1,"k","K","=","S__NDot","κ","⇒",",","=")
  isNotedActive := 1
  Check_BSTUpdate(1)
}

RestoreNotedKeys() {
  global
  if (!isNotedActive) {
    isNoted := 0
    return
  }
  for pos,saved in NotedSaved {
    Loop,8
      SetKeyPos("CP" . A_Index . pos,saved[A_Index])
    NOC%pos% := saved["NOC"]
  }
  NotedSaved := {}
  isNotedActive := 0
  isNoted := 0
  Check_BSTUpdate(1)
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
