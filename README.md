# Noted für Windows (AutoHotkey v2)

Eine bewusst minimale, ausschließlich auf **Standard-Noted** festgelegte AutoHotkey-v2-Distribution. Es gibt keine Layoutauswahl, INI-Einstellungen, Bildschirmtastatur, EXE, gebündelte Runtime oder Build-Abhängigkeit.

## Start

AutoHotkey v2 installieren und `noted.ahk` starten. Erwartet wird das deutsche QWERTZ-Windows-Tastaturlayout.

- linkes Mod3: physische CapsLock-Taste
- rechtes Mod3: `Ä` (`SC028`)
- Mod4: ISO-`<>` und rechte Alt-Taste
- Akut-/Tilde-/Strich-Tottaste: `#` (`SC02B`)
- beide Shift-Tasten: Shift-Lock; beide Mod4-Tasten: Mod4-Lock
- `Strg+Ende`: pausieren/fortsetzen (auch während Suspend erreichbar)

CapsLock wird beim Start und Fortsetzen sicher ausgeschaltet. Physische Shift-Tasten bleiben für native Windows-Shortcuts durchgereicht; rechte Alt-Taste wird als Mod4/AltGr behandelt. Noted enthält alle sechs Ebenen, Compose/Tottasten, Navigation, Nummernblock, F-Tasten und native Shortcuts.

Die Statusanzeige läuft rund zwei Sekunden auf dem Monitor des aktiven Fensters. Sie stiehlt keinen Fokus, ist klickdurchlässig und animiert die native große Icon-Grafik mit federndem Wachstum, ruhigem Halten und sanftem Schrumpfen. Schnelle Umschaltungen verwenden dasselbe Fenster erneut.

## Dateien und Herkunft

- `noted.ahk`: AHK-v2-Laufzeit
- `data.ahk`: 91 vollständig aufgelöste Noted-Zeilen und die vollständigen 7.622 Compose-Ergebnisse; 1.644 Präfixe werden beim Start daraus gebildet
- `noted_enabled.ico`: unverändertes `res/neo_enabled.ico` aus [Rojetto/ReNeo](https://github.com/Rojetto/ReNeo), Commit `c0dda5a59bce714a09bc4e1f64268eaf9bd4f416`, Git-Blob `08bb171a81ca2680fd4b6554f05d0b704c1eb64c`
- `noted_disabled.ico`: daraus lokal abgeleitete, entsättigte und abgedunkelte OFF-Variante mit 16/24/32/48/64/128/256 px; kein angeblicher Upstream-Dateiname

Die Standard-Noted-Belegung folgt `dariogoetz/noted-layout` `xkb/noted` bei Commit `20f43c1a27736a5f894f6fe32620d41e629a5aab`; die gepinnte Fixture liegt unter `tests/fixtures/noted.xkb`. `NoSymbol`-Werte sind in `BuildNotedData` bereits konkret aus der bisherigen Neo-Basis aufgelöst, `VoidSymbol` bleibt leer. Git-Historie enthält die entfernten Legacy-/Generatorquellen.

## Prüfung

```sh
python3 -m unittest tests.test_noted_layout -v
```

Unter Windows beziehungsweise der isolierten Testumgebung:

```text
AutoHotkey64.exe noted.ahk --self-test
AutoHotkey64.exe noted.ahk --smoke-test
AutoHotkey64.exe tests\verify_osd.ahk
```

`--self-test` beendet sich vor CapsLock-Änderung, Hotkeys, Tray und OSD. Die statischen Entwicklungstests brauchen nur Python aus der Entwicklungsumgebung; Endnutzer benötigen es nicht.

GPL-3.0; siehe `LICENSE`.
