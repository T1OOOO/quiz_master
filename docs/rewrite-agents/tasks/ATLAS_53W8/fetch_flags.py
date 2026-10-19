"""Cache Flagpedia/FlagCDN PNGs for offline country practice (2026-10-19)."""
import concurrent.futures
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / 'next/apps/quiz_app/assets/quizipedia'
raw = json.loads((ASSETS / 'country_facts.json').read_text(encoding='utf-8'))
rows = raw if isinstance(raw, list) else raw['countries']
codes = sorted({r.get('cca2', r.get('id', '')).lower() for r in rows})

def fetch(code):
    path = ASSETS / f'flag-{code}.png'
    if path.exists():
        return None
    url = f'https://flagcdn.com/w160/{code}.png'
    try:
        with urllib.request.urlopen(url, timeout=25) as response:
            data = response.read()
        assert data.startswith(b'\x89PNG\r\n\x1a\n'), url
        path.write_bytes(data)
    except Exception as error:
        return f'{code}: {error}'

with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    failures = [e for e in pool.map(fetch, codes) if e]
print(json.dumps({'codes': len(codes), 'failures': failures}))
if failures:
    raise SystemExit(1)
