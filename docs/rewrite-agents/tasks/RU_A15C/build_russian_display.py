"""Russian presentation labels; canonical facts, answer IDs and URLs stay intact."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / 'next/apps/quiz_app/assets/quizipedia'
terms = {}
for line in '''
Société Française de Teintures Inoffensives pour Cheveux|Французское общество безопасных красок для волос
Industria de Diseño Textil, S.A. (Inditex)|Индустрия де Дисеньо Текстиль (Индитекс)
PIF / Silver Lake / Affinity Partners|Государственный инвестиционный фонд Саудовской Аравии / Силвер Лейк / Аффинити Партнерс
LVMH Moët Hennessy Louis Vuitton|Луи Виттон — Моэт — Хеннесси
L'Oréal Paris|Лореаль Париж
L'Oréal|Лореаль
Gebrüder Dassler Schuhfabrik|Обувная фабрика братьев Дасслер
Bayerische Flugzeugwerke (BFW)|Баварские авиационные заводы (БФВ)
National Allied Publications|Нэшнл Эллайд Пабликейшнз
Starbucks Coffee, Tea and Spice|Старбакс: кофе, чай и пряности
Unique Clothing Warehouse|Юник Клоузинг Уэрхаус
Rowntree's Chocolate Crisp|Раунтрис Чоколейт Крисп
Kentucky Fried Chicken|Кентукки Фрайд Чикен
Sony Interactive Entertainment|Сони Интерактив Энтертейнмент
Amazon Web Services|Амазон Веб Сервисез
The Walt Disney Company|Уолт Дисней Компани
Sony Group Corporation|Сони Груп Корпорейшн
The Coca-Cola Company|Кока-Кола Компани
Fast Retailing Co., Ltd.|Фаст Ритейлинг
H & M Hennes & Mauritz AB|Хеннес энд Мауриц
Hennes & Mauritz|Хеннес энд Мауриц
Nintendo Co., Ltd.|Нинтендо
Toyota Motor Corporation|Тойота Мотор Корпорейшн
Honda Motor Co., Ltd.|Хонда Мотор
Mercedes-Benz Group AG|Мерседес-Бенц Груп
Microsoft Corporation|Майкрософт Корпорейшн
Spotify Technology S.A.|Спотифай Текнолоджи
Skydance Corporation|Скайдэнс Корпорейшн
Ubisoft Entertainment SA|Юбисофт Энтертейнмент
Apple Computer, Inc.|Эппл Компьютер
Disney Brothers Studio|Студия братьев Дисней
Blue Ribbon Sports|Блю Риббон Спортс
Tokyo Tsushin Kogyo|Токио Цусин Когё
Hermès International|Эрмес Интернасьональ
Samsung Electronics|Самсунг Электроникс
Chanel Limited|Шанель Лимитед
Warner Bros. Discovery|Уорнер Бразерс Дискавери
Warner Bros.|Уорнер Бразерс
Electronic Arts|Электроник Артс
McDonald's Bar-B-Q|Макдоналдс Барбекю
McDonald's Corporation|Макдоналдс Корпорейшн
McDonald's|Макдоналдс
Brad's Drink|Напиток Брэда
Alphabet Inc.|Алфабет
Apple Inc.|Эппл
Amazon.com, Inc.|Амазон
Netflix, Inc.|Нетфликс
Tesla, Inc.|Тесла
Ferrari N.V.|Феррари
NIKE, Inc.|Найк
adidas AG|Адидас
PUMA SE|Пума
Prada S.p.A.|Прада
Yum! Brands, Inc.|Ям Брэндс
Starbucks Corporation|Старбакс Корпорейшн
Nestlé S.A.|Нестле
Volkswagen AG|Фольксваген
BMW AG|БМВ
L'Oréal S.A.|Лореаль
PepsiCo, Inc.|Пепсико
LEGO Group|Группа Лего
Microsoft|Майкрософт
Micro-soft|Майкро-софт
Windows|Виндоус
PlayStation|Плейстейшен
YouTube|Ютуб
Google|Гугл
BackRub|БэкРаб
Apple|Эппл
Alphabet|Алфабет
Xbox|Иксбокс
Samsung Group|Группа Самсунг
Samsung|Самсунг
Sony|Сони
Amazon.com|Амазон
Amazon|Амазон
Cadabra|Кадабра
Netflix|Нетфликс
Toyota|Тойота
Toyoda|Тоёда
Lexus|Лексус
Honda|Хонда
Mercedes-Benz|Мерседес-Бенц
Daimler-Benz|Даймлер-Бенц
Daimler|Даймлер
Volkswagenwerk|Фольксвагенверк
Volkswagen|Фольксваген
Porsche|Порше
Ferrari|Феррари
Audi|Ауди
Tesla Motors|Тесла Моторс
Tesla|Тесла
Converse|Конверс
Louis Vuitton|Луи Виттон
Christian Dior|Кристиан Диор
Dior|Диор
Gucci|Гуччи
Prada|Прада
CHANEL|Шанель
Chanel|Шанель
Hermès|Эрмес
Inditex|Индитекс
UNIQLO|Юникло
Fast Retailing|Фаст Ритейлинг
H&M|Эйч-энд-Эм
Hennes|Хеннес
Mauritz|Мауриц
Zara|Зара
Zorba|Зорба
Coca-Cola|Кока-Кола
Pepsi-Cola|Пепси-Кола
PepsiCo|Пепсико
Pepsi|Пепси
Fanta|Фанта
Sprite|Спрайт
Lay's|Лейс
Doritos|Доритос
KFC|Кей-эф-си
Starbucks|Старбакс
Nestlé|Нестле
Nescafé|Нескафе
KitKat|Киткат
Kit Kat|Киткат
Timely Comics|Таймли Комикс
Atlas Comics|Атлас Комикс
Pixar|Пиксар
Marvel|Марвел
Lucasfilm|Лукасфильм
Disney|Дисней
Spotify|Спотифай
LEGO|Лего
Nintendo Koppai|Нинтендо Коппай
Nintendo|Нинтендо
Ubisoft|Юбисофт
Skydance|Скайдэнс
Kering|Керинг
Yum! Brands|Ям Брэндс
Ruda|Руда
adidas|Адидас
Adidas|Адидас
NIKE|Найк
Nike|Найк
PUMA|Пума
Puma|Пума
MINI|Мини
Mini|Мини
BMW|БМВ
HBO|Эйч-би-оу
LVMH|Луи Виттон — Моэт — Хеннесси
AWS|Амазон Веб Сервисез
DC|Ди-си
EA|Электроник Артс
LV|ЛВ
WBD|Уорнер Бразерс Дискавери
BFW|БФВ
Rolls-Royce|Роллс-Ройс
Land Rover|Ленд Ровер
Bentley|Бентли
Lamborghini|Ламборгини
Ducati|Дукати
Anglo-Swiss|Англо-Свисс
Macintosh|Макинтош
iPhone|Айфон
iPod|Айпод
Swoosh|Свуш
Star Wars|Звёздные войны
Indiana Jones|Индиана Джонс
Air Jordan|Эйр Джордан
Jordan Brand|Джордан Брэнд
R&B|ритм-н-блюз
CERN|Европейская организация по ядерным исследованиям
Arco|Арко
pizzicato|пиццикато
Dal segno|даль сеньо
To Coda|К коде
sebum, то есть кожное сало|кожное сало
T-лимфоцитов|Т-лимфоцитов
Гомеровa|Гомерова
Гарвардский Pluralism Project|Гарвардский проект изучения религиозного многообразия
Harvard Pluralism Project|Гарвардский проект изучения религиозного многообразия
Plurаlism Project|Гарвардский проект изучения религиозного многообразия
Pluralism Project|Гарвардский проект изучения религиозного многообразия
Sikh Coalition|Сикхская коалиция
Jainpedia|Джайнская энциклопедия
Jinja Honcho|Ассоциация синтоистских святилищ
Bahá’í Reference Library|Справочная библиотека бахаи
Pizza Napoletana|Неаполитанская пицца
Margherita|Маргарита
Marinara|Маринара
al dente|аль денте
ají limo|перец ахи лимон
gō|го
Jeonju|Чонджу
bibim|пибим
bap|пап
La Cucina Italiana|Итальянская кухня
Carbonara classica|Классическая карбонара
Georgia Travel|Туристический портал Грузии
Peru Travel|Туристический портал Перу
Turisme Comunitat Valenciana|Туристическая служба Валенсийского сообщества
Our Regional Cuisines|Наша региональная кухня
Korean Bapsang|Корейский стол
My Greek Dish|Моё греческое блюдо
Georgian Recipes|Грузинские рецепты
Pew Research Center|Исследовательский центр Пью
World Bank|Всемирный банк
Public domain|Общественное достояние
Semitone|Полутон
Whole tone|Целый тон
Octave|Октава
Major scale|Мажорная гамма
Natural minor|Натуральный минор
Triad|Трезвучие
Arpeggio|Арпеджио
New7Wonders|«Новые семь чудес света»
mledoze/countries|Справочник стран
Flagpedia / FlagCDN|Флагпедия: изображения флагов
CIA Factbook|Всемирная книга фактов ЦРУ
Stellarium|Стеллариум
IAU|МАС
Adolf Dassler adidas Sportschuhfabrik|Обувная фабрика Адольфа Дасслера «Адидас»
Adolf Dassler|Адольф Дасслер
Eugène Schueller|Эжен Шуэллер
Herman Lay|Херман Лэй
Rover Group|Ровер Груп
Rolls-Royce Motor Cars|Роллс-Ройс Мотор Карс
Brand Group Core|бренд-группа «Основные марки»
Brand Group Progressive|бренд-группа «Прогрессивные марки»
Sport Luxury brand group|бренд-группу «Спортивная роскошь»
Sport Luxury|«Спортивная роскошь»
Apple Computer Company|Эппл Компьютер Компани
Toyota Motor Co., Ltd.|Тойота Мотор
Toyota Motor Co.|Тойота Мотор
Honda Motor Co.|Хонда Мотор
Sony Corporation|Сони Корпорейшн
Sony Group|Сони Груп
Volkswagen Group|Фольксваген Груп
BMW Group|БМВ Груп
Burning Man|Бёрнинг Мэн
Altair BASIC|Альтаир Бейсик
MITS|МИТС
MS-DOS|Эм-эс-ДОС
Doodle|праздничный логотип
Hershey|Херши
Jordan|Джордан
Mercedes|Мерседес
Benz|Бенц
Widforss|Видфорсс
Pepsi Globe|Глобус Пепси
KitKat Chocolate Crisp|Киткат Чоколейт Крисп
Chocolate Crisp|Чоколейт Крисп
Daimler-Benz AG|Даймлер-Бенц АГ
Porsche AG|Порше АГ
Marvel Comics|Марвел Комикс
leg godt («играй хорошо»)|«играй хорошо»
leg godt|«играй хорошо»
PIF|Государственный инвестиционный фонд Саудовской Аравии
Silver Lake|Силвер Лейк
Affinity Partners|Аффинити Партнерс
Studio Ghibli|Студия Гибли
T-лимфоцит|Т-лимфоцит
Pizza Napoletana STG|«Неаполитанская пицца»
В варианте STG|В варианте по спецификации
Маргарита STG использует|В «Маргарите» по спецификации используют
Неаполитанская пицца STG|Неаполитанская пицца по традиционной спецификации
STG ограничивает|Спецификация ограничивает
STG описывает Marinara|Спецификация описывает «Маринару»
относит Marinara|относит «Маринару»
Valencia DOP|«Валенсия» с защищённым наименованием места происхождения
из MAFF Our Regional Cuisines|из справочника Министерства сельского хозяйства Японии «Наша региональная кухня»
рецепт MAFF|рецепт Министерства сельского хозяйства Японии
версия MAFF|версия Министерства сельского хозяйства Японии
версией MAFF|версией Министерства сельского хозяйства Японии
MAFF|Министерство сельского хозяйства Японии
GNTO|Национальная туристическая организация Греции
MSG|глутамат натрия
ají|перец ахи
°C|°С
Corporation|Корпорейшн
Inc.|Инк.
Group|Груп
Computer Company|Компьютер Компани

'''.strip().splitlines():
    en, ru = line.split('|', 1)
    terms[en] = ru

sources = {}
def register(filename, labels):
    raw = json.loads((ASSETS / filename).read_text(encoding='utf-8'))
    for s in raw['sources']:
        if s['id'] not in labels:
            raise ValueError((filename, s['id']))
        sources[s['title']] = labels[s['id']]

register('music_learning.json', dict(zip(
    ['notation','rhythm','meter','performance','scales','intervals','chords'],
    ['Открытая теория музыки: основы нотной записи','Открытая теория музыки: длительности','Открытая теория музыки: метр и размер','Открытая теория музыки: исполнительские обозначения','Открытая теория музыки: гаммы','Открытая теория музыки: интервалы','Открытая теория музыки: трезвучия и септаккорды']
)) | {
    **{e['id']+'-source':'Оркестр «Филармония»: '+e['name_ru'].lower() for e in json.loads((ASSETS/'music_learning.json').read_text())['entries'] if e['category']=='instruments'},
    'duduk-source':'ЮНЕСКО: Дживан Гаспарян и дудук',
    'angklung-source':'Архив ЮНЕСКО: индонезийский ангклунг',
    'dombra-source':'ЮНЕСКО: казахское искусство домбра-кюй',
    'mbira-source':'Университет Бат-Спа: «Мбира-хат»',
    'japan-source':'Министерство иностранных дел Японии: традиционная музыка',
    'india-source':'Метрополитен-музей: инструменты Индийского субконтинента',
    'gamelan-source':'ЮНЕСКО: гамелан','flamenco-source':'Архив ЮНЕСКО: фламенко',
    'tango-source':'ЮНЕСКО: танго','aitysh-source':'ЮНЕСКО: Айтыш/Айтыс, искусство импровизации','bagpipe-source':'ЮНЕСКО: культура волынки',
})
register('organ_atlas.json', {
    'openstax-'+id:'Издатель «ОпенСтакс»: анатомия и физиология: '+label for id,label in [
      ('endocrine','гипофиз и гипоталамус'),('digestive','вспомогательные органы пищеварения'),
      ('reproductive','репродуктивная система'),('urinary','мочевыводящие пути'),
      ('respiratory','дыхательная система'),('skin','структуры кожи'),('skeleton','скелет'),
      ('muscle','скелетные мышцы'),('endocrine-review','эндокринная система'),('sensory','чувственное восприятие'),
      ('nervous','центральная нервная система'),('vessels','кровеносные сосуды'),('lymphatic','лимфатическая и иммунная системы'),
      ('salivary','рот, глотка и пищевод'),('stomach','желудок'),('intestines','тонкая и толстая кишка'),
      ('female-reproductive','женская репродуктивная система')]
} | {'nhlbi-heart':'Национальный институт сердца, лёгких и крови США: строение сердца',
     'niddk-kidneys':'Национальный институт диабета и болезней органов пищеварения и почек США: работа почек',
     'nci-ovaries':'Учебный курс SEER Национального института рака США: яичники','nci-testes':'Учебный курс SEER Национального института рака США: семенники'})
register('belief_atlas.json', {
 'hesiod_theogony':'Гесиод, «Теогония», перевод Хью Эвелин-Уайта',
 'homeric_hymns':'Гомеровские гимны 5–33, перевод Хью Эвелин-Уайта',
 'homeric_hymns_1_3':'Гомеровские гимны 1–3, перевод Хью Эвелин-Уайта',
 'met_greek_gods':'Метрополитен-музей: греческие боги и религиозные практики',
 'pluralism_judaism':'Гарвардский проект изучения религиозного многообразия: Бог, Тора и Израиль',
 'pluralism_christianity':'Гарвардский проект изучения религиозного многообразия: введение в христианство',
 'quran_2_177':'Коран, сура 2, аят 177 — сайт «Коран.ком»',
 'pluralism_hindu_veda':'Гарвардский проект изучения религиозного многообразия: Веды',
 'pluralism_buddhist_dharma':'Гарвардский проект изучения религиозного многообразия: учение Будды',
 'sikh_coalition_history':'Сикхская коалиция: история', 'jainpedia_beliefs':'Джайнская энциклопедия: верования',
 'bahai_official':'Официальный сайт всемирной общины бахаи',
 'jinja_honcho_shinto':'Ассоциация синтоистских святилищ: что такое синто',
})
register('food_atlas.json', dict(zip(
 ['pizza-stg-pdf','paella-valencia-pdf','carbonara-lci','nigiri-maff','chirashi-maff','ceviche-peru','moussaka-gnto','khachapuri-author','khachapuri-georgia','borscht-klopotenko','bibimbap-koreanbapsang','moussaka-giannopoulos'],
 ['Спецификация традиционной неаполитанской пиццы','Туристическая служба Валенсии: валенсийская паэлья','Итальянская кухня: классическая карбонара','Министерство сельского хозяйства Японии: нигири-суси','Министерство сельского хозяйства Японии: тирасидзуси','Туристический портал Перу: рыбное севиче','Туристический портал Греции: мусака','Ирма Иантбелидзе: хачапури по-аджарски','Туристический портал Грузии: аджарские хачапури','Евгений Клопотенко: украинский борщ со свиными рёбрами','Хёсун Ро, «Корейский стол»: пибимпап','Эли Яннопулос: традиционная греческая мусака']
)))

def translate(text):
    for en,ru in sorted(terms.items(),key=lambda pair:-len(pair[0])):
        text=text.replace(en,ru)
    return text

brands=json.loads((ASSETS/'brands.json').read_text())
brand_source_names={
 'apple50':'Эппл: 50 лет «думать иначе»','google_story':'Гугл: история компании','ms_history':'Майкрософт: история компании',
 'nike_company':'Найк: сведения о компании','nike_swoosh':'Найк: история знака «Свуш»',
 'mb_history':'Мерседес-Бенц: сто лет бренда','vw_brands':'Фольксваген: бренды группы',
 'starbucks_history':'Старбакс: история компании','yum_history':'Ям Брэндс: хронология компании',
 'kering_gucci':'Керинг: история дома Гуччи','inditex_brands':'Индитекс: бренды группы',
 'fastretailing':'Фаст Ритейлинг: история компании','netflix_history':'Нетфликс: сведения о компании',
 'tesla_history':'Тесла: сведения о компании','warner_history':'Уорнер Бразерс Дискавери: сведения о компании',
 'spotify_history':'Спотифай: сведения о компании','ea_history':'Электроник Артс: сведения о компании',
 'skydance_closing':'Скайдэнс / Комиссия по ценным бумагам и биржам США: завершение сделки, 6 октября 2026 года',
 'ea_closing':'Завершение приобретения Электроник Артс, 4 августа 2026 года',
 'samsung_identity':'Самсунг: история бренда','pepsi_identity':'Пепси: история напитка, названия и эмблемы',
 'lego_name':'Лего: девяностолетняя история названия','nestle_timeline':'Нестле: хронология компании',
 'porsche_heritage':'Порше: историческое наследие',
}
for s in brands['sources']:
    if s['id'] not in brand_source_names:
        # Remaining records are company-history pages; the entity translation is explicit above.
        name=s['title'].split(' — ')[0].replace(' Group','').replace(' Group history','').replace(' history','')
        brand_source_names[s['id']]=translate(name)+': история компании'
register('brands.json',brand_source_names)

def literal(text):
    return json.dumps(text,ensure_ascii=False).replace('$',r'\$')
lines=['/// Russian presentation labels. Canonical facts, symbols, IDs and URLs are unchanged.',
       'const russianLearningTerms = <String, String>{']
for a,b in sorted(terms.items(),key=lambda pair:-len(pair[0])):
    lines.append('  '+literal(a)+': '+literal(b)+',')
lines += ['};','', 'const russianSourceTitles = <String, String>{']
for a,b in sorted(sources.items()): lines.append('  '+literal(a)+': '+literal(b)+',')
lines += ['};','', '''String russianLearningText(String value) {
  var result = value;
  for (final entry in russianLearningTerms.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

String learningSourceTitle(String title, {required bool russian}) =>
    russian ? russianSourceTitles[title] ?? 'Источник' : title;
''']
credits = {
 'natural-earth':'Данные «Нэчурал Эрт»: страны, масштаб 1:110 млн. Обобщённые фактические границы; фон карты не определяет список стран для викторины.',
 'hyg':'Каталог звёзд HYG 4.1, Дэвид Нэш / «Астронексус». Подборка из 681 звезды, фиксированные координаты эпохи J2000; сохранены восемь исходных учебных схем. Адаптированные данные: лицензия CC BY-SA 4.0.',
 'sky-modern':'Каталог звёзд HYG 4.1, Дэвид Нэш / «Астронексус», координаты эпохи J2000. Команда «Стеллариум»: линии современных схем созвездий. Данные и линии адаптированы по лицензии CC BY-SA 4.0. Иллюстрации не использованы; линии не являются границами Международного астрономического союза.',
 'colosseum':'Якоб Труэдсон Демиц для «Ристессон». Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'taj-mahal':'Марсмюкс. Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'giza-pyramid':'Автор под псевдонимом «каллерна». Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'petra-treasury':'Борис Дебич. Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'sydney-opera':'Майкл Эльвазир. Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'eiffel':'Автор под псевдонимом «ДискоА340». Учтена ориентация снимка; максимальная сторона уменьшена до 960 пикселей, выполнено повторное сжатие изображения.',
 'endocrine':'Открытый учебник «ОпенСтакс», Томаш Кеберт и образовательный портал «Умимето». Схема преобразована в растровое изображение; содержание оригинала не изменено.',
}
lines.append('const russianCreditAttributions = <String, String>{')
for a,b in credits.items():lines.append('  '+literal(a)+': '+literal(b)+',')
lines += ['};', '''String russianCreditAttribution(Map<String, dynamic> credit) =>
  russianCreditAttributions[credit['id']] ?? russianLearningText(credit['attribution'] as String);
''']
(ROOT/'next/apps/quiz_app/lib/russian_learning_text.dart').write_text('\n'.join(lines),encoding='utf-8')
print(len(terms),'Russian terms;',len(sources),'source titles')
