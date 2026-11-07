# Builds delta.json from the item table below. Run: python -I build.py
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
W = 'https://en.wikipedia.org/wiki/'
# key -> (title, url)
S = {
 'liechtenstein': ('Wikipedia: Liechtenstein', W+'Liechtenstein'),
 'li-suffrage': ('Wikipedia: 1984 Liechtenstein women\'s suffrage referendum', W+'1984_Liechtenstein_women%27s_suffrage_referendum'),
 'li-customs': ('Swiss FDFA: Bilateral relations Switzerland-Liechtenstein', 'https://www.eda.admin.ch/countries/liechtenstein/en/home/switzerland-and/bilateral-relations.html'),
 'san-marino': ('Wikipedia: San Marino', W+'San_Marino'),
 'whc-1245': ('UNESCO World Heritage Centre: San Marino Historic Centre and Mount Titano', 'https://whc.unesco.org/en/list/1245'),
 'cricova': ('Wikipedia: Cricova', W+'Cricova'),
 'orhei': ('Wikipedia: Orheiul Vechi', W+'Orheiul_Vechi'),
 'martisor': ('Wikipedia: Mărțișor', W+'M%C4%83r%C8%9Bi%C8%99or'),
 'struve': ('Wikipedia: Struve Geodetic Arc', W+'Struve_Geodetic_Arc'),
 'gorham': ('Wikipedia: Gorham\'s Cave', W+'Gorham%27s_Cave'),
 'gib-airport': ('Wikipedia: Gibraltar International Airport', W+'Gibraltar_International_Airport'),
 'gibraltar': ('Wikipedia: Gibraltar', W+'Gibraltar'),
 'iom-tt': ('Wikipedia: Isle of Man TT', W+'Isle_of_Man_TT'),
 'laxey': ('Wikipedia: Laxey Wheel', W+'Laxey_Wheel'),
 'tynwald': ('Wikipedia: Tynwald', W+'Tynwald'),
 'iom': ('Wikipedia: Isle of Man', W+'Isle_of_Man'),
 'anguilla': ('Wikipedia: Anguilla', W+'Anguilla'),
 'maho': ('Wikipedia: Maho Beach', W+'Maho_Beach'),
 'sxm': ('Wikipedia: Sint Maarten', W+'Sint_Maarten'),
 'mf': ('Wikipedia: Collectivity of Saint Martin', W+'Collectivity_of_Saint_Martin'),
 'mont-orgueil': ('Wikipedia: Mont Orgueil', W+'Mont_Orgueil'),
 'durrell': ('Wikipedia: Durrell Wildlife Conservation Trust', W+'Durrell_Wildlife_Conservation_Trust'),
 'hauteville': ('Maisons de Victor Hugo (Paris Musées): Hauteville House', 'https://www.maisonsvictorhugo.paris.fr/en/guernesey/house'),
 'castle-cornet': ('Wikipedia: Castle Cornet', W+'Castle_Cornet'),
 'nevis-museum': ('Wikipedia: Museum of Nevis History', W+'Museum_of_Nevis_History'),
 'liamuiga': ('Wikipedia: Mount Liamuiga', W+'Mount_Liamuiga'),
 'guinness-nobel': ('Guinness World Records: Most Nobel Prize laureates per capita', 'https://www.guinnessworldrecords.com/world-records/most-nobel-prize-laureates-per-capita'),
 'cayman-iguana': ('Visit Cayman Islands: blue iguana saved from extinction', 'https://www.visitcaymanislands.com/en-gb/ourcayman/news/2018/august/cayman-islands-conservation-milestone-reached-with'),
 'gouv-mc': ('Government of Monaco: François Grimaldi, also known as Malizia', 'https://en.gouv.mc/Government-Institutions/History-and-Heritage/Personalities/Francois-Grimaldi-also-known-as-Malizia'),
 'oceano-mc': ('Wikipedia: Oceanographic Museum of Monaco', W+'Oceanographic_Museum_of_Monaco'),
 'lux-city': ('Wikipedia: Luxembourg City', W+'Luxembourg_City'),
 'schengen': ('Wikipedia: Schengen Agreement', W+'Schengen_Agreement'),
 'cjeu': ('Wikipedia: Court of Justice of the European Union', W+'Court_of_Justice_of_the_European_Union'),
 'vianden': ('Wikipedia: Vianden Castle', W+'Vianden_Castle'),
 'skype': ('Wikipedia: Skype', W+'Skype'),
 'kaali': ('Wikipedia: Kaali crater', W+'Kaali_crater'),
 'ee-song': ('Wikipedia: Estonian Song Festival', W+'Estonian_Song_Festival'),
 'tallinn': ('Wikipedia: Tallinn Old Town', W+'Tallinn_Old_Town'),
 'lahemaa': ('Wikipedia: Lahemaa National Park', W+'Lahemaa_National_Park'),
 'riga-market': ('Wikipedia: Riga Central Market', W+'Riga_Central_Market'),
 'riga-freedom': ('Wikipedia: Freedom Monument (Riga)', W+'Freedom_Monument_(Riga)'),
 'riga-centre': ('Wikipedia: Historic Centre of Riga', W+'Historic_Centre_of_Riga'),
 'curonian': ('Wikipedia: Curonian Spit', W+'Curonian_Spit'),
 'kernave': ('Wikipedia: Kernavė', W+'Kernav%C4%97'),
 'baltic-way': ('Wikipedia: Baltic Way', W+'Baltic_Way'),
 'cepelinai': ('Wikipedia: Cepelinai', W+'Cepelinai'),
 'troodos': ('Wikipedia: Painted Churches in the Troodos Region', W+'Painted_Churches_in_the_Troodos_Region'),
 'choirokoitia': ('Wikipedia: Choirokoitia', W+'Choirokoitia'),
 'lefkara': ('Wikipedia: Lefkara lace', W+'Lefkara_lace'),
 'halloumi': ('Wikipedia: Halloumi', W+'Halloumi'),
 'paphos-tombs': ('Wikipedia: Tombs of the Kings (Paphos)', W+'Tombs_of_the_Kings_(Paphos)'),
 'valletta': ('Wikipedia: Valletta', W+'Valletta'),
 'hypogeum': ('Wikipedia: Ħal Saflieni Hypogeum', W+'%C4%A6al_Saflieni_Hypogeum'),
 'george-cross': ('Wikipedia: George Cross', W+'George_Cross'),
 'azure-window': ('Wikipedia: Azure Window', W+'Azure_Window'),
 'maltese': ('Wikipedia: Maltese language', W+'Maltese_language'),
 'durmitor': ('Wikipedia: Durmitor', W+'Durmitor'),
 'ostrog': ('Wikipedia: Ostrog Monastery', W+'Ostrog_Monastery'),
 'skadar': ('Wikipedia: Lake Skadar', W+'Lake_Skadar'),
 'skocjan': ('Wikipedia: Škocjan Caves', W+'%C5%A0kocjan_Caves'),
 'idrija': ('Wikipedia: Idrija', W+'Idrija'),
 'plecnik': ('Wikipedia: Jože Plečnik', W+'Jo%C5%BEe_Ple%C4%8Dnik'),
 'bled': ('Wikipedia: Lake Bled', W+'Lake_Bled'),
 'triglav': ('Wikipedia: Triglav', W+'Triglav'),
 'pile-dwellings': ('Wikipedia: Prehistoric Pile dwellings around the Alps', W+'Prehistoric_Pile_dwellings_around_the_Alps'),
 'brest': ('Wikipedia: Brest Fortress', W+'Brest_Fortress'),
 'sistine': ('Wikipedia: Sistine Chapel ceiling', W+'Sistine_Chapel_ceiling'),
 'swiss-guard': ('Wikipedia: Pontifical Swiss Guard', W+'Pontifical_Swiss_Guard'),
 'madriu': ('Wikipedia: Madriu-Perafita-Claror Valley', W+'Madriu-Perafita-Claror_Valley'),
 'co-princes': ('Wikipedia: Co-princes of Andorra', W+'Co-princes_of_Andorra'),
 'tinganes': ('Wikipedia: Tinganes', W+'Tinganes'),
 'mykines': ('Wikipedia: Mykines', W+'Mykines,_Faroe_Islands'),
 'faroe': ('Wikipedia: Faroe Islands', W+'Faroe_Islands'),
 'aland': ('Wikipedia: Åland', W+'%C3%85land'),
 'kastelholm': ('Wikipedia: Kastelholm Castle', W+'Kastelholm_Castle'),
 'pommern': ('Wikipedia: Pommern (ship)', W+'Pommern_(ship)'),
 'dobsina': ('Wikipedia: Dobšiná Ice Cave', W+'Dob%C5%A1in%C3%A1_Ice_Cave'),
 'vlkolinec': ('Wikipedia: Vlkolínec', W+'Vlkol%C3%ADnec'),
 'hortobagy': ('Wikipedia: Hortobágy National Park', W+'Hortob%C3%A1gy_National_Park'),
 'tokaj': ('Wikipedia: Tokaj wine region', W+'Tokaj_wine_region'),
 'rubik': ('Wikipedia: Rubik\'s Cube', W+'Rubik%27s_Cube'),
 'pannonhalma': ('Wikipedia: Pannonhalma Archabbey', W+'Pannonhalma_Archabbey'),
 'rila': ('Wikipedia: Rila Monastery', W+'Rila_Monastery'),
 'madara': ('Wikipedia: Madara Rider', W+'Madara_Rider'),
 'boyana': ('Wikipedia: Boyana Church', W+'Boyana_Church'),
 'be-beer': ('Wikipedia: Beer in Belgium', W+'Beer_in_Belgium'),
 'plantin': ('Wikipedia: Plantin-Moretus Museum', W+'Plantin-Moretus_Museum'),
 'sax': ('Wikipedia: Adolphe Sax', W+'Adolphe_Sax'),
 'nelson-dockyard': ('Wikipedia: Nelson\'s Dockyard', W+'Nelson%27s_Dockyard'),
 'bridgetown': ('Wikipedia: Bridgetown', W+'Bridgetown'),
 'harrison': ('Wikipedia: Harrison\'s Cave', W+'Harrison%27s_Cave'),
 'crop-over': ('Wikipedia: Crop Over', W+'Crop_Over'),
 'junkanoo': ('Wikipedia: Junkanoo', W+'Junkanoo'),
 'fort-charlotte': ('Wikipedia: Fort Charlotte (Nassau)', W+'Fort_Charlotte_(Nassau)'),
 'gibbs-hill': ('Wikipedia: Gibbs Hill Lighthouse', W+'Gibbs_Hill_Lighthouse'),
 'bermuda': ('Wikipedia: Bermuda', W+'Bermuda'),
 'belize-reef': ('Wikipedia: Belize Barrier Reef', W+'Belize_Barrier_Reef'),
 'cockscomb': ('Wikipedia: Cockscomb Basin Wildlife Sanctuary', W+'Cockscomb_Basin_Wildlife_Sanctuary'),
 'morne-trois': ('Wikipedia: Morne Trois Pitons National Park', W+'Morne_Trois_Pitons_National_Park'),
 'kalinago': ('Wikipedia: Kalinago Territory', W+'Kalinago_Territory'),
 'sisserou': ('Wikipedia: Imperial amazon', W+'Imperial_amazon'),
 'grenada': ('Wikipedia: Grenada', W+'Grenada'),
 'steelpan': ('Wikipedia: Steelpan', W+'Steelpan'),
 'caroni': ('Wikipedia: Caroni Swamp', W+'Caroni_Swamp'),
 'blue-mtn-coffee': ('Wikipedia: Blue Mountain coffee', W+'Blue_Mountain_coffee'),
 'bjc': ('Wikipedia: Blue and John Crow Mountains National Park', W+'Blue_and_John_Crow_Mountains_National_Park'),
 'port-royal': ('Wikipedia: Port Royal', W+'Port_Royal'),
 'merengue': ('Wikipedia: Merengue music', W+'Merengue_music'),
 'enriquillo': ('Wikipedia: Lake Enriquillo', W+'Lake_Enriquillo'),
 'fortaleza': ('Wikipedia: La Fortaleza', W+'La_Fortaleza'),
 'arecibo': ('Wikipedia: Arecibo Observatory', W+'Arecibo_Observatory'),
 'willemstad': ('Wikipedia: Willemstad', W+'Willemstad'),
 'bonaire': ('Wikipedia: Bonaire', W+'Bonaire'),
 'scenery': ('Wikipedia: Mount Scenery', W+'Mount_Scenery'),
 'pelee': ('Wikipedia: 1902 eruption of Mount Pelée', W+'1902_eruption_of_Mount_Pel%C3%A9e'),
 'soufriere-hills': ('Wikipedia: Soufrière Hills', W+'Soufri%C3%A8re_Hills'),
 'gustavia': ('Wikipedia: Gustavia, Saint Barthélemy', W+'Gustavia,_Saint_Barth%C3%A9lemy'),
 'spm': ('Wikipedia: Saint Pierre and Miquelon', W+'Saint_Pierre_and_Miquelon'),
 'conch-bar': ('Wikipedia: Conch Bar Caves', W+'Conch_Bar_Caves'),
 'falklands': ('Wikipedia: Falkland Islands', W+'Falkland_Islands'),
 'candombe': ('Wikipedia: Candombe', W+'Candombe'),
 'colonia': ('Wikipedia: Colonia del Sacramento', W+'Colonia_del_Sacramento'),
 'fray-bentos': ('Wikipedia: Fray Bentos', W+'Fray_Bentos'),
 'cocos': ('Wikipedia: Cocos Island', W+'Cocos_Island'),
 'spheres': ('Wikipedia: Stone spheres of Costa Rica', W+'Stone_spheres_of_Costa_Rica'),
 'coiba': ('Wikipedia: Coiba National Park', W+'Coiba_National_Park'),
 'panama-viejo': ('Wikipedia: Panamá Viejo', W+'Panam%C3%A1_Viejo'),
 'quito': ('Wikipedia: Quito', W+'Quito'),
 'panama-hat': ('Wikipedia: Panama hat', W+'Panama_hat'),
 'joya': ('Wikipedia: Joya de Cerén', W+'Joya_de_Cer%C3%A9n'),
 'pupusa': ('Wikipedia: Pupusa', W+'Pupusa'),
 'guarani': ('Wikipedia: Guaraní language', W+'Guaran%C3%AD_language'),
 'antigua-gt': ('Wikipedia: Antigua Guatemala', W+'Antigua_Guatemala'),
 'co-coffee': ('Wikipedia: Coffee Cultural Landscape of Colombia', W+'Coffee_Cultural_Landscape_of_Colombia'),
 'aruba': ('Wikipedia: Aruba', W+'Aruba'),
 'guadeloupe': ('Wikipedia: Guadeloupe', W+'Guadeloupe'),
}

R = []  # (iso, kind, id, name_en, name_ru, rel_en, rel_ru, src)
def I(*a): R.append(a)

# ---------------- Europe ----------------
I('LI','fact','liechtenstein-womens-suffrage-1984',
  "Women's suffrage approved by an all-male referendum in 1984",
  "Избирательное право женщин, одобренное на референдуме 1984 года",
  "On 1 July 1984 Liechtenstein's male voters approved women's right to vote in national elections by 2,370 votes to 2,251.",
  "1 июля 1984 года мужчины-избиратели Лихтенштейна одобрили избирательное право женщин на национальных выборах: 2370 голосов против 2251.",'li-suffrage')
I('LI','fact','liechtenstein-army-abolished-1868',
  "Army abolished in 1868",
  "Упразднение армии в 1868 году",
  "The Liechtenstein Army was abolished for financial reasons in February 1868.",
  "Армия Лихтенштейна была упразднена в феврале 1868 года из-за финансовых затруднений.",'liechtenstein')
I('LI','fact','liechtenstein-swiss-customs-treaty-1923',
  "Customs treaty with Switzerland of 1923",
  "Таможенный договор со Швейцарией 1923 года",
  "A treaty signed on 29 March 1923 brought Liechtenstein into the Swiss customs area, and the common economic space took effect on 1 January 1924.",
  "Договор, подписанный 29 марта 1923 года, включил Лихтенштейн в таможенную зону Швейцарии, а общее экономическое пространство начало действовать 1 января 1924 года.",'li-customs')
I('LI','landmark','vaduz-castle',
  "Vaduz Castle",
  "Замок Вадуц",
  "Castle overlooking the capital that is the home of the Prince of Liechtenstein.",
  "Замок над столицей, в котором живёт князь Лихтенштейна.",'liechtenstein')

I('SM','fact','san-marino-captains-regent',
  "Two Captains Regent elected every six months",
  "Два капитана-регента, избираемые каждые полгода",
  "The first two captains regent were nominated in 1243, and the council still elects two heads of state every six months.",
  "Первые два капитана-регента были назначены в 1243 году, и по сей день совет избирает двух глав государства каждые шесть месяцев.",'san-marino')
I('SM','landmark','san-marino-historic-centre-mount-titano',
  "Historic Centre of San Marino and Mount Titano",
  "Исторический центр Сан-Марино и гора Монте-Титано",
  "A 55-hectare World Heritage Site inscribed in 2008 that includes the Guaita, Cesta and Montale towers and the market town of Borgo Maggiore.",
  "Объект Всемирного наследия площадью 55 гектаров, внесённый в список в 2008 году: он включает башни Гуаита, Честа и Монтале и торговый городок Борго-Маджоре.",'whc-1245')
I('SM','fact','san-marino-statutes-of-1600',
  "Statutes of 1600",
  "Статуты 1600 года",
  "The Statutes of 8 October 1600 are still at the core of the republic's constitutional framework.",
  "Статуты от 8 октября 1600 года до сих пор лежат в основе конституционного устройства республики.",'san-marino')
I('SM','fact','san-marino-death-penalty-abolished-1865',
  "Death penalty abolished in 1865",
  "Отмена смертной казни в 1865 году",
  "San Marino abolished the death penalty in 1865, after it had gone unused since the 1400s.",
  "Сан-Марино отменило смертную казнь в 1865 году, хотя к ней не прибегали с XV века.",'san-marino')

I('MD','fact','cricova-underground-wine-city',
  "Cricova underground wine city",
  "Подземный винный город Крикова",
  "Most of the Cricova winery's facilities lie 60 to 80 metres underground, forming a network of avenues and streets.",
  "Основные помещения винодельни Крикова расположены на глубине 60–80 метров и образуют сеть подземных проспектов и улиц.",'cricova')
I('MD','landmark','orheiul-vechi-cave-monastery',
  "Orheiul Vechi cave monastery",
  "Пещерный монастырь Старый Орхей",
  "Cave churches and an Orthodox monastery near Trebujeni, about 60 km north-east of Chișinău on the Răut River.",
  "Пещерные церкви и православный монастырь близ села Требужень, примерно в 60 км к северо-востоку от Кишинёва на реке Реут.",'orhei')
I('MD','fact','martisor-spring-charm-tradition',
  "Mărțișor red-and-white spring charm",
  "Мэрцишор — красно-белый весенний оберег",
  "Two intertwined red and white strings with tassels are worn from 1 March, a tradition practised in Moldova and Romania and listed by UNESCO as intangible heritage.",
  "Витой красно-белый шнурок с кисточками носят с 1 марта; эта традиция распространена в Молдове и Румынии и внесена ЮНЕСКО в список нематериального наследия.",'martisor')
I('MD','fact','struve-geodetic-arc-moldova',
  "Struve Geodetic Arc survey points",
  "Геодезическая дуга Струве: пункты триангуляции",
  "Moldova is one of ten countries sharing the Struve Geodetic Arc, a chain of survey points over 2,820 km long that was inscribed on the World Heritage List in 2005.",
  "Молдова — одна из десяти стран, через которые проходит геодезическая дуга Струве: цепь пунктов длиной более 2820 км, внесённая в список Всемирного наследия в 2005 году.",'struve')

I('GI','landmark','gorhams-cave-complex',
  "Gorham's Cave Complex",
  "Пещерный комплекс Горама",
  "Cave complex with evidence of Neanderthal habitation, inscribed on the World Heritage List on 15 July 2016 as Gibraltar's only World Heritage site.",
  "Пещерный комплекс со следами обитания неандертальцев, внесённый в список Всемирного наследия 15 июля 2016 года как единственный объект Гибралтара.",'gorham')
I('GI','fact','winston-churchill-avenue-runway-crossing',
  "Winston Churchill Avenue runway crossing",
  "Пересечение взлётной полосы улицей Уинстона Черчилля",
  "Until the new Kingsway route opened on 31 March 2023, the main road towards the Spanish border crossed the airport runway and closed whenever aircraft took off or landed.",
  "До открытия нового маршрута Кингсуэй 31 марта 2023 года главная дорога к испанской границе пересекала взлётную полосу аэропорта и перекрывалась при каждом взлёте и посадке самолётов.",'gib-airport')
I('GI','fact','mons-calpe-pillar-of-hercules',
  "Mons Calpe, one of the Pillars of Hercules",
  "Монс-Кальпе — одна из Геркулесовых колонн",
  "The ancient Greeks and Romans considered the 426-metre Rock of Gibraltar, Mons Calpe, to be one of the Pillars of Hercules.",
  "Древние греки и римляне считали Гибралтарскую скалу высотой 426 метров, Монс-Кальпе, одной из Геркулесовых колонн.",'gibraltar')

I('IM','fact','isle-of-man-tt-races-1907',
  "Isle of Man TT motorcycle races",
  "Мотогонки «Тур Айл-оф-Мэн» (TT)",
  "The first TT race was held on 28 May 1907, and the modern Mountain Course is a 37.73-mile (60.72 km) circuit of public roads.",
  "Первая гонка TT прошла 28 мая 1907 года, а современная трасса Маунтин-Курс — это кольцо длиной 60,72 км (37,73 мили) по дорогам общего пользования.",'iom-tt')
I('IM','landmark','laxey-wheel',
  "Laxey Wheel (Lady Isabella)",
  "Колесо Лакси («Леди Изабелла»)",
  "Built in 1854 to pump water from the Great Laxey Mines, this 22.1-metre waterwheel is described as the largest surviving original working waterwheel in the world.",
  "Построенное в 1854 году для откачки воды из рудников Грейт-Лакси водяное колесо диаметром 22,1 метра называют самым большим из сохранившихся действующих оригинальных водяных колёс в мире.",'laxey')
I('IM','fact','tynwald-day-laws-in-manx-and-english',
  "Tynwald Day and laws promulgated in Manx and English",
  "День Тинвальда и обнародование законов на мэнском и английском",
  "Tynwald meets annually on Tynwald Day, usually 5 July, and all laws are promulgated at St John's in both Manx and English.",
  "Тинвальд собирается ежегодно в День Тинвальда, обычно 5 июля, и все законы обнародуются в Сент-Джонсе на мэнском и английском языках.",'tynwald')
I('IM','fact','isle-of-man-unesco-biosphere-reserve',
  "UNESCO biosphere reserve status",
  "Статус биосферного заповедника ЮНЕСКО",
  "In 2016 UNESCO awarded the Isle of Man biosphere reserve status.",
  "В 2016 году ЮНЕСКО присвоило острову Мэн статус биосферного заповедника.",'iom')

I('AI','fact','anguilla-boat-racing-national-sport',
  "Boat racing as the national sport",
  "Гонки на лодках как национальный вид спорта",
  "Boat racing has deep roots in Anguillan culture and is the national sport.",
  "Гонки на лодках глубоко укоренились в культуре Ангильи и считаются национальным видом спорта.",'anguilla')
I('AI','landmark','wallblake-house',
  "Wallblake House",
  "Усадьба Уоллблейк",
  "Plantation house thought to be the oldest building on Anguilla.",
  "Дом на бывшей плантации, который считается старейшим зданием Ангильи.",'anguilla')
I('AI','fact','fountain-cavern-petroglyphs',
  "Fountain Cavern petroglyphs",
  "Петроглифы пещеры Фаунтин",
  "Fountain Cavern is one of the two known petroglyph sites on Anguilla, alongside Big Spring.",
  "Пещера Фаунтин — одно из двух известных мест с петроглифами на Ангилье, наряду с Биг-Спринг.",'anguilla')
I('AI','fact','anguilla-name-means-eel',
  "Island name meaning 'eel'",
  "Название острова, означающее «угорь»",
  "The island's name comes from the Italian word anguilla, 'eel', a reference to its long, thin shape.",
  "Название острова происходит от итальянского слова anguilla, «угорь», и отсылает к его вытянутой форме.",'anguilla')
I('AI','fact','anguilla-1967-ejection-of-st-kitts-police',
  "1967 expulsion of the Saint Kitts police",
  "Изгнание полиции Сент-Китса в 1967 году",
  "In 1967 Anguillans forcibly ejected the Saint Kitts police from the island in a bid to separate from Saint Kitts and Nevis.",
  "В 1967 году жители Ангильи силой выдворили с острова полицию Сент-Китса, стремясь отделиться от Сент-Китса и Невиса.",'anguilla')

I('SX','landmark','maho-beach',
  "Maho Beach",
  "Пляж Махо",
  "Beach next to Princess Juliana International Airport, where aircraft on final approach fly less than 100 feet (30 m) overhead.",
  "Пляж рядом с международным аэропортом Принцессы Юлианы: заходящие на посадку самолёты пролетают над ним ниже 30 метров (100 футов).",'maho')
I('SX','landmark','fort-amsterdam-sint-maarten',
  "Fort Amsterdam",
  "Форт Амстердам",
  "The Dutch built Fort Amsterdam on the island in 1631.",
  "Форт Амстердам голландцы построили на острове в 1631 году.",'sxm')
I('SX','fact','sint-maarten-constituent-country-2010',
  "Constituent country since 10 October 2010",
  "Статус автономной страны с 10 октября 2010 года",
  "On 10 October 2010 Sint Maarten became a constituent country of the Kingdom of the Netherlands.",
  "10 октября 2010 года Синт-Мартен стал автономной страной в составе Королевства Нидерландов.",'sxm')
I('SX','landmark','mount-flagstaff-sint-maarten',
  "Mount Flagstaff",
  "Гора Флагстафф",
  "The highest peak of Sint Maarten, rising 383 metres on the Dutch side of the island.",
  "Высшая точка Синт-Мартена: гора высотой 383 метра на нидерландской части острова.",'sxm')

I('MF','fact','treaty-of-concordia-1648',
  "Treaty of Concordia",
  "Договор Конкордия",
  "The treaty of 23 March 1648 divided the island of Saint Martin between France and the Netherlands.",
  "Договор от 23 марта 1648 года разделил остров Сен-Мартен между Францией и Нидерландами.",'mf')
I('MF','landmark','pic-paradis',
  "Pic Paradis",
  "Пик Парадиз",
  "At 424 metres, it is the highest peak on the island of Saint Martin as a whole.",
  "Высотой 424 метра, это высочайшая вершина острова Сен-Мартен.",'mf')
I('MF','fact','saint-martin-collectivity-2007',
  "Separation from Guadeloupe in 2007",
  "Выход из состава Гваделупы в 2007 году",
  "Before 2007 the French part of the island was a commune of Guadeloupe; it was then detached and became a territorial collectivity.",
  "До 2007 года французская часть острова была коммуной Гваделупы, а затем была выделена в отдельное заморское сообщество.",'mf')

I('JE','landmark','mont-orgueil-castle',
  "Mont Orgueil Castle",
  "Замок Мон-Оргей",
  "Castle at Gorey begun after King John lost Normandy in 1204 and the island's main fortress until Elizabeth Castle was built in 1594.",
  "Замок в Горе, заложенный после потери Нормандии королём Иоанном в 1204 году и остававшийся главной крепостью острова до постройки замка Елизаветы в 1594 году.",'mont-orgueil')
I('JE','fact','jersey-zoo-gerald-durrell',
  "Jersey Zoo founded by Gerald Durrell",
  "Зоопарк Джерси, основанный Джеральдом Даррелом",
  "Gerald Durrell founded Jersey Zoo in 1959 in the grounds of Les Augrès Manor in Trinity.",
  "Джеральд Даррелл основал зоопарк Джерси в 1959 году на территории поместья Ле-Огре в приходе Тринити.",'durrell')

I('GG','landmark','hauteville-house',
  "Hauteville House",
  "Отвиль-Хаус",
  "Victor Hugo bought this house in St Peter Port on 16 May 1856 during his exile, and it is now a City of Paris museum.",
  "Виктор Гюго купил этот дом в Сент-Питер-Порте 16 мая 1856 года в годы изгнания; сегодня это музей, принадлежащий городу Парижу.",'hauteville')
I('GG','landmark','castle-cornet',
  "Castle Cornet",
  "Замок Корнет",
  "Castle on a former tidal islet guarding St Peter Port harbour that was the last Royalist stronghold to surrender in the English Civil War, in 1651.",
  "Замок на бывшем приливном островке, охраняющий гавань Сент-Питер-Порта; в 1651 году он последним из оплотов роялистов сдался в ходе Английской гражданской войны.",'castle-cornet')

I('KN','fact','alexander-hamilton-birthplace-nevis',
  "Alexander Hamilton's birthplace in Charlestown",
  "Место рождения Александра Гамильтона в Чарлстауне",
  "The Museum of Nevis History in Charlestown stands on the foundation of the building where US Founding Father Alexander Hamilton was born.",
  "Музей истории Невиса в Чарлстауне стоит на фундаменте здания, где родился один из «отцов-основателей» США Александр Гамильтон.",'nevis-museum')
I('KN','landmark','mount-liamuiga',
  "Mount Liamuiga",
  "Вулкан Лиамуйга",
  "A 1,156-metre stratovolcano in north-western Saint Kitts and the highest point of Saint Kitts and Nevis.",
  "Стратовулкан высотой 1156 метров на северо-западе Сент-Китса, высшая точка Сент-Китса и Невиса.",'liamuiga')

I('LC','fact','saint-lucia-two-nobel-laureates',
  "Two Nobel laureates: Arthur Lewis and Derek Walcott",
  "Два нобелевских лауреата: Артур Льюис и Дерек Уолкотт",
  "Sir Arthur Lewis won the 1979 Nobel Prize in Economics and Sir Derek Walcott the 1992 Nobel Prize in Literature.",
  "Сэр Артур Льюис получил Нобелевскую премию по экономике 1979 года, а сэр Дерек Уолкотт — Нобелевскую премию по литературе 1992 года.",'guinness-nobel')

I('KY','fact','blue-iguana-recovery-programme',
  "Blue iguana recovery programme",
  "Программа спасения голубой игуаны",
  "The blue iguana was functionally extinct in the wild in 2005 with only about ten animals left, and its 1,000th captive-bred iguana was released in August 2018.",
  "В 2005 году голубая игуана была функционально вымершей в дикой природе, оставалось около десяти особей, а в августе 2018 года на волю выпустили тысячную особь, выращенную в неволе.",'cayman-iguana')

I('MC','fact','grimaldi-1297-monk-disguise',
  "Grimaldi capture of the Rock in 1297",
  "Захват Скалы Гримальди в 1297 году",
  "According to tradition, on 8 January 1297 François Grimaldi, disguised as a Franciscan monk, took the fortress on the Rock of Monaco, beginning the Grimaldi dynasty.",
  "По преданию, 8 января 1297 года Франсуа Гримальди, переодетый францисканским монахом, захватил крепость на Скале Монако, положив начало династии Гримальди.",'gouv-mc')
I('MC','landmark','oceanographic-museum-monaco',
  "Oceanographic Museum of Monaco",
  "Океанографический музей Монако",
  "Museum inaugurated in 1910 by Prince Albert I and directed by Jacques-Yves Cousteau from 1957 to 1988.",
  "Музей, открытый в 1910 году князем Альбертом I; с 1957 по 1988 год его возглавлял Жак-Ив Кусто.",'oceano-mc')

I('LU','landmark','luxembourg-city-old-quarters-fortifications',
  "City of Luxembourg: its Old Quarters and Fortifications",
  "Город Люксембург: старые кварталы и укрепления",
  "UNESCO World Heritage Site where Spain began building 23 km of casemate tunnels in 1644.",
  "Объект Всемирного наследия ЮНЕСКО, где в 1644 году испанцы начали строить 23 км казематных туннелей.",'lux-city')
I('LU','fact','schengen-agreement-signed-on-the-moselle',
  "Schengen Agreement signed on the Moselle",
  "Шенгенское соглашение, подписанное на Мозеле",
  "Five countries signed the agreement on 14 June 1985 aboard the MS Princesse Marie-Astrid on the Moselle near Schengen.",
  "Пять стран подписали соглашение 14 июня 1985 года на борту судна «Принцесса Мари-Астрид» на Мозеле близ Шенгена.",'schengen')
I('LU','fact','court-of-justice-of-the-eu-kirchberg',
  "Court of Justice of the European Union",
  "Суд Европейского союза",
  "The court, formed in 1952, has its seat at the Palais de la Cour de Justice in Kirchberg, Luxembourg City.",
  "Суд, образованный в 1952 году, заседает во Дворце правосудия в районе Кирхберг в городе Люксембург.",'cjeu')
I('LU','landmark','vianden-castle',
  "Vianden Castle",
  "Замок Вианден",
  "Castle above the River Our built in the Romanesque style from the 11th to 14th centuries and restored after Grand Duke Jean ceded it to the state in 1977.",
  "Замок над рекой Ур, возведённый в романском стиле в XI–XIV веках и восстановленный после того, как великий герцог Жан передал его государству в 1977 году.",'vianden')

I('EE','fact','skype-created-by-estonians',
  "Skype created by Estonian developers",
  "Skype, созданный эстонскими разработчиками",
  "The Skype software was created by Estonians Ahti Heinla, Priit Kasesalu, Jaan Tallinn and Toivo Annus and first released on 29 August 2003.",
  "Программу Skype создали эстонцы Ахти Хейнла, Прийт Касесалу, Яан Таллинн и Тойво Аннус; первая версия вышла 29 августа 2003 года.",'skype')
I('EE','landmark','kaali-meteorite-craters',
  "Kaali meteorite craters",
  "Метеоритные кратеры Каали",
  "A group of nine meteorite craters on the island of Saaremaa, the largest of them 110 metres across.",
  "Группа из девяти метеоритных кратеров на острове Сааремаа, самый большой из которых имеет диаметр 110 метров.",'kaali')
I('EE','fact','estonian-song-festival-laulupidu',
  "Estonian Song Festival (Laulupidu)",
  "Эстонский праздник песни (Лаулупидо)",
  "The first nationwide festival took place in Tartu in 1869; since 1928 it has been held at the Song Festival Grounds in Tallinn, and the Baltic tradition was inscribed by UNESCO in 2008.",
  "Первый общеэстонский праздник прошёл в Тарту в 1869 году; с 1928 года он проводится на Певческом поле в Таллине, а балтийская традиция внесена в список ЮНЕСКО в 2008 году.",'ee-song')
I('EE','landmark','tallinn-old-town',
  "Old Town of Tallinn",
  "Старый город Таллина",
  "Registered on the UNESCO World Heritage List in 1997, it has wholly preserved its structure of medieval and Hanseatic origin.",
  "Внесён в список Всемирного наследия ЮНЕСКО в 1997 году и полностью сохранил планировку средневекового и ганзейского происхождения.",'tallinn')
I('EE','landmark','lahemaa-national-park',
  "Lahemaa National Park",
  "Национальный парк Лахемаа",
  "Established in 1971 as the first national park of the former Soviet Union, it covers 747 km² including 274.9 km² of sea.",
  "Основанный в 1971 году как первый национальный парк бывшего Советского Союза, он занимает 747 км², из них 274,9 км² — морская акватория.",'lahemaa')

I('LV','fact','riga-central-market-zeppelin-hangars',
  "Riga Central Market in Zeppelin hangars",
  "Центральный рынок Риги в ангарах для цеппелинов",
  "Five of the market's pavilions were built by reusing German Zeppelin hangars, and retail sales began in 1930.",
  "Пять павильонов рынка построены из переоборудованных немецких ангаров для цеппелинов, а розничная торговля началась в 1930 году.",'riga-market')
I('LV','landmark','freedom-monument-riga',
  "Freedom Monument in Riga",
  "Памятник Свободы в Риге",
  "The 42-metre monument unveiled in 1935 is topped by the figure Milda holding three gilded stars for Vidzeme, Latgale and Courland.",
  "Памятник высотой 42 метра, открытый в 1935 году, венчает фигура Милды с тремя позолоченными звёздами — Видземе, Латгале и Курземе.",'riga-freedom')
I('LV','landmark','historic-centre-of-riga-art-nouveau',
  "Historic Centre of Riga",
  "Исторический центр Риги",
  "Designated a World Heritage Site in 1997 and known for Art Nouveau buildings, especially those by architect Mikhail Eisenstein.",
  "Внесён в список Всемирного наследия в 1997 году; известен зданиями в стиле модерн, особенно построенными архитектором Михаилом Эйзенштейном.",'riga-centre')

I('LT','landmark','curonian-spit',
  "Curonian Spit",
  "Куршская коса",
  "A 98-km sand-dune spit shared with Russia and a World Heritage Site since 2000; Parnidis Dune near Nida rises about 52 metres.",
  "Песчаная коса длиной 98 км, разделённая с Россией и входящая в список Всемирного наследия с 2000 года; дюна Парнидис близ Нидды поднимается примерно на 52 метра.",'curonian')
I('LT','landmark','kernave-archaeological-site',
  "Kernavė Archaeological Site",
  "Археологический памятник Кернаве",
  "Medieval capital of the Grand Duchy of Lithuania with hillforts, included in the UNESCO World Heritage List in 2004.",
  "Средневековая столица Великого княжества Литовского с городищами, внесённая в список Всемирного наследия ЮНЕСКО в 2004 году.",'kernave')
I('LT','fact','baltic-way-human-chain-1989',
  "Baltic Way human chain",
  "Живая цепь «Балтийский путь»",
  "On 23 August 1989 about two million people formed a 675-km human chain linking Vilnius, Riga and Tallinn; its records joined UNESCO's Memory of the World Register in 2009.",
  "23 августа 1989 года около двух миллионов человек образовали живую цепь длиной 675 км, соединившую Вильнюс, Ригу и Таллин; документы о ней включены в реестр ЮНЕСКО «Память мира» в 2009 году.",'baltic-way')
I('LT','food','cepelinai',
  "Cepelinai",
  "Цепелинай",
  "Potato dumplings stuffed with ground meat, named for their resemblance to Zeppelin airships and described as a national dish of Lithuania.",
  "Картофельные клёцки с мясной начинкой, названные так за сходство с дирижаблями-цеппелинами; их называют национальным блюдом Литвы.",'cepelinai')

I('CY','landmark','painted-churches-troodos',
  "Painted Churches in the Troodos Region",
  "Расписные церкви региона Троодос",
  "Ten Byzantine churches and monasteries with murals; nine were designated by UNESCO in 1985 and the church of Palaichori was added in 2001.",
  "Десять византийских церквей и монастырей с росписями; девять из них признаны ЮНЕСКО в 1985 году, а церковь в Палайхори добавлена в 2001 году.",'troodos')
I('CY','landmark','choirokoitia-neolithic-settlement',
  "Choirokoitia Neolithic settlement",
  "Неолитическое поселение Хирокития",
  "Settlement of round houses called tholoi founded around 7000 BC and listed as a World Heritage Site since 1998.",
  "Поселение из круглых домов — толосов, основанное около 7000 года до н. э. и включённое в список Всемирного наследия в 1998 году.",'choirokoitia')
I('CY','fact','lefkara-lace',
  "Lefkara lace",
  "Кружево Лефкара",
  "Handmade lace from Pano and Kato Lefkara that was added to UNESCO's Representative List of the Intangible Cultural Heritage in 2009.",
  "Кружево ручной работы из Пано-Лефкары и Като-Лефкары, добавленное в Репрезентативный список нематериального культурного наследия ЮНЕСКО в 2009 году.",'lefkara')
I('CY','food','halloumi',
  "Halloumi cheese",
  "Сыр халлуми",
  "Cheese traditionally made from goat and sheep milk that can be fried or grilled without melting and is protected in the EU as a designation of origin.",
  "Сыр, традиционно изготавливаемый из козьего и овечьего молока, который можно жарить и готовить на гриле без расплавления; в ЕС защищён как наименование места происхождения.",'halloumi')
I('CY','landmark','tombs-of-the-kings-paphos',
  "Tombs of the Kings at Paphos",
  "Гробницы царей в Пафосе",
  "Underground tombs carved out of solid rock from the 4th century BC; despite the name, no kings were buried there.",
  "Подземные гробницы, высеченные в монолитной скале начиная с IV века до н. э.; вопреки названию, царей здесь не хоронили.",'paphos-tombs')

I('MT','landmark','valletta-founded-1566',
  "Valletta",
  "Валлетта",
  "Grand Master Jean de Valette laid the city's foundation stone on 28 March 1566; it became a World Heritage Site in 1980 and European Capital of Culture in 2018.",
  "Великий магистр Жан де Валетт заложил первый камень города 28 марта 1566 года; в 1980 году Валлетта попала в список Всемирного наследия, а в 2018 году стала культурной столицей Европы.",'valletta')
I('MT','landmark','hal-saflieni-hypogeum',
  "Ħal Saflieni Hypogeum",
  "Гипогей Хал-Сафлиени",
  "Neolithic underground structure of three levels hewn into limestone, dating to 3300–3000 BC and discovered by accident in 1902.",
  "Неолитическое подземное сооружение из трёх уровней, высеченных в известняке; оно относится к 3300–3000 годам до н. э. и было случайно обнаружено в 1902 году.",'hypogeum')
I('MT','fact','george-cross-awarded-to-malta',
  "George Cross awarded to the island of Malta",
  "Крест Георга, которым награждён остров Мальта",
  "King George VI awarded the George Cross to the Island Fortress of Malta in April 1942, and it was added to the Maltese flag in 1943.",
  "Король Георг VI наградил Крестом Георга остров-крепость Мальту в апреле 1942 года, а в 1943 году крест появился на флаге Мальты.",'george-cross')
I('MT','fact','azure-window-collapse-2017',
  "Azure Window on Gozo",
  "Лазурное окно на Гозо",
  "The 28-metre natural arch at Dwejra, used in Game of Thrones, collapsed on 8 March 2017 after heavy storms.",
  "Природная арка высотой 28 метров в бухте Двейра, снимавшаяся в «Игре престолов», рухнула 8 марта 2017 года после сильных штормов.",'azure-window')
I('MT','fact','maltese-language-semitic-latin-script',
  "Maltese, the Semitic language in Latin script",
  "Мальтийский — семитский язык на латинице",
  "Maltese descends from Siculo-Arabic, is the only Semitic language officially written in the Latin script and is the only official Semitic language of the European Union.",
  "Мальтийский язык происходит от сицилийско-арабского, это единственный семитский язык с официальной латинской письменностью и единственный официальный семитский язык Европейского союза.",'maltese')

I('ME','landmark','durmitor-national-park',
  "Durmitor National Park",
  "Национальный парк Дурмитор",
  "Inscribed on the World Heritage List in 1980, it has 18 glacial lakes, including the Black Lake, and its highest peak Bobotov Kuk reaches 2,523 metres.",
  "Внесён в список Всемирного наследия в 1980 году; в парке 18 ледниковых озёр, в том числе Чёрное озеро, а высшая вершина Бобов-Кук достигает 2523 метров.",'durmitor')
I('ME','landmark','ostrog-monastery',
  "Ostrog Monastery",
  "Монастырь Острог",
  "Monastery set against an almost vertical rock face and founded by St Basil of Ostrog in the early 17th century.",
  "Монастырь на почти отвесной скале, основанный святым Василием Острожским в начале XVII века.",'ostrog')
I('ME','fact','lake-skadar-border-lake',
  "Lake Skadar on the Montenegro-Albania border",
  "Скадарское озеро на границе Черногории и Албании",
  "The lake's surface fluctuates between 370 and 530 km² through the year, and its Montenegrin part became a national park in 1983.",
  "Площадь озера в течение года колеблется от 370 до 530 км², а его черногорская часть стала национальным парком в 1983 году.",'skadar')

I('SI','landmark','skocjan-caves',
  "Škocjan Caves",
  "Пещеры Шкоцьян",
  "Included on the UNESCO World Heritage List in 1986, the caves hold the underground course of the Reka River and Hanke's Channel, over 140 metres high.",
  "Внесены в список Всемирного наследия ЮНЕСКО в 1986 году; здесь под землёй течёт река Река, а канал Ханке достигает более 140 метров в высоту.",'skocjan')
I('SI','fact','idrija-mercury-heritage',
  "Idrija mercury mine",
  "Ртутный рудник Идрия",
  "Mercury was discovered in Idrija in the late 15th century, and the Heritage of Mercury site shared with Almadén has been on the World Heritage List since 2012.",
  "Ртуть в Идрии обнаружили в конце XV века, а объект «Наследие ртути» вместе с Альмаденом входит в список Всемирного наследия с 2012 года.",'idrija')
I('SI','landmark','plecnik-works-in-ljubljana',
  "Works of Jože Plečnik in Ljubljana",
  "Работы Йоже Плечника в Любляне",
  "Plečnik designed the Triple Bridge and the National and University Library, and selected works were inscribed on the World Heritage List in 2021.",
  "Плечник спроектировал Тройной мост и Национальную и университетскую библиотеку, а избранные его работы внесены в список Всемирного наследия в 2021 году.",'plecnik')
I('SI','landmark','bled-island-church',
  "Church on Bled Island",
  "Церковь на острове Блед",
  "The pilgrimage church of the Assumption of Mary is reached by 99 stone steps, and the traditional boat to the island is a wooden pletna.",
  "К паломнической церкви Успения Богородицы ведут 99 каменных ступеней, а на остров традиционно добираются на деревянной лодке плетна.",'bled')
I('SI','landmark','triglav-highest-peak',
  "Triglav",
  "Триглав",
  "The highest mountain of Slovenia and the Julian Alps appears on the country's coat of arms and flag, and its first recorded ascent was in 1778.",
  "Высочайшая гора Словении и Юлийских Альп изображена на гербе и флаге страны; первое зафиксированное восхождение на неё состоялось в 1778 году.",'triglav')
I('SI','fact','alpine-pile-dwellings-ig',
  "Prehistoric pile dwellings at Ig",
  "Доисторические свайные поселения у Ига",
  "Two of the 111 Alpine pile-dwelling sites on the 2011 World Heritage List lie at Ig and were the first Slovenian sites listed for their cultural value.",
  "Два из 111 альпийских свайных поселений, внесённых в список Всемирного наследия в 2011 году, находятся у Ига; это первые словенские объекты, признанные за культурную ценность.",'pile-dwellings')

I('BY','landmark','brest-hero-fortress',
  "Brest Hero-Fortress",
  "Брестская крепость-герой",
  "German forces attacked the fortress without warning on 22 June 1941, and it was given the title Hero Fortress in 1965.",
  "Немецкие войска атаковали крепость без предупреждения 22 июня 1941 года, а в 1965 году ей присвоили звание «Крепость-герой».",'brest')

I('VA','landmark','sistine-chapel-ceiling',
  "Sistine Chapel ceiling",
  "Плафон Сикстинской капеллы",
  "Michelangelo painted it in fresco between 1508 and 1512 for Pope Julius II, including nine scenes from the Book of Genesis.",
  "Микеланджело расписал его фресками в 1508–1512 годах по заказу папы Юлия II; на своде девять сцен из Книги Бытия.",'sistine')
I('VA','fact','pontifical-swiss-guard-1506',
  "Pontifical Swiss Guard",
  "Папская швейцарская гвардия",
  "Established in 1506 under Pope Julius II, the Guard lost 147 of its 189 members defending the Pope during the Sack of Rome on 6 May 1527.",
  "Основанная в 1506 году при папе Юлии II, гвардия потеряла 147 из 189 человек, защищая папу во время разграбления Рима 6 мая 1527 года.",'swiss-guard')

I('AD','landmark','madriu-perafita-claror-valley',
  "Madriu-Perafita-Claror Valley",
  "Долина Мадриу-Перафита-Клор",
  "A glacial valley covering about 9% of the country that became Andorra's only UNESCO World Heritage Site in 2004.",
  "Ледниковая долина площадью около 9% территории страны, ставшая единственным объектом Всемирного наследия ЮНЕСКО в Андорре в 2004 году.",'madriu')
I('AD','fact','andorra-co-princes',
  "Co-princes: the Bishop of Urgell and the President of France",
  "Совместные князья: епископ Урхельский и президент Франции",
  "The Bishop of Urgell and the President of France serve jointly as heads of state, a diarchy that dates to a treaty of 1278 and was confirmed by the 1993 constitution.",
  "Епископ Урхельский и президент Франции совместно исполняют обязанности глав государства; эта диархия восходит к договору 1278 года и закреплена конституцией 1993 года.",'co-princes')

I('FO','landmark','tinganes-torshavn',
  "Tinganes in Tórshavn",
  "Тингганес в Торсхавне",
  "Peninsula with turf-roofed old parliament buildings where the Faroese home-rule government still sits.",
  "Полуостров со старыми зданиями парламента под дерновыми крышами, где по сей день заседает правительство автономии Фарерских островов.",'tinganes')
I('FO','landmark','mykines-puffin-island',
  "Mykines",
  "Мюкинес",
  "The westernmost of the 18 main Faroese islands, home to large numbers of puffins and with a lighthouse built in 1909 on the islet of Mykineshólmur.",
  "Самый западный из 18 основных Фарерских островов; здесь гнездится множество тупиков, а на островке Мюкинесхоульмур в 1909 году построен маяк.",'mykines')
I('FO','fact','faroe-name-sheep-islands',
  "Name read as 'sheep islands'",
  "Название, которое толкуют как «овечьи острова»",
  "The most widely held theory reads Færeyjar as a compound of fær, 'sheep', and eyjar, 'islands'.",
  "Самая распространённая теория трактует название Færeyjar как соединение слов fær, «овца», и eyjar, «острова».",'faroe')

I('AX','fact','aland-demilitarised-1921',
  "Åland Convention of 1921",
  "Аландская конвенция 1921 года",
  "The convention of 20 October 1921 declared Åland neutral and demilitarised, and Swedish is its sole official language.",
  "Конвенция от 20 октября 1921 года объявила Аландские острова нейтральными и демилитаризованными, а единственным официальным языком там является шведский.",'aland')
I('AX','landmark','kastelholm-castle',
  "Kastelholm Castle",
  "Замок Кастельхольм",
  "Medieval castle in Sund built by the Swedes in the late 14th century and first mentioned in 1388.",
  "Средневековый замок в Сунде, построенный шведами в конце XIV века и впервые упомянутый в 1388 году.",'kastelholm')
I('AX','landmark','pommern-museum-ship',
  "Pommern",
  "Парусник «Поммерн»",
  "Four-masted steel barque built in Glasgow in 1903 and now a museum ship in Mariehamn.",
  "Стальной четырёхмачтовый барк, построенный в Глазго в 1903 году и ставший судном-музеем в Мариехамне.",'pommern')

I('SK','landmark','dobsina-ice-cave',
  "Dobšiná Ice Cave",
  "Добшинская ледяная пещера",
  "Ice cave near the mining town of Dobšiná discovered on 15 June 1870 by Jenő Ruffinyi and part of a UNESCO site shared with Aggtelek Karst.",
  "Ледяная пещера близ шахтёрского города Добшина, открытая 15 июня 1870 года Енё Руффини; входит в объект ЮНЕСКО, общий с карстом Аггтелек.",'dobsina')
I('SK','landmark','vlkolinec-log-village',
  "Vlkolínec",
  "Влколинец",
  "Remarkably intact settlement of more than 45 log houses that has been a UNESCO World Heritage Site since 1993.",
  "Удивительно хорошо сохранившееся поселение из более чем 45 бревенчатых домов, входящее в список Всемирного наследия ЮНЕСКО с 1993 года.",'vlkolinec')

I('HU','landmark','hortobagy-national-park',
  "Hortobágy National Park",
  "Национальный парк Хортобадь",
  "Designated in 1973 as Hungary's first national park, this grassy steppe with Hungarian Grey cattle was inscribed on the World Heritage List in 1999.",
  "Объявленная в 1973 году первым национальным парком Венгрии, эта травяная степь с венгерским серым скотом внесена в список Всемирного наследия в 1999 году.",'hortobagy')
I('HU','fact','tokaj-wine-region-unesco',
  "Tokaj Wine Region Historic Cultural Landscape",
  "Историко-культурный ландшафт винодельческого региона Токай",
  "Declared a World Heritage Site in 2002, Tokaj is the origin of Tokaji aszú wine.",
  "Объявлен объектом Всемирного наследия в 2002 году; Токай — родина вина токайи асу.",'tokaj')
I('HU','fact','rubiks-cube-invented-1974',
  "Rubik's Cube",
  "Кубик Рубика",
  "Hungarian sculptor and architecture professor Ernő Rubik invented the Magic Cube in 1974, and it was released internationally in 1980.",
  "Венгерский скульптор и преподаватель архитектуры Эрнё Рубик изобрёл «Волшебный куб» в 1974 году, а в 1980 году головоломка вышла на мировой рынок.",'rubik')
I('HU','landmark','pannonhalma-archabbey',
  "Pannonhalma Archabbey",
  "Архиабатство Паннонхальма",
  "Benedictine abbey founded in 996 by Prince Géza and inscribed on the World Heritage List in 1996.",
  "Бенедиктинское аббатство, основанное в 996 году князем Гезой и внесённое в список Всемирного наследия в 1996 году.",'pannonhalma')

I('BG','landmark','rila-monastery',
  "Rila Monastery",
  "Рильский монастырь",
  "Founded in the 10th century by the hermit St Ivan of Rila, it became a UNESCO World Heritage Site in 1983.",
  "Основан в X веке отшельником Иваном Рильским и в 1983 году включён в список Всемирного наследия ЮНЕСКО.",'rila')
I('BG','landmark','madara-rider',
  "Madara Rider",
  "Мадарский всадник",
  "Rock relief of a horseman spearing a lion, carved about 23 metres above ground and dated to the very late 7th or early 8th century.",
  "Скальный рельеф всадника, поражающего копьём льва, высеченный примерно в 23 метрах над землёй и датируемый самым концом VII или началом VIII века.",'madara')
I('BG','landmark','boyana-church',
  "Boyana Church",
  "Боянская церковь",
  "Church on the outskirts of Sofia whose second layer of frescoes dates from 1259 and which joined the UNESCO list in 1979.",
  "Церковь на окраине Софии, второй слой фресок которой относится к 1259 году; в 1979 году она вошла в список ЮНЕСКО.",'boyana')

I('BE','fact','belgian-beer-culture-unesco',
  "Belgian beer culture",
  "Бельгийская пивная культура",
  "Belgian beer culture was inscribed on UNESCO's Representative List of the Intangible Cultural Heritage on 1 December 2016.",
  "Бельгийская пивная культура была внесена в Репрезентативный список нематериального культурного наследия ЮНЕСКО 1 декабря 2016 года.",'be-beer')
I('BE','landmark','plantin-moretus-museum',
  "Plantin-Moretus Museum",
  "Музей Плантена — Моретуса",
  "Antwerp museum of printing history in the Gulden Passer building of the Plantin Press, inscribed on the World Heritage List in 2005.",
  "Антверпенский музей истории книгопечатания в здании «Золотой циркуль» типографии Плантена, внесённый в список Всемирного наследия в 2005 году.",'plantin')
I('BE','fact','adolphe-sax-saxophone-inventor',
  "Saxophone inventor Adolphe Sax",
  "Изобретатель саксофона Адольф Сакс",
  "Born in Dinant on 6 November 1814, Adolphe Sax patented the saxophone on 28 June 1846.",
  "Адольф Сакс родился в Динане 6 ноября 1814 года и запатентовал саксофон 28 июня 1846 года.",'sax')

# ---------------- Americas ----------------
I('AG','landmark','nelsons-dockyard-english-harbour',
  "Nelson's Dockyard",
  "Верфь Нельсона",
  "Georgian naval dockyard at English Harbour where Horatio Nelson lived from 1784 to 1787, described as the only continuously working Georgian-era dockyard in the world.",
  "Военно-морская верфь георгианской эпохи в Инглиш-Харбор, где с 1784 по 1787 год жил Горацио Нельсон; её называют единственной непрерывно действующей верфью той эпохи в мире.",'nelson-dockyard')

I('BB','landmark','historic-bridgetown-and-garrison',
  "Historic Bridgetown and its Garrison",
  "Исторический Бриджтаун и его гарнизон",
  "Listed as a World Heritage Site on 25 June 2011; English settlement of Bridgetown began on 5 July 1628.",
  "Внесён в список Всемирного наследия 25 июня 2011 года; английское заселение Бриджтауна началось 5 июля 1628 года.",'bridgetown')
I('BB','landmark','harrisons-cave',
  "Harrison's Cave",
  "Пещера Харрисона",
  "Limestone cave in the central uplands of Barbados, shaped by flowing water and visited by tram, with stalactites and stalagmites.",
  "Известняковая пещера в центральной возвышенности Барбадоса, образованная текущей водой; её осматривают на электропоезде, а своды украшают сталактиты и сталагмиты.",'harrison')
I('BB','fact','crop-over-festival',
  "Crop Over festival",
  "Фестиваль Кроп-Овер",
  "Festival that grew out of end-of-harvest celebrations on sugar plantations, was revived as a national festival in 1974 and ends with the Grand Kadooment.",
  "Фестиваль, выросший из праздника окончания сбора урожая на сахарных плантациях, возрождённый в 1974 году как национальный и завершающийся парадом Гранд-Кадумент.",'crop-over')

I('BS','fact','junkanoo-festival',
  "Junkanoo festival",
  "Фестиваль Джункану",
  "Street festival of costumed masqueraders, goatskin drums and cowbells that originated during the period of slavery.",
  "Уличный фестиваль костюмированных участников под звуки барабанов из козлиной кожи и коровьих колокольчиков, возникший в эпоху рабства.",'junkanoo')
I('BS','landmark','fort-charlotte-nassau',
  "Fort Charlotte in Nassau",
  "Форт Шарлотта в Нассау",
  "Late-18th-century fort built by colonial governor Lord Dunmore that has never been used in battle.",
  "Форт конца XVIII века, построенный колониальным губернатором лордом Данмором и ни разу не применявшийся в бою.",'fort-charlotte')

I('BM','landmark','gibbs-hill-lighthouse',
  "Gibbs Hill Lighthouse",
  "Маяк Гиббс-Хилл",
  "Cast-iron lighthouse completed in 1846, 36 metres high and described as one of the first in the world made of cast iron.",
  "Чугунный маяк высотой 36 метров, построенный в 1846 году; его называют одним из первых в мире маяков из чугуна.",'gibbs-hill')
I('BM','landmark','town-of-st-george-bermuda',
  "Town of St George",
  "Город Сент-Джордж",
  "Settled by the English in 1612 as New London and later renamed St George's Town, it is a UNESCO World Heritage Site.",
  "Основан англичанами в 1612 году как Нью-Лондон, позднее переименован в Сент-Джорджес-Таун и входит в список Всемирного наследия ЮНЕСКО.",'bermuda')
I('BM','landmark','crystal-caves-bermuda',
  "Crystal Caves",
  "Хрустальные пещеры",
  "Caves with stalactites and underground saltwater pools.",
  "Пещеры со сталактитами и подземными солёными озёрами.",'bermuda')

I('BZ','landmark','belize-barrier-reef-reserve-system',
  "Belize Barrier Reef Reserve System",
  "Заповедная система Барьерного рифа Белиза",
  "A 300-km section of the 900-km Mesoamerican Barrier Reef System that was designated a World Heritage Site in 1996.",
  "Участок длиной 300 км от 900-километровой Мезоамериканской системы барьерных рифов, объявленный объектом Всемирного наследия в 1996 году.",'belize-reef')
I('BZ','landmark','cockscomb-basin-jaguar-sanctuary',
  "Cockscomb Basin Wildlife Sanctuary",
  "Заповедник дикой природы Кокскомб-Бейсин",
  "Sanctuary in the Stann Creek District that was the first protected area created to protect the jaguar.",
  "Заповедник в округе Стэнн-Крик, ставший первой охраняемой территорией, созданной для защиты ягуара.",'cockscomb')

I('DM','landmark','morne-trois-pitons-national-park',
  "Morne Trois Pitons National Park",
  "Национальный парк Морн-Труа-Питон",
  "Established in 1975 and made a World Heritage Site in 1997, the park includes the Valley of Desolation with boiling mud ponds.",
  "Основанный в 1975 году и ставший объектом Всемирного наследия в 1997 году парк включает Долину запустения с кипящими грязевыми озёрами.",'morne-trois')
I('DM','fact','kalinago-territory-1903',
  "Kalinago Territory",
  "Территория калинаго",
  "District in north-east Dominica formed by the British colonial authorities in 1903 for the indigenous Kalinago people.",
  "Округ на северо-востоке Доминики, созданный британскими колониальными властями в 1903 году для коренного народа калинаго.",'kalinago')
I('DM','fact','sisserou-parrot-national-bird',
  "Sisserou parrot",
  "Императорский амазон (сиссеру)",
  "The imperial amazon, locally called the sisserou, is endemic to Dominica, is its national bird and appears on the national flag.",
  "Императорский амазон, который на Доминике называют сиссеру, обитает только на этом острове, является национальной птицей и изображён на государственном флаге.",'sisserou')

I('GD','fact','grenada-isle-of-spice',
  "Isle of Spice",
  "Остров пряностей",
  "Grenada is known as the Island of Spice because it produces nutmeg and mace.",
  "Гренаду называют островом пряностей, потому что здесь выращивают мускатный орех и получают мускатный цвет.",'grenada')
I('GD','landmark','grand-etang-lake',
  "Grand Etang lake",
  "Озеро Гранд-Этанг",
  "A crater lake in an extinct volcano, one of two such lakes that helped form Grenada alongside Lake Antoine.",
  "Кратерное озеро в потухшем вулкане; вместе с озером Антуан оно входит в число двух таких водоёмов, участвовавших в образовании острова Гренада.",'grenada')

I('TT','fact','steelpan-national-instrument',
  "Steelpan",
  "Стальной барабан (стилпан)",
  "The steelpan developed in the 1930s and 1940s from Carnival percussion traditions and was declared the national instrument in 1992.",
  "Стальной барабан сформировался в 1930–1940-х годах из карнавальных ударных традиций, а в 1992 году был объявлен национальным инструментом.",'steelpan')
I('TT','landmark','caroni-swamp-scarlet-ibis',
  "Caroni Swamp",
  "Болото Кэрони",
  "Mangrove wetland on the west coast of Trinidad where scarlet ibises, the national bird, return each evening to roost.",
  "Мангровое болото на западном побережье Тринидада, куда каждый вечер на ночлег возвращаются алые ибисы — национальные птицы страны.",'caroni')

I('JM','food','blue-mountain-coffee',
  "Blue Mountain coffee",
  "Кофе «Блю Маунтин»",
  "Only coffee grown in the Blue Mountains and certified by the Jamaica Commodities Regulatory Authority may carry the Blue Mountain label.",
  "Название «Блю Маунтин» вправе носить лишь кофе, выращенный в Голубых горах и сертифицированный Управлением по регулированию сырьевых товаров Ямайки.",'blue-mtn-coffee')
I('JM','landmark','blue-and-john-crow-mountains',
  "Blue and John Crow Mountains National Park",
  "Национальный парк Голубые горы и Джон-Кроу",
  "Inscribed as a mixed natural and cultural World Heritage Site on 3 July 2015.",
  "Внесён в список Всемирного наследия как смешанный природно-культурный объект 3 июля 2015 года.",'bjc')
I('JM','fact','port-royal-earthquake-1692',
  "Port Royal earthquake of 1692",
  "Землетрясение в Порт-Рояле 1692 года",
  "An earthquake and tsunami destroyed the pirate-haunted port at the mouth of Kingston Harbour on 7 June 1692.",
  "Землетрясение и цунами 7 июня 1692 года разрушили пиратский порт в устье гавани Кингстона.",'port-royal')

I('DO','fact','merengue-dominican-unesco',
  "Merengue music and dance",
  "Музыка и танец меренге",
  "Merengue from the Cibao region uses the accordion, tambora and güira, and was inscribed on UNESCO's Representative List on 30 November 2016.",
  "Меренге из региона Сибао исполняют на аккордеоне, тамборе и гуире; в Репрезентативный список ЮНЕСКО оно внесено 30 ноября 2016 года.",'merengue')
I('DO','landmark','lake-enriquillo',
  "Lake Enriquillo",
  "Озеро Энрикильо",
  "Hypersaline lake about 46 metres below sea level, the largest lake in the Caribbean, which is home to the largest population of American crocodiles.",
  "Гиперсолёное озеро примерно на 46 метров ниже уровня моря, крупнейшее в Карибском регионе; здесь обитает самая большая популяция американских крокодилов.",'enriquillo')

I('PR','landmark','la-fortaleza-san-juan',
  "La Fortaleza",
  "Ла-Форталеса",
  "Built as a fortress in 1533–1540, it is the governor's residence in Old San Juan and was named a World Heritage Site in 1983.",
  "Построенная как крепость в 1533–1540 годах, это резиденция губернатора в Старом Сан-Хуане, объявленная объектом Всемирного наследия в 1983 году.",'fortaleza')
I('PR','landmark','arecibo-observatory',
  "Arecibo Observatory",
  "Обсерватория Аресибо",
  "Its 305-metre dish, completed in 1963, was the largest single-aperture telescope for 53 years before the telescope collapsed on 1 December 2020.",
  "Его 305-метровая антенна, построенная в 1963 году, 53 года оставалась крупнейшим однозеркальным телескопом, а 1 декабря 2020 года телескоп обрушился.",'arecibo')

I('CW','landmark','willemstad-historic-area',
  "Historic Area of Willemstad",
  "Исторический центр Виллемстада",
  "Designated a World Heritage Site in 1997, the centre is divided into the Punda and Otrobanda quarters by Sint Anna Bay.",
  "Объявлен объектом Всемирного наследия в 1997 году; центр заливом Синт-Анна делится на кварталы Пунда и Отробанда.",'willemstad')

I('BQ','fact','bonaire-national-marine-park',
  "Bonaire National Marine Park",
  "Национальный морской парк Бонэйра",
  "The marine park was established in 1979 with the support of the World Wide Fund for Nature and others.",
  "Морской парк основан в 1979 году при поддержке Всемирного фонда дикой природы и других организаций.",'bonaire')
I('BQ','fact','bonaire-flamingo-nesting-ground',
  "Pekelmeer flamingo sanctuary",
  "Заповедник фламинго Пекелмер",
  "Bonaire is home to one of only four nesting grounds of the Caribbean flamingo, in the Pekelmeer in the south.",
  "На Бонэйре, в районе Пекелмер на юге острова, находится одно из четырёх мест гнездования карибского фламинго.",'bonaire')
I('BQ','landmark','mount-scenery-saba',
  "Mount Scenery",
  "Гора Сценери",
  "Dormant volcano on Saba whose 870-metre summit is the highest point of the Kingdom of the Netherlands.",
  "Спящий вулкан на Сабе, чья вершина высотой 870 метров — высшая точка Королевства Нидерландов.",'scenery')

I('MQ','fact','mount-pelee-eruption-1902',
  "Eruption of Mount Pelée in 1902",
  "Извержение горы Пеле в 1902 году",
  "On 8 May 1902 Mount Pelée destroyed the city of Saint-Pierre, and the death toll is given as approximately 29,000.",
  "8 мая 1902 года гора Пеле уничтожила город Сен-Пьер; число погибших оценивают примерно в 29 тысяч человек.",'pelee')

I('MS','fact','soufriere-hills-eruption-plymouth',
  "Soufrière Hills eruption and Plymouth",
  "Извержение Суфриер-Хиллс и город Плимут",
  "The eruption that began on 18 July 1995 led to the destruction and abandonment of the capital Plymouth by 1997.",
  "Извержение, начавшееся 18 июля 1995 года, к 1997 году привело к разрушению и оставлению столицы острова — города Плимут.",'soufriere-hills')

I('BL','fact','gustavia-swedish-colonial-period',
  "Gustavia and the Swedish period",
  "Густавия и шведский период",
  "Renamed in honour of King Gustav III of Sweden, Gustavia belonged to Sweden from 1784 until the island was sold back to France in 1878.",
  "Город, переименованный в честь шведского короля Густава III, принадлежал Швеции с 1784 года, пока в 1878 году остров не был продан обратно Франции.",'gustavia')

I('PM','fact','free-french-seizure-1941',
  "Free French seizure in 1941",
  "Захват островов «Сражающейся Францией» в 1941 году",
  "Free French Forces seized the islands from Vichy France on 24 December 1941.",
  "Силы «Сражающейся Франции» захватили острова у вишистского режима 24 декабря 1941 года.",'spm')

I('TC','landmark','conch-bar-caves',
  "Conch Bar Caves",
  "Пещеры Конч-Бар",
  "Caves on Middle Caicos, the largest above-ground cave system in the Bahamas-Turks and Caicos archipelago, where Lucayan artefacts were found in the 1880s.",
  "Пещеры на острове Мидл-Кайкос — крупнейшая надземная пещерная система архипелага Багамы — Тёркс и Кайкос, где в 1880-х годах нашли артефакты лукайев.",'conch-bar')

I('FK','fact','falklands-five-penguin-species',
  "Five penguin species",
  "Пять видов пингвинов",
  "The Falkland Islands host five different penguin species as well as some of the largest albatross colonies on the planet.",
  "На Фолклендских островах гнездятся пять видов пингвинов, а также одни из крупнейших в мире колоний альбатросов.",'falklands')

I('GP','fact','guadeloupe-butterfly-shape',
  "Butterfly-shaped archipelago with La Grande Soufrière",
  "Архипелаг в форме бабочки с вулканом Гранд-Суфриер",
  "Basse-Terre and Grande-Terre form a butterfly shape seen from above, and La Grande Soufrière, at 1,467 metres, is the highest peak in the Lesser Antilles.",
  "Бас-Тер и Гранд-Тер сверху образуют форму бабочки, а вулкан Гранд-Суфриер высотой 1467 метров — высочайшая вершина Малых Антильских островов.",'guadeloupe')

I('AW','fact','aruba-constituent-country-1986',
  "Constituent country since 1986",
  "Статус автономной страны с 1986 года",
  "In 1986 Aruba became a constituent country within the Kingdom of the Netherlands.",
  "В 1986 году Аруба стала автономной страной в составе Королевства Нидерландов.",'aruba')
I('AW','fact','aruba-papiamento-official-language',
  "Papiamento as an official language",
  "Папьяменто как официальный язык",
  "Papiamento is listed as an official language of Aruba alongside Dutch.",
  "Папьяменто признан официальным языком Арубы наряду с нидерландским.",'aruba')

I('UY','fact','candombe-drumming',
  "Candombe drumming",
  "Барабанная традиция кандомбе",
  "Afro-Uruguayan tradition based on three drums, the chico, repique and piano, that was inscribed on UNESCO's Representative List in 2009.",
  "Афроуругвайская традиция на трёх барабанах — чико, репике и пиано, внесённая в Репрезентативный список ЮНЕСКО в 2009 году.",'candombe')
I('UY','landmark','colonia-del-sacramento-historic-quarter',
  "Historic Quarter of Colonia del Sacramento",
  "Исторический квартал Колонии-дель-Сакраменто",
  "The Portuguese established the town in 1680 on the Río de la Plata facing Buenos Aires, and its historic quarter was inscribed in 1995.",
  "Португальцы основали город в 1680 году на берегу Ла-Платы напротив Буэнос-Айреса, а его исторический квартал внесён в список ЮНЕСКО в 1995 году.",'colonia')
I('UY','landmark','fray-bentos-industrial-landscape',
  "Fray Bentos Industrial Landscape",
  "Индустриальный ландшафт Фрай-Бентоса",
  "The Liebig meat-extract plant founded in 1863 later became the Anglo plant, and its district was declared a World Heritage Site on 5 July 2015.",
  "Завод мясного экстракта Либиха, основанный в 1863 году, позднее стал заводом «Англо», а его район объявлен объектом Всемирного наследия 5 июля 2015 года.",'fray-bentos')

I('CR','landmark','cocos-island-national-park',
  "Cocos Island National Park",
  "Национальный парк острова Кокос",
  "Island about 550 km from the mainland, a World Heritage Site since 1997 and a diving destination known for hammerhead sharks.",
  "Остров примерно в 550 км от материка, с 1997 года входящий в список Всемирного наследия и известный дайвингом среди акул-молотов.",'cocos')
I('CR','landmark','diquis-stone-spheres',
  "Stone spheres of the Diquís",
  "Каменные шары дельты Дикис",
  "Pre-Columbian spheres up to over 2 metres across, attributed to the Diquís culture, were added to the UNESCO list in 2014.",
  "Доколумбовы каменные шары диаметром до двух с лишним метров, приписываемые культуре дикис, были внесены в список ЮНЕСКО в 2014 году.",'spheres')

I('PA','landmark','coiba-national-park',
  "Coiba National Park",
  "Национальный парк Койба",
  "Island that held a penal colony from 1919 until the prison closed in 2004 and was declared a World Heritage Site in 2005.",
  "Остров, где с 1919 года находилась исправительная колония, закрытая в 2004 году, и который в 2005 году был объявлен объектом Всемирного наследия.",'coiba')
I('PA','landmark','panama-viejo-ruins',
  "Panamá Viejo",
  "Панама-Вьехо",
  "The settlement founded on 15 August 1519 was destroyed by the privateer Henry Morgan in 1671 and has been a World Heritage Site since 1997.",
  "Поселение, основанное 15 августа 1519 года, было разрушено корсаром Генри Морганом в 1671 году и с 1997 года входит в список Всемирного наследия.",'panama-viejo')

I('EC','landmark','quito-historic-centre',
  "Historic centre of Quito",
  "Исторический центр Кито",
  "In 1978 Quito and Kraków were the first cultural sites declared World Heritage by UNESCO; the city lies at 2,850 metres.",
  "В 1978 году Кито и Краков стали первыми объектами культурного наследия, объявленными ЮНЕСКО; город расположен на высоте 2850 метров.",'quito')
I('EC','fact','panama-hat-toquilla-weaving',
  "Panama hat weaving",
  "Плетение шляп «панама»",
  "The hat originated in Ecuador, where it is woven from toquilla palm leaves, and the weaving art joined UNESCO's lists on 5 December 2012.",
  "Шляпа родом из Эквадора, где её плетут из листьев пальмы токилья, а искусство плетения внесено в списки ЮНЕСКО 5 декабря 2012 года.",'panama-hat')

I('SV','landmark','joya-de-ceren',
  "Joya de Cerén",
  "Хойя-де-Серен",
  "Archaeological site buried under volcanic ash around AD 600, inscribed on the World Heritage List in 1993 and often called the Pompeii of the Americas.",
  "Археологический памятник, погребённый под вулканическим пеплом около 600 года н. э., внесённый в список Всемирного наследия в 1993 году и часто называемый «Помпеями Америки».",'joya')
I('SV','food','pupusa',
  "Pupusa",
  "Пупуса",
  "Thick griddle flatbread stuffed with cheese, beans or chicharrón, the national dish, celebrated on National Pupusa Day on the second Sunday of November.",
  "Толстая лепёшка с начинкой из сыра, фасоли или чичаррона — национальное блюдо, которому посвящён Национальный день пупусы во второе воскресенье ноября.",'pupusa')

I('PY','fact','guarani-official-language-1992',
  "Guaraní as an official language",
  "Гуарани как официальный язык",
  "The 1992 constitution made Guaraní equal to Spanish, and it is one of the two official languages of Paraguay.",
  "Конституция 1992 года уравняла гуарани с испанским, и он является одним из двух официальных языков Парагвая.",'guarani')

I('GT','landmark','antigua-guatemala-world-heritage',
  "Antigua Guatemala",
  "Антигуа-Гватемала",
  "Capital of the Captaincy General of Guatemala from 1543 to 1773 and a World Heritage Site since 1979, encircled by three large volcanoes.",
  "Столица генерал-капитанства Гватемала с 1543 по 1773 год и объект Всемирного наследия с 1979 года, окружённый тремя крупными вулканами.",'antigua-gt')

I('CO','landmark','coffee-cultural-landscape-colombia',
  "Coffee Cultural Landscape of Colombia",
  "Культурный ландшафт кофе Колумбии",
  "Coffee-growing region in Caldas, Risaralda and Quindío that was inscribed on the UNESCO World Heritage List in 2011.",
  "Кофейный регион в департаментах Кальдас, Рисаральда и Киндио, внесённый в список Всемирного наследия ЮНЕСКО в 2011 году.",'co-coffee')

used = sorted({r[7] for r in R})
missing = [k for k in used if k not in S]
assert not missing, missing
out = {'sources': [{'id': 'qzw-' + k, 'title': S[k][0], 'url': S[k][1]} for k in used], 'countries': {}}
for iso, kind, iid, ne, nr, re_, rr, src in R:
    out['countries'].setdefault(iso, []).append({'id': iid, 'kind': kind, 'name_en': ne, 'name_ru': nr, 'relation_en': re_, 'relation_ru': rr, 'source_id': 'qzw-' + src})
out['countries'] = dict(sorted(out['countries'].items()))
with open(os.path.join(HERE, 'delta.json'), 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(len(R), 'items', len(out['countries']), 'countries', len(out['sources']), 'sources')
