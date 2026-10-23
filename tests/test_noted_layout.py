"""Focused dependency-free checks for the minimal Noted-only distribution."""
import csv
import hashlib
import re
import struct
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENTRY = (ROOT / "noted.ahk").read_text(encoding="utf-8-sig")
DATA = (ROOT / "data.ahk").read_text(encoding="utf-8-sig")
XKB = (ROOT / "tests/fixtures/noted.xkb").read_text(encoding="utf-8")
SC = {f"AD{i:02d}": f"sc{i + 0x0f:03X}" for i in range(1, 13)}
SC.update({f"AC{i:02d}": f"sc{i + 0x1d:03X}" for i in range(1, 12)})
SC.update({f"AB{i:02d}": f"sc{i + 0x2b:03X}" for i in range(1, 11)})
SC["AC12"] = "sc02B"
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
    if symbol in ("NoSymbol", "VoidSymbol"): return symbol
    if re.fullmatch(r"U[0-9A-Fa-f]{4,8}", symbol): return chr(int(symbol[1:], 16))
    if symbol in SYMBOL: return SYMBOL[symbol]
    if symbol.startswith("Greek_"):
        name = symbol[6:]; result = GREEK[name.lower()]
        return result.upper() if name.isupper() else result
    return symbol


def rows():
    result = {}
    for key, body in re.findall(r'^\s*data\["([^"]+)"\] := \[(.*?)\]$', DATA, re.M):
        cap = int(body[0])
        fields = [s.replace("``", "`").replace('`"', '"')
                  for s in re.findall(r'"((?:``|`"|[^"])*)"', body)]
        result[key] = [cap, *fields]
    return result


def ico_sizes(path):
    raw = path.read_bytes(); count = struct.unpack_from("<H", raw, 4)[0]
    result = set()
    for i in range(count):
        width, height = raw[6 + i * 16], raw[7 + i * 16]
        result.add((width or 256, height or 256))
    return result


class NotedDistributionTests(unittest.TestCase):
    def test_minimal_script_only_tree(self):
        files = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob("*")
                 if p.is_file() and ".git/" not in p.as_posix() and "__pycache__" not in p.as_posix()}
        self.assertEqual({".gitignore", "LICENSE", "README.md", "noted.ahk", "data.ahk",
                          "noted_enabled.ico", "noted_disabled.ico",
                          "tests/fixtures/noted.xkb", "tests/test_noted_layout.py",
                          "tests/verify_osd.ahk"}, files)
        self.assertFalse(any(ROOT.rglob("*.exe")))

    def test_entrypoint_is_noted_only_v2(self):
        self.assertIn("#Requires AutoHotkey v2.0", ENTRY)
        self.assertIn("#Include data.ahk", ENTRY)
        for stale in ("NeoBase", "Variant", "QWERTZ", "NordTast", "IniRead", "IniWrite", "F7"):
            self.assertNotIn(stale, ENTRY)
        self.assertIn('Hotkey("*sc028", ModifierDown.Bind("mod3R"))', ENTRY)
        self.assertIn('if key != "sc028"\n            Hotkey("*" key, KeyDown.Bind(key))', ENTRY)
        self.assertIn('data["sc02B"]', DATA)
        self.assertIn('Hotkey("~*RShift"', ENTRY)
        self.assertIn('#SuspendExempt True\n^End::TogglePause()', ENTRY)
        self.assertLess(ENTRY.index('HasArg("--self-test")'), ENTRY.index('SetCapsLockState("AlwaysOff")'))

    def test_complete_resolved_table_is_pinned(self):
        parsed = rows()
        self.assertEqual(91, len(parsed))
        canonical = "\n".join(f"{key}={body}" for key, body in
                              re.findall(r'^\s*data\["([^"]+)"\] := \[(.*?)\]$', DATA, re.M))
        self.assertEqual("efd492b8b410da3083bdaf1a5632e32f4964301e64c113bbb60c317e51b31cd2",
                         hashlib.sha256(canonical.encode()).hexdigest())
        self.assertEqual("]", parsed["sc013"][3])  # inherited NoSymbol is concrete
        self.assertEqual("", parsed["sc012"][5])   # VoidSymbol stays empty
        self.assertEqual("", parsed["sc028"][1])

    def test_every_xkb_noted_value_matches_baked_rows(self):
        parsed = rows()
        body = XKB.split('xkb_symbols "noted_base"', 1)[1].split("\n};", 1)[0]
        fixture = {key: [x.strip() for x in vals.split(",")]
                   for key, vals in re.findall(r"key <([A-Z]{2}[0-9]{2})>\s*\{\s*\[([^]]+)]", body)}
        for key, slots in fixture.items():
            if key == "AC11": continue
            for layer, expected in enumerate((value(slots[i]) for i in ORDER), 1):
                if expected == "NoSymbol": continue
                if key == "AC12" and layer == 7: expected = ""
                with self.subTest(key=key, layer=layer):
                    self.assertEqual(expected if expected != "VoidSymbol" else "", parsed[SC[key]][layer])

    def test_compose_dictionary_and_derived_prefixes(self):
        packed = DATA.split("( Join`n", 1)[1].split('\n)"', 1)[0].strip("\n")
        lines = packed.splitlines()
        self.assertEqual(7622, len(lines))
        self.assertEqual("aeb6104f0d1f518748166f59c0fee0b8a00b7b8a8ae8e2e078f4244f81c5674c",
                         hashlib.sha256(packed.encode()).hexdigest())
        prefixes = {key[:n] for line in lines for key in [line.split("`t", 1)[0]]
                    for n in range(7, len(key), 7)}
        self.assertEqual(1644, len(prefixes))

    def test_icons_and_osd_contract(self):
        enabled = (ROOT / "noted_enabled.ico").read_bytes()
        blob = hashlib.sha1(f"blob {len(enabled)}\0".encode() + enabled).hexdigest()
        self.assertEqual("08bb171a81ca2680fd4b6554f05d0b704c1eb64c", blob)
        self.assertEqual({(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)},
                         ico_sizes(ROOT / "noted_disabled.ico"))
        for text in ("-DPIScale", "DrawIconEx", "PauseOsdCenterX - size / 2",
                     "PauseOsdCenterY - size / 2", "static duration := 2000", "c1 := 1.35",
                     "OnMessage(0x000F, PaintPauseOsd)", "BeginPaint", "EndPaint"):
            self.assertIn(text, ENTRY)
        self.assertNotIn("WinSetTransparent", ENTRY)


if __name__ == "__main__":
    unittest.main()
