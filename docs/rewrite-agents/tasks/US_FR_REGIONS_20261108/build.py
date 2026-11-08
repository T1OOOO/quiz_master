"""Build delta.json: US states and cities (US, ids usa-*) and French regions (FR, ids frr-*).

Run: python build.py -> delta.json; then validate.py [--links]; then merge.py.
Every claim was checked against the cited page opened in a browser on 2026-11-08 (notes.md).
"""
import json
from pathlib import Path

S, US, FR = [], [], []


def src(sid, title, url):
    S.append({"id": sid, "title": title, "url": url})
    return sid


def item(bucket, prefix, iid, kind, en, ru, rel_en, rel_ru, sid):
    bucket.append({
        "id": prefix + iid, "kind": kind, "name_en": en, "name_ru": ru,
        "relation_en": rel_en, "relation_ru": rel_ru, "source_id": sid,
    })


def us(*a):
    item(US, "usa-", *a)


def fr(*a):
    item(FR, "frr-", *a)


B = "https://www.britannica.com/place/"
T = "https://www.britannica.com/topic/"
U = "https://whc.unesco.org/en/list/"

# ================================================================ US states
us("alaska-49th-state", "fact", "Alaska, the 49th state", "Аляска — 49-й штат",
   "Bought from Russia in 1867 for $7.2 million at Secretary Seward's urging, enlarging the US by nearly a fifth; admitted on 3 January 1959. Its capital is Juneau, and Denali is the highest peak in North America.",
   "Куплена у России в 1867 году за 7,2 млн долларов по настоянию госсекретаря Сьюарда, что увеличило территорию США почти на пятую часть; принята 3 января 1959 года. Столица — Джуно, а Денали — высочайшая вершина Северной Америки.",
   src("usa-brit-alaska", "Britannica: Alaska", B + "Alaska"))
us("hawaii-island-state", "fact", "Hawaii, the island state", "Гавайи — островной штат",
   "A group of volcanic islands in the central Pacific Ocean that became the 50th US state on 21 August 1959; its capital Honolulu lies on the island of Oahu.",
   "Группа вулканических островов в центре Тихого океана, ставшая 50-м штатом США 21 августа 1959 года; столица Гонолулу расположена на острове Оаху.",
   src("usa-brit-hawaii", "Britannica: Hawaii", B + "Hawaii-state"))
us("texas-lone-star", "fact", "Texas, the Lone Star State", "Техас — штат одинокой звезды",
   "Largest state in area after Alaska; part of Mexico from 1821 to 1836, when it won independence as the Republic of Texas, it became the 28th state in 1845. Austin is the capital, Houston the largest city.",
   "Крупнейший штат по площади после Аляски; с 1821 по 1836 год был частью Мексики, затем добился независимости как Республика Техас и в 1845 году вошёл в Союз 28-м штатом. Столица — Остин, крупнейший город — Хьюстон.",
   src("usa-brit-texas", "Britannica: Texas", B + "Texas-state"))
us("california-most-populous", "fact", "California, the most populous state", "Калифорния — самый населённый штат",
   "Admitted as the 31st state in 1850 after the Gold Rush of 1848 and the most populous US state since the early 1960s; its capital is Sacramento, and Los Angeles, San Francisco and San Diego are its great cities.",
   "Принята 31-м штатом в 1850 году после золотой лихорадки 1848 года и с начала 1960-х — самый населённый штат США; столица — Сакраменто, крупные города — Лос-Анджелес, Сан-Франциско и Сан-Диего.",
   src("usa-brit-california", "Britannica: California", B + "California-state"))
us("florida-sunshine-state", "fact", "Florida, the Sunshine State", "Флорида — солнечный штат",
   "Peninsula between the Atlantic and the Gulf of Mexico with Tallahassee as capital; St. Augustine, founded in 1565 by the Spaniard Pedro Menéndez de Avilés, is the oldest European settlement in the continental US.",
   "Полуостров между Атлантикой и Мексиканским заливом со столицей Таллахасси; Сент-Огастин, основанный в 1565 году испанцем Педро Менендесом де Авилесом, — старейшее европейское поселение в континентальных США.",
   src("usa-brit-florida", "Britannica: Florida", B + "Florida"))
us("new-york-state-albany", "fact", "New York State and its capital Albany", "Штат Нью-Йорк и его столица Олбани",
   "One of the 13 original colonies and states; its capital is Albany, not New York City, and Niagara Falls lies on its border with Canada near Lake Ontario.",
   "Один из 13 первоначальных колоний и штатов; его столица — Олбани, а не Нью-Йорк, а Ниагарский водопад находится на границе с Канадой у озера Онтарио.",
   src("usa-brit-new-york-state", "Britannica: New York (state)", B + "New-York-state"))
us("nevada-silver-state", "fact", "Nevada, the Silver State", "Невада — серебряный штат",
   "The most arid state, in the deserts of the Great Basin; silver mining boomed after the Comstock Lode of 1859, its capital is Carson City, and gambling legalised in 1931 built the casinos of Las Vegas and Reno.",
   "Самый засушливый штат с песчаными щелочными пустынями Большого Бассейна; добыча серебра расцвела после жилы Комсток 1859 года, столица — Карсон-Сити, а легализация азартных игр в 1931 году создала казино Лас-Вегаса и Рино.",
   src("usa-brit-nevada", "Britannica: Nevada", B + "Nevada-state"))
us("arizona-48th-state", "fact", "Arizona, the last of the contiguous 48", "Аризона — последний из 48 смежных штатов",
   "Achieved statehood on 14 February 1912, the last of the 48 conterminous states; its capital is Phoenix, and the Grand Canyon of the Colorado River lies in its north.",
   "Стала штатом 14 февраля 1912 года — последним из 48 смежных; столица — Финикс, а на севере лежит Гранд-Каньон реки Колорадо.",
   src("usa-brit-arizona", "Britannica: Arizona", B + "Arizona-state"))
us("louisiana-purchase-parishes", "fact", "Louisiana and the Louisiana Purchase", "Луизиана и Луизианская покупка",
   "Claimed by La Salle for Louis XIV; Spain returned it to France in 1800 and three years later the US bought it from Napoleon (the Louisiana Purchase). It has 64 parishes instead of counties; capital Baton Rouge.",
   "Объявлена Ла Салем владением Людовика XIV; в 1800 году Испания вернула Луизиану Франции, а через три года США купили её у Наполеона — Луизианская покупка. Штат делится на 64 прихода, а не округа; столица — Батон-Руж.",
   src("usa-brit-louisiana", "Britannica: Louisiana", B + "Louisiana-state"))
us("colorado-fourteeners", "fact", "Colorado and its fourteeners", "Колорадо и его четырёхтысячники",
   "Rocky Mountain state with some 53 peaks above 14,000 feet, the highest being Mount Elbert at 14,440 feet; its capital and largest city is Denver.",
   "Штат Скалистых гор, где около 53 вершин выше 14 000 футов, высшая — Маунт-Элберт (14 440 футов, 4401 м); столица и крупнейший город — Денвер.",
   src("usa-brit-colorado", "Britannica: Colorado", B + "Colorado-state"))
us("washington-state-evergreen", "fact", "Washington, the Evergreen State", "Вашингтон — вечнозелёный штат",
   "Pacific Northwest state, the only one named after a US president; its capital is Olympia, about half its people live in the Seattle–Tacoma–Bellevue area, and 14,410-foot Mount Rainier crowns its volcanic peaks.",
   "Штат на тихоокеанском северо-западе, единственный названный в честь президента США; столица — Олимпия, около половины жителей живут в агломерации Сиэтл — Такома — Беллвью, а вулкан Рейнир (14 410 футов) венчает цепь вулканов.",
   src("usa-brit-washington-state", "Britannica: Washington (state)", B + "Washington-state"))
us("massachusetts-pilgrims", "fact", "Massachusetts, the Pilgrims' state", "Массачусетс — штат пилигримов",
   "The Pilgrims established the Plymouth colony in 1620 and the Puritans of the Massachusetts Bay Company followed in 1630; Harvard College was founded in 1636, and the state capital is Boston.",
   "Пилигримы основали колонию Плимут в 1620 году, а пуритане Компании Массачусетского залива последовали в 1630-м; Гарвардский колледж основан в 1636 году; столица штата — Бостон.",
   src("usa-brit-massachusetts", "Britannica: Massachusetts", B + "Massachusetts"))
us("pennsylvania-keystone", "fact", "Pennsylvania, the Keystone State", "Пенсильвания — краеугольный штат",
   "Founded as a Quaker colony under the charter Charles II granted William Penn in 1681; the Declaration of Independence was signed in Philadelphia on 4 July 1776, while the capital is Harrisburg.",
   "Основана как квакерская колония по хартии, которую Карл II выдал Уильяму Пенну в 1681 году; Декларация независимости подписана в Филадельфии 4 июля 1776 года, а столица штата — Гаррисберг.",
   src("usa-brit-pennsylvania", "Britannica: Pennsylvania", B + "Pennsylvania-state"))
us("utah-mormon-state", "fact", "Utah, settled by the Mormons", "Юта, заселённая мормонами",
   "Mormon pioneers led by Brigham Young entered the valley of the Great Salt Lake in 1847 and founded Salt Lake City, called Great Salt Lake City until 1868; Utah became the 45th state on 4 January 1896.",
   "Мормонские пионеры во главе с Бригамом Янгом вошли в долину Большого Солёного озера в 1847 году и основали Солт-Лейк-Сити, до 1868 года называвшийся Грейт-Солт-Лейк-Сити; Юта стала 45-м штатом 4 января 1896 года.",
   src("usa-brit-utah", "Britannica: Utah", B + "Utah"))
us("wyoming-equality-state", "fact", "Wyoming, the Equality State", "Вайоминг — штат равенства",
   "Its constitution was the first in the world to grant women full voting rights, hence the nickname; nearly the whole of Yellowstone, the world's oldest national park, lies within its borders.",
   "Его конституция первой в мире дала женщинам полное избирательное право — отсюда прозвище; почти весь Йеллоустон, старейший национальный парк мира, лежит в его границах.",
   src("usa-brit-wyoming", "Britannica: Wyoming", B + "Wyoming-state"))
us("delaware-first-state", "fact", "Delaware, the First State", "Делавэр — первый штат",
   "Ranks 49th of the 50 states in area and is called the First State because it was the first of the original 13 to ratify the US Constitution, on 7 December 1787; its capital is Dover.",
   "Занимает 49-е место из 50 штатов по площади и зовётся Первым штатом, потому что первым из 13 первоначальных ратифицировал Конституцию США 7 декабря 1787 года; столица — Довер.",
   src("usa-brit-delaware", "Britannica: Delaware", B + "Delaware-state"))
us("new-mexico-santa-fe", "fact", "New Mexico and Santa Fe", "Нью-Мексико и Санта-Фе",
   "The 47th state, admitted in 1912; its capital Santa Fe, founded by the Spanish in 1610, is the oldest continuously used seat of government in North America, and Los Alamos created the first atomic bomb in 1945.",
   "47-й штат, принятый в 1912 году; столица Санта-Фе, основанная испанцами в 1610 году, — старейшая непрерывно действующая резиденция власти в Северной Америке, а в Лос-Аламосе в 1945 году создали первую атомную бомбу.",
   src("usa-brit-new-mexico", "Britannica: New Mexico", B + "New-Mexico"))
us("michigan-great-lakes", "fact", "Michigan, the Great Lakes State", "Мичиган — штат Великих озёр",
   "The only state split into two large land segments, joined since 1957 by the 5-mile Mackinac Bridge, and bordered by four of the five Great Lakes; its capital is Lansing, and Detroit became the world's car capital.",
   "Единственный штат, разделённый на две большие части, которые с 1957 года соединяет пятимильный мост Макино; омывается четырьмя из пяти Великих озёр, столица — Лансинг, а Детройт стал мировым центром автопрома.",
   src("usa-brit-michigan", "Britannica: Michigan", B + "Michigan"))
us("georgia-peach-state", "fact", "Georgia, the Peach State", "Джорджия — персиковый штат",
   "The youngest of the 13 English colonies, founded in 1732 with the first settlement at Savannah in 1733; its capital Atlanta hosted the 1996 Summer Olympic Games.",
   "Самая молодая из 13 английских колоний, основанная в 1732 году с первым поселением в Саванне в 1733-м; её столица Атланта принимала летние Олимпийские игры 1996 года.",
   src("usa-brit-georgia", "Britannica: Georgia (state)", B + "Georgia-state"))
us("illinois-land-of-lincoln", "fact", "Illinois, the Land of Lincoln", "Иллинойс — земля Линкольна",
   "The Prairie State, whose capital Springfield was Abraham Lincoln's home; Chicago on Lake Michigan became the country's second largest city in the 1880s and is a national transportation hub.",
   "Степной штат, чья столица Спрингфилд была домом Авраама Линкольна; Чикаго на озере Мичиган в 1880-х стал вторым по величине городом страны и остаётся национальным транспортным узлом.",
   src("usa-brit-illinois", "Britannica: Illinois", B + "Illinois-state"))

# ================================================================ US cities
nyc = src("usa-brit-new-york-city", "Britannica: New York City", B + "New-York-City")
us("new-york-city-five-boroughs", "fact", "New York City and its five boroughs", "Нью-Йорк и его пять боро",
   "The most populous US city, formed in January 1898 by consolidating Manhattan, Brooklyn, Queens, the Bronx and Staten Island; as the first capital of the United States it saw Washington inaugurated in April 1789.",
   "Самый населённый город США, образованный в январе 1898 года объединением Манхэттена, Бруклина, Куинса, Бронкса и Статен-Айленда; как первая столица страны он принял инаугурацию Вашингтона в апреле 1789 года.",
   nyc)
us("new-york-central-park", "landmark", "Central Park in New York", "Центральный парк в Нью-Йорке",
   "Park in the middle of Manhattan whose plan by Frederick Law Olmsted and Calvert Vaux was chosen in 1858; one of the first American parks developed with landscape-architecture techniques.",
   "Парк в центре Манхэттена, план которого авторства Фредерика Ло Олмстеда и Калверта Во выбрали в 1858 году; один из первых американских парков, созданных методами ландшафтной архитектуры.",
   src("usa-brit-central-park", "Britannica: Central Park", B + "Central-Park-New-York-City"))
dc = src("usa-brit-washington-dc", "Britannica: Washington, D.C.", B + "Washington-DC")
us("washington-dc-capital", "fact", "Washington, D.C., the federal capital", "Вашингтон, округ Колумбия — столица",
   "Congress first convened here in 1800; the city on the Potomac was planned by Pierre Charles L'Enfant on land ceded by Maryland and Virginia (Virginia's part was later returned), and the District is not a state.",
   "Конгресс впервые собрался здесь в 1800 году; город на Потомаке спланировал Пьер Шарль Ланфан на земле, уступленной Мэрилендом и Виргинией (часть Виргинии позже вернули), а округ остаётся территорией, а не штатом.",
   dc)
us("washington-dc-capitol-mall", "landmark", "US Capitol and the National Mall", "Капитолий и Национальная аллея",
   "The Capitol stands on a high ridge above the National Mall, where the Washington Monument rises; the Lincoln Memorial closes the Mall at the far western end of its Reflecting Pool.",
   "Капитолий стоит на высоком гребне над Национальной аллеей, где возвышается монумент Вашингтона; мемориал Линкольна замыкает аллею у дальнего западного конца её Зеркального пруда.",
   dc)
us("los-angeles-hollywood", "fact", "Los Angeles and Hollywood", "Лос-Анджелес и Голливуд",
   "The city started in 1781 with 44 settlers brought by Governor Felipe de Neve and is now the second most populous US city after New York; its district of Hollywood produces about half of all films shot in the US.",
   "Город начался в 1781 году с 44 поселенцев, приведённых губернатором Фелипе де Неве, и сегодня второй по населению город США после Нью-Йорка; его район Голливуд выпускает около половины всех фильмов, снимаемых в США.",
   src("usa-brit-los-angeles", "Britannica: Los Angeles", B + "Los-Angeles-California"))
chi = src("usa-brit-chicago", "Britannica: Chicago", B + "Chicago")
us("chicago-fire-skyscrapers", "fact", "Chicago and the first skyscrapers", "Чикаго и первые небоскрёбы",
   "City on Lake Michigan rebuilt after the Great Fire of 1871 with steel-framed office towers dubbed skyscrapers, a term reputedly coined in Chicago; it is the third most populous US city.",
   "Город на озере Мичиган, отстроенный после Великого пожара 1871 года с офисными башнями на стальном каркасе, прозванными небоскрёбами — слово, по преданию, родилось в Чикаго; третий по населению город США.",
   chi)
us("chicago-willis-tower", "landmark", "Willis Tower in Chicago", "Уиллис-тауэр в Чикаго",
   "Skyscraper completed in 1974 as the Sears Tower and the world's tallest building until 1996, when the Petronas Twin Towers surpassed it; the 103rd-floor Skydeck has glass boxes jutting out from the facade.",
   "Небоскрёб, достроенный в 1974 году как Сирс-тауэр и остававшийся самым высоким зданием мира до 1996 года, когда его превзошли башни Петронас; на смотровой площадке 103-го этажа — стеклянные выступы над фасадом.",
   src("usa-brit-willis-tower", "Britannica: Willis Tower", T + "Willis-Tower"))
us("san-francisco-1906-cable-cars", "fact", "San Francisco, the city of hills", "Сан-Франциско — город холмов",
   "Hilly port city on the northern tip of a peninsula that boomed with the gold seekers of 1849, was devastated by the 1906 earthquake and its fires, and is famous for its cable cars and the Golden Gate Bridge.",
   "Холмистый портовый город на северной оконечности полуострова, расцветший с золотоискателями 1849 года, разрушенный землетрясением 1906 года и вызванными им пожарами и знаменитый канатными трамваями и мостом Золотые Ворота.",
   src("usa-brit-san-francisco", "Britannica: San Francisco", B + "San-Francisco-California"))
us("san-francisco-alcatraz", "landmark", "Alcatraz Island in San Francisco Bay", "Остров Алькатрас в заливе Сан-Франциско",
   "Rocky island in San Francisco Bay that served as a federal prison from 1934 to 1963, holding Al Capone among others; in 1972 it became part of the Golden Gate National Recreation Area.",
   "Скалистый остров в заливе Сан-Франциско, служивший федеральной тюрьмой с 1934 по 1963 год, где сидел в том числе Аль Капоне; в 1972 году вошёл в национальную зону отдыха Золотые Ворота.",
   src("usa-brit-alcatraz", "Britannica: Alcatraz Island", B + "Alcatraz-Island"))
us("las-vegas-strip", "fact", "Las Vegas, the gambling capital", "Лас-Вегас — столица азартных игр",
   "Founded on 15 May 1905 as a desert railroad service centre; after Nevada legalised gambling again in 1931 it grew into the casino capital, with the most ostentatious resorts along the Strip on Las Vegas Boulevard.",
   "Основан 15 мая 1905 года как железнодорожный посёлок в пустыне; после повторной легализации азартных игр в Неваде в 1931 году вырос в столицу казино, самые роскошные курорты которой стоят на Стрипе — бульваре Лас-Вегас.",
   src("usa-brit-las-vegas", "Britannica: Las Vegas", B + "Las-Vegas-Nevada"))
us("hoover-dam", "landmark", "Hoover Dam near Las Vegas", "Плотина Гувера под Лас-Вегасом",
   "Built in 1930–1936 on the Colorado River at the Arizona–Nevada border, the highest concrete arch-gravity dam in the US; it impounds Lake Mead, one of the largest artificial lakes in the world.",
   "Построена в 1930–1936 годах на реке Колорадо на границе Аризоны и Невады; самая высокая бетонная арочно-гравитационная плотина США, образующая озеро Мид — одно из крупнейших искусственных озёр мира.",
   src("usa-brit-hoover-dam", "Britannica: Hoover Dam", T + "Hoover-Dam"))
us("new-orleans-jazz-mardi-gras", "fact", "New Orleans, the birthplace of jazz", "Новый Орлеан — родина джаза",
   "Founded by the French in 1718 on the Mississippi; famous for its French Quarter (Vieux Carré), Mardi Gras and Creole culture, it was the birthplace of jazz between the 1880s and the First World War.",
   "Основан французами в 1718 году на Миссисипи; знаменит Французским кварталом (Вьё-Карре), Марди Гра и креольской культурой; между 1880-ми и Первой мировой войной здесь родился джаз.",
   src("usa-brit-new-orleans", "Britannica: New Orleans", B + "New-Orleans-Louisiana"))
us("louisiana-gumbo", "food", "Gumbo, the stew of Louisiana", "Гамбо — луизианская похлёбка",
   "Aromatic soup-stew characteristic of the Creole cuisine of Louisiana, made with okra or thickened with filé powder, with seafood, chicken or ham, and eaten over a mound of rice.",
   "Ароматная похлёбка-рагу, характерная для креольской кухни Луизианы: с окрой или загущённая порошком филе, с морепродуктами, курицей или ветчиной, подаётся на горке риса.",
   src("usa-brit-gumbo", "Britannica: Gumbo", T + "gumbo"))
us("miami-cuban-south-beach", "fact", "Miami, the gateway to Latin America", "Майами — ворота в Латинскую Америку",
   "Leading resort and Atlantic port in southern Florida, incorporated in 1896; some 500,000 Cubans settled here after 1959 and created Little Havana, and neighbouring Miami Beach keeps its mid-1930s Art Deco buildings.",
   "Ведущий курорт и атлантический порт на юге Флориды, получивший статус города в 1896 году; после 1959 года здесь осели около 500 тысяч кубинцев, создав Маленькую Гавану, а соседний Майами-Бич хранит здания ар-деко середины 1930-х.",
   src("usa-brit-miami", "Britannica: Miami", B + "Miami-Florida"))
us("boston-tea-party-freedom-trail", "fact", "Boston, the cradle of the Revolution", "Бостон — колыбель революции",
   "Settled by English Puritans in 1630; the Boston Tea Party of 1773 marked the unrest before the Revolution, the Freedom Trail links its historic sites, and Boston Common has been public open space since 1634.",
   "Основан английскими пуританами в 1630 году; Бостонское чаепитие 1773 года отметило рост недовольства перед Американской революцией, Тропа свободы соединяет исторические места, а Бостон-Коммон открыт публике с 1634 года.",
   src("usa-brit-boston", "Britannica: Boston", B + "Boston"))
us("seattle-pike-place", "fact", "Seattle, the Emerald City", "Сиэтл — изумрудный город",
   "Largest metropolis of the Pacific Northwest on Puget Sound, settled on 13 November 1851; Boeing, Microsoft and Amazon grew up around it, and Pike Place Market of 1907 is one of the oldest public markets in the US.",
   "Крупнейший город тихоокеанского северо-запада на заливе Пьюджет, основанный 13 ноября 1851 года; вокруг него выросли Boeing, Microsoft и Amazon, а рынок Пайк-Плейс 1907 года — один из старейших непрерывно работающих рынков США.",
   src("usa-brit-seattle", "Britannica: Seattle", B + "Seattle-Washington"))
us("houston-space-city", "fact", "Houston, Space City", "Хьюстон — космический город",
   "The fourth largest US city and a leading oil and petrochemical centre; since 1961 it has housed the Manned Spacecraft Center (the Johnson Space Center since 1973), the command post for US astronauts' flights.",
   "Четвёртый по величине город США и ведущий нефтяной и нефтехимический центр; с 1961 года здесь работает Центр пилотируемых полётов, с 1973 года носящий имя Линдона Джонсона, — командный пункт полётов американских астронавтов.",
   src("usa-brit-houston", "Britannica: Houston", B + "Houston"))
us("philadelphia-independence-hall", "landmark", "Independence Hall in Philadelphia", "Индепенденс-холл в Филадельфии",
   "Dignified early 18th-century brick building where the Declaration of Independence (1776) and the US Constitution (1787) were both signed; a UNESCO World Heritage site since 1979.",
   "Строгое кирпичное здание начала XVIII века, где были подписаны Декларация независимости (1776) и Конституция США (1787); объект Всемирного наследия ЮНЕСКО с 1979 года.",
   src("usa-unesco-independence-hall", "UNESCO World Heritage Centre: Independence Hall", U + "78/"))
us("honolulu-pearl-harbor", "landmark", "Pearl Harbor in Honolulu", "Пёрл-Харбор в Гонолулу",
   "Naval base on southern Oahu about 10 km west of Honolulu; the surprise Japanese air attack of 7 December 1941 brought the US into the Second World War, and a white memorial stands over the sunken USS Arizona.",
   "Военно-морская база на юге Оаху примерно в 10 км к западу от Гонолулу; внезапный японский авианалёт 7 декабря 1941 года ввёл США во Вторую мировую войну, а над затонувшим линкором «Аризона» стоит белый мемориал.",
   src("usa-brit-pearl-harbor", "Britannica: Pearl Harbor", T + "Pearl-Harbor"))
us("detroit-motor-city", "fact", "Detroit, Motor City", "Детройт — город моторов",
   "Founded in 1701 by the French trader Antoine de la Mothe Cadillac on the Detroit River; it became the car capital of the world after Henry Ford's assembly line of 1914, and Berry Gordy Jr. founded Motown here.",
   "Основан в 1701 году французским торговцем Антуаном де ла Мот Кадильяком на реке Детройт; стал автомобильной столицей мира после того, как Генри Форд ввёл конвейер в 1914 году, а Берри Горди-младший основал здесь Motown.",
   src("usa-brit-detroit", "Britannica: Detroit", B + "Detroit"))
us("nashville-music-city", "fact", "Nashville, Music City", "Нэшвилл — город музыки",
   "Capital of Tennessee since 1843 on the Cumberland River; regular broadcasts of the Grand Ole Opry began here in 1925 and made it the centre of country music, and the city has a full-scale replica of the Parthenon.",
   "Столица Теннесси с 1843 года на реке Камберленд; регулярные передачи Grand Ole Opry начались здесь в 1925 году и сделали город центром кантри, а в парке стоит полноразмерная копия Парфенона.",
   src("usa-brit-nashville", "Britannica: Nashville", B + "Nashville-Tennessee"))
us("denver-mile-high", "fact", "Denver, the Mile High City", "Денвер — город на высоте мили",
   "Capital of Colorado founded after the discovery of gold in June 1858; its elevation of 5,280 feet (1,609 m) above sea level at the State Capitol, exactly one mile, gives it the nickname Mile High City.",
   "Столица Колорадо, основанная после находки золота в июне 1858 года; высота 5280 футов (1609 м) над уровнем моря у Капитолия штата — ровно миля — дала городу прозвище «город на высоте мили».",
   src("usa-brit-denver", "Britannica: Denver", B + "Denver"))
us("san-antonio-alamo", "landmark", "The Alamo in San Antonio", "Аламо в Сан-Антонио",
   "18th-century Franciscan mission in San Antonio, Texas, where in 1836 some 180–190 defenders, Davy Crockett among them, held out 13 days against the Mexican army and died; \"Remember the Alamo!\" became a rallying cry.",
   "Францисканская миссия XVIII века в Сан-Антонио (Техас), где в 1836 году около 180–190 защитников, включая Дэви Крокетта, 13 дней держались против мексиканской армии и погибли; «Помни Аламо!» стало боевым кличем.",
   src("usa-brit-alamo", "Britannica: The Alamo", B + "Alamo"))
us("st-louis-gateway-arch", "landmark", "Gateway Arch in St. Louis", "Арка «Ворота Запада» в Сент-Луисе",
   "Arch 630 feet (192 m) tall on the Mississippi riverfront in St. Louis, designed by Eero Saarinen in 1948 and built in 1963–1965 as a monument to the westward expansion of the United States.",
   "Арка высотой 630 футов (192 м) на берегу Миссисипи в Сент-Луисе, спроектированная Ээро Саариненом в 1948 году и построенная в 1963–1965 годах как памятник продвижению США на запад.",
   src("usa-brit-gateway-arch", "Britannica: Gateway Arch", T + "Gateway-Arch"))
us("mount-rushmore", "landmark", "Mount Rushmore in South Dakota", "Гора Рашмор в Южной Дакоте",
   "Colossal granite sculpture in the Black Hills carved under Gutzon Borglum from October 1927 to October 1941, with heads about 60 feet (18 m) tall of presidents Washington, Jefferson, Theodore Roosevelt and Lincoln.",
   "Колоссальная гранитная скульптура в Блэк-Хилс, высеченная под руководством Гутзона Борглума с октября 1927 по октябрь 1941 года: головы президентов Вашингтона, Джефферсона, Теодора Рузвельта и Линкольна высотой около 18 м.",
   src("usa-brit-mount-rushmore", "Britannica: Mount Rushmore National Memorial", T + "Mount-Rushmore-National-Memorial"))
us("new-york-yankees", "sports_team", "New York Yankees (baseball)", "«Нью-Йорк Янкиз» (бейсбол)",
   "Baseball club based in the Bronx with a record 27 World Series titles; Babe Ruth, Lou Gehrig, Joe DiMaggio and Mickey Mantle played for it.",
   "Бейсбольный клуб из Бронкса с рекордными 27 победами в Мировой серии; за него играли Бейб Рут, Лу Гериг, Джо Ди Маджо и Микки Мантл.",
   src("usa-brit-yankees", "Britannica: New York Yankees", T + "New-York-Yankees"))
us("green-bay-packers", "sports_team", "Green Bay Packers (American football)", "«Грин-Бей Пэкерс» (американский футбол)",
   "NFL team from the small city of Green Bay, Wisconsin, organised in 1919 by Curly Lambeau and George Calhoun, a publicly owned nonprofit since 1923; it won the first two Super Bowls under coach Vince Lombardi.",
   "Команда НФЛ из небольшого Грин-Бея (Висконсин), созданная в 1919 году Кёрли Ламбо и Джорджем Калхуном и с 1923 года принадлежащая публике как некоммерческая корпорация; выиграла первые два Супербоула при тренере Винсе Ломбарди.",
   src("usa-brit-packers", "Britannica: Green Bay Packers", T + "Green-Bay-Packers"))

# ================================================================ France regions
fr("ile-de-france-paris-region", "fact", "Île-de-France, the Paris region", "Иль-де-Франс — парижский регион",
   "The most densely populated region of France around Paris, the nucleus from which Hugh Capet's dynasty built the French state; it includes Versailles and the Disneyland theme park at Marne-la-Vallée.",
   "Самый густонаселённый регион Франции вокруг Парижа, ядро, из которого династия Гуго Капета построила французское государство; включает Версаль и парк Диснейленд в Марн-ла-Валле.",
   src("frr-brit-ile-de-france", "Britannica: Île-de-France", B + "Ile-de-France-region-France"))
fr("provence-alpes-cote-dazur", "fact", "Provence-Alpes-Côte d'Azur", "Прованс — Альпы — Лазурный Берег",
   "South-eastern region from the lower Rhône and the Camargue to the Italian border, with Marseille as its capital; it unites Provence with its lavender, the Alps and the Riviera resorts of Nice and Cannes.",
   "Юго-восточный регион от нижней Роны и Камарга до границы с Италией со столицей Марселем; объединяет Прованс с его лавандой, Альпы и курорты Ривьеры — Ниццу и Канны.",
   src("frr-brit-paca", "Britannica: Provence-Alpes-Côte d'Azur", B + "Provence-Alpes-Cote-dAzur"))
fr("marseille-founded-by-greeks", "fact", "Marseille, founded by the Greeks", "Марсель, основанный греками",
   "Founded more than 2,500 years ago, about 600 BCE, as the trading port Massalia by Greeks from Phocaea; today one of the major ports of the Mediterranean and the capital of Provence-Alpes-Côte d'Azur.",
   "Основан более 2500 лет назад, около 600 года до н. э., как торговый порт Массалия греками из Фокеи; сегодня один из главных портов Средиземноморья и столица региона Прованс — Альпы — Лазурный Берег.",
   src("frr-brit-marseille", "Britannica: Marseille", B + "Marseille"))
fr("occitanie-toulouse", "fact", "Occitanie and Toulouse", "Окситания и Тулуза",
   "Southern region created in 2016 by the union of Languedoc-Roussillon and Midi-Pyrénées, bordering Spain and Andorra along the Pyrenees; its capital is Toulouse.",
   "Южный регион, созданный в 2016 году слиянием Лангедока-Руссильона и Юга-Пиренеев и граничащий с Испанией и Андоррой по Пиренеям; столица — Тулуза.",
   src("frr-brit-occitanie", "Britannica: Occitanie", B + "Occitanie"))
fr("nouvelle-aquitaine-bordeaux", "fact", "Nouvelle-Aquitaine and Bordeaux", "Новая Аквитания и Бордо",
   "The largest of France's 13 metropolitan regions, created in 2016 by the union of Aquitaine, Poitou-Charentes and Limousin on the Atlantic coast of the Bay of Biscay; its capital is Bordeaux.",
   "Крупнейший из 13 регионов метрополии, созданный в 2016 году слиянием Аквитании, Пуату-Шаранты и Лимузена на атлантическом побережье Бискайского залива; столица — Бордо.",
   src("frr-brit-nouvelle-aquitaine", "Britannica: Nouvelle-Aquitaine", B + "Nouvelle-Aquitaine"))
fr("auvergne-rhone-alpes-lyon", "fact", "Auvergne-Rhône-Alpes and Lyon", "Овернь — Рона — Альпы и Лион",
   "Region of east-central France created in 2016 by the union of the former regions of Auvergne and Rhône-Alpes; its capital is Lyon.",
   "Регион на востоке центральной Франции, созданный в 2016 году слиянием прежних регионов Овернь и Рона — Альпы; столица — Лион.",
   src("frr-brit-auvergne-rhone-alpes", "Britannica: Auvergne-Rhône-Alpes", B + "Auvergne-Rhone-Alpes"))
fr("mont-blanc-highest-alps", "landmark", "Mont Blanc in the French Alps", "Монблан во французских Альпах",
   "The highest peak in Europe at 4,807 m, on the French–Italian border above Chamonix; its summit was first reached in 1786 by Michel-Gabriel Paccard and Jacques Balmat.",
   "Высочайшая вершина Европы (4807 м) на границе Франции и Италии над Шамони; впервые её покорили в 1786 году Мишель-Габриэль Паккар и Жак Бальма.",
   src("frr-brit-mont-blanc", "Britannica: Mont Blanc", B + "Mont-Blanc-mountain-Europe"))
fr("grand-est-strasbourg-alsace", "fact", "Grand Est, Alsace and Strasbourg", "Гранд-Эст, Эльзас и Страсбург",
   "North-eastern region created in 2016 by the union of Alsace, Lorraine and Champagne-Ardenne, bordered by Germany to the east and north; its capital is Strasbourg.",
   "Северо-восточный регион, созданный в 2016 году слиянием Эльзаса, Лотарингии и Шампани-Арденн, с Германией на востоке и севере; столица — Страсбург.",
   src("frr-brit-grand-est", "Britannica: Grand Est", B + "Grand-Est"))
fr("champagne-region-wine", "food", "Champagne, the sparkling wine of its region", "Шампанское — игристое вино своего региона",
   "Sparkling wine named for the Champagne region around Reims and Épernay, the site of its origin and, in France, its exclusive production; its bubbles come from a second fermentation in bottles or pressure tanks.",
   "Игристое вино, названное по региону Шампань вокруг Реймса и Эперне — месту его происхождения и, во Франции, единственного производства; пузырьки рождает вторичное брожение в бутылках или в танках под давлением.",
   src("frr-brit-champagne-wine", "Britannica: Champagne (alcoholic beverage)", T + "champagne-alcoholic-beverage"))
fr("hauts-de-france-lille", "fact", "Hauts-de-France and Lille", "О-де-Франс и Лилль",
   "Northernmost region of France, created in 2016 by the union of Nord-Pas-de-Calais and Picardy; its capital is Lille.",
   "Самый северный регион Франции, созданный в 2016 году слиянием Нор-Па-де-Кале и Пикардии; столица — Лилль.",
   src("frr-brit-hauts-de-france", "Britannica: Hauts-de-France", B + "Hauts-de-France"))
fr("normandy-d-day", "fact", "Normandy and the D-Day landings", "Нормандия и высадка в день «Д»",
   "Region on the Channel coast settled by Vikings, who became known as Normans after the treaty of 911; William, duke of Normandy, invaded England from here in 1066, and the Allies landed on its beaches on 6 June 1944.",
   "Регион на побережье Ла-Манша, заселённый викингами, которых после договора 911 года стали называть норманнами; отсюда герцог Вильгельм вторгся в Англию в 1066 году, а 6 июня 1944 года на его пляжи высадились союзники.",
   src("frr-brit-normandy", "Britannica: Normandy", B + "Normandy"))
fr("brittany-celtic-region", "fact", "Brittany, the Celtic peninsula", "Бретань — кельтский полуостров",
   "Peninsula protruding westward into the Atlantic, settled by Celts from Britain in the 5th and 6th centuries; Breton is still spoken, the region joined France by treaty in 1532, and its capital is Rennes.",
   "Полуостров, выступающий на запад в Атлантику, заселённый кельтами из Британии в V–VI веках; здесь до сих пор говорят по-бретонски, регион присоединён к Франции договором 1532 года, столица — Ренн.",
   src("frr-brit-brittany", "Britannica: Brittany", B + "Brittany-region-France"))
fr("crepes-french-pancakes", "food", "Crêpes, thin French pancakes", "Крепы — тонкие французские блинчики",
   "French pancake made of a thin batter and cooked on a hot griddle, served sweet with sugar, jam or chocolate, or savoury with fillings such as ham and cheese.",
   "Французский блинчик из жидкого теста, выпекаемый на горячей сковороде; подаётся сладким с сахаром, джемом или шоколадом либо несладким с начинкой вроде ветчины и сыра.",
   src("frr-brit-crepe", "Britannica: Crêpe", T + "crepe-pancake"))
fr("pays-de-la-loire-nantes", "fact", "Pays de la Loire and Nantes", "Земли Луары и Нант",
   "Region on the lower Loire and the Bay of Biscay with Nantes as its capital; it hosts the Le Mans 24-hour sports-car race, the resorts of the Vendée coast and châteaux at Saumur, Angers and Nantes.",
   "Регион в нижнем течении Луары и на Бискайском заливе со столицей в Нанте; здесь проходит 24-часовая гонка в Ле-Мане, расположены курорты побережья Вандеи и замки Сомюра, Анже и Нанта.",
   src("frr-brit-pays-de-la-loire", "Britannica: Pays de la Loire", B + "Pays-de-la-Loire"))
fr("loire-valley-chateaux", "landmark", "Loire Valley, the château country", "Долина Луары — край замков",
   "Stretch of the Loire from Sully-sur-Loire, east of Orléans, to Chalonnes, west of Angers, in the Centre-Val de Loire and Pays de la Loire regions; with Chambord and Chenonceau, a UNESCO site since 2000.",
   "Участок Луары от Сюлли-сюр-Луар восточнее Орлеана до Шалонна западнее Анже в регионах Центр — Долина Луары и Земли Луары; его замки, такие как Шамбор и Шенонсо, — объект ЮНЕСКО с 2000 года.",
   src("frr-unesco-loire-valley", "UNESCO World Heritage Centre: The Loire Valley between Sully-sur-Loire and Chalonnes", U + "933/"))
fr("bourgogne-franche-comte-dijon", "fact", "Bourgogne-Franche-Comté and Dijon", "Бургундия — Франш-Конте и Дижон",
   "Region of eastern France created in 2016 by the union of the former regions of Bourgogne (Burgundy) and Franche-Comté; its capital is Dijon.",
   "Регион на востоке Франции, созданный в 2016 году слиянием прежних регионов Бургундия и Франш-Конте; столица — Дижон.",
   src("frr-brit-bourgogne-franche-comte", "Britannica: Bourgogne-Franche-Comté", B + "Bourgogne-Franche-Comte"))
fr("corsica-napoleon", "fact", "Corsica, the island of Napoleon", "Корсика — остров Наполеона",
   "Largely mountainous Mediterranean island sold by Genoa to France in 1768; Napoleon Bonaparte was born in its capital Ajaccio on 15 August 1769, and since 1991 it has had a special territorial status.",
   "Гористый средиземноморский остров, проданный Генуей Франции в 1768 году; 15 августа 1769 года в его столице Аяччо родился Наполеон Бонапарт, а с 1991 года остров имеет особый статус территориального коллектива.",
   src("frr-brit-corsica", "Britannica: Corsica", B + "Corsica"))
fr("provence-lavender-avignon", "fact", "Provence, the land of lavender", "Прованс — край лаванды",
   "South-eastern region named after Gallia Transalpina, the first Roman provincia beyond the Alps, formed by the late 2nd century BCE; known for Arles, lavender fields and the popes who lived in Avignon in 1309–1377.",
   "Историческая область на юго-востоке, получившая имя от Gallia Transalpina — первой римской провинции за Альпами, сложившейся к концу II века до н. э.; известна Арлем, лавандовыми полями и папами, жившими в Авиньоне в 1309–1377 годах.",
   src("frr-brit-provence", "Britannica: Provence", B + "Provence-region-France"))
fr("cote-dazur-nice-cannes", "fact", "Côte d'Azur, the French Riviera", "Лазурный Берег — Французская Ривьера",
   "Mediterranean coast encompassing the French Riviera between Menton and Cannes in the Alpes-Maritimes département and extending into southern Var; Nice and Cannes are its best-known resorts.",
   "Средиземноморское побережье, охватывающее Французскую Ривьеру между Ментоном и Каннами в департаменте Приморские Альпы и заходящее на юг Вара; самые известные курорты — Ницца и Канны.",
   src("frr-brit-cote-dazur", "Britannica: Côte d'Azur", B + "Cote-dAzur"))
fr("chaine-des-puys-volcanoes", "wonder", "Chaîne des Puys volcanoes in Auvergne", "Цепь вулканов Пюи в Оверни",
   "Alignment of volcanoes along the Limagne fault in the Auvergne Volcanoes Regional Natural Park of Auvergne-Rhône-Alpes; a UNESCO World Heritage site since 2018.",
   "Цепочка вулканов вдоль разлома Лимань в региональном природном парке вулканов Оверни в регионе Овернь — Рона — Альпы; объект Всемирного наследия ЮНЕСКО с 2018 года.",
   src("frr-unesco-chaine-des-puys", "UNESCO World Heritage Centre: Chaîne des Puys - Limagne fault tectonic arena", U + "1434/"))

Path(__file__).with_name("delta.json").write_text(
    json.dumps({"sources": S, "countries": {"US": US, "FR": FR}}, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8", newline="\n")
print(len(US), "US items,", len(FR), "FR items,", len(S), "sources")
