# noted-layout-windows-ahk

Native **AutoHotkey v2** implementation of Neo 2 and standard Noted for Windows. Full standard Noted is the default when no layout preference has been saved; explicitly saved Neo and other variants remain selected on later starts. The standard Noted data follows `dariogoetz/noted-layout`’s `xkb/noted` at commit `20f43c1a27736a5f894f6fe32620d41e629a5aab` (fixture: `tests/fixtures/noted.xkb`).

## Start

Install AutoHotkey v2, extract this repository, and run exactly:

```text
neo-ahk/neo20-all.ahk
```

The entrypoint explicitly requires AutoHotkey v2.0 and every file it executes is v2 code. No v1 interpreter, launcher, shim, executable, build step, Python installation, or global dependency is part of the distribution. The preserved older `.ahk` files in `neo-ahk/source/` are legacy/reference source only and are not included by the entrypoint.

Use a German QWERTZ Windows input layout. Standard Noted places right Mod3 on `Ä` (`SC028`), `ß/ẞ` on the acute key (`SC01B`), and the acute dead-key family on `#` (`SC02B`). Left Mod3 is the physical CapsLock key; while the script runs, the Windows CapsLock state and LED are forced off (including while paused), so they do not reflect or control the independent Neo Shift lock. Mod4 is the ISO `< >` key or physical Right Alt.

- `Mod3+F7`: toggle Neo/Noted
- `Mod4+F7`: persist the selection to `%APPDATA%\Neo2\Neo2.ini`
- `Mod3+F6`: toggle QWERTZ; `Mod4+F6` saves it
- `Mod3+F12`: cycle Neo, NordTast, AdNW, DIEgO, K.O,Y; `Mod4+F12` saves it
- both Shift keys: Shift lock; both Mod4 keys: Mod4 lock
- `Ctrl+End`: pause/resume

The tray menu provides compact keyboard help, pause, reload, and exit controls. `Ctrl+End` and the tray pause command show the enabled/disabled icon at the center of the active application's monitor for about two seconds, with brief fades; the borderless click-through overlay does not take typing focus. Repeated toggles replace and restart that one overlay. Switching clears compose state while retaining held physical modifier roles; pause/resume resynchronizes physical modifiers without emitting unrelated modifier-up events. CapsLock acts as Mod3 while active; pausing disables the layout hotkeys but continues to prevent ordinary Windows CapsLock toggling. Other layout/save notifications remain normal Windows tray notifications.

The enabled tray and on-screen icon is the unmodified `res/neo_enabled.ico` from [Rojetto/ReNeo](https://github.com/Rojetto/ReNeo) at commit `c0dda5a59bce714a09bc4e1f64268eaf9bd4f416` (Git blob `08bb171a81ca2680fd4b6554f05d0b704c1eb64c`, 24,018 bytes). The upstream project and this repository are GPL-3.0 licensed. The same checked-in asset is used for both the enabled tray state and the enabled overlay state; `neo_disabled.ico` supplies the corresponding disabled states.

## Verification

Static fixture checks:

```sh
python3 -m unittest tests.test_noted_layout -v
```

Harmless v2 runtime self-test (does not install hotkeys, create directories, or read/write preferences):

```text
AutoHotkey64.exe neo-ahk\neo20-all.ahk --self-test
```

It loads the actual v2 entrypoint/data and checks all 32 exact Neo modifier states, pseudo-layer fallback and layer-6 dispatch, standard Noted overrides, compose/dead keys, F/numpad action resolution, shifted output specs, variants, held-key transitions, and all saved preference values. It writes PASS/FAIL to stdout and `neo-ahk/neo20-self-test.txt`, and exits nonzero on failure. It does not touch the saved INI.

## Compatibility note

The old v1 implementation contained additional specialist utilities (dynamic compose-file rebuilding, learning/one-hand modes, Unicode-number tools, ROM/clipboard/window helpers, and the large graphical screen keyboard). They remain as clearly legacy/reference source but are not executed and have not been ported. Core layouts, six layers, navigation/numpad actions, compose/dead-key data, locks, selection/persistence, and tray lifecycle controls are implemented in v2.

GPL-3.0; see `LICENSE`.
