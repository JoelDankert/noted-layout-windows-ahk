"""Static tests for Joel's Noted letter layers on the existing Neo AHK engine.

First-layer fixture: dariogoetz/noted-layout xkb/noted at
20f43c1a27736a5f894f6fe32620d41e629a5aab (GPL-3.0).
Noted's moved modifier/ß/dead key and higher levels are deliberately NOT imported.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
XKB = (ROOT / 'tests/fixtures/noted.xkb').read_text(encoding='utf-8')
XKB_BASE = XKB.split('xkb_symbols "noted_base"', 1)[1].split('\n};', 1)[0]
SC = ['00C'] + [f'{n:03X}' for n in range(0x10, 0x1B)] + [f'{n:03X}' for n in range(0x1E, 0x29)] + [f'{n:03X}' for n in range(0x2C, 0x36)]
SC_BY_XKB = {f'AD{i:02d}': f'{i+0x0f:03X}' for i in range(1, 12)}
SC_BY_XKB.update({f'AC{i:02d}': f'{i+0x1d:03X}' for i in range(1, 12)})
SC_BY_XKB.update({f'AB{i:02d}': f'{i+0x2b:03X}' for i in range(1, 11)})
SYMBOLS = {'ssharp':'ß', 'udiaeresis':'ü', 'adiaeresis':'ä', 'odiaeresis':'ö', 'comma':',', 'period':'.'}


def body_of(text, name):
    match = re.search(r'^'+name+r'\([^)]*\)\s*\{(.*?)^\}', text, re.M | re.S)
    assert match, 'missing function '+name
    return match.group(1)


def noted_source():
    return (ROOT/'neo-ahk/source/noted.ahk').read_text(encoding='utf-8-sig')


class NotedMappingTests(unittest.TestCase):
    def test_letter_positions_follow_noted_except_neo_modifier_and_dead_key(self):
        body = body_of(noted_source(), 'CharProcNoted1')
        match = re.search(r'Change12Layout\("([^"]+)"\)', body)
        self.assertIsNotNone(match)
        assert match is not None
        chars = match.group(1)
        self.assertEqual(len(SC), len(chars))
        self.assertEqual(set('-xvlcwkhgfqßuia eosnrtd yüöäpzbm,.j'.replace(' ','')), set(chars))
        actual = dict(zip(SC, chars))
        definitions = re.findall(r'key <([A-Z]{2}[0-9]{2})>\s*\{\s*\[\s*([^,\s]+)', XKB_BASE)
        self.assertGreater(len(definitions), 20)
        for key, symbol in definitions:
            if key in SC_BY_XKB:
                with self.subTest(key=key):
                    self.assertEqual(SYMBOLS.get(symbol, symbol), actual[SC_BY_XKB[key]])
        # Official Noted makes AC11 a modifier and moves ß to AD12. In this
        # letter-only variant Neo's Mod3 and acute positions must remain fixed.
        self.assertEqual('ß', actual['028'])
        self.assertEqual('j', actual['01A'])
        self.assertEqual('-', actual['00C'])

    def test_layout_change_touches_only_neo_levels_one_and_two(self):
        defs=(ROOT/'neo-ahk/source/keydefinitions.ahk').read_text(encoding='utf-8-sig')
        change=body_of(defs, 'Change12Layout')
        ed12=re.search(r'ED12\([^)]*\)\s*\{(.*?)^\}', defs, re.M|re.S)
        self.assertIsNotNone(ed12)
        assert ed12 is not None
        self.assertIn('ED12(',change)
        self.assertNotIn('ED1256(',change)
        self.assertNotIn('CP3', change+ed12.group(1))
        self.assertNotIn('CP4', change+ed12.group(1))
        self.assertNotIn('CP5', change+ed12.group(1))
        self.assertNotIn('CP6', change+ed12.group(1))
        self.assertIn('SetKeyPos("CP1"',ed12.group(1))
        self.assertIn('SetKeyPos("CP2"',ed12.group(1))
        body=body_of(noted_source(), 'CharProcNoted1')
        self.assertNotIn('Change1256Layout(',body)
        self.assertNotRegex(body,r'\b(EDS|ED1S|SetKeyPos)\(')
        self.assertNotIn('vksc028',body)

    def test_selection_like_qwertz_and_neo_default(self):
        source=noted_source()
        entry=(ROOT/'neo-ahk/neo20-all.ahk').read_text(encoding='utf-8-sig')
        self.assertIn('source\\noted.ahk',entry)
        self.assertIn('CP3F7 := "PNotedT"',source)
        self.assertIn('CP4F7 := "PNoteds"',source)
        self.assertIn('IniRead,isNoted,%ini%,Global,isNoted,0',source)
        self.assertNotIn('A_Args',source)
        nord=(ROOT/'neo-ahk/source/nordtast.ahk').read_text(encoding='utf-8-sig')
        self.assertNotIn('CharProcNordT5',nord)

    def test_restoring_neo_letters_and_switching_other_variants(self):
        restore=body_of(noted_source(),'RestoreNotedKeys')
        self.assertIn('Change12Layout(neo20layoutstring)',restore)
        self.assertNotIn('Change1256LayoutNeo20()',restore)
        qwertz=(ROOT/'neo-ahk/source/qwertz.ahk').read_text(encoding='utf-8-sig')
        nord=(ROOT/'neo-ahk/source/nordtast.ahk').read_text(encoding='utf-8-sig')
        self.assertIn('RestoreNotedKeys()',body_of(qwertz,'CharProcQwerT1'))
        self.assertIn('RestoreNotedKeys()',body_of(nord,'CharProcNordT1'))
        self.assertIn('IniDelete,%ini%,Global,isNoted',body_of(qwertz,'CharProcQwerts'))
        self.assertIn('IniDelete,%ini%,Global,isNoted',body_of(nord,'CharProcNordTs'))

    def test_shortcuts_in_tray_help(self):
        tray=(ROOT/'neo-ahk/source/tray.ahk').read_text(encoding='utf-8-sig')
        self.assertIn('M3 + F7:',tray)
        self.assertIn('M4 + F7:',tray)

    def test_distribution_has_no_cmd_exe_or_interpreter(self):
        self.assertFalse((ROOT/'portable/start-noted.cmd').exists())
        self.assertFalse((ROOT/'.github/workflows/build-windows.yml').exists())
        self.assertFalse((ROOT/'neo20-noted.exe').exists())
        self.assertFalse((ROOT/'runtime').exists())


if __name__ == '__main__':
    unittest.main()
