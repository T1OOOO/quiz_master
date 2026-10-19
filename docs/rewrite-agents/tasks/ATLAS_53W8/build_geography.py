"""Build source-linked major water/resource relations from the CIA Factbook mirror.

CIA text is US government public-domain material. The mirror is a historical
snapshot, so only geographic associations are imported (never current politics).
"""
import concurrent.futures
import html
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / 'next/apps/quiz_app/assets/quizipedia'
HERE = Path(__file__).resolve().parent
BASE = 'https://raw.githubusercontent.com/factbook/factbook.json/master/'

SEAS = {
 'Arctic Ocean':'Северный Ледовитый океан','Atlantic Ocean':'Атлантический океан',
 'Pacific Ocean':'Тихий океан','Indian Ocean':'Индийский океан',
 'Southern Ocean':'Южный океан','Mediterranean Sea':'Средиземное море',
 'Black Sea':'Чёрное море','Baltic Sea':'Балтийское море','North Sea':'Северное море',
 'Red Sea':'Красное море','Caribbean Sea':'Карибское море','Arabian Sea':'Аравийское море',
 'South China Sea':'Южно-Китайское море','East China Sea':'Восточно-Китайское море',
 'Sea of Japan':'Японское море','Sea of Okhotsk':'Охотское море','Bering Sea':'Берингово море',
 'Gulf of Mexico':'Мексиканский залив','Persian Gulf':'Персидский залив',
 'Gulf of Oman':'Оманский залив','Gulf of Aden':'Аденский залив','Gulf of Guinea':'Гвинейский залив',
 'Bay of Bengal':'Бенгальский залив','Bay of Biscay':'Бискайский залив',
 'English Channel':'Ла-Манш','Norwegian Sea':'Норвежское море','Barents Sea':'Баренцево море',
 'Coral Sea':'Коралловое море','Tasman Sea':'Тасманово море','Timor Sea':'Тиморское море',
 'Arafura Sea':'Арафурское море','Adriatic Sea':'Адриатическое море','Aegean Sea':'Эгейское море',
 'Ionian Sea':'Ионическое море','Tyrrhenian Sea':'Тирренское море',
 'Gulf of Bothnia':'Ботнический залив','Gulf of Finland':'Финский залив',
 'Mozambique Channel':'Мозамбикский пролив','Andaman Sea':'Андаманское море',
 'Celebes Sea':'Море Сулавеси','Sulu Sea':'Море Сулу','Philippine Sea':'Филиппинское море',
 'Gulf of Thailand':'Сиамский залив','Gulf of Tonkin':'Тонкинский залив',
 'Kara Sea':'Карское море','Laptev Sea':'Море Лаптевых','East Siberian Sea':'Восточно-Сибирское море',
 'Beaufort Sea':'Море Бофорта','Labrador Sea':'Море Лабрадор','Hudson Bay':'Гудзонов залив',
 'Baffin Bay':'Баффинов залив','Davis Strait':'Девисов пролив',
 'Strait of Gibraltar':'Гибралтарский пролив','Strait of Malacca':'Малаккский пролив',
}
NAMES = {
 'Lake Baikal':'Байкал','Lake Ladoga':'Ладожское озеро','Lake Onega':'Онежское озеро',
 'Lake Victoria':'Озеро Виктория','Lake Tanganyika':'Танганьика','Lake Malawi':'Озеро Малави',
 'Lake Superior':'Озеро Верхнее','Lake Michigan':'Озеро Мичиган','Lake Huron':'Озеро Гурон',
 'Lake Erie':'Озеро Эри','Lake Ontario':'Озеро Онтарио','Lake Titicaca':'Титикака',
 'Caspian Sea':'Каспийское море','Aral Sea':'Аральское море','Dead Sea':'Мёртвое море',
 'Lake Chad':'Озеро Чад','Lake Geneva':'Женевское озеро','Lake Constance':'Боденское озеро',
 'Lake Peipus':'Чудское озеро','Lake Khanka':'Ханка','Lake Balkhash':'Балхаш',
 'Great Bear Lake':'Большое Медвежье озеро','Great Slave Lake':'Большое Невольничье озеро',
 'Lake Winnipeg':'Озеро Виннипег','Lake Nicaragua':'Озеро Никарагуа','Lake Van':'Озеро Ван',
 'Lake Urmia':'Озеро Урмия','Lake Albert':'Озеро Альберт','Lake Turkana':'Озеро Туркана',
 'Nile':'Нил','Amazon':'Амазонка','Danube':'Дунай','Rhine':'Рейн','Volga':'Волга',
 'Niger':'Нигер','Congo':'Конго','Zambezi':'Замбези','Mekong':'Меконг','Ganges':'Ганг',
 'Indus':'Инд','Brahmaputra':'Брахмапутра','Yangtze':'Янцзы','Huang He':'Хуанхэ',
 'Mississippi':'Миссисипи','Missouri':'Миссури','Rio Grande':'Рио-Гранде',
 'Parana':'Парана','Paraná':'Парана','Orinoco':'Ориноко','Murray':'Муррей',
 'Lena':'Лена','Don':'Дон','Ural':'Урал','Amur':'Амур','Ob-Irtysh':'Обь — Иртыш',
 'Yenisey-Angara':'Енисей — Ангара','Dnepr (Dnieper)':'Днепр','Dnieper':'Днепр',
 'Dnepr':'Днепр','Dniester':'Днестр','Elbe':'Эльба','Oder':'Одра','Vistula':'Висла',
 'Seine':'Сена','Loire':'Луара','Rhone':'Рона','Rhône':'Рона','Po':'По','Tigris':'Тигр',
 'Euphrates':'Евфрат','Jordan':'Иордан','Senegal':'Сенегал','Orange':'Оранжевая',
}
RESOURCES = {
 'petroleum':'Нефть','oil':'Нефть','natural gas':'Природный газ','coal':'Уголь',
 'iron ore':'Железная руда','copper':'Медь','gold':'Золото','silver':'Серебро',
 'diamonds':'Алмазы','bauxite':'Бокситы','uranium':'Уран','nickel':'Никель',
 'cobalt':'Кобальт','lithium':'Литий','tin':'Олово','zinc':'Цинк','lead':'Свинец',
 'manganese':'Марганец','phosphates':'Фосфаты','potash':'Калийные соли',
 'tungsten':'Вольфрам','chromium':'Хром','platinum':'Платина','titanium':'Титан',
 'salt':'Соль','timber':'Древесина','hydropower':'Гидроэнергетические ресурсы',
}
DESERTS = {'Sahara':'Сахара','Gobi':'Гоби','Kalahari':'Калахари','Namib':'Намиб',
 'Atacama':'Атакама','Karakum':'Каракумы','Kyzylkum':'Кызылкум',
 'Thar':'Тар','Taklamakan':'Такла-Макан','Rub al Khali':'Руб-эль-Хали',
 'Syrian Desert':'Сирийская пустыня','Great Victoria Desert':'Большая пустыня Виктория'}

def text(value):
    if isinstance(value,dict):
        return '; '.join(text(v) for v in value.values())
    return html.unescape(re.sub('<[^>]+>',' ',str(value)))

def fetch(path):
    with urllib.request.urlopen(BASE+path,timeout=25) as response:
        return path,json.load(response)

def slug(name):
    return re.sub('[^a-z0-9]+','-',name.lower()).strip('-')

def build():
    tree=json.load(urllib.request.urlopen('https://api.github.com/repos/factbook/factbook.json/git/trees/master?recursive=1'))
    paths=[r['path'] for r in tree['tree'] if r['path'].endswith('.json')]
    facts=json.loads((ASSETS/'country_facts.json').read_text(encoding='utf8'))['countries']
    ids={r['id'] for r in facts}
    waters={'sources':[],'countries':{}}
    links={'sources':[],'countries':{}}
    evidence={}
    failures=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures={pool.submit(fetch,p):p for p in paths}
        for future in concurrent.futures.as_completed(futures):
            try: path,data=future.result()
            except Exception as error:
                failures.append(str(error));continue
            tld=text(data.get('Communications',{}).get('Internet country code',''))
            found=re.findall(r'\.([a-z]{2})\b',tld)
            if not found: continue
            code={'UK':'GB'}.get(found[0].upper(),found[0].upper())
            if code not in ids: continue
            geo=data.get('Geography',{})
            source_id='factbook-'+code.lower()+'-'+Path(path).stem
            source={'id':source_id,'title':'CIA World Factbook geographic snapshot: '+code,
                'url':'https://github.com/factbook/factbook.json/blob/master/'+path}
            rows=[]; extra=[]
            location=text(geo.get('Location',''))
            # Only explicit coastal location phrases; inland lake/rivers come from their own fields.
            for en,ru in SEAS.items():
                if re.search(r'\b'+re.escape(en)+r'\b',location,re.I):
                    rows.append({'id':slug(en),'name_en':en,'name_ru':ru,'relation':'coast','source_id':source_id})
            lakes=text(geo.get('Major lakes (area sq km)',''))
            rivers=text(geo.get('Major rivers (by length in km)',''))
            for en,ru in NAMES.items():
                is_lake = en.startswith(('Lake ', 'Great ')) or en.endswith(' Sea')
                if is_lake and re.search(r'(?:^|;\s*)'+re.escape(en)+r'\b',lakes,re.I):
                    # A lake can be partly shared without touching the state border in every locality.
                    relation='border' if re.search(re.escape(en)+r'[^;]*shared with',lakes,re.I) else 'internal'
                    rows.append({'id':slug(ru) or slug(en),'name_en':en,'name_ru':ru,'relation':relation,'source_id':source_id})
                if not is_lake and re.search(r'(?:^|;\s*)(?:'+re.escape(en)+r'\b|[^;()]+\('+re.escape(en)+r'\))',rivers,re.I):
                    rows.append({'id':slug(en),'name_en':en,'name_ru':ru,'relation':'flows','source_id':source_id})
            resources=text(geo.get('Natural resources',''))
            for en,ru in RESOURCES.items():
                if re.search(r'\b'+re.escape(en)+r'\b',resources,re.I):
                    extra.append({'id':slug('petroleum' if en=='oil' else en),'kind':'resource',
                        'name_en':'Petroleum' if en=='oil' else en.capitalize(),'name_ru':ru,
                        'relation_en':'Listed natural resource','relation_ru':'Природный ресурс страны','source_id':source_id})
            terrain=text({k:geo.get(k,'') for k in ['Terrain','Geography - note']})
            for en,ru in DESERTS.items():
                if re.search(r'\b'+re.escape(en)+r'\b',terrain,re.I):
                    extra.append({'id':slug(en),'kind':'desert','name_en':en,'name_ru':ru,
                        'relation_en':'Desert in the country','relation_ru':'Пустыня на территории страны','source_id':source_id})
            if rows:
                waters['sources'].append(source)
                merged=waters['countries'].get(code,[])+rows
                waters['countries'][code]=list({(r['name_ru'],r['relation']):r for r in merged}.values())
            if extra:
                links['sources'].append(source)
                merged=links['countries'].get(code,[])+extra
                links['countries'][code]=list({(r['id'],r['kind']):r for r in merged}.values())
            if rows or extra:
                evidence[source_id]={'country':code,'path':path,'location':location,'lakes':lakes,'rivers':rivers,'resources':resources,'terrain':terrain}
    for filename,doc in [('country_waters.json',waters),('country_links.json',links)]:
        assert doc['countries'] and len(doc['countries'])>80
        sources={s['id'] for s in doc['sources']}
        assert all(r['source_id'] in sources for rows in doc['countries'].values() for r in rows)
        (ASSETS/filename).write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
    (HERE/'geography-source-evidence.json').write_text(json.dumps(evidence,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
    print(json.dumps({'water_countries':len(waters['countries']),'link_countries':len(links['countries']),'fetch_failures':failures}))

if __name__=='__main__': build()
