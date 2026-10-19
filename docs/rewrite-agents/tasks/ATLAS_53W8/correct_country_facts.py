"""Apply independently reviewed exceptions; retain provenance alongside snapshot."""
import json
import urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
path=ROOT/'next/apps/quiz_app/assets/quizipedia/country_facts.json'
doc=json.loads(path.read_text(encoding='utf8'))
raw=json.load(urllib.request.urlopen('https://raw.githubusercontent.com/mledoze/countries/master/countries.json'))
iso2={row['cca3']:row['cca2'] for row in raw}
for row in doc['countries']:
    row['neighbors']=[iso2.get(code,code) for code in row['neighbors']]
    row['currencies']=[code for code in row['currencies'] if isinstance(code,str)]
    official=row.get('official_languages')
    if isinstance(official,str): row['official_languages']=[official]
    if row['id']=='US':
        row['official_languages']=['English']
        row['official_languages_source']='https://www.whitehouse.gov/fact-sheets/2025/03/fact-sheet-president-donald-j-trump-designates-english-as-the-official-language-of-the-united-states/'
    if row['id']=='ZW':
        row['currencies']=[c for c in row['currencies'] if c not in ['ZWB','ZWL']]+(['ZWG'] if 'ZWG' not in row['currencies'] else [])
        row['currency_source']='https://www.rbz.co.zw/documents/press/2024/July/PRESS_STATEMENT_ON_ZiG_CURRENCY_CODE.pdf'
    if row['id']=='ZA':
        row['capital']='Pretoria (administrative); Cape Town (legislative); Bloemfontein (judicial)'
    if row['id']=='BO': row['capital']='Sucre (constitutional capital)'
    if row['id']=='NL': row['capital']='Amsterdam (capital; government in The Hague)'
by_id={row['id']:row for row in doc['countries']}
for a,b,source in [
    ('CA','DK','https://canada.um.dk/en/the-arctic'),
    ('CA','GL','https://canada.um.dk/en/the-arctic'),
    ('FR','BR','https://www.defense.gouv.fr/terre/actualites/mission-trijonction-jusquaux-trois-frontieres'),
    ('FR','SR','https://www.defense.gouv.fr/terre/actualites/mission-trijonction-jusquaux-trois-frontieres'),
    ('FR','NL','https://www.diplomatie.gouv.fr/en/information-by-country/netherlands/france-and-the-netherlands'),
]:
    for country,neighbor in [(a,b),(b,a)]:
        if neighbor not in by_id[country]['neighbors']: by_id[country]['neighbors'].append(neighbor)
        by_id[country].setdefault('neighbor_sources',{})[neighbor]=source
doc['sources']['review']='See docs/rewrite-agents/tasks/ATLAS_53W8/fact-review.md for legal-language exclusions and capital/currency exceptions.'
path.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
print('Normalized official-language arrays and applied US, ZW, ZA, BO, NL review corrections.')
