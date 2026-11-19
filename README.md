# Noted für Windows (AutoHotkey v2)

Eine bewusst minimale AutoHotkey-v2-Distribution für **Noted** und **NeoQwertz**. Es gibt keine Bildschirmtastatur, EXE, gebündelte Runtime oder Build-Abhängigkeit.

## Start

AutoHotkey v2 installieren und `noted.ahk` starten. Erwartet wird das deutsche QWERTZ-Windows-Tastaturlayout.

Die Zeichenausgabe verwendet nach Möglichkeit native Tastendrücke und fällt für nicht verfügbare Zeichen automatisch auf Unicode zurück.

- linkes Mod3: physische CapsLock-Taste
- rechtes Mod3: bei Noted `Ä` (`SC028`), bei NeoQwertz `#` (`SC02B`)
- Mod4: ISO-`<>` und rechte Alt-Taste
- Akut-/Tilde-/Strich-Tottaste: bei Noted `#` (`SC02B`), bei NeoQwertz `+` (`SC01B`)
- beide Shift-Tasten: Shift-Lock; beide Mod4-Tasten: Mod4-Lock
- `Strg+Ende`: pausieren/fortsetzen (auch während Suspend erreichbar)

Das Traymenü wählt Noted oder NeoQwertz und markiert die aktuelle Auswahl. Ein Doppelklick auf das Tray-Icon pausiert beziehungsweise setzt fort, genau wie `Strg+Ende`; ein einzelner Klick behält das normale Tray-Verhalten. Ein Wechsel aktiviert die neue Belegung sofort, auch aus dem pausierten Zustand; `Strg+Ende` pausiert beziehungsweise aktiviert danach diese Auswahl. Sie wird unter `%APPDATA%\NotedLayoutWindowsAhk\settings.ini` gespeichert, bei fehlender oder ungültiger Datei gilt Noted. In NeoQwertz schreibt die Ä-Taste normal `ä`/`Ä`.

Eine zweite Instanz – auch aus einem anderen Verzeichnis – zeigt `Noted läuft bereits.` und beendet sich, ohne die laufende Belegung oder CapsLock anzufassen. „Neu laden“ im Tray bleibt möglich.

Solange Noted aktiv ist, bleibt CapsLock ausgeschaltet und die physische Taste arbeitet ausschließlich als Mod3. Auch ein von einem anderen Programm eingeschalteter CapsLock-Zustand wird dabei zurückgesetzt. Beim Pausieren wird CapsLock einmal ausgeschaltet und die Erzwingung vollständig freigegeben, sodass die Taste bis zum Fortsetzen wieder normal ein- und ausgeschaltet werden kann. Beenden und Neuladen hinterlassen CapsLock ausgeschaltet, aber nicht erzwungen. Shift-Lock bleibt davon unabhängig. Physische Shift-Tasten bleiben für native Windows-Shortcuts durchgereicht; rechte Alt-Taste wird als Mod4/AltGr behandelt. Noted enthält alle sechs Ebenen, Compose/Tottasten, Navigation, Nummernblock, F-Tasten und native Shortcuts.

Die Statusanzeige läuft rund zwei Sekunden auf dem Monitor des aktiven Fensters. Sie stiehlt keinen Fokus, ist klickdurchlässig und animiert die native große Icon-Grafik mit federndem Wachstum, ruhigem Halten und sanftem Schrumpfen. Vollständige Bilder werden in einem wiederverwendeten 32-Bit-Puffer vorbereitet und mit `UpdateLayeredWindow` zusammen mit Position und Größe atomar ausgegeben, ohne sichtbares Leerzeichnen oder separate Resize-/Paint-Schritte. Schnelle Umschaltungen verwenden dasselbe Fenster und die aktuelle Größe weiter; erst der letzte Wechsel bestimmt die verbleibenden zwei Sekunden. Gedrückthalten von `Strg+Ende` schaltet nur einmal bis zum Loslassen von Ende. Zusätzliche Modifikatoren wie `Strg+Shift+Ende` und die normale Ende-Taste werden nicht als Pause-Kürzel behandelt; Ende funktioniert auch bei pausierter Belegung. Beide Icons und die GDI-Ressourcen werden wiederverwendet und beim Beenden freigegeben.

## Credits

Historischer Ausgangspunkt dieses Projekts war [kingdase/neo2-layout-windows-ahk](https://github.com/kingdase/neo2-layout-windows-ahk). Danke an kingdase und die ursprünglichen Neo-Entwickler für diese Vorarbeit.

Der heutige Treiber wird als eigenständige AutoHotkey-v2-Implementierung für Noted und NeoQwertz weiterentwickelt. Belegungsdaten und Icons sind oben unter „Dateien und Herkunft“ gesondert zugeordnet. Die Herkunft und die GPL-3.0-Lizenzierung bleiben erhalten.

## Dateien und Herkunft

- `noted.ahk`: AHK-v2-Laufzeit
- `data.ahk`: 91 vollständig aufgelöste Noted-Zeilen, kleine NeoQwertz-Overrides und die vollständigen 7.622 Compose-Ergebnisse; 1.644 Präfixe werden beim Start daraus gebildet
- `noted_enabled.ico`: unverändertes `res/neo_enabled.ico` aus [Rojetto/ReNeo](https://github.com/Rojetto/ReNeo), Commit `c0dda5a59bce714a09bc4e1f64268eaf9bd4f416`, Git-Blob `08bb171a81ca2680fd4b6554f05d0b704c1eb64c`
- `noted_disabled.ico`: daraus lokal abgeleitete, entsättigte und abgedunkelte OFF-Variante mit 16/24/32/48/64/128/256 px; kein angeblicher Upstream-Dateiname

Die Standard-Noted-Belegung folgt `dariogoetz/noted-layout` `xkb/noted` bei Commit `20f43c1a27736a5f894f6fe32620d41e629a5aab`; die gepinnte Fixture liegt unter `tests/fixtures/noted.xkb`. `NoSymbol`-Werte sind in `BuildNotedData` bereits konkret aus der bisherigen Neo-Basis aufgelöst, `VoidSymbol` bleibt leer. Git-Historie enthält die entfernten Legacy-/Generatorquellen.

NeoQwertz folgt der [offiziellen Beschreibung](https://neo-layout.org/Layouts/neoqwertz/) und den installierten, maßgeblichen XKB-Blöcken `de(neo_base)`/`de(neo_qwertz_base)` aus `xkb-data` 2.42-1 (`/usr/share/X11/xkb/symbols/de`, SHA-256 `4e5710a31d27b40dc056e71d274531a57d3eea672e28be83f163fdfc9e2200bf`). Daher bleiben die Neo-Ebenen 3/4 an ihren physischen Positionen; griechische und mathematische Ebenen folgen den QWERTZ-Buchstaben.

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

Der Laufzeittest prüft zusätzlich den echten CapsLock-Togglezustand: normales Ein/Aus im pausierten Zustand, Ausschalten beim Fortsetzen, Korrektur eines extern eingeschalteten Zustands, wiederholte Umschaltungen sowie Freigabe nach der Bereinigung. Unter Wine kann die Weitergabe injizierter Lock-Tasten vom Host/Compositor eingeschränkt sein; in diesem Fall ist das eine Einschränkung der Testumgebung und kein bestandener Test.

`--self-test` beendet sich vor CapsLock-Änderung, Hotkeys, Tray und OSD. Die statischen Entwicklungstests brauchen nur Python aus der Entwicklungsumgebung; Endnutzer benötigen es nicht.

GPL-3.0; siehe `LICENSE`.
