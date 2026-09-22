"""Standard-library structural test; does not pretend to parse or execute GDScript."""
from pathlib import Path
import json
import re

root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'data/case_1142.json').read_text())
translations = json.loads((root / 'data/translations.json').read_text())
timeline = data['truth']['timeline']
clues = data['evidence']
ids = [e['id'] for e in clues]
checks = {
    'eight_unique_clues': len(ids) == len(set(ids)) == 8,
    'all_locations_exist': all(e['location'] in data['map'] for e in clues),
    'all_links_have_valid_endpoints': all(set(pair).issubset(ids) for pair in data['required_links']),
    'chronological_canonical_events': all(a['time'] <= b['time'] for a,b in zip(timeline,timeline[1:])),
    'offset_explains_camera': data['truth']['camera_offset_minutes'] == 7 and
        any(e.get('time') == '23:35' and e.get('recorded_time') == '23:42' for e in timeline),
    'english_and_arabic_key_parity': set(translations['en']) == set(translations['ar_EG']),
    'all_clues_localized': all(e['text_key'] in translations['en'] for e in clues),
    'all_clue_names_localized': all('ev.name.' + e['id'] in translations['en'] for e in clues),
    'three_separate_explanations': len(data['required_links']) == 3,
}
for path in (root/'scripts').rglob('*.gd'):
    source = path.read_text()
    for key in re.findall(r'Loc\.t\("([^"]+)"\)',source):
        checks[f'{path.name}:{key}'] = key in translations['en']
for name, ok in checks.items():
    print(('PASS' if ok else 'FAIL') + ': ' + name)
print(f'{sum(checks.values())}/{len(checks)} structural checks passed')
raise SystemExit(0 if all(checks.values()) else 1)
