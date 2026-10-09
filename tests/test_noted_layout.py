"""Static, offline checks against the official Noted XKB first-layer specification.

Fixture: dariogoetz/noted-layout, xkb/noted at
20f43c1a27736a5f894f6fe32620d41e629a5aab (GPL-3.0).
Windows key events still need a real Windows machine to validate.
"""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = (ROOT / 'neo-ahk/source/nordtast.ahk').read_text(encoding='utf-8-sig')
ENTRY = (ROOT / 'neo-ahk/neo20-all.ahk').read_text(encoding='utf-8-sig')
XKB = (ROOT / 'tests/fixtures/noted.xkb').read_text(encoding='utf-8')
SC = ['00C'] + [f'{n:03X}' for n in range(0x10, 0x1B)] + [f'{n:03X}' for n in range(0x1E, 0x29)] + [f'{n:03X}' for n in range(0x2C, 0x36)]
SC_BY_XKB = {f'AD{i:02d}': f'{i+0x0f:03X}' for i in range(1, 12)}
SC_BY_XKB.update({f'AC{i:02d}': f'{i+0x1d:03X}' for i in range(1, 12)})
SC_BY_XKB.update({f'AB{i:02d}': f'{i+0x2b:03X}' for i in range(1, 11)})
SC_BY_XKB.update({'AD12': '01B', 'AC12': '02B'})
SYMBOLS = {'ssharp':'ß', 'udiaeresis':'ü', 'adiaeresis':'ä', 'odiaeresis':'ö',
           'comma':',', 'period':'.', 'dead_acute':'T__acut'}


def variant():
    match = re.search(r'^CharProcNordT5\(\)\s*\{(.*?)^\}', SOURCE, re.M | re.S)
    assert match, 'missing Noted variant'
    return match.group(1)


def actual_first_layer():
    match = re.search(r'Change1256Layout\("([^"]+)"\)', variant())
    assert match, 'missing 33-key Noted base'
    chars = match.group(1)
    assert len(chars) == len(SC) == 33
    first = dict(zip(SC, chars))
    first['01B'] = 'T__acut'
    first['02B'] = 'P__M3RD'
    for line in variant().splitlines():
        call = re.match(r'\s*(EDS|ED1S)\("([0-9A-F]{3})"\s*,\s*(.*)', line)
        if call:
            quoted = re.findall(r'"([^"]*)"', call.group(3))
            if call.group(1) == 'EDS':
                first[call.group(2)] = quoted[0]
            else:
                first[call.group(2)] = quoted[0]
    return first


class NotedMappingTests(unittest.TestCase):
    def test_first_layer_matches_official_noted_xkb(self):
        first = actual_first_layer()
        definitions = re.findall(r'key <([A-Z]{2}[0-9]{2})>\s*\{\s*\[\s*([^,\s]+)', XKB.split('xkb_symbols "noted_base"', 1)[1].split('\n};', 1)[0])
        self.assertGreater(len(definitions), 20)
        for key, symbol in definitions:
            if key in SC_BY_XKB:
                expected = SYMBOLS.get(symbol, symbol)
                with self.subTest(key=key):
                    self.assertEqual(expected, first[SC_BY_XKB[key]])
        self.assertEqual('P__M3RD', first['028'], 'Noted shifts the right Mod3 to AC11')
        self.assertEqual('T__acut', first['02B'], 'Noted shifts the dead key to AC12')
        self.assertEqual('-', first['00C'])

    def test_noted_special_layers_and_modifier_are_explicit(self):
        body = variant()
        for required in ('EDS("01A",1,"j","J","@","−","θ","Θ")',
                         'EDS("01B",1,"ß","ẞ","ſ",";","ς","∘")',
                         'EDS("027",1,"h","H",":",".","ψ","Ψ")',
                         'EDS("035",1,"k","K",";","S__NDot","κ","⇒")',
                         'ED1S("028","P__M3RD")',
                         'EDS("02B",0,"T__acut","T__tlde","T__strk","T__dbac","T_psili","T__brve")'):
            with self.subTest(required=required):
                self.assertIn(required, body)

    def test_noted_is_in_normal_cycle_and_persisted_on_startup(self):
        self.assertIsNotNone(re.search(r'isNordTast\s*==\s*4.*?CharProcNordT5\(', SOURCE, re.S), 'Noted follows K.O,Y')
        self.assertIsNotNone(re.search(r'isNordTast\s*==\s*5\)\s*\n\s*CharProcNordT5\(', SOURCE), 'saved Noted variant loads')
        self.assertIn('source\\nordtast.ahk', ENTRY)

    def test_portable_launcher_selects_noted_without_changing_saved_variant(self):
        launcher = ROOT / 'portable/start-noted.cmd'
        self.assertTrue(launcher.is_file())
        text = launcher.read_text(encoding='utf-8')
        self.assertIn('AutoHotkeyU64.exe', text)
        self.assertIn('neo20-all.ahk', text)
        self.assertIn(' noted', text)
        self.assertIn('A_Args[1] == "noted"', SOURCE)

    def test_windows_build_compiles_portable_exe_without_install(self):
        workflow = ROOT / '.github/workflows/build-windows.yml'
        self.assertTrue(workflow.is_file())
        text = workflow.read_text(encoding='utf-8')
        self.assertIn('windows-latest', text)
        self.assertIn('Ahk2Exe.exe', text)
        self.assertIn('Start-Process', text)
        self.assertIn('6f3663f7cdd25063c8c8728f5d9b07813ced8780522fd1f124ba539e2854215f', text)
        self.assertIn('neo20-all.ahk', text)

    def test_switching_away_restores_all_noted_only_positions(self):
        self.assertIn('RestoreNotedKeys()', SOURCE)
        self.assertIsNotNone(re.search(r'CharProcNordT0\(\)\s*\{.*?RestoreNotedKeys\(\)', SOURCE, re.S), 'Neo restoration must clear Noted modifiers')
        self.assertIsNotNone(re.search(r'CharProcNordT1\(\)\s*\{.*?RestoreNotedKeys\(\)', SOURCE, re.S), 'next variant must clear Noted modifiers')


if __name__ == '__main__':
    unittest.main()
