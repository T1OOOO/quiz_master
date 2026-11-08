"""Build delta.json: well-known cities of ~30 countries for country_links.json (ids wc-*, kind fact/landmark).

Run: python build.py -> delta.json; then validate.py; then merge.py.
Every claim was checked against the cited Britannica page opened in a browser on 2026-11-08 (notes.md).
"""
import json
from collections import defaultdict
from pathlib import Path

S, C = [], defaultdict(list)
B = "https://www.britannica.com/place/"


def city(cc, iid, slug, en, ru, rel_en, rel_ru, kind="fact", title=None):
    sid = "wc-brit-" + iid
    S.append({"id": sid, "title": "Britannica: " + (title or en.split(",")[0]), "url": B + slug})
    C[cc].append({
        "id": "wc-" + iid, "kind": kind, "name_en": en, "name_ru": ru,
        "relation_en": rel_en, "relation_ru": rel_ru, "source_id": sid,
    })


# ---------------------------------------------------------------- Italy
city("IT", "rome", "Rome", "Rome, the Eternal City", "Рим — Вечный город",
     "Capital of Italy on the Tiber; the ancient Romans dated its founding to 753 BCE, it was the capital of the Roman republic and empire, and it is the seat of the Roman Catholic Church.",
     "Столица Италии на Тибре; древние римляне относили её основание к 753 году до н. э., она была столицей Римской республики и империи и остаётся центром Римско-католической церкви.")
city("IT", "milan", "Milan-Italy", "Milan, the capital of fashion and finance", "Милан — столица моды и финансов",
     "Capital of Lombardy and Italy's leading financial and industrial centre, famous for its Gothic cathedral (Duomo), La Scala opera house and the fashion industry.",
     "Столица Ломбардии и ведущий финансовый и промышленный центр Италии, знаменитый готическим собором (Дуомо), оперным театром Ла Скала и индустрией моды.")
city("IT", "venice", "Venice", "Venice, the city on the lagoon", "Венеция — город на лагуне",
     "City linking together 118 islands in a lagoon of the Adriatic, threaded by canals and narrow streets; for a thousand years it was the capital of the Venetian republic.",
     "Город, соединяющий 118 островов в лагуне Адриатики, пронизанный каналами и узкими улочками; тысячу лет был столицей Венецианской республики.")
city("IT", "florence", "Florence", "Florence, the cradle of the Renaissance", "Флоренция — колыбель Возрождения",
     "Capital of Tuscany on the Arno; ruled by the Medici family, it was the birthplace of the Renaissance and holds the Uffizi Gallery and Brunelleschi's cathedral dome.",
     "Столица Тосканы на реке Арно; под властью семьи Медичи стала родиной Возрождения, здесь находятся галерея Уффици и купол собора работы Брунеллески.")
city("IT", "naples", "Naples-Italy", "Naples under Vesuvius", "Неаполь под Везувием",
     "Chief city of southern Italy on the Bay of Naples beneath the volcano Vesuvius, which buried nearby Pompeii in 79 CE; founded by the Greeks as Neapolis.",
     "Главный город юга Италии на Неаполитанском заливе у подножия Везувия, засыпавшего соседние Помпеи в 79 году н. э.; основан греками как Неаполис.")

# ---------------------------------------------------------------- Spain
city("ES", "madrid", "Madrid", "Madrid, the capital at the centre of Spain", "Мадрид — столица в центре Испании",
     "Capital of Spain in the centre of the country; Philip II took the court to Madrid in 1561, and Philip III officially made it the national capital. The Prado museum and the Royal Palace are among its landmarks.",
     "Столица Испании в центре страны; Филипп II перенёс сюда двор в 1561 году, а Филипп III официально сделал город столицей. Среди достопримечательностей — музей Прадо и Королевский дворец.")
city("ES", "barcelona", "Barcelona", "Barcelona, the capital of Catalonia", "Барселона — столица Каталонии",
     "Spain's major Mediterranean port and commercial centre and the capital of Catalonia; it hosted the 1992 Summer Olympics and is famous for Antoni Gaudí's architecture.",
     "Главный средиземноморский порт и торговый центр Испании, столица Каталонии; принимала летнюю Олимпиаду 1992 года и знаменита архитектурой Антонио Гауди.")
city("ES", "seville", "Sevilla-Spain", "Seville on the Guadalquivir", "Севилья на Гвадалквивире",
     "Capital of Andalusia on the Guadalquivir and once the capital of Muslim Spain; from 1503 its Casa de Contratación directed the exploration of America, and its cathedral is among the largest Gothic churches.",
     "Столица Андалусии на Гвадалквивире, некогда столица мусульманской Испании; с 1503 года её Торговая палата руководила освоением Америки, а собор — один из крупнейших готических храмов.")
city("ES", "valencia", "Valencia-Spain", "Valencia and its huerta", "Валенсия и её уэрта",
     "Port on Spain's Mediterranean coast at the mouth of the Turia (Guadalaviar) River, surrounded by the irrigated market gardens of the Huerta de Valencia, whose rice is exported.",
     "Порт на средиземноморском побережье Испании в устье реки Турия (Гвадалавьяр), окружённый орошаемыми садами и полями Валенсийской уэрты, чей рис идёт на экспорт.")

# ---------------------------------------------------------------- Germany
city("DE", "berlin", "Berlin", "Berlin, the reunited capital", "Берлин — воссоединённая столица",
     "Capital of Germany on the Spree; divided by the Berlin Wall from 1961 to 1989, it became the capital of reunified Germany in 1990 and is the country's largest city.",
     "Столица Германии на Шпрее; разделённый Берлинской стеной с 1961 по 1989 год, в 1990 году стал столицей объединённой Германии и остаётся крупнейшим городом страны.")
city("DE", "munich", "Munich-Bavaria-Germany", "Munich, the capital of Bavaria", "Мюнхен — столица Баварии",
     "Capital of Bavaria on the Isar; in 1157 Henry the Lion granted the local monks the right to hold a market, the event counted as the city's founding; famous for the Oktoberfest and its museums.",
     "Столица Баварии на Изаре; в 1157 году Генрих Лев дал местным монахам право держать рынок, что считается основанием города; знаменит Октоберфестом и музеями.")
city("DE", "hamburg", "Hamburg-Germany", "Hamburg, the gateway to the world", "Гамбург — ворота в мир",
     "Germany's largest port and second largest city, on the Elbe; its role in the medieval Hanseatic League was second only to Lübeck's, and the harbour is called Hamburg's gateway to the world.",
     "Крупнейший порт и второй по величине город Германии на Эльбе; в средневековой Ганзе уступал по роли только Любеку, а его порт называют воротами Гамбурга в мир.")
city("DE", "cologne", "Cologne-Germany", "Cologne and its cathedral", "Кёльн и его собор",
     "City on the Rhine founded by the Romans as Colonia Claudia Ara Agrippinensium; its Gothic cathedral, begun in 1248 after a fire and completed only in 1880, is the largest Gothic church in northern Europe.",
     "Город на Рейне, основанный римлянами как Колония Клавдия Ара Агриппиненсиум; готический собор, начатый в 1248 году после пожара и завершённый лишь в 1880-м, — крупнейший готический храм Северной Европы.")
city("DE", "frankfurt", "Frankfurt-am-Main", "Frankfurt am Main, the financial centre", "Франкфурт-на-Майне — финансовый центр",
     "City on the Main River, the financial centre of Germany and seat of the European Central Bank; its international airport is one of the busiest in Europe, and Goethe was born here.",
     "Город на реке Майн, финансовый центр Германии и резиденция Европейского центрального банка; его аэропорт — один из самых загруженных в Европе, здесь родился Гёте.")

# ---------------------------------------------------------------- United Kingdom
city("GB", "london", "London", "London on the Thames", "Лондон на Темзе",
     "Capital of the United Kingdom on the Thames, founded by the Romans as Londinium; Westminster is the seat of Parliament and the monarchy, while the City is a global financial centre.",
     "Столица Соединённого Королевства на Темзе, основанная римлянами как Лондиниум; Вестминстер — резиденция парламента и монархии, а Сити — мировой финансовый центр.")
city("GB", "edinburgh", "Edinburgh-Scotland", "Edinburgh, the capital of Scotland", "Эдинбург — столица Шотландии",
     "Capital of Scotland built around a castle on a volcanic rock; its Old and New Towns are a UNESCO site, and every August the Edinburgh International Festival and the Fringe fill the city.",
     "Столица Шотландии, выросшая вокруг замка на вулканической скале; Старый и Новый город — объект ЮНЕСКО, а каждый август город наполняют Эдинбургский международный фестиваль и Фриндж.")
city("GB", "manchester", "Manchester-England", "Manchester, the city of the Industrial Revolution", "Манчестер — город промышленной революции",
     "City in north-west England at the forefront of the Industrial Revolution, an urban prototype built on cotton; by 1851 its textile industries led the world, and today it is known for its football clubs.",
     "Город на северо-западе Англии в авангарде промышленной революции, прообраз индустриального города, выросший на хлопке; к 1851 году его текстиль лидировал в мире, сегодня известен футбольными клубами.")
city("GB", "liverpool", "Liverpool-England", "Liverpool, the port of the Beatles", "Ливерпуль — порт «Битлз»",
     "Port on the Mersey estuary that grew rich in the 18th century on trade with the Americas, its docks outranking even London's; the Beatles emerged from its Cavern Club in the 1960s.",
     "Порт в устье Мерси, разбогатевший в XVIII веке на торговле с Америкой, его доки превосходили даже лондонские; в 1960-х из его клуба «Каверн» вышли «Битлз».")
city("GB", "oxford", "Oxford-England", "Oxford, the city of the university", "Оксфорд — город университета",
     "City on the Thames, there called the Isis, whose university, founded in the second half of the 12th century, is the oldest in England; its skyline of Gothic towers and steeples is famous.",
     "Город на Темзе, здесь называемой Айсис, чей университет, основанный во второй половине XII века, — старейший в Англии; знаменит силуэтом готических башен и шпилей.")

# ---------------------------------------------------------------- China
city("CN", "beijing", "Beijing", "Beijing, the northern capital", "Пекин — северная столица",
     "Capital of China: in 1267 the Yuan (Mongol) dynasty made it, as Dadu, the administrative capital; the Forbidden City of the Ming and Qing emperors stands at its centre, and it hosted the 2008 Olympics.",
     "Столица Китая: в 1267 году монгольская династия Юань сделала его, под именем Даду, административной столицей; в центре стоит Запретный город императоров Мин и Цин, город принимал Олимпиаду 2008 года.")
city("CN", "shanghai", "Shanghai", "Shanghai, the largest city of China", "Шанхай — крупнейший город Китая",
     "China's most populous city and one of the world's largest seaports, at the mouth of the Yangtze; the Pudong New District, established in 1993, holds the Jin Mao Tower and the Shanghai Tower.",
     "Самый населённый город Китая и один из крупнейших морских портов мира в устье Янцзы; в Новом районе Пудун, созданном в 1993 году, стоят башни Цзинь Мао и Шанхайская башня.")
city("CN", "xian", "Xian-China", "Xi'an, the ancient capital", "Сиань — древняя столица",
     "Capital of Shaanxi province and the ancient capital of several dynasties as Chang'an, the eastern end of the Silk Road; the Terracotta Army of the first emperor was found nearby in 1974.",
     "Столица провинции Шэньси и древняя столица нескольких династий под именем Чанъань, восточный конец Шёлкового пути; в 1974 году рядом нашли Терракотовую армию первого императора.")
city("CN", "hong-kong", "Hong-Kong", "Hong Kong, the special administrative region", "Гонконг — особый административный район",
     "Former British colony on the South China coast returned to China on 1 July 1997 as a special administrative region; a major financial centre and port.",
     "Бывшая британская колония на южном побережье Китая, возвращённая Китаю 1 июля 1997 года как особый административный район; крупный финансовый центр и порт.")
city("CN", "guangzhou", "Guangzhou", "Guangzhou (Canton) on the Pearl River", "Гуанчжоу (Кантон) на Жемчужной реке",
     "Capital of Guangdong on the Pearl River delta and the first Chinese port regularly visited by European traders, who called it Canton; its people speak Cantonese and its cuisine is famous.",
     "Столица Гуандуна в дельте Жемчужной реки, первый китайский порт, который регулярно посещали европейские купцы, называвшие его Кантоном; жители говорят по-кантонски, кухня знаменита.")

# ---------------------------------------------------------------- Japan
city("JP", "tokyo", "Tokyo", "Tokyo, the capital of Japan", "Токио — столица Японии",
     "Capital of Japan on Tokyo Bay and the largest urban and industrial agglomeration in Japan; with the Meiji Restoration of 1868 the capital was moved to Edo, which was renamed Tokyo.",
     "Столица Японии на Токийском заливе и крупнейшая городская и промышленная агломерация страны; после Реставрации Мэйдзи 1868 года столицу перенесли в Эдо, переименованный в Токио.")
city("JP", "kyoto", "Kyoto-Japan", "Kyoto, the old imperial capital", "Киото — старая императорская столица",
     "Capital of Japan for more than a thousand years, from 794 to 1868; its temples and gardens, including the Kinkaku Temple known as the Golden Pavilion, are a UNESCO site.",
     "Столица Японии более тысячи лет, с 794 по 1868 год; его храмы и сады, включая храм Кинкаку, известный как Золотой павильон, — объект ЮНЕСКО.")
city("JP", "osaka", "Osaka-Japan", "Osaka, the second metropolis of Japan", "Осака — вторая агломерация Японии",
     "Japan's second largest urban and industrial agglomeration, on Osaka Bay; Osaka Castle was built by the warlord Toyotomi Hideyoshi in the 16th century.",
     "Вторая по величине городская и промышленная агломерация Японии на Осакском заливе; замок Осака построил полководец Тоётоми Хидэёси в XVI веке.")
city("JP", "hiroshima", "Hiroshima-Japan", "Hiroshima and the Peace Memorial", "Хиросима и Мемориал мира",
     "City on the Inland Sea destroyed by the first atomic bomb used in war on 6 August 1945; the ruined Atomic Bomb Dome stands in the Peace Memorial Park as a UNESCO site.",
     "Город на Внутреннем Японском море, разрушенный первой боевой атомной бомбой 6 августа 1945 года; руины Купола атомной бомбы в Мемориальном парке мира — объект ЮНЕСКО.")
city("JP", "nara", "Nara-Japan", "Nara, the first permanent capital", "Нара — первая постоянная столица",
     "National capital of Japan from 710 to 784; its Todai Temple houses the Great Buddha, a giant bronze statue.",
     "Столица Японии с 710 по 784 год; в храме Тодай-дзи стоит Великий Будда — гигантская бронзовая статуя.")

# ---------------------------------------------------------------- India
city("IN", "mumbai", "Mumbai", "Mumbai, the gateway of India", "Мумбаи — ворота Индии",
     "India's largest city and financial capital, built on islands on the west coast; known as Bombay until 1995, it is the home of the Bollywood film industry.",
     "Крупнейший город и финансовая столица Индии, построенный на островах западного побережья; до 1995 года назывался Бомбеем, родина киноиндустрии Болливуда.")
city("IN", "delhi", "Delhi", "Delhi and New Delhi", "Дели и Нью-Дели",
     "Historic city on the Yamuna, capital of successive empires; New Delhi, built by the British from 1911, is the capital of India, while Old Delhi holds the Red Fort.",
     "Исторический город на Джамне, столица сменявших друг друга империй; Нью-Дели, построенный британцами с 1911 года, — столица Индии, а в Старом Дели стоит Красный форт.")
city("IN", "kolkata", "Kolkata", "Kolkata, the former capital of British India", "Калькутта — бывшая столица Британской Индии",
     "City on the Hugli River in West Bengal, capital of British India until 1911; known as Calcutta until 2001, it is a centre of Bengali culture and literature.",
     "Город на реке Хугли в Западной Бенгалии, столица Британской Индии до 1911 года; до 2001 года назывался Калькуттой, центр бенгальской культуры и литературы.")
city("IN", "jaipur", "Jaipur-India", "Jaipur, the Pink City", "Джайпур — Розовый город",
     "Capital of Rajasthan, founded in 1727 by Maharaja Sawai Jai Singh with straight-line planning; its rose-coloured buildings earned it the name pink city, and the Hawa Mahal (Hall of Winds) stands here.",
     "Столица Раджастхана, основанная в 1727 году махараджей Саваи Джай Сингхом с прямолинейной планировкой; розовые здания дали ей имя «розовый город», здесь стоит Хава-Махал (Дворец ветров).")
city("IN", "varanasi", "Varanasi", "Varanasi, the holy city on the Ganges", "Варанаси — священный город на Ганге",
     "One of the oldest continuously inhabited cities in the world and one of the seven sacred cities of Hinduism, where pilgrims bathe from the ghats on the Ganges; also known as Benares.",
     "Один из древнейших непрерывно населённых городов мира и один из семи священных городов индуизма, где паломники совершают омовения с гхатов на Ганге; известен и как Бенарес.")

# ---------------------------------------------------------------- Brazil
city("BR", "rio-de-janeiro", "Rio-de-Janeiro-Brazil", "Rio de Janeiro, the former capital", "Рио-де-Жанейро — бывшая столица",
     "Capital of independent Brazil from 1822 until 1960, set between mountains and the Atlantic on Guanabara Bay; famous for Sugarloaf, Copacabana beach, the statue of Christ the Redeemer and Carnival.",
     "Столица независимой Бразилии с 1822 по 1960 год между горами и Атлантикой на заливе Гуанабара; знаменит Сахарной головой, пляжем Копакабана, статуей Христа-Искупителя и карнавалом.")
city("BR", "sao-paulo", "Sao-Paulo-Brazil", "São Paulo, the largest city of South America", "Сан-Паулу — крупнейший город Южной Америки",
     "Brazil's largest city and the foremost industrial centre in Latin America, founded by Jesuit missionaries on 25 January 1554; the largest city of the Southern Hemisphere.",
     "Крупнейший город Бразилии и главный промышленный центр Латинской Америки, основанный миссионерами-иезуитами 25 января 1554 года; крупнейший город Южного полушария.")
city("BR", "brasilia", "Brasilia", "Brasília, the planned capital", "Бразилиа — спроектированная столица",
     "Capital of Brazil built from scratch on the central plateau and inaugurated in 1960; planned by Lúcio Costa with buildings by Oscar Niemeyer, it is a UNESCO site.",
     "Столица Бразилии, построенная с нуля на центральном плато и открытая в 1960 году; спланирована Лусио Костой со зданиями Оскара Нимейера, объект ЮНЕСКО.")
city("BR", "salvador", "Salvador-Brazil", "Salvador, the first capital of Brazil", "Салвадор — первая столица Бразилии",
     "Capital of Bahia state and the first capital of colonial Brazil (1549–1763); its colonial old town Pelourinho and Afro-Brazilian culture are famous.",
     "Столица штата Баия и первая столица колониальной Бразилии (1549–1763); знаменит колониальным старым городом Пелоуринью и афробразильской культурой.")

# ---------------------------------------------------------------- Egypt
city("EG", "cairo", "Cairo", "Cairo, the thousand-year city on the Nile", "Каир — тысячелетний город на Ниле",
     "Capital of Egypt on the Nile, a city for more than a thousand years with a medieval core built under the Fatimid dynasty; one of the largest cities in Africa, with the pyramids of Giza to its south-west.",
     "Столица Египта на Ниле, город с более чем тысячелетней историей и средневековым ядром, построенным при династии Фатимидов; один из крупнейших городов Африки, к юго-западу от которого стоят пирамиды Гизы.")
city("EG", "alexandria", "Alexandria-Egypt", "Alexandria, the city of Alexander", "Александрия — город Александра",
     "Mediterranean port founded by Alexander the Great in 332 BCE; in antiquity it held the great Library and the Pharos lighthouse, one of the Seven Wonders.",
     "Средиземноморский порт, основанный Александром Македонским в 332 году до н. э.; в древности здесь были великая Библиотека и Фаросский маяк — одно из семи чудес света.")
city("EG", "luxor", "Luxor", "Luxor, the ancient Thebes", "Луксор — древние Фивы",
     "City on the Nile on the site of ancient Thebes; the temples of Luxor and Karnak and, among the other Theban sites, the Valley of the Kings have been a UNESCO site since 1979.",
     "Город на Ниле на месте древних Фив; храмы Луксора и Карнака и, среди прочих фиванских памятников, Долина царей — объект ЮНЕСКО с 1979 года.")
city("EG", "aswan", "Aswan-Egypt", "Aswan at the First Cataract", "Асуан у первого порога",
     "City on the Nile just below the First Cataract, the southern frontier of pharaonic Egypt; the Aswan High Dam, completed in 1970, lies upstream.",
     "Город на Ниле чуть ниже первого порога, южная граница Египта фараонов; выше по течению стоит Асуанская высотная плотина, завершённая в 1970 году.")

# ---------------------------------------------------------------- Australia
city("AU", "sydney", "Sydney-New-South-Wales", "Sydney, the oldest city of Australia", "Сидней — старейший город Австралии",
     "Capital of New South Wales and Australia's largest city, founded in 1788 as the first British settlement on the continent; its harbour holds the Opera House and Harbour Bridge.",
     "Столица Нового Южного Уэльса и крупнейший город Австралии, основанный в 1788 году как первое британское поселение на континенте; в гавани стоят Оперный театр и мост Харбор-Бридж.")
city("AU", "melbourne", "Melbourne", "Melbourne, the former capital", "Мельбурн — бывшая столица",
     "Capital of Victoria on Port Phillip Bay, founded in 1835; when Australia became a commonwealth, Melbourne served as its federal capital until 1927, and it hosted the 1956 Olympics.",
     "Столица Виктории на заливе Порт-Филлип, основанная в 1835 году; когда Австралия стала федерацией, Мельбурн служил федеральной столицей до 1927 года; принимал Олимпиаду 1956 года.")
city("AU", "canberra", "Canberra", "Canberra, the planned federal capital", "Канберра — спроектированная федеральная столица",
     "Capital of Australia planned by Walter Burley Griffin; on 9 May 1927 the federal Parliament was officially transferred there from Melbourne, and Lake Burley Griffin is its centrepiece.",
     "Столица Австралии, спланированная Уолтером Бёрли Гриффином; 9 мая 1927 года федеральный парламент официально переехал сюда из Мельбурна, в центре города — озеро Бёрли-Гриффин.")
city("AU", "perth", "Perth-Western-Australia", "Perth on the Swan River", "Перт на реке Суон",
     "Capital of Western Australia on the Swan River, where a colony was declared in 1829; the fourth largest city in Australia.",
     "Столица Западной Австралии на реке Суон, где в 1829 году была провозглашена колония; четвёртый по величине город Австралии.")

# ---------------------------------------------------------------- Canada
city("CA", "toronto", "Toronto", "Toronto, the largest city of Canada", "Торонто — крупнейший город Канады",
     "Capital of Ontario on Lake Ontario and Canada's largest city and financial centre; known as York until 1834, it is famous for the CN Tower.",
     "Столица Онтарио на озере Онтарио, крупнейший город и финансовый центр Канады; до 1834 года назывался Йорком, знаменит башней Си-Эн.")
city("CA", "montreal", "Montreal", "Montreal, the French-speaking metropolis", "Монреаль — франкоязычный мегаполис",
     "Largest city of Quebec on an island in the St. Lawrence River, founded in 1642; the second largest French-speaking city in the world after Paris, it hosted Expo 67 and the 1976 Olympics.",
     "Крупнейший город Квебека на острове в реке Святого Лаврентия, основанный в 1642 году; второй по величине франкоязычный город мира после Парижа, принимал Экспо-67 и Олимпиаду 1976 года.")
city("CA", "vancouver", "Vancouver", "Vancouver, the Pacific gateway", "Ванкувер — тихоокеанские ворота",
     "Canada's chief Pacific port in British Columbia, set between the sea and the Coast Mountains; incorporated in 1886, it hosted the 2010 Winter Olympics.",
     "Главный тихоокеанский порт Канады в Британской Колумбии между морем и Береговым хребтом; получил статус города в 1886 году, принимал зимнюю Олимпиаду 2010 года.")
city("CA", "quebec-city", "Quebec", "Quebec City, the walled capital", "Квебек — столица за крепостными стенами",
     "Capital of Quebec province, founded by Samuel de Champlain in 1608 on the St. Lawrence; the only walled city north of Mexico, its old town is a UNESCO site.",
     "Столица провинции Квебек, основанная Самюэлем де Шампленом в 1608 году на реке Святого Лаврентия; единственный город с крепостными стенами к северу от Мексики, старый город — объект ЮНЕСКО.")

# ---------------------------------------------------------------- Mexico
city("MX", "mexico-city", "Mexico-City", "Mexico City on the site of Tenochtitlán", "Мехико на месте Теночтитлана",
     "Capital of Mexico built by the Spanish from 1521 on the ruins of the Aztec capital Tenochtitlán in the Valley of Mexico; one of the most populous cities in the world.",
     "Столица Мексики, построенная испанцами с 1521 года на руинах ацтекской столицы Теночтитлан в долине Мехико; один из самых населённых городов мира.")
city("MX", "guadalajara", "Guadalajara-Mexico", "Guadalajara, the second city of Mexico", "Гвадалахара — второй город Мексики",
     "Capital of Jalisco, founded by the Spanish in 1531 and relocated several times until the 1540s; by the 1970s it was Mexico's second largest city.",
     "Столица Халиско, основанная испанцами в 1531 году и несколько раз переносившаяся до 1540-х; к 1970-м годам стала вторым по величине городом Мексики.")
city("MX", "cancun", "Cancun", "Cancún, the resort on the Caribbean", "Канкун — курорт на Карибах",
     "Resort on the Caribbean coast of the Yucatán Peninsula, a settlement of about 100 Maya until 1970; built on Isla Cancún, linked to the mainland by a causeway, it draws tourists from the US and Europe.",
     "Курорт на карибском побережье полуострова Юкатан, до 1970 года посёлок примерно ста майя; построен на острове Канкун, соединённом с материком дамбой, принимает туристов из США и Европы.")
city("MX", "oaxaca", "Oaxaca-Mexico", "Oaxaca, the city of the Zapotecs", "Оахака — город сапотеков",
     "Capital of Oaxaca state in the southern highlands, founded by the Spanish in the 1520s near the Zapotec hilltop city of Monte Albán; its colonial centre is a UNESCO site.",
     "Столица штата Оахака в южном нагорье, основанная испанцами в 1520-х годах близ сапотекского города на холме Монте-Альбан; колониальный центр — объект ЮНЕСКО.")

# ---------------------------------------------------------------- Netherlands, Greece, Portugal
city("NL", "amsterdam", "Amsterdam", "Amsterdam, the city of canals", "Амстердам — город каналов",
     "Capital of the Netherlands laid out around three main canals dating from the early 17th century; the seat of government is in The Hague, and the city holds the Rijksmuseum and the Anne Frank House.",
     "Столица Нидерландов, распланированная вокруг трёх главных каналов начала XVII века; правительство заседает в Гааге, а в городе — Рейксмузей и дом Анны Франк.")
city("NL", "rotterdam", "Rotterdam-Netherlands", "Rotterdam, the port of Europe", "Роттердам — порт Европы",
     "City on the Rhine–Meuse delta whose harbour and Europoort are the largest in the world by capacity; devastated by bombing in the Second World War, it got a totally new inner city of modern architecture.",
     "Город в дельте Рейна и Мааса, чей порт с Европортом — крупнейший в мире по мощности; разрушенный бомбардировками Второй мировой, получил совершенно новый центр современной архитектуры.")
city("NL", "the-hague", "The-Hague", "The Hague, the seat of government", "Гаага — резиденция правительства",
     "Seat of the Dutch government, parliament and royal court, although Amsterdam is the capital; it also hosts the International Court of Justice in the Peace Palace.",
     "Резиденция правительства, парламента и королевского двора Нидерландов, хотя столица — Амстердам; здесь же во Дворце мира заседает Международный суд ООН.")
city("GR", "athens", "Athens", "Athens, the cradle of democracy", "Афины — колыбель демократии",
     "Capital of Greece, dominated by the Acropolis with the Parthenon; the birthplace of Western civilization, it hosted the revival of the Olympic Games in 1896.",
     "Столица Греции, над которой возвышается Акрополь с Парфеноном; колыбель западной цивилизации, в 1896 году приняла возрождённые Олимпийские игры.")
city("GR", "thessaloniki", "Thessaloniki", "Thessaloniki, the second city of Greece", "Салоники — второй город Греции",
     "Port city on the Gulf of Thermai founded in 316 BCE and named for a sister of Alexander the Great; the second city of the Byzantine Empire, rich in Byzantine churches.",
     "Портовый город на заливе Термаикос, основанный в 316 году до н. э. и названный в честь сестры Александра Македонского; второй город Византийской империи, богатый византийскими церквями.")
city("PT", "lisbon", "Lisbon", "Lisbon on the Tagus", "Лиссабон на Тежу",
     "Capital of Portugal on the estuary of the Tagus, rebuilt after the great earthquake of 1755; Vasco da Gama led a Portuguese fleet to India in 1498.",
     "Столица Португалии в устье Тежу, отстроенная после великого землетрясения 1755 года; в 1498 году Васко да Гама привёл португальский флот в Индию.")
city("PT", "porto", "Porto-Portugal", "Porto, the city of port wine", "Порту — город портвейна",
     "Portugal's second city at the mouth of the Douro, called Portus Cale in Roman times; port wine is blended and stored in the red-tiled warehouses of Vila Nova de Gaia across the river.",
     "Второй город Португалии в устье Дору, в римские времена называвшийся Портус-Кале; портвейн купажируют и хранят в складах под красной черепицей в Вила-Нова-ди-Гая на другом берегу.")

# ---------------------------------------------------------------- Americas and Africa
city("AR", "buenos-aires", "Buenos-Aires", "Buenos Aires, the Paris of South America", "Буэнос-Айрес — Париж Южной Америки",
     "Capital of Argentina on the Río de la Plata estuary, called a miniature Paris; tango originated in its lower-class districts, and the Teatro Colón and the Casa Rosada stand here.",
     "Столица Аргентины на эстуарии Ла-Платы, прозванная маленьким Парижем; танго родилось в её бедных кварталах, здесь стоят театр Колон и Каса Росада.")
city("ZA", "cape-town", "Cape-Town", "Cape Town, the Mother City", "Кейптаун — город-мать",
     "Legislative capital of South Africa at the foot of Table Mountain, founded by the Dutch East India Company in 1652 as a supply station on the route to the East.",
     "Законодательная столица ЮАР у подножия Столовой горы, основанная Голландской Ост-Индской компанией в 1652 году как станция снабжения на пути на Восток.")
city("ZA", "johannesburg", "Johannesburg-South-Africa", "Johannesburg, the city of gold", "Йоханнесбург — город золота",
     "South Africa's chief industrial and financial metropolis, founded in 1886 following the discovery of gold on the Witwatersrand; Soweto township lies 10 miles to its south-west.",
     "Главный промышленный и финансовый центр ЮАР, основанный в 1886 году после открытия золота на Витватерсранде; в 10 милях к юго-западу лежит тауншип Соуэто.")
city("PE", "lima", "Lima", "Lima, the City of Kings", "Лима — Город королей",
     "Capital of Peru on the Pacific coast, founded by Francisco Pizarro in 1535 as the City of Kings and the seat of Spanish rule in South America for centuries.",
     "Столица Перу на тихоокеанском побережье, основанная Франсиско Писарро в 1535 году как Город королей и веками бывшая центром испанской власти в Южной Америке.")
city("PE", "cusco", "Cuzco", "Cusco, the capital of the Incas", "Куско — столица инков",
     "City in the Andes at about 3,400 m, the capital of the Inca Empire until the Spanish conquest in 1533; Inca stonework survives beneath its colonial buildings, and Machu Picchu lies nearby.",
     "Город в Андах на высоте около 3400 м, столица империи инков до испанского завоевания в 1533 году; кладка инков сохранилась под колониальными зданиями, неподалёку — Мачу-Пикчу.")
city("MA", "marrakech", "Marrakech", "Marrakech, the first imperial city", "Марракеш — первый имперский город",
     "First of Morocco's four imperial cities, founded in the mid-11th century by Yusuf ibn Tashufin of the Almoravid dynasty; the Koutoubia minaret and the Jamaa el-Fna square are famous.",
     "Первый из четырёх имперских городов Марокко, основанный в середине XI века Юсуфом ибн Ташфином из династии Альморавидов; знамениты минарет Кутубия и площадь Джемаа-эль-Фна.")
city("MA", "casablanca", "Casablanca-Morocco", "Casablanca, the economic capital of Morocco", "Касабланка — экономическая столица Марокко",
     "Morocco's principal port on the Atlantic, which became the country's chief port during the French protectorate (1912–56); its Hassan II Mosque is one of the largest and most ornate in the world.",
     "Главный порт Марокко на Атлантике, ставший главным портом страны при французском протекторате (1912–56); мечеть Хасана II — одна из крупнейших и самых нарядных в мире.")

# ---------------------------------------------------------------- Asia and Middle East
city("KR", "seoul", "Seoul", "Seoul on the Han River", "Сеул на реке Ханган",
     "Capital of South Korea on the Han River and the capital of Korea since 1394; it hosted the 1988 Summer Olympics.",
     "Столица Южной Кореи на реке Ханган и столица Кореи с 1394 года; принимала летнюю Олимпиаду 1988 года.")
city("KR", "busan", "Busan", "Busan, the port of Korea", "Пусан — порт Кореи",
     "South Korea's second city and largest port on the south-east coast; it served as the temporary capital during the Korean War and hosts an international film festival.",
     "Второй город Южной Кореи и крупнейший порт на юго-восточном побережье; во время Корейской войны служил временной столицей, проводит международный кинофестиваль.")
city("TH", "bangkok", "Bangkok", "Bangkok, the city of angels", "Бангкок — город ангелов",
     "Capital of Thailand on the Chao Phraya River, founded as the capital in 1782; the Grand Palace and the Temple of the Emerald Buddha stand on the river, and its Thai name is Krung Thep.",
     "Столица Таиланда на реке Чаупхрая, ставшая столицей в 1782 году; на берегу стоят Большой дворец и храм Изумрудного Будды, а тайское имя города — Крунгтхеп.")
city("TH", "chiang-mai", "Chiang-Mai", "Chiang Mai, the rose of the north", "Чиангмай — роза севера",
     "Largest city of northern Thailand, founded in 1296 as the capital of the Lanna kingdom; its walled old town is full of temples, and it is a centre of handicrafts.",
     "Крупнейший город севера Таиланда, основанный в 1296 году как столица королевства Ланна; старый город в стенах полон храмов, центр ремёсел.")
city("AE", "dubai", "Dubai-United-Arab-Emirates", "Dubai, from pearls to skyscrapers", "Дубай — от жемчуга до небоскрёбов",
     "One of the wealthiest of the seven emirates, on the Persian Gulf; it grew from pearl diving and trade into a hub of finance, aviation and tourism crowned by the Burj Khalifa.",
     "Один из богатейших из семи эмиратов на Персидском заливе; вырос из ловли жемчуга и торговли в центр финансов, авиации и туризма, увенчанный Бурдж-Халифой.")
city("AE", "abu-dhabi", "Abu-Dhabi", "Abu Dhabi, the capital of the Emirates", "Абу-Даби — столица Эмиратов",
     "Capital of the UAE on a small triangular island off the Persian Gulf coast; rich oil fields discovered in 1958 and in commercial production since 1962 made it wealthy.",
     "Столица ОАЭ на небольшом треугольном острове у побережья Персидского залива; богатые нефтяные месторождения, открытые в 1958 году и разрабатываемые с 1962-го, принесли ей богатство.")
city("VN", "hanoi", "Hanoi", "Hanoi, the capital on the Red River", "Ханой — столица на Красной реке",
     "Capital of Vietnam on the Red River; in 1010 the emperor Ly Thai To chose the site for his capital.",
     "Столица Вьетнама на Красной реке; в 1010 году император Ли Тхай То выбрал это место для своей столицы.")
city("VN", "ho-chi-minh-city", "Ho-Chi-Minh-City", "Ho Chi Minh City, the former Saigon", "Хошимин — бывший Сайгон",
     "Vietnam's largest city, north of the Mekong delta; as Saigon it was the capital of South Vietnam (1954–75) and was renamed after North Vietnamese troops captured it on 30 April 1975.",
     "Крупнейший город Вьетнама к северу от дельты Меконга; как Сайгон был столицей Южного Вьетнама (1954–75) и был переименован после взятия северовьетнамскими войсками 30 апреля 1975 года.")
city("IL", "jerusalem", "Jerusalem", "Jerusalem, the holy city of three faiths", "Иерусалим — святой город трёх религий",
     "Ancient city sacred to Judaism, Christianity and Islam; its walled Old City holds the Western Wall, the Church of the Holy Sepulchre and the Dome of the Rock.",
     "Древний город, священный для иудаизма, христианства и ислама; в его Старом городе за стенами — Стена Плача, храм Гроба Господня и Купол Скалы.")
city("IL", "tel-aviv", "Tel-Aviv-Yafo", "Tel Aviv, the city that never stops", "Тель-Авив — город, который не останавливается",
     "Mediterranean city founded in 1909 beside the ancient port of Jaffa, with which it merged in 1950; Israel's economic centre, its Bauhaus White City is a UNESCO site.",
     "Средиземноморский город, основанный в 1909 году рядом с древним портом Яффа, с которым объединился в 1950 году; экономический центр Израиля, его Белый город в стиле баухаус — объект ЮНЕСКО.")

# ---------------------------------------------------------------- Central and Northern Europe
city("CZ", "prague", "Prague", "Prague, the city of a hundred spires", "Прага — город ста шпилей",
     "Capital of the Czech Republic on the Vltava, a royal capital of the Holy Roman Empire under Charles IV in the 14th century; its castle, Charles Bridge and Old Town are a UNESCO site.",
     "Столица Чехии на Влтаве, в XIV веке при Карле IV столица Священной Римской империи; Пражский Град, Карлов мост и Старый город — объект ЮНЕСКО.")
city("AT", "vienna", "Vienna", "Vienna, the imperial capital on the Danube", "Вена — имперская столица на Дунае",
     "Capital of Austria on the Danube and for centuries the seat of the Habsburgs; the city of Mozart, Beethoven and Strauss, with the Hofburg and Schönbrunn palaces.",
     "Столица Австрии на Дунае, веками резиденция Габсбургов; город Моцарта, Бетховена и Штрауса с дворцами Хофбург и Шёнбрунн.")
city("AT", "salzburg", "Salzburg-Austria", "Salzburg, the city of Mozart", "Зальцбург — город Моцарта",
     "City on the Salzach whose archbishops, acknowledged princes of the Holy Roman Empire in 1278, resided in the Hohensalzburg fortress; Mozart's birthplace and home of the Salzburg Festival.",
     "Город на Зальцахе, чьи архиепископы, признанные князьями Священной Римской империи в 1278 году, жили в крепости Хоэнзальцбург; родина Моцарта и дом Зальцбургского фестиваля.")
city("PL", "warsaw", "Warsaw", "Warsaw, the rebuilt capital", "Варшава — восстановленная столица",
     "Capital of Poland on the Vistula since 1611, when the king and his court moved from Kraków; razed in 1944, its Old Town was rebuilt so faithfully that it is a UNESCO site.",
     "Столица Польши на Висле с 1611 года, когда король и двор переехали из Кракова; разрушенный в 1944 году Старый город восстановили так точно, что он стал объектом ЮНЕСКО.")
city("PL", "krakow", "Krakow", "Kraków, the old royal capital", "Краков — старая королевская столица",
     "Royal capital of Poland until Sigismund III Vasa moved the capital to Warsaw by 1611, with the kings' seat at Wawel Castle; its Main Square dates from the 13th century, and the Jagiellonian University is famous.",
     "Королевская столица Польши, пока король Сигизмунд III Ваза к 1611 году не перенёс столицу в Варшаву; резиденция королей — замок Вавель, Рыночная площадь существует с XIII века, знаменит Ягеллонский университет.")
city("SE", "stockholm", "Stockholm", "Stockholm on the islands", "Стокгольм на островах",
     "Capital of Sweden built on numerous islands where Lake Mälaren meets the Baltic, first mentioned as a town in 1252; the Royal Swedish Academy of Sciences here selects Nobel laureates.",
     "Столица Швеции на многочисленных островах там, где озеро Меларен встречается с Балтикой; впервые упомянута как город в 1252 году; здесь Королевская академия наук выбирает нобелевских лауреатов.")
city("NO", "oslo", "Oslo", "Oslo at the head of the fjord", "Осло в глубине фьорда",
     "Capital of Norway at the head of the Oslofjord, founded by King Harald Hardraade about 1050; renamed Christiania after the fire of 1624, it was given back its name Oslo in 1925.",
     "Столица Норвегии в глубине Осло-фьорда, основанная королём Харальдом Суровым около 1050 года; после пожара 1624 года переименована в Христианию, имя Осло возвращено в 1925 году.")
city("NO", "bergen", "Bergen-Norway", "Bergen, the gateway to the fjords", "Берген — ворота фьордов",
     "Norway's second largest city, on the west coast, founded in 1070 by King Olaf III and the capital in the 12th and 13th centuries; the Hanseatic wharf of Bryggen is a UNESCO site.",
     "Второй по величине город Норвегии на западном побережье, основанный в 1070 году королём Олафом III и бывший столицей в XII–XIII веках; ганзейская набережная Брюгген — объект ЮНЕСКО.")
city("CH", "zurich", "Zurich", "Zurich, the largest Swiss city", "Цюрих — крупнейший город Швейцарии",
     "Largest city of Switzerland at the northern end of Lake Zurich, a banking and financial centre; the Reformation under Zwingli began here in the 16th century.",
     "Крупнейший город Швейцарии на северной оконечности Цюрихского озера, банковский и финансовый центр; в XVI веке здесь началась Реформация Цвингли.")
city("CH", "geneva", "Geneva-Switzerland", "Geneva, the city of international organisations", "Женева — город международных организаций",
     "City at the western end of Lake Geneva on the Rhône, Calvin's Protestant Rome in the 16th century; the European seat of the United Nations and home of the Red Cross.",
     "Город на западной оконечности Женевского озера на Роне, в XVI веке протестантский Рим Кальвина; европейская резиденция ООН и родина Красного Креста.")
city("CH", "bern", "Bern", "Bern, the federal city", "Берн — федеральный город",
     "Capital of Switzerland on a bend of the Aare River, founded in 1191; its medieval old town with arcades and the Zytglogge clock tower is a UNESCO site.",
     "Столица Швейцарии в излучине реки Аре, основанная в 1191 году; средневековый старый город с аркадами и часовой башней Цитглогге — объект ЮНЕСКО.")

Path(__file__).with_name("delta.json").write_text(
    json.dumps({"sources": S, "countries": dict(C)}, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8", newline="\n")
print(sum(len(v) for v in C.values()), "items in", len(C), "countries,", len(S), "sources")
