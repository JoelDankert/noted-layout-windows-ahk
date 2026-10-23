"""Static checks for the active AutoHotkey v2 implementation and pinned Noted fixture."""
import csv
import hashlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENTRY = (ROOT / "neo-ahk/neo20-all.ahk").read_text(encoding="utf-8-sig")
DATA = (ROOT / "neo-ahk/source/v2-generated-data.ahk").read_text(encoding="utf-8-sig")
XKB = (ROOT / "tests/fixtures/noted.xkb").read_text(encoding="utf-8")
SC = {f"AD{i:02d}": f"{i + 0x0f:03X}" for i in range(1, 13)}
SC.update({f"AC{i:02d}": f"{i + 0x1d:03X}" for i in range(1, 12)})
SC.update({f"AB{i:02d}": f"{i + 0x2b:03X}" for i in range(1, 11)})
SC["AC12"] = "02B"
ORDER = (0, 1, 2, 4, 3, 6, 5, 7)
SYMBOL = {
    "ssharp":"ß", "comma":",", "period":".", "semicolon":";", "udiaeresis":"ü",
    "Udiaeresis":"Ü", "adiaeresis":"ä", "Adiaeresis":"Ä", "odiaeresis":"ö",
    "Odiaeresis":"Ö", "endash":"–", "enfilledcircbullet":"•", "at":"@", "multiply":"×",
    "partialderivative":"∂", "jot":"∘", "radical":"√", "union":"∪", "intersection":"∩",
    "includedin":"⊂", "elementof":"∈", "integral":"∫", "nabla":"∇", "ifonlyif":"⇔",
    "KP_Separator":"S__NDot", "KP_Decimal":"S__NDot", "dead_acute":"T__acut",
    "dead_tilde":"T__tlde", "dead_stroke":"T__strk", "dead_psili":"T_psili",
    "dead_doubleacute":"T__dbac", "dead_breve":"T__brve", "Greek_finalsmallsigma":"ς",
}
GREEK = dict(zip("alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi omicron pi rho sigma tau upsilon phi chi psi omega".split(), "α β γ δ ε ζ η θ ι κ λ μ ν ξ ο π ρ σ τ υ φ χ ψ ω".split()))


def value(symbol):
    if symbol == "NoSymbol": return "="
    if symbol == "VoidSymbol": return ""
    if re.fullmatch(r"U[0-9A-Fa-f]{4,8}", symbol): return chr(int(symbol[1:], 16))
    if symbol in SYMBOL: return SYMBOL[symbol]
    if symbol.startswith("Greek_"):
        name = symbol[6:]
        result = GREEK[name.lower()]
        return result.upper() if name.isupper() else result
    return symbol


def fixture():
    body = XKB.split('xkb_symbols "noted_base"', 1)[1].split("\n};", 1)[0]
    return {key: [x.strip() for x in vals.split(",")]
            for key, vals in re.findall(r"key <([A-Z]{2}[0-9]{2})>\s*\{\s*\[([^]]+)]", body)}


def noted_rows():
    rows = {}
    for args in re.findall(r'^\s*AddNoted\(m,(.*)\)$', ENTRY, re.M):
        row = next(csv.reader([args], skipinitialspace=True))
        rows[row[0]] = row[2:]
    return rows


class ActiveV2Tests(unittest.TestCase):
    def test_entrypoint_is_v2_only(self):
        self.assertIn("#Requires AutoHotkey v2.0", ENTRY)
        self.assertIn("#SingleInstance Force", ENTRY)
        self.assertIn("#Include source\\v2-generated-data.ahk", ENTRY)
        self.assertNotRegex(ENTRY, r"#Include .*?(initialize|keyhooks|levelfunctions)\.ahk")

    def test_every_official_noted_override_matches_semantic_order(self):
        actual = noted_rows()
        for key, slots in fixture().items():
            if key == "AC11":  # physical right Mod3, handled by DualKeyDown
                continue
            expected = [value(slots[i]) for i in ORDER]
            if key == "AC12": expected[6] = ""
            with self.subTest(key=key):
                self.assertEqual(expected, actual[SC[key]])

    def test_physical_modifiers_void_and_inheritance(self):
        self.assertIn('key = "sc028" : key = "sc02B"', ENTRY)
        self.assertIn('Hotkey("~*RShift"', ENTRY)
        self.assertIn('Hotkey("~*LShift"', ENTRY)
        self.assertIn('Hotkey("*RAlt"', ENTRY)
        rows = noted_rows()
        self.assertEqual("", rows["012"][4])
        self.assertEqual("=", rows["012"][2])
        self.assertEqual("S__NDot", rows["027"][6])

    def test_compose_and_variants_are_checked_in(self):
        self.assertGreater(DATA.count("prefixes["), 1500)
        self.assertGreater(DATA.count("exact["), 7000)
        for name in ("QWERTZ", "NordTast", "AdNW", "DIEgO", "K.O,Y", "Noted"):
            self.assertIn(f'"{name}"', ENTRY)
        self.assertIn('%APPDATA%\\Neo2\\Neo2.ini', (ROOT / "README.md").read_text(encoding="utf-8"))

    def test_headless_path_precedes_preferences_and_hooks(self):
        self.assertLess(ENTRY.index('HasArg("--self-test")'), ENTRY.index("LoadPreference()"))
        self.assertLess(ENTRY.index('HasArg("--self-test")'), ENTRY.index("InstallHotkeys()"))
        self.assertIn("ExitApp(1)", ENTRY)
        self.assertIn("ExitApp(0)", ENTRY)

    def test_caps_lock_is_forced_off_only_after_headless_exit_path(self):
        caps = 'SetCapsLockState("AlwaysOff")'
        self.assertLess(ENTRY.index('HasArg("--self-test")'), ENTRY.index(caps))
        self.assertLess(ENTRY.index(caps), ENTRY.index("LoadPreference()"))
        toggle = ENTRY.split("TogglePause(*) {", 1)[1].split("\n}", 1)[0]
        self.assertIn(caps, toggle)
        self.assertLess(toggle.index(caps), toggle.index("SyncPhysicalState()"))
        self.assertIn('Hotkey("*CapsLock", ModifierDown.Bind("mod3L"))', ENTRY)
        self.assertIn("global ShiftLDown := false, ShiftRDown := false, ShiftLock := false", ENTRY)

    def test_layout_preference_default_and_explicit_persistence(self):
        self.assertIn('IniRead(IniPath, "Global", "LayoutVariant", "")', ENTRY)
        self.assertIn('IniWrite(CurrentVariant, IniPath, "Global", "LayoutVariant")', ENTRY)
        self.assertIn('return "Noted"', ENTRY)
        self.assertIn('VariantFromPreferences("Neo", "1", "1", "4") = "Neo"', ENTRY)
        for name in ("Noted", "QWERTZ", "NordTast", "AdNW", "DIEgO", "K.O,Y"):
            self.assertIn(f'VariantFromPreferences("{name}",', ENTRY)

    def test_script_only_distribution(self):
        self.assertFalse(any(ROOT.rglob("*.exe")))
        self.assertFalse(any(ROOT.rglob("*.cmd")))
        self.assertFalse((ROOT / "runtime").exists())

    def test_tray_icon_tracks_suspended_state(self):
        self.assertTrue((ROOT / "neo-ahk/neo_enabled.ico").is_file())
        self.assertTrue((ROOT / "neo-ahk/neo_disabled.ico").is_file())
        self.assertIn('TraySetIcon(A_ScriptDir "\\neo_" (enabled ? "enabled" : "disabled") ".ico",, true)', ENTRY)
        self.assertRegex(ENTRY, r"InstallTray\(\) \{\s+SetTrayIcon\(true\)")
        toggle = ENTRY.split("TogglePause(*) {", 1)[1].split("\n}", 1)[0]
        self.assertIn("Suspend(IsPaused)", toggle)
        self.assertIn("SetTrayIcon(!IsPaused)", toggle)
        self.assertLess(toggle.index("Suspend(IsPaused)"), toggle.index("SetTrayIcon(!IsPaused)"))
        self.assertIn("ShowPauseOsd(!IsPaused)", toggle)
        self.assertNotIn("TrayTip", toggle)
        self.assertIn("#SuspendExempt True\n^End::TogglePause()\n#SuspendExempt False", ENTRY)

    def test_pause_osd_and_pinned_icons(self):
        enabled = (ROOT / "neo-ahk/neo_enabled.ico").read_bytes()
        disabled = (ROOT / "neo-ahk/neo_disabled.ico").read_bytes()
        git_blob = lambda data: hashlib.sha1(
            f"blob {len(data)}\0".encode("ascii") + data).hexdigest()
        self.assertEqual(24018, len(enabled))
        self.assertEqual("08bb171a81ca2680fd4b6554f05d0b704c1eb64c", git_blob(enabled))
        self.assertEqual(2238, len(disabled))
        self.assertEqual("1e2c2af90b064c3393102397091133cdd482a466", git_blob(disabled))
        self.assertIn('Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000 -DPIScale")', ENTRY)
        self.assertIn('AddPicture("x0 y0 w" iconSize " h" iconSize)', ENTRY)
        self.assertIn("PauseOsdStart := A_TickCount", ENTRY)
        self.assertIn("SetTimer(AnimatePauseOsd, 16)", ENTRY)
        self.assertIn('PauseOsdGui.Show("NA x"', ENTRY)
        self.assertIn('DllCall("MonitorFromWindow"', ENTRY)
        initial_alpha = 'WinSetTransColor("010203 1", PauseOsdGui)'
        self.assertEqual(2, len(re.findall(r'^\s*WinSetTransColor\(.+, PauseOsdGui\)$', ENTRY, re.M)))
        self.assertNotIn('"ahk_id " PauseOsdGui.Hwnd', ENTRY)
        self.assertLess(ENTRY.index(initial_alpha), ENTRY.index('PauseOsdGui.Show("NA x"'))


if __name__ == "__main__":
    unittest.main()
