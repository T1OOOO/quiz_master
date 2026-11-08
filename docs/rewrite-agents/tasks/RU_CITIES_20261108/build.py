"""Build delta.json with facts about well-known Russian cities for country_links.json (RU).

Every claim below was checked against the cited page opened in a browser on 2026-11-08
(see notes.md). Run: python build.py -> writes delta.json; then validate.py, then merge.py.
"""
import json
from pathlib import Path

S = []  # sources
I = []  # items


def src(sid, title, url):
    S.append({"id": sid, "title": title, "url": url})
    return sid


def add(iid, kind, en, ru, rel_en, rel_ru, sid):
    I.append({
        "id": "ruc-" + iid, "kind": kind, "name_en": en, "name_ru": ru,
        "relation_en": rel_en, "relation_ru": rel_ru, "source_id": sid,
    })


B = "https://www.britannica.com/place/"
U = "https://whc.unesco.org/en/list/"

# ---------------------------------------------------------------- Saint Petersburg
spb = src("ruc-brit-saint-petersburg", "Britannica: St. Petersburg", B + "St-Petersburg-Russia")
add("spb-peter-and-paul-fortress", "landmark",
    "Peter and Paul Fortress in Saint Petersburg", "Петропавловская крепость в Санкт-Петербурге",
    "Fortress on Zayachy (Hare) Island whose foundation Peter I laid on 27 May 1703, the date taken as the founding of the city; its cathedral with a golden spire holds the tombs of almost all tsars from Peter I onwards.",
    "Крепость на Заячьем острове, заложенная Петром I 27 мая 1703 года — эта дата считается днём основания города; в её соборе с золочёным шпилем покоятся почти все императоры начиная с Петра I.",
    spb)
add("spb-white-nights", "fact",
    "White Nights of Saint Petersburg", "Белые ночи Санкт-Петербурга",
    "The city lies only about 7° south of the Arctic Circle, so around the summer solstice daylight lasts nearly 19 hours and the sky never gets fully dark; the White Nights are celebrated with festivals.",
    "Город лежит всего примерно на 7° южнее полярного круга, поэтому около летнего солнцестояния светлое время длится почти 19 часов и небо не темнеет полностью; на белые ночи приходятся фестивали.",
    spb)
add("spb-drawbridges-neva", "bridge",
    "Drawbridges over the Neva in Saint Petersburg", "Разводные мосты Невы в Санкт-Петербурге",
    "Saint Petersburg spreads across 42 islands linked by bridges; each night in the White Nights season the bridges spanning the Neva are raised to let boat traffic through.",
    "Санкт-Петербург раскинулся на 42 островах, соединённых мостами; каждую ночь в сезон белых ночей мосты через Неву разводят, чтобы пропустить суда.",
    spb)
add("spb-venice-of-the-north", "fact",
    "Saint Petersburg, the \"Venice of the North\"", "Санкт-Петербург — «Северная Венеция»",
    "Built from 1703 on a marshy site in the Neva delta and the capital of Russia for two centuries (1712–1918), the city is threaded by rivers and canals, which earned it the nickname Venice of the North.",
    "Построенный с 1703 года на болотистом месте в дельте Невы и бывший столицей России два века (1712–1918), город пронизан реками и каналами, за что его прозвали Северной Венецией.",
    spb)
add("spb-peterhof-grand-cascade", "landmark",
    "Peterhof and its Grand Cascade near Saint Petersburg", "Петергоф и Большой каскад под Санкт-Петербургом",
    "Imperial residence built in 1714–1728 for Peter I on the Gulf of Finland; its Grand Cascade combines a grotto, 64 fountains and two cascading staircases, and the ensemble is part of the UNESCO site.",
    "Императорская резиденция, построенная в 1714–1728 годах для Петра I на берегу Финского залива; Большой каскад объединяет грот, 64 фонтана и две каскадные лестницы, ансамбль входит в объект ЮНЕСКО.",
    spb)
siege = src("ruc-brit-siege-of-leningrad", "Britannica: Siege of Leningrad", "https://www.britannica.com/event/Siege-of-Leningrad")
add("spb-siege-of-leningrad", "fact",
    "Siege of Leningrad (1941–1944)", "Блокада Ленинграда (1941–1944)",
    "German and Finnish forces besieged Leningrad from 8 September 1941 to 27 January 1944, 872 days, known as the 900-day siege; supplies reached the city only across Lake Ladoga, by truck and over the ice in winter.",
    "Немецкие и финские войска осаждали Ленинград с 8 сентября 1941 по 27 января 1944 года — 872 дня, известные как 900-дневная блокада; снабжение шло лишь через Ладожское озеро, зимой по льду.",
    siege)
kunst = src("ruc-kunstkamera-official", "Kunstkamera (Peter the Great Museum of Anthropology and Ethnography): History", "https://www.kunstkamera.ru/en/museum/kunst_hist/")
add("spb-kunstkamera", "landmark",
    "Kunstkamera in Saint Petersburg", "Кунсткамера в Санкт-Петербурге",
    "The first Russian museum, established in 1714 on a site chosen by Peter I; its building on the Neva embankment, crowned by a tower with an armillary sphere, houses anthropology and ethnography collections.",
    "Первый российский музей, учреждённый в 1714 году на месте, выбранном Петром I; здание на набережной Невы, увенчанное башней с армиллярной сферой, хранит собрания по антропологии и этнографии.",
    kunst)
zenit = src("ruc-fc-zenit-official", "FC Zenit Saint Petersburg: official site (club history and trophies)", "https://fc-zenit.ru/")
add("spb-fc-zenit", "sports_team",
    "FC Zenit Saint Petersburg", "ФК «Зенит» (Санкт-Петербург)",
    "Football club from Saint Petersburg founded on 25 May 1925; winner of the UEFA Cup and UEFA Super Cup in 2008 and many-time Russian champion, it plays at the Gazprom Arena.",
    "Футбольный клуб из Санкт-Петербурга, основанный 25 мая 1925 года; обладатель Кубка и Суперкубка УЕФА 2008 года и многократный чемпион России, играет на «Газпром Арене».",
    zenit)

# ---------------------------------------------------------------- Moscow
msk = src("ruc-brit-moscow", "Britannica: Moscow", B + "Moscow")
add("moscow-first-mention-1147", "fact",
    "First chronicle mention of Moscow in 1147", "Первое летописное упоминание Москвы в 1147 году",
    "Moscow is first mentioned in the chronicles under 1147, when Prince Yury Dolgoruky hosted a great banquet there for his ally; this traditional founding date let the city mark its 800th anniversary in 1947.",
    "Москва впервые упомянута в летописи под 1147 годом, когда князь Юрий Долгорукий дал здесь пир своему союзнику; это традиционная дата основания, и в 1947 году город отметил 800-летие.",
    msk)
add("moscow-metro-1935", "fact",
    "Moscow Metro, begun in 1935", "Московский метрополитен, открытый в 1935 году",
    "The Moscow Metro was begun in 1935 and is renowned for the elaborate architecture of its stations, decorated with marble, stained glass, statuary and chandeliers.",
    "Московское метро открыто в 1935 году и знаменито пышной архитектурой станций, украшенных мрамором, витражами, скульптурой и люстрами.",
    msk)
add("moscow-stalin-skyscrapers", "landmark",
    "Stalin-era skyscrapers (vysotki) in Moscow", "Сталинские высотки в Москве",
    "Ornate tiered high-rises known as vysotki built in Moscow in the late 1940s and early 1950s under Stalin; the Ministry of Foreign Affairs and the main building of Moscow State University are among them.",
    "Нарядные ступенчатые высотные здания, построенные в Москве в конце 1940-х — начале 1950-х годов при Сталине; среди них здание МИД и главный корпус МГУ.",
    msk)
tret = src("ruc-tretyakov-official", "State Tretyakov Gallery: History of the gallery", "https://www.tretyakovgallery.ru/about/history/")
add("moscow-tretyakov-gallery", "landmark",
    "Tretyakov Gallery in Moscow", "Третьяковская галерея в Москве",
    "National museum of Russian art grown from the collection of the merchant Pavel Tretyakov, who gave it to the city of Moscow in August 1892; his icons began its collection of medieval Russian painting.",
    "Национальный музей русского искусства, выросший из собрания купца Павла Третьякова, который в августе 1892 года передал его в дар Москве; с его икон началась коллекция древнерусской живописи.",
    tret)
add("moscow-kolomenskoye-ascension", "landmark",
    "Church of the Ascension at Kolomenskoye in Moscow", "Церковь Вознесения в Коломенском (Москва)",
    "Tent-roofed stone church built in 1532 at the royal estate of Kolomenskoye to celebrate the birth of the prince who became Tsar Ivan IV the Terrible; a UNESCO World Heritage site since 1994.",
    "Шатровая каменная церковь, возведённая в 1532 году в царской усадьбе Коломенское в честь рождения будущего царя Ивана IV Грозного; объект Всемирного наследия ЮНЕСКО с 1994 года.",
    src("ruc-unesco-kolomenskoye", "UNESCO World Heritage Centre: Church of the Ascension, Kolomenskoye", U + "634/"))
add("moscow-novodevichy-convent", "landmark",
    "Novodevichy Convent in Moscow", "Новодевичий монастырь в Москве",
    "Convent founded by Grand Duke Vasily III in the 1520s by a crossing of the Moskva River, a landmark of the \"Moscow Baroque\"; women of the tsar's family were cloistered and buried here.",
    "Монастырь, основанный великим князем Василием III в 1520-х годах у переправы через Москву-реку, памятник «московского барокко»; здесь принимали постриг и были погребены женщины царской семьи.",
    src("ruc-unesco-novodevichy", "UNESCO World Heritage Centre: Ensemble of the Novodevichy Convent", U + "1097/"))

# ---------------------------------------------------------------- Kazan
kzn = src("ruc-unesco-kazan-kremlin", "UNESCO World Heritage Centre: Historic and Architectural Complex of the Kazan Kremlin", U + "980/")
add("kazan-kremlin", "landmark",
    "Kazan Kremlin", "Казанский кремль",
    "Fortress of the former Tatar khanate conquered by Ivan the Terrible in 1552; the complex holds the Annunciation Cathedral, the Syuyumbike Tower and a modern mosque, and is a UNESCO World Heritage site.",
    "Крепость бывшего Казанского ханства, завоёванная Иваном Грозным в 1552 году; в комплексе — Благовещенский собор, башня Сююмбике и современная мечеть; объект Всемирного наследия ЮНЕСКО.",
    kzn)
add("kazan-chak-chak", "food",
    "Chak-chak, the sweet of Kazan", "Чак-чак — казанское лакомство",
    "Tatar dessert of crisp fried dough drenched in honey, the best-known sweet of Tatarstan; Kazan's Old Tatar Quarter even has a Chak-Chak Museum.",
    "Татарский десерт из хрустящих обжаренных кусочков теста, залитых мёдом, самое известное лакомство Татарстана; в Старо-Татарской слободе Казани есть даже музей чак-чака.",
    src("ruc-visit-tatarstan-gastronomy", "Visit Tatarstan: Gastronomic pleasures in Tatarstan", "https://visit-tatarstan.com/en/guides/gastronomicheskie-udovolstviya-v-tatarstane/"))

# ---------------------------------------------------------------- Nizhny Novgorod
nn = src("ruc-brit-nizhny-novgorod", "Britannica: Nizhny Novgorod", B + "Nizhny-Novgorod")
add("nizhny-novgorod-kremlin", "landmark",
    "Nizhny Novgorod Kremlin", "Нижегородский кремль",
    "Fortress on the high bank at the confluence of the Oka and the Volga; the city was founded here in 1221 by Yury Vsevolodovich, prince of Vladimir, as a stronghold on the eastern frontier.",
    "Крепость на высоком берегу при слиянии Оки и Волги; город основал здесь в 1221 году владимирский князь Юрий Всеволодович как опорный пункт на восточной границе.",
    nn)
add("nizhny-novgorod-fair", "fact",
    "Nizhny Novgorod Fair", "Нижегородская ярмарка",
    "The annual fair established at Nizhny Novgorod in 1817 became the largest and most important in Russia, drawing merchants from across the empire and from Asia every summer.",
    "Ежегодная ярмарка, учреждённая в Нижнем Новгороде в 1817 году, стала крупнейшей и важнейшей в России, каждое лето собирая купцов со всей империи и из Азии.",
    nn)
add("nizhny-novgorod-gorky", "fact",
    "Nizhny Novgorod as the city of Gorky", "Нижний Новгород как город Горький",
    "The writer Maxim Gorky was born in Nizhny Novgorod in 1868; in 1932 the city was renamed Gorky in his honour, and its historical name was restored in 1990.",
    "Писатель Максим Горький родился в Нижнем Новгороде в 1868 году; в 1932 году город переименовали в Горький в его честь, историческое имя вернули в 1990 году.",
    nn)

# ---------------------------------------------------------------- Yekaterinburg
ekb = src("ruc-brit-yekaterinburg", "Britannica: Yekaterinburg", B + "Yekaterinburg")
add("yekaterinburg-founded-1723", "fact",
    "Yekaterinburg, the cultural centre of the Urals", "Екатеринбург — центр Урала",
    "Grew from an ironworks begun in 1721 and was named in 1723 after Empress Catherine I; called Sverdlovsk from 1924 to 1991, it lies just east of the border between Europe and Asia.",
    "Вырос из железоделательного завода, заложенного в 1721 году, и в 1723 году назван в честь императрицы Екатерины I; с 1924 по 1991 год носил имя Свердловск, лежит чуть восточнее границы Европы и Азии.",
    ekb)
add("yekaterinburg-last-tsar", "fact",
    "Yekaterinburg and the execution of the last tsar", "Екатеринбург и расстрел последнего царя",
    "In July 1918, during the Civil War, the last tsar Nicholas II and his family were executed in Yekaterinburg, where they had been held by the Bolsheviks.",
    "В июле 1918 года, во время Гражданской войны, в Екатеринбурге были расстреляны последний царь Николай II и его семья, которых удерживали здесь большевики.",
    ekb)

# ---------------------------------------------------------------- Novosibirsk
nsk = src("ruc-brit-novosibirsk", "Britannica: Novosibirsk", B + "Novosibirsk-Russia")
add("novosibirsk-trans-siberian-bridge", "fact",
    "Novosibirsk, a city born of the Trans-Siberian Railway", "Новосибирск — город, рождённый Транссибом",
    "The site was chosen in 1893 as the point where the Trans-Siberian Railway would cross the Ob; the settlement was named Novonikolayevsk in 1895, renamed Novosibirsk in 1925 and grew into the largest city in Siberia.",
    "Место выбрали в 1893 году для перехода Транссибирской магистрали через Обь; в 1895 году посёлок назвали Новониколаевском, в 1925-м переименовали в Новосибирск, и он вырос в крупнейший город Сибири.",
    nsk)
add("novosibirsk-akademgorodok", "fact",
    "Akademgorodok in Novosibirsk", "Новосибирский Академгородок",
    "\"Academic Town\" south of the city, seat of the Siberian Branch of the Russian Academy of Sciences and Russia's largest cluster of basic research institutes outside Moscow and Saint Petersburg.",
    "«Академический городок» к югу от города, центр Сибирского отделения Российской академии наук и крупнейшее в России скопление институтов фундаментальной науки за пределами Москвы и Петербурга.",
    nsk)
add("novosibirsk-opera-theatre", "landmark",
    "Novosibirsk Opera and Ballet Theatre", "Новосибирский театр оперы и балета",
    "The largest theatre building in Russia, standing in the centre of Novosibirsk; it opened on 12 May 1945, days after the end of the war in Europe, with Glinka's opera \"Ivan Susanin\".",
    "Самое большое театральное здание России в центре Новосибирска; открылось 12 мая 1945 года, через несколько дней после окончания войны в Европе, оперой Глинки «Иван Сусанин».",
    src("ruc-novat-official", "Novosibirsk Opera and Ballet Theatre (NOVAT): History", "https://novat.ru/theatre/theatre/history/"))

# ---------------------------------------------------------------- Volgograd
vlg = src("ruc-brit-volgograd", "Britannica: Volgograd", B + "Volgograd-Russia")
add("volgograd-motherland-calls", "landmark",
    "The Motherland Calls in Volgograd", "«Родина-мать зовёт!» в Волгограде",
    "Colossal statue of a woman with a raised sword in Volgograd, the symbol of the city, commemorating the Battle of Stalingrad (1942–43), the decisive battle of the Second World War fought here.",
    "Колоссальная статуя женщины с поднятым мечом в Волгограде, символ города, в память о Сталинградской битве 1942–1943 годов — решающем сражении Второй мировой войны, шедшем здесь.",
    vlg)
add("volgograd-three-names", "fact",
    "Tsaritsyn, Stalingrad, Volgograd", "Царицын, Сталинград, Волгоград",
    "Founded as the fortress of Tsaritsyn in 1589, the city was renamed Stalingrad in Stalin's honour and later Volgograd; from August 1942 to February 1943 it was the scene of the Battle of Stalingrad.",
    "Основанный как крепость Царицын в 1589 году, город был переименован в Сталинград в честь Сталина, а затем в Волгоград; с августа 1942 по февраль 1943 года здесь шла Сталинградская битва.",
    vlg)

# ---------------------------------------------------------------- Sochi
add("sochi-winter-olympics-2014", "fact",
    "Sochi, host of the 2014 Winter Olympics", "Сочи — столица зимней Олимпиады 2014 года",
    "The 22nd Olympic Winter Games took place in Sochi on 7–23 February 2014, the first Winter Olympics held in Russia; the ice venues stood in the Olympic Park on the Black Sea shore.",
    "XXII зимние Олимпийские игры прошли в Сочи 7–23 февраля 2014 года — первая зимняя Олимпиада в России; ледовые арены разместились в Олимпийском парке на берегу Чёрного моря.",
    src("ruc-brit-sochi-2014", "Britannica: Sochi 2014 Olympic Winter Games", "https://www.britannica.com/event/Sochi-2014-Olympic-Winter-Games"))
add("sochi-subtropical-resort", "fact",
    "Sochi, Russia's subtropical resort", "Сочи — субтропический курорт России",
    "Subtropical resort and winter-sports centre stretching along the Black Sea coast at the foot of the western Caucasus; the Krasnaya Polyana mountain area east of the city hosted the 2014 Olympic snow events.",
    "Субтропический курорт и центр зимнего спорта, вытянувшийся вдоль Чёрного моря у подножия Западного Кавказа; в горном районе Красная Поляна к востоку от города прошли снежные соревнования Олимпиады-2014.",
    src("ruc-brit-sochi", "Britannica: Sochi", B + "Sochi"))

# ---------------------------------------------------------------- Vladivostok
add("vladivostok-trans-siberian-terminus", "fact",
    "Vladivostok, the end of the Trans-Siberian", "Владивосток — конец Транссиба",
    "Founded in 1860 as a Russian military outpost on Golden Horn Bay, the city is Russia's chief Pacific port, home of the Pacific Fleet and the eastern terminus of the Trans-Siberian Railway.",
    "Основанный в 1860 году как русский военный пост на бухте Золотой Рог, город стал главным тихоокеанским портом России, базой Тихоокеанского флота и восточной конечной станцией Транссиба.",
    src("ruc-brit-vladivostok", "Britannica: Vladivostok", B + "Vladivostok"))

# ---------------------------------------------------------------- Kaliningrad
kgd = src("ruc-brit-kaliningrad", "Britannica: Kaliningrad", B + "Kaliningrad")
add("kaliningrad-koenigsberg-kant", "fact",
    "Kaliningrad, the former Königsberg", "Калининград — бывший Кёнигсберг",
    "As Königsberg the city was the capital of East Prussia; it was ceded to the Soviet Union in 1945 and renamed Kaliningrad in 1946. The grave of the philosopher Immanuel Kant is here.",
    "Как Кёнигсберг город был столицей Восточной Пруссии; в 1945 году отошёл к Советскому Союзу и в 1946-м переименован в Калининград. Здесь находится могила философа Иммануила Канта.",
    kgd)
add("kaliningrad-exclave", "fact",
    "Kaliningrad, an exclave on the Baltic", "Калининград — эксклав на Балтике",
    "The Kaliningrad region forms an exclave of Russia reachable by land only through Lithuania or Poland; the city is Russia's only ice-free European port, and nearby Baltiysk is a naval base.",
    "Калининградская область — эксклав России, по суше доступный только через Литву или Польшу; город — единственный незамерзающий европейский порт России, а соседний Балтийск — военно-морская база.",
    kgd)
add("kaliningrad-amber-museum", "landmark",
    "Amber Museum in Kaliningrad", "Музей янтаря в Калининграде",
    "Museum devoted to Baltic amber housed in the Dohna Tower of 1853; the Kaliningrad region holds the world's largest amber deposit, mined in an open pit at the settlement of Yantarny.",
    "Музей балтийского янтаря в башне Дона 1853 года; в Калининградской области находится крупнейшее в мире месторождение янтаря, которое разрабатывают в карьере у посёлка Янтарный.",
    src("ruc-amber-museum-official", "Kaliningrad Regional Amber Museum: official site", "https://www.ambermuseum.ru/en/"))
add("kaliningrad-curonian-spit", "landmark",
    "Curonian Spit near Kaliningrad", "Куршская коса под Калининградом",
    "Sand dune peninsula 98 km long separating the Curonian Lagoon from the Baltic Sea, shared by Russia and Lithuania; its dunes survive only thanks to ceaseless human stabilisation, and it is a UNESCO site.",
    "Песчаная коса длиной 98 км, отделяющая Куршский залив от Балтийского моря и разделённая между Россией и Литвой; её дюны сохраняются лишь благодаря постоянному укреплению людьми; объект ЮНЕСКО.",
    src("ruc-unesco-curonian-spit", "UNESCO World Heritage Centre: Curonian Spit", U + "994/"))

# ---------------------------------------------------------------- Veliky Novgorod
add("veliky-novgorod-st-sophia", "landmark",
    "Cathedral of St Sophia in Veliky Novgorod", "Софийский собор в Великом Новгороде",
    "Mid-11th-century church of St Sophia inside the Novgorod Kremlin; medieval Novgorod was a city-republic governed through its People's Assembly, the veche, and a UNESCO site today.",
    "Церковь Святой Софии середины XI века в Новгородском кремле; средневековый Новгород был городом-республикой, управлявшимся народным собранием — вече; сегодня объект ЮНЕСКО.",
    src("ruc-unesco-novgorod", "UNESCO World Heritage Centre: Historic Monuments of Novgorod and Surroundings", U + "604/"))
add("veliky-novgorod-birch-bark-letters", "fact",
    "Birch-bark letters of Novgorod", "Новгородские берестяные грамоты",
    "The first birch-bark letters were found during excavations in Novgorod in 1951; by 2017 more than 1,100 had been unearthed there, most of them private letters about household, family, money and trade.",
    "Первые берестяные грамоты найдены при раскопках в Новгороде в 1951 году; к 2017 году там обнаружено более 1100 грамот, в основном частных писем о хозяйстве, семье, деньгах и торговле.",
    src("ruc-gramoty-ru", "Birchbark Literacy from Medieval Rus (gramoty.ru): General information", "https://gramoty.ru/birchbark/about-source/general-information"))

# ---------------------------------------------------------------- Golden Ring cities
add("yaroslavl-historical-centre", "landmark",
    "Historical centre of Yaroslavl", "Исторический центр Ярославля",
    "City founded by Prince Yaroslav the Wise in the early 11th century at the confluence of the Volga and the Kotorosl; its 17th-century churches and radial plan from Catherine II's 1763 reform are a UNESCO site.",
    "Город, основанный князем Ярославом Мудрым в начале XI века при слиянии Волги и Которосли; его церкви XVII века и лучевая планировка по реформе Екатерины II 1763 года — объект ЮНЕСКО.",
    src("ruc-unesco-yaroslavl", "UNESCO World Heritage Centre: Historical Centre of the City of Yaroslavl", U + "1170/"))
vs = src("ruc-unesco-vladimir-suzdal", "UNESCO World Heritage Centre: White Monuments of Vladimir and Suzdal", U + "633/")
add("vladimir-golden-gate-assumption", "landmark",
    "Golden Gate and Assumption Cathedral in Vladimir", "Золотые ворота и Успенский собор во Владимире",
    "White-stone monuments of 12th-century Vladimir: the Golden Gate of 1164 and the Cathedral of the Assumption, whose murals were painted in 1408 by Andrei Rublev and Daniil Chorny; a UNESCO site.",
    "Белокаменные памятники Владимира XII века: Золотые ворота 1164 года и Успенский собор, росписи которого в 1408 году выполнили Андрей Рублёв и Даниил Чёрный; объект ЮНЕСКО.",
    vs)
add("bogolyubovo-church-intercession-nerl", "landmark",
    "Church of the Intercession on the Nerl near Vladimir", "Церковь Покрова на Нерли под Владимиром",
    "White-stone church on the River Nerl near Vladimir, listed by UNESCO together with the princely castle at Bogolyubovo (1165) among the White Monuments of Vladimir and Suzdal.",
    "Белокаменная церковь на реке Нерль под Владимиром, включённая ЮНЕСКО вместе с княжеским замком в Боголюбове (1165) в число белокаменных памятников Владимира и Суздаля.",
    vs)
add("suzdal-kremlin-monasteries", "landmark",
    "Suzdal Kremlin and monasteries", "Суздальский кремль и монастыри",
    "Small ancient town whose kremlin with the Cathedral of the Nativity and several monasteries, including the Monastery of Our Saviour and St Euthymius, belong to the UNESCO White Monuments of Vladimir and Suzdal.",
    "Небольшой древний город, чей кремль с собором Рождества Богородицы и несколько монастырей, включая Спасо-Евфимиев, входят в объект ЮНЕСКО «Белокаменные памятники Владимира и Суздаля».",
    vs)
add("sergiev-posad-trinity-lavra", "landmark",
    "Trinity Lavra of St Sergius in Sergiev Posad", "Троице-Сергиева лавра в Сергиевом Посаде",
    "Monastery founded in 1337 by the monk Sergius of Radonezh, a world-famous spiritual centre of the Russian Orthodox Church; Andrei Rublev painted his famous icon \"The Trinity\" for it; a UNESCO site.",
    "Монастырь, основанный в 1337 году монахом Сергием Радонежским, всемирно известный духовный центр Русской православной церкви; для него Андрей Рублёв написал знаменитую икону «Троица»; объект ЮНЕСКО.",
    src("ruc-unesco-trinity-lavra", "UNESCO World Heritage Centre: Architectural Ensemble of the Trinity Sergius Lavra in Sergiev Posad", U + "657/"))
add("pskov-churches", "landmark",
    "Churches of the Pskov school of architecture", "Храмы псковской архитектурной школы",
    "Ancient city on the banks of the Velikaya River; its churches of the 12th to early 17th centuries, with cubic volumes, domes, porches and belfries, form a UNESCO World Heritage site.",
    "Древний город на берегах реки Великой; его храмы XII — начала XVII века с кубическими объёмами, главами, притворами и звонницами образуют объект Всемирного наследия ЮНЕСКО.",
    src("ruc-unesco-pskov", "UNESCO World Heritage Centre: Churches of the Pskov School of Architecture", U + "1523/"))

# ---------------------------------------------------------------- Derbent
add("derbent-fortress-walls", "landmark",
    "Citadel and walls of Derbent", "Цитадель и стены Дербента",
    "Fortifications built by the Sasanian Persians in the 5th century, with two parallel walls closing the narrow 3-km strip between the Caucasus mountains and the Caspian; Derbent is the oldest city in Russia.",
    "Укрепления, возведённые персами-Сасанидами в V веке: две параллельные стены запирают узкую трёхкилометровую полосу между горами Кавказа и Каспием; Дербент — древнейший город России.",
    src("ruc-unesco-derbent", "UNESCO World Heritage Centre: Citadel, Ancient City and Fortress Buildings of Derbent", U + "1070/"))

# ---------------------------------------------------------------- North
add("murmansk-arctic-city", "fact",
    "Murmansk, the largest city beyond the Arctic Circle", "Мурманск — крупнейший город за полярным кругом",
    "Founded in 1915 as Romanov-na-Murmane, a supply port of the First World War, Murmansk is the largest city in the world north of the Arctic Circle and has an ice-free harbour.",
    "Основанный в 1915 году как Романов-на-Мурмане, порт снабжения Первой мировой войны, Мурманск — крупнейший в мире город за Северным полярным кругом с незамерзающей гаванью.",
    src("ruc-brit-murmansk", "Britannica: Murmansk", B + "Murmansk-Russia"))
add("arkhangelsk-first-seaport", "fact",
    "Arkhangelsk, Russia's first seaport", "Архангельск — первый морской порт России",
    "Founded in 1584 on the Northern Dvina, Arkhangelsk was the first port of the Russian state to trade with England; it declined after Saint Petersburg was founded in 1703.",
    "Основанный в 1584 году на Северной Двине Архангельск стал первым портом Русского государства, торговавшим с Англией; после основания Петербурга в 1703 году он пришёл в упадок.",
    src("ruc-brit-arkhangelsk", "Britannica: Arkhangelsk", B + "Arkhangelsk-Russia"))
add("norilsk-arctic-nickel-city", "fact",
    "Norilsk, the Arctic nickel city", "Норильск — заполярный город никеля",
    "Industrial city founded in 1935 north of the Arctic Circle, one of the world's leading producers of nickel and platinum, with copper also mined; it had about 213,000 inhabitants in 2006.",
    "Промышленный город, основанный в 1935 году за Северным полярным кругом, один из ведущих в мире производителей никеля и платины, добывается также медь; в 2006 году в нём жило около 213 тысяч человек.",
    src("ruc-brit-norilsk", "Britannica: Norilsk", B + "Norilsk"))

# ---------------------------------------------------------------- Siberia and Far East
add("irkutsk-angara-baikal", "fact",
    "Irkutsk on the Angara", "Иркутск на Ангаре",
    "City on the Angara River that grew from a fort built in 1661; the reservoir of its hydroelectric dam extends back to Lake Baikal, and many old wooden houses survive in the centre.",
    "Город на реке Ангаре, выросший из острога 1661 года; водохранилище его ГЭС простирается до самого Байкала, а в центре сохранилось много старых деревянных домов.",
    src("ruc-brit-irkutsk", "Britannica: Irkutsk", B + "Irkutsk-Russia"))
add("yakutsk-lena-1632", "fact",
    "Yakutsk, the capital of Yakutia", "Якутск — столица Якутии",
    "Capital of the Sakha republic (Yakutia) on the Lena River in eastern Siberia; it grew from a fort founded in 1632 during the Russian advance across Siberia.",
    "Столица Республики Саха (Якутия) на реке Лене в Восточной Сибири; вырос из острога, основанного в 1632 году во время русского продвижения по Сибири.",
    src("ruc-brit-yakutsk", "Britannica: Yakutsk", B + "Yakutsk"))
add("krasnoyarsk-yenisei", "fact",
    "Krasnoyarsk on the Yenisei", "Красноярск на Енисее",
    "Founded as the fort of Krasny Yar in 1628 on the Yenisei, the city grew with 19th-century gold finds and the Trans-Siberian Railway in the 1890s; one of the world's largest hydroelectric stations stands here.",
    "Основанный как острог Красный Яр в 1628 году на Енисее, город вырос на золотых находках XIX века и приходе Транссиба в 1890-х; рядом стоит одна из крупнейших в мире ГЭС.",
    src("ruc-brit-krasnoyarsk", "Britannica: Krasnoyarsk", B + "Krasnoyarsk-Russia"))
add("omsk-irtysh-fortress", "fact",
    "Omsk on the Irtysh", "Омск на Иртыше",
    "City in south-western Siberia on the Irtysh River at its junction with the Om; founded in 1716 as a stronghold, it became a major administrative and industrial centre of Siberia.",
    "Город на юго-западе Сибири на Иртыше при впадении Оми; основанный в 1716 году как крепость, он стал крупным административным и промышленным центром Сибири.",
    src("ruc-brit-omsk", "Britannica: Omsk", B + "Omsk-Russia"))
add("tobolsk-early-siberia", "fact",
    "Tobolsk, an early centre of Siberia", "Тобольск — ранний центр Сибири",
    "Founded in 1587 at the confluence of the Irtysh and the Tobol, Tobolsk was one of the chief centres of early Russian colonisation of Siberia; its stone kremlin crowns the hill above the river.",
    "Основанный в 1587 году при слиянии Иртыша и Тобола, Тобольск был одним из главных центров ранней русской колонизации Сибири; его каменный кремль венчает холм над рекой.",
    src("ruc-brit-tobolsk", "Britannica: Tobolsk", B + "Tobolsk"))
add("chelyabinsk-meteor-2013", "fact",
    "Chelyabinsk meteorite of 2013", "Челябинский метеорит 2013 года",
    "In 2013 an asteroid about 17 m wide broke up in the atmosphere over the Chelyabinsk region; the shock wave shattered windows and injured over 1,500 people, mostly by flying glass.",
    "В 2013 году астероид шириной около 17 м разрушился в атмосфере над Челябинской областью; ударная волна выбила окна, пострадали более 1500 человек, в основном от осколков стекла.",
    src("ruc-brit-chelyabinsk-meteorite", "Britannica: Chelyabinsk meteorite of 2013", "https://www.britannica.com/topic/Chelyabinsk-meteorite-of-2013"))

# ---------------------------------------------------------------- Volga and south
add("samara-kuybyshev-wartime", "fact",
    "Samara, the wartime refuge of the government", "Самара — военное убежище правительства",
    "Called Kuybyshev from 1935 to 1991, the city on the Volga received numerous government functions evacuated from Moscow when the capital was threatened by the German attack in the Second World War.",
    "С 1935 по 1991 год город на Волге назывался Куйбышев; сюда эвакуировали многие правительственные учреждения из Москвы, когда столице угрожало немецкое наступление во Второй мировой войне.",
    src("ruc-brit-samara", "Britannica: Samara", B + "Samara-Russia"))
add("rostov-on-don-customs-post", "fact",
    "Rostov-on-Don, from customs post to southern hub", "Ростов-на-Дону — от таможни до столицы юга",
    "Founded in 1749 as the customs post of Temernika on the Don about 50 km above its mouth on the Sea of Azov, the city grew into the main transport and industrial hub of the north Caucasus region.",
    "Основанный в 1749 году как Темерницкая таможня на Дону примерно в 50 км выше его устья на Азовском море, город стал главным транспортным и промышленным узлом Северного Кавказа.",
    src("ruc-brit-rostov-on-don", "Britannica: Rostov-on-Don", B + "Rostov-on-Don"))
add("voronezh-peter-fleet", "fact",
    "Voronezh, where Peter I built his first fleet", "Воронеж, где Пётр I строил первый флот",
    "Peter I the Great built his naval flotilla at Voronezh on the Don for his campaigns against the Turkish fortress of Azov, which is why the city is remembered as a birthplace of the Russian navy.",
    "Пётр I строил в Воронеже на Дону свою флотилию для походов на турецкую крепость Азов, поэтому город помнят как одну из колыбелей русского флота.",
    src("ruc-brit-voronezh", "Britannica: Voronezh", B + "Voronezh-Russia"))
add("perm-permian-period", "fact",
    "Perm and the Permian period", "Пермь и пермский период",
    "The Permian period of Earth's history is named after the Perm region: in 1840–1841 the Scottish geologist Roderick Murchison studied the rock strata on the western flanks of the Urals and named the Permian System.",
    "Пермский период истории Земли назван по Пермскому краю: в 1840–1841 годах шотландский геолог Родерик Мурчисон изучил последовательность пород на западных склонах Урала и назвал её пермской системой.",
    src("ruc-brit-permian-period", "Britannica: Permian Period", "https://www.britannica.com/science/Permian-Period"))
add("tula-arms-factory", "fact",
    "Tula, the city of gunsmiths", "Тула — город оружейников",
    "Tula is the site of Russia's first armament factory, built in 1712 by Peter I the Great; the city south of Moscow has remained a centre of arms manufacture ever since.",
    "В Туле находится первый оружейный завод России, построенный в 1712 году Петром I; город к югу от Москвы с тех пор остаётся центром оружейного производства.",
    src("ruc-brit-tula", "Britannica: Tula", B + "Tula-Russia"))
add("tula-pryanik", "food",
    "Tula gingerbread (pryanik)", "Тульский пряник",
    "Printed honey gingerbread baked in Tula for centuries, patterned with carved wooden boards and made with many fillings and shapes; the first gingerbread museum in Russia opened in Tula in 1996.",
    "Печатный медовый пряник, который веками пекут в Туле, с узором от резных деревянных досок, с разными начинками и формами; первый в России музей пряника открылся в Туле в 1996 году.",
    src("ruc-oldtula-pryanik-museum", "Old Tula (Staraya Tula) factory: Tula Gingerbread Museum", "https://oldtula.ru/museum/"))

Path(__file__).with_name("delta.json").write_text(
    json.dumps({"sources": S, "countries": {"RU": I}}, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8", newline="\n")
print(len(I), "items,", len(S), "sources")
