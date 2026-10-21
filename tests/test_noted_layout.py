"""Focused static regression checks for the full standard Noted AHK mapping."""
import csv
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XKB = (ROOT / "tests/fixtures/noted.xkb").read_text(encoding="utf-8")
SOURCE = (ROOT / "neo-ahk/source/noted.ahk").read_text(encoding="utf-8-sig")

SC_BY_XKB = {f"AD{i:02d}": f"{i + 0x0f:03X}" for i in range(1, 13)}
SC_BY_XKB.update({f"AC{i:02d}": f"{i + 0x1d:03X}" for i in range(1, 13)})
SC_BY_XKB.update({f"AB{i:02d}": f"{i + 0x2b:03X}" for i in range(1, 11)})
SC_BY_XKB["AC12"] = "02B"  # German BKSL/# key, not another home-row key
# XKB: E1,E2,E3,E5,E4,pseudo,E6,E8; AHK: E1..E6,pseudo,E8.
AHK_FROM_XKB = (0, 1, 2, 4, 3, 6, 5, 7)

SYMBOL = {
    "ssharp": "ß", "comma": ",", "period": ".", "semicolon": ";",
    "udiaeresis": "ü", "Udiaeresis": "Ü",
    "adiaeresis": "ä", "Adiaeresis": "Ä",
    "odiaeresis": "ö", "Odiaeresis": "Ö",
    "endash": "–", "enfilledcircbullet": "•", "at": "@",
    "multiply": "×", "partialderivative": "∂", "jot": "∘",
    "radical": "√", "union": "∪", "intersection": "∩",
    "includedin": "⊂", "elementof": "∈", "integral": "∫",
    "nabla": "∇", "ifonlyif": "⇔", "KP_Separator": "S__NDot",
    "KP_Decimal": "S__NDot", "dead_acute": "T__acut",
    "dead_tilde": "T__tlde", "dead_stroke": "T__strk",
    "dead_psili": "T_psili", "dead_doubleacute": "T__dbac",
    "dead_breve": "T__brve", "Greek_finalsmallsigma": "ς",
}
GREEK = {
    "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
    "epsilon": "ε", "zeta": "ζ", "eta": "η", "theta": "θ",
    "iota": "ι", "kappa": "κ", "lambda": "λ", "mu": "μ",
    "nu": "ν", "xi": "ξ", "omicron": "ο", "pi": "π",
    "rho": "ρ", "sigma": "σ", "tau": "τ", "upsilon": "υ",
    "phi": "φ", "chi": "χ", "psi": "ψ", "omega": "ω",
}


def body_of(text, name):
    match = re.search(r"^" + name + r"\([^)]*\)\s*\{(.*?)^\}", text, re.M | re.S)
    assert match, "missing function " + name
    return match.group(1)


def xkb_value(symbol):
    if symbol == "NoSymbol":
        return "="
    if symbol == "VoidSymbol":
        return ""
    if symbol.startswith("U") and re.fullmatch(r"U[0-9A-Fa-f]{4,8}", symbol):
        return chr(int(symbol[1:], 16))
    if symbol in SYMBOL:
        return SYMBOL[symbol]
    if symbol.startswith("Greek_"):
        name = symbol[6:]
        upper = name.isupper()
        value = GREEK[name.lower()]
        return value.upper() if upper else value
    return symbol


def fixture_keys():
    base = XKB.split('xkb_symbols "noted_base"', 1)[1].split("\n};", 1)[0]
    found = {}
    for key, values in re.findall(r"key <([A-Z]{2}[0-9]{2})>\s*\{\s*\[([^]]+)]", base):
        found[key] = [part.strip() for part in values.split(",")]
    return found


def declared_keys():
    body = body_of(SOURCE, "CharProcNoted1")
    found = {}
    for args in re.findall(r"NotedKey\(([^\n]+)\)", body):
        row = next(csv.reader([args], skipinitialspace=True))
        found[row[0]] = row[2:]
    return found


class NotedMappingTests(unittest.TestCase):
    def test_every_official_override_matches_ahk_semantic_order(self):
        actual = declared_keys()
        reference = fixture_keys()
        self.assertGreaterEqual(len(reference), 30)
        for key, slots in reference.items():
            if key == "AC11":
                continue
            sc = SC_BY_XKB[key]
            expected = [xkb_value(slots[index]) for index in AHK_FROM_XKB]
            # AC12 receives Neo AD12's dead-key family.  Its NoSymbol pseudo
            # slot corresponds to Neo AD12's intentionally empty slot.
            if key == "AC12":
                expected[6] = ""
            with self.subTest(key=key, sc=sc):
                self.assertIn(sc, actual)
                self.assertEqual(expected, actual[sc])

    def test_standard_physical_modifier_and_dead_key_positions(self):
        body = body_of(SOURCE, "CharProcNoted1")
        self.assertIn('ED1S("028","P__M3RD")', body)
        self.assertIn('NotedKey("01B",1,"ß","ẞ","ſ",";","ς","∘"', body)
        self.assertIn('NotedKey("02B",0,"T__acut","T__tlde","T__strk"', body)
        self.assertNotIn('ED1S("02B","P__M3RD")', body)

    def test_inheritance_void_and_pseudo_level_are_explicit(self):
        actual = declared_keys()
        self.assertEqual("", actual["012"][4])       # AD03 VoidSymbol, E5
        self.assertEqual("=", actual["012"][2])      # AD03 NoSymbol, E3
        self.assertEqual("S__NDot", actual["027"][6]) # AC10 shifted E4
        self.assertEqual(",", actual["035"][6])      # AB10 shifted E4
        self.assertIn('if (value == "=")', body_of(SOURCE, "NotedKey"))

    def test_switching_restores_all_eight_slots_and_variant_metadata(self):
        restore = body_of(SOURCE, "RestoreNotedKeys")
        self.assertIn("Loop,8", restore)
        self.assertIn('SetKeyPos("CP" . A_Index . pos,saved[A_Index])', restore)
        self.assertIn('NOC%pos% := saved["NOC"]', restore)
        for filename, function in (("qwertz.ahk", "CharProcQwerT1"),
                                   ("nordtast.ahk", "CharProcNordT1")):
            text = (ROOT / "neo-ahk/source" / filename).read_text(encoding="utf-8-sig")
            self.assertIn("RestoreNotedKeys()", body_of(text, function))
            self.assertIn("IniDelete,%ini%,Global,isNoted", text)
        install = body_of(SOURCE, "CharProcNoted1")
        self.assertIn("Change1256LayoutNeo20()", install)
        self.assertIn("Check_BSTUpdate(1)", install)
        self.assertIn("Check_BSTUpdate(1)", restore)

    def test_selection_persistence_and_neo_default(self):
        entry = (ROOT / "neo-ahk/neo20-all.ahk").read_text(encoding="utf-8-sig")
        self.assertIn("source\\noted.ahk", entry)
        self.assertIn('CP3F7 := "PNotedT"', SOURCE)
        self.assertIn('CP4F7 := "PNoteds"', SOURCE)
        self.assertIn("IniRead,isNoted,%ini%,Global,isNoted,0", SOURCE)
        self.assertNotIn("A_Args", SOURCE)

    def test_distribution_remains_script_only(self):
        self.assertFalse(any(ROOT.rglob("*.exe")))
        self.assertFalse(any(ROOT.rglob("*.cmd")))
        self.assertFalse((ROOT / "runtime").exists())


if __name__ == "__main__":
    unittest.main()
