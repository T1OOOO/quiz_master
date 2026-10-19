"""Import Pew's 2020 percentages with explicit country-code matching."""
import csv
import hashlib
import io
import json
from pathlib import Path
from zipfile import ZipFile

here = Path(__file__).parent
repo = here.parents[3]
raw_codes = (here / 'country-codes-source.json').read_bytes()
codes = json.loads(raw_codes)
mapping = {str(int(r['ccn3'])): r['cca2'] for r in codes if r.get('ccn3')}
# Pew uses 412 for Kosovo; the existing atlas uses XK. Do not distribute the
# Channel Islands aggregate (830) to either Guernsey or Jersey.
mapping['412'] = 'XK'
facts = json.loads((repo / 'next/apps/quiz_app/assets/quizipedia/country_facts.json').read_text(encoding='utf-8'))
atlas_ids = {r['id'] for r in facts['countries']}
keys = ['Christians', 'Muslims', 'Religiously_unaffiliated', 'Buddhists', 'Hindus', 'Jews', 'Other_religions']
archive = here / 'pew-dataset.zip'
with ZipFile(archive) as source:
    name = next(n for n in source.namelist() if n.endswith('(percentages).csv'))
    rows = list(csv.DictReader(io.StringIO(source.read(name).decode('utf-8-sig'))))
rows = [r for r in rows if r['Year'] == '2020' and r['Level'] == '1']
assert len(rows) == 201
countries, unmatched = [], []
for row in rows:
    code = row['Countrycode']
    country_id = mapping.get(code)
    if country_id not in atlas_ids:
        unmatched.append({'source_name': row['Country'], 'source_code': code})
        continue
    shares = {key: round(float(row[key]), 6) for key in keys}
    assert abs(sum(shares.values()) - 100) < .001
    countries.append({'id': country_id, 'source_name': row['Country'],
                      'source_code': code, 'shares': shares})
assert len(countries) == 200
assert len({r['id'] for r in countries}) == 200
assert unmatched == [{'source_name': 'Channel Islands', 'source_code': '830'}]
doc = {
    'schema_version': 'qm-country-religions/v1', 'year': 2020,
    'published_year': 2025, 'checked_on': '2026-10-19',
    'source_url': 'https://www.pewresearch.org/religion/feature/religious-composition-by-country-2010-2020/',
    'methodology_url': 'https://www.pewresearch.org/religion/2025/06/09/global-religious-change-methodology/',
    'dataset_url': 'https://www.pewresearch.org/wp-content/uploads/sites/20/2025/06/Religious-Composition-2010-2020-dataset.zip',
    'dataset_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
    'citation': 'Hackett et al. (2025), Religious Composition by Country, 2010-2020, Pew Research Center. doi:10.58094/5shf-2d69.',
    'country_codes_source': 'https://github.com/mledoze/countries/blob/master/countries.json',
    'country_codes_license': 'ODbL-1.0',
    'country_codes_sha256': hashlib.sha256(raw_codes).hexdigest(),
    'note_ru': 'Оценки религиозной принадлежности населения за 2020 год, не официальный статус религий. Другие религии объединены источником; отсутствие принадлежности не означает исключительно атеизм. Числа округлены. Из 201 страны и территории источника сопоставлено 200; совокупные данные Нормандских островов не приписаны отдельно Гернси и Джерси.',
    'note_en': 'Estimated population affiliation in 2020, not religions’ official status. Other religions are combined by the source; unaffiliated does not mean exclusively atheist. Figures are rounded. 200 of the source’s 201 countries and territories are matched; Channel Islands aggregate is not assigned separately to Guernsey or Jersey.',
    'unmatched': unmatched, 'countries': countries,
}
out = repo / 'next/apps/quiz_app/assets/quizipedia/country_religions.json'
out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(f'{len(countries)} matched countries; {len(unmatched)} excluded aggregate; year 2020')
