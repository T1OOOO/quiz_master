"""One-off: apply the browser fact-check (notes.md) to build.py — new slugs, names and relations."""
import re
from pathlib import Path

p = Path(__file__).with_name("build.py")
s = p.read_text(encoding="utf-8")

SLUGS = {"milan": "Milan-Italy", "kyoto": "Kyoto-Japan", "jaipur": "Jaipur-India", "quebec-city": "Quebec",
         "rotterdam": "Rotterdam-Netherlands", "lima": "Lima", "cusco": "Cuzco", "chiang-mai": "Chiang-Mai",
         "zurich": "Zurich", "bern": "Bern"}
NAMES = {
    "valencia": ("Valencia and its huerta", "Валенсия и её уэрта"),
    "manchester": ("Manchester, the city of the Industrial Revolution", "Манчестер — город промышленной революции"),
    "osaka": ("Osaka, the second metropolis of Japan", "Осака — вторая агломерация Японии"),
    "rio-de-janeiro": ("Rio de Janeiro, the former capital", "Рио-де-Жанейро — бывшая столица"),
    "aswan": ("Aswan at the First Cataract", "Асуан у первого порога"),
    "perth": ("Perth on the Swan River", "Перт на реке Суон"),
    "guadalajara": ("Guadalajara, the second city of Mexico", "Гвадалахара — второй город Мексики"),
    "marrakech": ("Marrakech, the first imperial city", "Марракеш — первый имперский город"),
    "stockholm": ("Stockholm on the islands", "Стокгольм на островах"),
    "cairo": ("Cairo, the thousand-year city on the Nile", "Каир — тысячелетний город на Ниле"),
    "dubai": ("Dubai, from pearls to skyscrapers", "Дубай — от жемчуга до небоскрёбов"),
}
REL = {
"rome": ("Capital of Italy on the Tiber; the ancient Romans dated its founding to 753 BCE, it was the capital of the Roman republic and empire, and it is the seat of the Roman Catholic Church.",
         "Столица Италии на Тибре; древние римляне относили её основание к 753 году до н. э., она была столицей Римской республики и империи и остаётся центром Римско-католической церкви."),
"venice": ("City linking together 118 islands in a lagoon of the Adriatic, threaded by canals and narrow streets; for a thousand years it was the capital of the Venetian republic.",
           "Город, соединяющий 118 островов в лагуне Адриатики, пронизанный каналами и узкими улочками; тысячу лет был столицей Венецианской республики."),
"madrid": ("Capital of Spain in the centre of the country; Philip II took the court to Madrid in 1561, and Philip III officially made it the national capital. The Prado museum and the Royal Palace are among its landmarks.",
           "Столица Испании в центре страны; Филипп II перенёс сюда двор в 1561 году, а Филипп III официально сделал город столицей. Среди достопримечательностей — музей Прадо и Королевский дворец."),
"barcelona": ("Spain's major Mediterranean port and commercial centre and the capital of Catalonia; it hosted the 1992 Summer Olympics and is famous for Antoni Gaudí's architecture.",
              "Главный средиземноморский порт и торговый центр Испании, столица Каталонии; принимала летнюю Олимпиаду 1992 года и знаменита архитектурой Антонио Гауди."),
"seville": ("Capital of Andalusia on the Guadalquivir and once the capital of Muslim Spain; from 1503 its Casa de Contratación directed the exploration of America, and its cathedral is among the largest Gothic churches.",
            "Столица Андалусии на Гвадалквивире, некогда столица мусульманской Испании; с 1503 года её Торговая палата руководила освоением Америки, а собор — один из крупнейших готических храмов."),
"valencia": ("Port on Spain's Mediterranean coast at the mouth of the Turia (Guadalaviar) River, surrounded by the irrigated market gardens of the Huerta de Valencia, whose rice is exported.",
             "Порт на средиземноморском побережье Испании в устье реки Турия (Гвадалавьяр), окружённый орошаемыми садами и полями Валенсийской уэрты, чей рис идёт на экспорт."),
"munich": ("Capital of Bavaria on the Isar; in 1157 Henry the Lion granted the local monks the right to hold a market, the event counted as the city's founding; famous for the Oktoberfest and its museums.",
           "Столица Баварии на Изаре; в 1157 году Генрих Лев дал местным монахам право держать рынок, что считается основанием города; знаменит Октоберфестом и музеями."),
"hamburg": ("Germany's largest port and second largest city, on the Elbe; its role in the medieval Hanseatic League was second only to Lübeck's, and the harbour is called Hamburg's gateway to the world.",
            "Крупнейший порт и второй по величине город Германии на Эльбе; в средневековой Ганзе уступал по роли только Любеку, а его порт называют воротами Гамбурга в мир."),
"cologne": ("City on the Rhine founded by the Romans as Colonia Claudia Ara Agrippinensium; its Gothic cathedral, begun in 1248 after a fire and completed only in 1880, is the largest Gothic church in northern Europe.",
            "Город на Рейне, основанный римлянами как Колония Клавдия Ара Агриппиненсиум; готический собор, начатый в 1248 году после пожара и завершённый лишь в 1880-м, — крупнейший готический храм Северной Европы."),
"edinburgh": ("Capital of Scotland built around a castle on a volcanic rock; its Old and New Towns are a UNESCO site, and every August the Edinburgh International Festival and the Fringe fill the city.",
              "Столица Шотландии, выросшая вокруг замка на вулканической скале; Старый и Новый город — объект ЮНЕСКО, а каждый август город наполняют Эдинбургский международный фестиваль и Фриндж."),
"manchester": ("City in north-west England at the forefront of the Industrial Revolution, an urban prototype built on cotton; by 1851 its textile industries led the world, and today it is known for its football clubs.",
               "Город на северо-западе Англии в авангарде промышленной революции, прообраз индустриального города, выросший на хлопке; к 1851 году его текстиль лидировал в мире, сегодня известен футбольными клубами."),
"liverpool": ("Port on the Mersey estuary that grew rich in the 18th century on trade with the Americas, its docks outranking even London's; the Beatles emerged from its Cavern Club in the 1960s.",
              "Порт в устье Мерси, разбогатевший в XVIII веке на торговле с Америкой, его доки превосходили даже лондонские; в 1960-х из его клуба «Каверн» вышли «Битлз»."),
"oxford": ("City on the Thames, there called the Isis, whose university, founded in the second half of the 12th century, is the oldest in England; its skyline of Gothic towers and steeples is famous.",
           "Город на Темзе, здесь называемой Айсис, чей университет, основанный во второй половине XII века, — старейший в Англии; знаменит силуэтом готических башен и шпилей."),
"beijing": ("Capital of China: in 1267 the Yuan (Mongol) dynasty made it, as Dadu, the administrative capital; the Forbidden City of the Ming and Qing emperors stands at its centre, and it hosted the 2008 Olympics.",
            "Столица Китая: в 1267 году монгольская династия Юань сделала его, под именем Даду, административной столицей; в центре стоит Запретный город императоров Мин и Цин, город принимал Олимпиаду 2008 года."),
"shanghai": ("China's most populous city and one of the world's largest seaports, at the mouth of the Yangtze; the Pudong New District, established in 1993, holds the Jin Mao Tower and the Shanghai Tower.",
             "Самый населённый город Китая и один из крупнейших морских портов мира в устье Янцзы; в Новом районе Пудун, созданном в 1993 году, стоят башни Цзинь Мао и Шанхайская башня."),
"hong-kong": ("Former British colony on the South China coast returned to China on 1 July 1997 as a special administrative region; a major financial centre and port.",
              "Бывшая британская колония на южном побережье Китая, возвращённая Китаю 1 июля 1997 года как особый административный район; крупный финансовый центр и порт."),
"guangzhou": ("Capital of Guangdong on the Pearl River delta and the first Chinese port regularly visited by European traders, who called it Canton; its people speak Cantonese and its cuisine is famous.",
              "Столица Гуандуна в дельте Жемчужной реки, первый китайский порт, который регулярно посещали европейские купцы, называвшие его Кантоном; жители говорят по-кантонски, кухня знаменита."),
"tokyo": ("Capital of Japan on Tokyo Bay and the largest urban and industrial agglomeration in Japan; with the Meiji Restoration of 1868 the capital was moved to Edo, which was renamed Tokyo.",
          "Столица Японии на Токийском заливе и крупнейшая городская и промышленная агломерация страны; после Реставрации Мэйдзи 1868 года столицу перенесли в Эдо, переименованный в Токио."),
"kyoto": ("Capital of Japan for more than a thousand years, from 794 to 1868; its temples and gardens, including the Kinkaku Temple known as the Golden Pavilion, are a UNESCO site.",
          "Столица Японии более тысячи лет, с 794 по 1868 год; его храмы и сады, включая храм Кинкаку, известный как Золотой павильон, — объект ЮНЕСКО."),
"osaka": ("Japan's second largest urban and industrial agglomeration, on Osaka Bay; Osaka Castle was built by the warlord Toyotomi Hideyoshi in the 16th century.",
          "Вторая по величине городская и промышленная агломерация Японии на Осакском заливе; замок Осака построил полководец Тоётоми Хидэёси в XVI веке."),
"nara": ("National capital of Japan from 710 to 784; its Todai Temple houses the Great Buddha, a giant bronze statue.",
         "Столица Японии с 710 по 784 год; в храме Тодай-дзи стоит Великий Будда — гигантская бронзовая статуя."),
"jaipur": ("Capital of Rajasthan, founded in 1727 by Maharaja Sawai Jai Singh with straight-line planning; its rose-coloured buildings earned it the name pink city, and the Hawa Mahal (Hall of Winds) stands here.",
           "Столица Раджастхана, основанная в 1727 году махараджей Саваи Джай Сингхом с прямолинейной планировкой; розовые здания дали ей имя «розовый город», здесь стоит Хава-Махал (Дворец ветров)."),
"varanasi": ("One of the oldest continuously inhabited cities in the world and one of the seven sacred cities of Hinduism, where pilgrims bathe from the ghats on the Ganges; also known as Benares.",
             "Один из древнейших непрерывно населённых городов мира и один из семи священных городов индуизма, где паломники совершают омовения с гхатов на Ганге; известен и как Бенарес."),
"rio-de-janeiro": ("Capital of independent Brazil from 1822 until 1960, set between mountains and the Atlantic on Guanabara Bay; famous for Sugarloaf, Copacabana beach, the statue of Christ the Redeemer and Carnival.",
                   "Столица независимой Бразилии с 1822 по 1960 год между горами и Атлантикой на заливе Гуанабара; знаменит Сахарной головой, пляжем Копакабана, статуей Христа-Искупителя и карнавалом."),
"sao-paulo": ("Brazil's largest city and the foremost industrial centre in Latin America, founded by Jesuit missionaries on 25 January 1554; the largest city of the Southern Hemisphere.",
              "Крупнейший город Бразилии и главный промышленный центр Латинской Америки, основанный миссионерами-иезуитами 25 января 1554 года; крупнейший город Южного полушария."),
"cairo": ("Capital of Egypt on the Nile, a city for more than a thousand years with a medieval core built under the Fatimid dynasty; one of the largest cities in Africa, with the pyramids of Giza to its south-west.",
          "Столица Египта на Ниле, город с более чем тысячелетней историей и средневековым ядром, построенным при династии Фатимидов; один из крупнейших городов Африки, к юго-западу от которого стоят пирамиды Гизы."),
"luxor": ("City on the Nile on the site of ancient Thebes; the temples of Luxor and Karnak and, among the other Theban sites, the Valley of the Kings have been a UNESCO site since 1979.",
          "Город на Ниле на месте древних Фив; храмы Луксора и Карнака и, среди прочих фиванских памятников, Долина царей — объект ЮНЕСКО с 1979 года."),
"aswan": ("City on the Nile just below the First Cataract, the southern frontier of pharaonic Egypt; the Aswan High Dam, completed in 1970, lies upstream.",
          "Город на Ниле чуть ниже первого порога, южная граница Египта фараонов; выше по течению стоит Асуанская высотная плотина, завершённая в 1970 году."),
"melbourne": ("Capital of Victoria on Port Phillip Bay, founded in 1835; when Australia became a commonwealth, Melbourne served as its federal capital until 1927, and it hosted the 1956 Olympics.",
              "Столица Виктории на заливе Порт-Филлип, основанная в 1835 году; когда Австралия стала федерацией, Мельбурн служил федеральной столицей до 1927 года; принимал Олимпиаду 1956 года."),
"canberra": ("Capital of Australia planned by Walter Burley Griffin; on 9 May 1927 the federal Parliament was officially transferred there from Melbourne, and Lake Burley Griffin is its centrepiece.",
             "Столица Австралии, спланированная Уолтером Бёрли Гриффином; 9 мая 1927 года федеральный парламент официально переехал сюда из Мельбурна, в центре города — озеро Бёрли-Гриффин."),
"perth": ("Capital of Western Australia on the Swan River, where a colony was declared in 1829; the fourth largest city in Australia.",
          "Столица Западной Австралии на реке Суон, где в 1829 году была провозглашена колония; четвёртый по величине город Австралии."),
"guadalajara": ("Capital of Jalisco, founded by the Spanish in 1531 and relocated several times until the 1540s; by the 1970s it was Mexico's second largest city.",
                "Столица Халиско, основанная испанцами в 1531 году и несколько раз переносившаяся до 1540-х; к 1970-м годам стала вторым по величине городом Мексики."),
"cancun": ("Resort on the Caribbean coast of the Yucatán Peninsula, a settlement of about 100 Maya until 1970; built on Isla Cancún, linked to the mainland by a causeway, it draws tourists from the US and Europe.",
           "Курорт на карибском побережье полуострова Юкатан, до 1970 года посёлок примерно ста майя; построен на острове Канкун, соединённом с материком дамбой, принимает туристов из США и Европы."),
"amsterdam": ("Capital of the Netherlands laid out around three main canals dating from the early 17th century; the seat of government is in The Hague, and the city holds the Rijksmuseum and the Anne Frank House.",
              "Столица Нидерландов, распланированная вокруг трёх главных каналов начала XVII века; правительство заседает в Гааге, а в городе — Рейксмузей и дом Анны Франк."),
"rotterdam": ("City on the Rhine–Meuse delta whose harbour and Europoort are the largest in the world by capacity; devastated by bombing in the Second World War, it got a totally new inner city of modern architecture.",
              "Город в дельте Рейна и Мааса, чей порт с Европортом — крупнейший в мире по мощности; разрушенный бомбардировками Второй мировой, получил совершенно новый центр современной архитектуры."),
"athens": ("Capital of Greece, dominated by the Acropolis with the Parthenon; the birthplace of Western civilization, it hosted the revival of the Olympic Games in 1896.",
           "Столица Греции, над которой возвышается Акрополь с Парфеноном; колыбель западной цивилизации, в 1896 году приняла возрождённые Олимпийские игры."),
"thessaloniki": ("Port city on the Gulf of Thermai founded in 316 BCE and named for a sister of Alexander the Great; the second city of the Byzantine Empire, rich in Byzantine churches.",
                 "Портовый город на заливе Термаикос, основанный в 316 году до н. э. и названный в честь сестры Александра Македонского; второй город Византийской империи, богатый византийскими церквями."),
"lisbon": ("Capital of Portugal on the estuary of the Tagus, rebuilt after the great earthquake of 1755; Vasco da Gama led a Portuguese fleet to India in 1498.",
           "Столица Португалии в устье Тежу, отстроенная после великого землетрясения 1755 года; в 1498 году Васко да Гама привёл португальский флот в Индию."),
"porto": ("Portugal's second city at the mouth of the Douro, called Portus Cale in Roman times; port wine is blended and stored in the red-tiled warehouses of Vila Nova de Gaia across the river.",
          "Второй город Португалии в устье Дору, в римские времена называвшийся Портус-Кале; портвейн купажируют и хранят в складах под красной черепицей в Вила-Нова-ди-Гая на другом берегу."),
"buenos-aires": ("Capital of Argentina on the Río de la Plata estuary, called a miniature Paris; tango originated in its lower-class districts, and the Teatro Colón and the Casa Rosada stand here.",
                 "Столица Аргентины на эстуарии Ла-Платы, прозванная маленьким Парижем; танго родилось в её бедных кварталах, здесь стоят театр Колон и Каса Росада."),
"johannesburg": ("South Africa's chief industrial and financial metropolis, founded in 1886 following the discovery of gold on the Witwatersrand; Soweto township lies 10 miles to its south-west.",
                 "Главный промышленный и финансовый центр ЮАР, основанный в 1886 году после открытия золота на Витватерсранде; в 10 милях к юго-западу лежит тауншип Соуэто."),
"marrakech": ("First of Morocco's four imperial cities, founded in the mid-11th century by Yusuf ibn Tashufin of the Almoravid dynasty; the Koutoubia minaret and the Jamaa el-Fna square are famous.",
              "Первый из четырёх имперских городов Марокко, основанный в середине XI века Юсуфом ибн Ташфином из династии Альморавидов; знамениты минарет Кутубия и площадь Джемаа-эль-Фна."),
"casablanca": ("Morocco's principal port on the Atlantic, which became the country's chief port during the French protectorate (1912–56); its Hassan II Mosque is one of the largest and most ornate in the world.",
               "Главный порт Марокко на Атлантике, ставший главным портом страны при французском протекторате (1912–56); мечеть Хасана II — одна из крупнейших и самых нарядных в мире."),
"seoul": ("Capital of South Korea on the Han River and the capital of Korea since 1394; it hosted the 1988 Summer Olympics.",
          "Столица Южной Кореи на реке Ханган и столица Кореи с 1394 года; принимала летнюю Олимпиаду 1988 года."),
"dubai": ("One of the wealthiest of the seven emirates, on the Persian Gulf; it grew from pearl diving and trade into a hub of finance, aviation and tourism crowned by the Burj Khalifa.",
          "Один из богатейших из семи эмиратов на Персидском заливе; вырос из ловли жемчуга и торговли в центр финансов, авиации и туризма, увенчанный Бурдж-Халифой."),
"abu-dhabi": ("Capital of the UAE on a small triangular island off the Persian Gulf coast; rich oil fields discovered in 1958 and in commercial production since 1962 made it wealthy.",
              "Столица ОАЭ на небольшом треугольном острове у побережья Персидского залива; богатые нефтяные месторождения, открытые в 1958 году и разрабатываемые с 1962-го, принесли ей богатство."),
"hanoi": ("Capital of Vietnam on the Red River; in 1010 the emperor Ly Thai To chose the site for his capital.",
          "Столица Вьетнама на Красной реке; в 1010 году император Ли Тхай То выбрал это место для своей столицы."),
"ho-chi-minh-city": ("Vietnam's largest city, north of the Mekong delta; as Saigon it was the capital of South Vietnam (1954–75) and was renamed after North Vietnamese troops captured it on 30 April 1975.",
                     "Крупнейший город Вьетнама к северу от дельты Меконга; как Сайгон был столицей Южного Вьетнама (1954–75) и был переименован после взятия северовьетнамскими войсками 30 апреля 1975 года."),
"salzburg": ("City on the Salzach whose archbishops, acknowledged princes of the Holy Roman Empire in 1278, resided in the Hohensalzburg fortress; Mozart's birthplace and home of the Salzburg Festival.",
             "Город на Зальцахе, чьи архиепископы, признанные князьями Священной Римской империи в 1278 году, жили в крепости Хоэнзальцбург; родина Моцарта и дом Зальцбургского фестиваля."),
"warsaw": ("Capital of Poland on the Vistula since 1611, when the king and his court moved from Kraków; razed in 1944, its Old Town was rebuilt so faithfully that it is a UNESCO site.",
           "Столица Польши на Висле с 1611 года, когда король и двор переехали из Кракова; разрушенный в 1944 году Старый город восстановили так точно, что он стал объектом ЮНЕСКО."),
"krakow": ("Royal capital of Poland until King Sigismund III Vasa moved his capital to Warsaw by 1611, with the kings' seat at Wawel Castle; its Main Square dates from the 13th century, and the Jagiellonian University is famous.",
           "Королевская столица Польши, пока король Сигизмунд III Ваза к 1611 году не перенёс столицу в Варшаву; резиденция королей — замок Вавель, Рыночная площадь существует с XIII века, знаменит Ягеллонский университет."),
"stockholm": ("Capital of Sweden built on numerous islands where Lake Mälaren meets the Baltic, first mentioned as a town in 1252; the Royal Swedish Academy of Sciences here selects Nobel laureates.",
              "Столица Швеции на многочисленных островах там, где озеро Меларен встречается с Балтикой; впервые упомянута как город в 1252 году; здесь Королевская академия наук выбирает нобелевских лауреатов."),
"oslo": ("Capital of Norway at the head of the Oslofjord, founded by King Harald Hardraade about 1050; renamed Christiania after the fire of 1624, it was given back its name Oslo in 1925.",
         "Столица Норвегии в глубине Осло-фьорда, основанная королём Харальдом Суровым около 1050 года; после пожара 1624 года переименована в Христианию, имя Осло возвращено в 1925 году."),
"bergen": ("Norway's second largest city, on the west coast, founded in 1070 by King Olaf III and the capital in the 12th and 13th centuries; the Hanseatic wharf of Bryggen is a UNESCO site.",
           "Второй по величине город Норвегии на западном побережье, основанный в 1070 году королём Олафом III и бывший столицей в XII–XIII веках; ганзейская набережная Брюгген — объект ЮНЕСКО."),
}


def patch(iid, slug=None, name=None, rel=None):
    global s
    pat = re.compile(r'(city\("[A-Z]{2}", "%s", )"([^"]*)"(, )"([^"]*)"(, )"([^"]*)"(,\s*)"([^"]*)"(,\s*)"([^"]*)"\)' % re.escape(iid))
    m = pat.search(s)
    assert m, iid
    g = list(m.groups())
    if slug:
        g[1] = slug
    if name:
        g[3], g[5] = name
    if rel:
        g[7], g[9] = rel
    new = g[0] + '"%s"%s"%s"%s"%s"%s"%s"%s"%s")' % (g[1], g[2], g[3], g[4], g[5], g[6], g[7], g[8], g[9])
    s = s[:m.start()] + new + s[m.end():]


for iid in set(SLUGS) | set(NAMES) | set(REL):
    patch(iid, SLUGS.get(iid), NAMES.get(iid), REL.get(iid))
p.write_text(s, encoding="utf-8", newline="\n")
print("patched", len(set(SLUGS) | set(NAMES) | set(REL)))
