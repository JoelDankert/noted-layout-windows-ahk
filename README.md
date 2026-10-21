# noted-layout-windows-ahk

Fork von [kingdase/neo2-layout-windows-ahk](https://github.com/kingdase/neo2-layout-windows-ahk) mit **vollständigem Standard-Noted** als zusätzlicher, separat wählbarer AHK-Belegung. Neo bleibt Standard; QWERTZ, NordTast, AdNW, DIEgO und K.O,Y bleiben erhalten.

Die sechs semantischen Noted-Ebenen entsprechen [dariogoetz/noted-layout](https://github.com/dariogoetz/noted-layout) aus `xkb/noted` in Revision `20f43c1a27736a5f894f6fe32620d41e629a5aab`. Das umfasst die griechischen und mathematischen Ebenen, Satzzeichen, `ß`/`ẞ`, tote Tasten sowie geerbte Neo-Funktionen. Es handelt sich um Standard-Noted, **nicht** um die Angle-Mod-Variante.

Standard-Noted verändert gegenüber Neo auch drei physische Positionen:

- rechte Mod3-Taste: `AC11`, deutsche `Ä`-Taste, `SC028`
- `ß`/`ẞ`: `AD12`, deutsche Akut-Taste, `SC01B`
- tote Akut-/Tilde-/Strich-Tastenfamilie: `AC12`, deutsche `#`-Taste, `SC02B`

Die linke Mod3-Taste bleibt Feststelltaste. Shift bleibt unverändert; ISO-Taste und AltGr bleiben Mod4. Die bestehende Mod4-Feststellung bleibt erhalten.

## Nutzung

Das Repository enthält nur AHK-v1-Skripte und Ressourcen – **keine EXE, keinen CMD-Starter und keinen Interpreter**. `neo-ahk/neo20-all.ahk` mit einem auf dem Windows-Rechner bereits vorhandenen **AutoHotkey v1.1 (Unicode)** ausführen. Alle Dateien im Ordner `neo-ahk/` zusammenhalten. Das Windows-Eingabelayout muss Deutsch (QWERTZ) sein. Ohne vorhandenen AHK-Interpreter kann Windows eine `.ahk`-Datei nicht selbst ausführen.

- `Mod3+F7`: zwischen Neo und Noted wechseln.
- `Mod4+F7`: die aktuelle Noted-Auswahl in `%APPDATA%\Neo2\Neo2.ini` speichern.
- Wie bisher: `Mod3+F6` für QWERTZ, `Mod3+F12` für NordTast/AdNW/DIEgO/K.O,Y.

Gespeichertes Noted wird beim nächsten Start vollständig einschließlich der geänderten Mod3- und Totzeichenpositionen installiert. Beim Wechsel zu einer anderen Variante werden die Noted-spezifischen Tasten und Ebenen wiederhergestellt. Ohne gespeicherte Variante startet Neo. Nur eine Instanz des Neo-Skripts gleichzeitig ausführen.

## Prüfung und Herkunft

```sh
python3 -m unittest tests.test_noted_layout -v
```

Der fokussierte statische Test gleicht die deklarativen Noted-Zuordnungen mit der angehefteten offiziellen XKB-Referenz ab und prüft Umschalt-/Persistenzpfade sowie die skriptbasierte Distribution. Mangels Windows-/AHK-v1-Laufzeitumgebung wurde die tatsächliche Tastatureingabe nicht praktisch geprüft.

Der Originalcode stammt aus [neo-layout/windows/neo-vars](https://github.com/neo-layout/neo-layout/tree/master/windows/neo-vars). Original und Noted-Quelltext stehen unter GPL-3.0; siehe `LICENSE`.
