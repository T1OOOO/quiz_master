"""Apply independently reviewed factual corrections to the curated registry."""
import json
from pathlib import Path

path = Path(__file__).resolve().parents[4] / 'next/apps/quiz_app/assets/quizipedia/brands.json'
doc = json.loads(path.read_text(encoding='utf8'))
brands = {row['id']: row for row in doc['brands']}
owners = {row['id']: row for row in doc['owners']}
new_sources = {
    'samsung_identity': ('Samsung brand story', 'https://www.samsung.com/us/about-us/brand-identity/brand-story/'),
    'pepsi_identity': ('Pepsi history: drink, name and globe', 'https://www.pepsico.com/newsroom/stories/2026/pepsi-history-brads-drink-iconic-american-brand'),
    'prada_history': ('Prada Group history', 'https://www.pradagroup.com/en/group/history.html'),
    'lego_name': ('LEGO: 90-year history of the name', 'https://www.lego.com/en-gb/aboutus/news/2026/february/90-year-history-of-the-lego-name'),
    'nestle_timeline': ('Nestlé: company history timeline', 'https://www.nestle.com/about/history/nestle-company-history'),
    'porsche_heritage': ('Porsche AG: heritage', 'https://investorrelations.porsche.com/en/about-porsche/heritage'),
}
existing = {row['id'] for row in doc['sources']}
for source_id, (title, url) in new_sources.items():
    if source_id not in existing:
        doc['sources'].append(dict(id=source_id, title=title, url=url, checked_on='2026-10-19'))

brand = brands['samsung']
brand.update(name='Samsung Electronics', founded_year=1969,
    date_note_ru='Samsung Electronics основана в 1969 году; 1938 — год основания группы Samsung.',
    date_note_en='Samsung Electronics was founded in 1969; 1938 is the founding year of the Samsung group.',
    source_ids=['samsung_identity', 'samsung_history'], founders=[])
brand['facts'] = [dict(text_ru='История группы Samsung начинается с торговой компании 1938 года; это отдельная дата от основания Samsung Electronics.',
    text_en='The Samsung group traces its history to a trading company founded in 1938, a separate date from the foundation of Samsung Electronics.',
    source_ids=['samsung_history', 'samsung_identity'])]
owners['samsung']['source_ids'] = ['samsung_identity']

brand = brands['pepsi']
brand['logo_history'] = [dict(year=1951,
    text_ru='Красно-бело-синяя крышка бутылки стала предшественницей круглого знака Pepsi Globe.',
    text_en='A red-white-blue bottle cap became the precursor of the round Pepsi Globe mark.',
    source_ids=['pepsi_identity'])]
brand['source_ids'] = list(dict.fromkeys([*brand['source_ids'], 'pepsi_identity']))

brands['prada']['source_ids'] = ['prada_history']
owners['prada']['source_ids'] = ['prada_history']
for fact in brands['prada']['facts']:
    fact['source_ids'] = ['prada_history']

brands['lego']['logo_history'] = []
lego_fact = dict(text_ru='По уточнённой истории компании, название LEGO официально используется с января 1936 года; оно происходит от датского leg godt («играй хорошо»).',
    text_en='The company’s revised history dates official use of the LEGO name to January 1936; it derives from Danish leg godt (play well).', source_ids=['lego_name'])
brands['lego']['facts'] = [fact for fact in brands['lego']['facts'] if 'lego_name' not in fact['source_ids']] + [lego_fact]
brands['warner_bros']['logo_history'] = []
for brand_id in ['gucci', 'chanel', 'hermes', 'disney']:
    for moment in brands[brand_id]['logo_history']:
        moment['year'] = None
brands['chanel']['logo_history'][0].update(text_ru='Переплетённые буквы CC — узнаваемый знак дома Chanel.', text_en='Interlocking CC letters are a recognisable Chanel house mark.')
brands['hermes']['logo_history'][0].update(text_ru='В эмблеме дома изображены экипаж и лошадь.', text_en='The house emblem depicts a carriage and horse.')
brands['dior']['former_names'] = []
brands['mini']['founders'] = []  # Issigonis designed the original car, rather than founding the marque.
brands['mercedes_benz']['founders'] = []  # Founders of the predecessor companies are not founders of the 1926 marque.
brands['nestle'].update(
    date_note_ru='1866 — основание Anglo-Swiss братьями Чарльзом и Джорджем Пейджами. Анри Нестле начал пищевой бизнес в 1867 году; компании объединились в 1905 году.',
    date_note_en='1866 marks the Page brothers’ foundation of Anglo-Swiss. Henri Nestlé began his food business in 1867; the companies merged in 1905.',
    founders=['Анри Нестле', 'Чарльз Пейдж', 'Джордж Пейдж'])
brands['nestle']['source_ids'] = list(dict.fromkeys([*brands['nestle']['source_ids'], 'nestle_timeline']))
brands['porsche'].update(founded_year=1931,
    date_note_ru='Инженерное бюро Porsche основано в 1931 году Фердинандом Порше, Адольфом Розенбергером и Антоном Пиехом. Первый автомобиль марки Porsche появился в 1948 году.',
    date_note_en='The Porsche engineering company was founded in 1931 by Ferdinand Porsche, Adolf Rosenberger and Anton Piëch. The first Porsche-branded car appeared in 1948.',
    founders=['Фердинанд Порше', 'Адольф Розенбергер', 'Антон Пиех'])
brands['porsche']['source_ids'] = list(dict.fromkeys([*brands['porsche']['source_ids'], 'porsche_heritage']))
for former in brands['nike']['former_names']:
    former['quiz_enabled'] = False
    former['to_year'] = None
    former['note_ru'] = 'Историческое название компании, начавшей работу в 1964 году. Название собственного бренда Nike появилось в 1971 году; это отдельное событие от юридического переименования.'
    former['note_en'] = 'Historical company name, with the business starting in 1964. Nike appeared as its own brand in 1971, a separate event from the legal company renaming.'
for brand_id in ['google', 'bmw', 'marvel', 'dc', 'loreal_paris', 'adidas', 'puma']:
    for former in brands[brand_id]['former_names']:
        former['quiz_enabled'] = False

scopes = {
    'youtube': 'service', 'windows': 'product', 'xbox': 'product',
    'playstation': 'product', 'aws': 'service', 'lexus': 'brand',
    'bmw': 'predecessor', 'mini': 'product', 'mercedes_benz': 'brand',
    'porsche': 'company', 'ferrari': 'product', 'nike': 'rename',
    'prada': 'first_store', 'chanel': 'first_store', 'zara': 'first_store',
    'uniqlo': 'first_store', 'hm': 'first_store', 'loreal_paris': 'predecessor',
    'coca_cola': 'product', 'fanta': 'product', 'sprite': 'product',
    'pepsi': 'product', 'doritos': 'product', 'mcdonalds': 'first_restaurant',
    'kfc': 'first_franchise', 'starbucks': 'first_store', 'nestle': 'predecessor',
    'nescafe': 'brand', 'kitkat': 'product', 'marvel': 'predecessor',
    'hbo': 'service', 'dc': 'predecessor',
}
for brand in doc['brands']:
    brand['date_scope'] = scopes.get(brand['id'], 'company')
doc['coverage_note_ru'] = f"Учебная подборка: {len(doc['brands'])} бренд и {len(doc['owners'])} компаний/групп. Это не полный мировой реестр. Связи владельцев проверены на 19.10.2026; даты основания, запуска и предшественников поясняются отдельно."
doc['coverage_note_en'] = f"Learning selection: {len(doc['brands'])} brands and {len(doc['owners'])} companies/groups, not a complete global registry. Ownership checked as of 2026-10-19; foundation, launch and predecessor dates are qualified separately."
path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf8', newline='\n')
print(len(doc['brands']), 'brands;', len(doc['sources']), 'sources; review corrections applied')
