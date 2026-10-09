# noted-layout-windows-ahk

Fork von [kingdase/neo2-layout-windows-ahk](https://github.com/kingdase/neo2-layout-windows-ahk) mit **Noted** als zusätzlicher, separat wählbarer AHK-Belegungsvariante. Neo bleibt Standard; QWERTZ, NordTast, AdNW, DIEgO und K.O,Y bleiben erhalten.

**Nur die Haupt- und Shift-Ebene ändern sich.** Mod3, Mod4, Mod5, Mod6, die zugehörigen Sonderzeichen und die Neo-Modifikatortasten bleiben auf ihren bisherigen physischen Positionen. Die Buchstabenpositionen folgen [Noted](https://github.com/dariogoetz/noted-layout) (`xkb/noted`, Revision `20f43c1a27736a5f894f6fe32620d41e629a5aab`). Da die rechte Mod3-Taste und die Akzenttaste bei Neo bleiben, liegt `ß` in dieser angepassten Variante auf der früheren Neo-`y`-Taste; das ist **nicht** die vollständige Noted-XKB-Belegung.

## Nutzung

Das Repository und die bereitgestellte ZIP enthalten nur AHK-v1-Skripte und deren Ressourcen – **keine EXE, keinen CMD-Starter und keinen Interpreter**. `neo-ahk/neo20-all.ahk` mit einem auf dem Windows-Rechner bereits vorhandenen **AutoHotkey v1.1 (Unicode)** ausführen. Alle Dateien im Ordner `neo-ahk/` zusammenhalten. Das Windows-Eingabelayout muss Deutsch (QWERTZ) sein. Ohne vorhandenen AHK-Interpreter kann Windows eine `.ahk`-Datei nicht selbst ausführen.

- `Mod3+F7`: zwischen Neo und Noted wechseln.
- `Mod4+F7`: die aktuelle Noted-Auswahl in `%APPDATA%\Neo2\Neo2.ini` speichern.
- Wie bisher: `Mod3+F6` für QWERTZ, `Mod3+F12` für NordTast/AdNW/DIEgO/K.O,Y.

Gespeicherte Varianten bleiben nach dem Neustart aktiv; ohne gespeicherte Variante startet Neo. Nur eine Instanz des Neo-Skripts gleichzeitig ausführen.

## Prüfung und Herkunft

```sh
python3 -m unittest discover -s tests -v
```

Die Tests prüfen die Noted-Buchstabenpositionen und dass der neue Layoutwechsel ausschließlich die ersten beiden Neo-Ebenen ändert. Die tatsächliche Tastatureingabe wurde mangels Windows-Gerät nicht praktisch getestet. Der Originalcode stammt aus [neo-layout/windows/neo-vars](https://github.com/neo-layout/neo-layout/tree/master/windows/neo-vars). Original und Noted-Quelltext stehen unter GPL-3.0; siehe `LICENSE`.
