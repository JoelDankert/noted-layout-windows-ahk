# noted-layout-windows-ahk

Fork von [kingdase/neo2-layout-windows-ahk](https://github.com/kingdase/neo2-layout-windows-ahk) mit zusätzlicher [Noted](https://github.com/dariogoetz/noted-layout)-Variante. Die vorhandenen Varianten Neo, NordTast, AdNW, DIEgO und K.O,Y bleiben erhalten. Die Noted-Zeichenbelegung folgt `dariogoetz/noted-layout` (`xkb/noted`, Revision `20f43c1a27736a5f894f6fe32620d41e629a5aab`); rechte Mod3-, ß- und Akzenttaste sind entsprechend mitverschoben. Die bestehende AHK-/Neo-Compose-Engine und ihre Sonderfunktionen bleiben erhalten. Daher ist die Windows-AHK-Implementierung keine vollständige XKB-Installation.

## Ohne Installation unter Windows

Die **bereitgestellte ZIP** vollständig entpacken und `portable\start-noted.cmd` doppelklicken. Sie verwendet, wenn vorhanden, die enthaltene `neo20-noted.exe`; sonst den offiziell veröffentlichten portablen **AutoHotkey v1.1.37.02**-Interpreter unter `runtime\AutoHotkeyU64.exe` zusammen mit `neo-ahk\neo20-all.ahk`. AutoHotkey muss nicht installiert werden. Der portable Start wählt Noted für diesen Lauf, ohne die gespeicherte Layoutwahl zu überschreiben. Das Windows-Eingabelayout muss dabei **Deutsch (QWERTZ)** sein. Nur eine Instanz eines Neo-/Noted-Tastaturtools gleichzeitig laufen lassen.

`Mod3+F12` schaltet Neo → NordTast → AdNW → DIEgO → K.O,Y → Noted → Neo. `Mod4+F12` speichert die aktuelle Variante in `%APPDATA%\Neo2\Neo2.ini`. Zum Umschalten **aus Noted** vorsichtshalber die linke Mod3-Taste (CapsLock) verwenden, bis das Verhalten der verschobenen rechten Mod3-Taste auf Windows getestet ist. Der portable Starter startet unabhängig von dieser gespeicherten Wahl jedes Mal mit Noted; für die gespeicherte Wahl `neo-ahk\neo20-all.ahk` mit AutoHotkey v1 ohne Argument starten. Zum Beenden das Taskleistensymbol von AutoHotkey verwenden.

Der Quellcode kann auf Windows auch mit dem GitHub-Actions-Workflow `.github/workflows/build-windows.yml` ohne Installation zu einer EXE gebaut werden. Die ZIP bringt den portablen Interpreter als Rückfalloption mit. Die AHK-Tastenereignisse selbst wurden nicht auf Windows getestet; die Linux-Tests prüfen die Noted-Tasten anhand des offiziellen XKB-Quelltexts (`python3 -m unittest discover -s tests -v`). Original- und Noted-Quellen stehen unter GPL-3.0; der mitgelieferte AutoHotkey-Lizenztext liegt unter `runtime\license.txt`.

## Hinweise zum Originalprojekt

Dies ist ein Extrakt von github.com/neo-layout/neo-layout/tree/master/windows/neo-vars

Worum geht es hier:

- [x] Neubau von neo20.exe mit einem aktuellen Autohotkey Compiler
- [x] "Einbrennen" des Bildschirm-Tastatur Fonts
- [x] Hilfe mit sinnvollen Informationen
- [x] Font von GitHub nehmen
- [x] Rechte Strg-Taste als zusätzlichen Mod4 Umschalter aktivieren
- [x] Bildschirmtastatur - Fix fuer Skalierung ; Ticket #390 und #530
- [x] Fix für Citrix-Problem
- [ ] Neo20.exe als Release bereitstellen

## VKDCSC029 Problem

Die Fehlermeldung "VKDCSC029" kommt daher, das das HotKey Kommando nur noch VK (ohne SC) akzeptiert.

Fix fuer VKDCSC029 Problem in keydefinitions.ahk vorgenommen.

neo20-all.ahk laesst sich jetzt mit aktuellem AHK 1.1.32 als Script oder kompiliert nutzen.

## Wie nutzen

Repository clonen oder als ZIP herunterladen und entpacken.

Autohotkey installieren - 32/64 bit scheint momentan keinen Unterschied zu machen.

Im Windows File-Explorer das Kontextmenü zu neo20-all.ahk öffnen.

- Run Script
- Compile

Fehlen die Einträge im Kontextmenü wurde Authotkey nicht richtig installiert.

Mit Compile kann man eine neo20-all.exe erstellen. Dieser Exe fehlt dann allerdings gegenüber der Version 
von neo-layout.org das eingebrannte Icon.

Dies kann über die Kommandozeile gemacht werden:

    "c:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in neo20-all.ahk /out neo20.exe /icon neo_enabled.ico

Pfad zur Ahk2Exe.exe kann abweichen. Bei der Choco Installation sollte er stimmen.

## neo2.ini

    [Global]
    isQwertz=1
    RControlAsM4=0
    NeoDebug=0
    fixCitrix=1
    

Die initalize.ahk kennt drei neue Optionen in neo2.ini.

- RControlAsM4 damit kann die rechte Ctrl Taste als zusätzlicher M4 Umschalter genutzt werden
- NeoDebug     sendet Debug Ausgaben an DebugView
- fixCitrix    siehe Citrix Altgr Problem

Jeweils mit 0/1 ein- und abschaltbar

## Citrix AltGr Problem

Bei Eingabe von AltGr+v werden auf einem lokalen Windows folgende Tastatur-Events generiert:

    A2  01D	 	d	LControl
    A5  138	 	d	RAlt
    56  02F	 	d	v
    56  02F	 	u	v
    A2  01D	 	u	LControl
    A5  138	 	u	RAlt

In einer entfernten Citrix Session werden folgende Tastatur-Events genereriert:

    A2  01D	 	d	LControl
    A5  138	 	d	RAlt
    56  02F	 	d	v
    56  02F	 	u	v
    A2  01D	 	u	LControl
    A2  01D	 	u	LControl
    A5  138	 	u	RAlt

Es wird ein zusätzliches LControl up generiert.

https://kb.vmware.com/s/article/1022454

Die AHK Neo Scripte sind für Control transparent, d.h. die Events werden gar nicht mittels Hotkey Definition(en) verarbeitet.

Der Fix macht zwei Sachen:

- bei M4R Down wird ein Ctrl Up gesendet.
- LControl Up (zwei Events) werden im Modus M4 unterdrückt

## Authotkey installieren

Am einfachsten, wenn man https://chocolatey.org nutzt:

    choco install autohotkey -y

## Debugging

Um zu sehen, was in den AHK Scripten passiert, könnte man MsgBox nutzen.
Das ist zum Debuggen eines Tastatur-Treibers aber nicht wirklich komfortabel.

Besser ist die Nutzung der OutPutDebug Funktion von AHK.

Die Nachrichten können dann mit DebugView von Sysinternals angezeigt werden.

DebugView kann zb. von Microsoft, für die PorableApps Platform oder auch über Chocolatey bezogen werden:

    choco install dbgview -y

Für Mapping-Probleme bietet sich eine Modifikation der varsfunctions.ahk an.

Nutzt man die Neo2 Scripte mittels direkter Ausführung über "Run Script",
gelangt man über das Kontextmenü des AHK Interpreters ( in der Taskleiste ggf. versteckt) zu dem Punkt "Öffnen".
Im AHK Fenster kann man sich unter "View -> Key history and script info" die von AHK erkannten Tasten-Events anzeigen lassen.
