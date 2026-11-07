import json, os

W = 'https://www.worldhistory.org/'
# (id, year, approx, end_year, era, countries, source, [title_ru,title_en, what_ru,what_en, why_ru,why_en, cons_ru,cons_en])
E = []
def ev(id, year, era, ids, src, tr, te, wr, we, yr, ye, cr, ce, approx=False, end=None):
    E.append(dict(id=id, year=year, approx=approx, end=end, era=era, ids=ids, src=src,
                  t=(tr, te, wr, we, yr, ye, cr, ce)))

ev('gobekli_tepe', -9600, 'prehistory', ['TR'], 'https://whc.unesco.org/en/list/1572',
   'Гёбекли-Тепе',
   'Göbekli Tepe',
   'Охотники-собиратели возвели на Гёбекли-Тепе монументальные каменные ограждения с резными Т-образными столбами.',
   'Hunter-gatherers raised monumental stone enclosures with carved T-shaped pillars at Göbekli Tepe.',
   'Постройки, вероятно, служили ритуалам, скорее всего погребальным.',
   'The structures were probably used for rituals, most likely funerary ones.',
   'Памятник показывает, что монументальное строительство началось у охотников-собирателей там, где возникли первые земледельческие общины.',
   'The site shows monumental building began among hunter-gatherers where the first farming communities emerged.',
   approx=True, end=-8200)

ev('ashoka_kalinga', -260, 'ancient', ['IN'], W + 'Ashoka/',
   'Ашока и война с Калингой',
   'Ashoka and the Kalinga war',
   'Император Маурьев Ашока отказался от войн после кровопролитного похода на государство Калинга.',
   'The Mauryan emperor Ashoka renounced war after a bloody campaign against the kingdom of Kalinga.',
   'Резня и разрушения этого похода, как считается, привели его к буддизму и идее дхаммы, благочестивого общественного поведения.',
   'The carnage of the campaign is said to have turned him to Buddhism and to dhamma, pious social conduct.',
   'Ашока записал свои наставления в эдиктах, высеченных в камне, и поддерживал распространение буддизма.',
   'Ashoka recorded his teaching in edicts carved in stone and promoted Buddhism.',
   approx=True)

ev('cyrus_babylon', -539, 'ancient', ['IQ', 'IR'], W + 'article/166/the-cyrus-cylinder/',
   'Кир Великий берёт Вавилон',
   'Cyrus the Great takes Babylon',
   'Персидский царь Кир Великий овладел Вавилоном, и по его приказу был создан глиняный цилиндр с аккадской клинописью.',
   'Cyrus the Great of Persia took Babylon, and a clay cylinder in Akkadian cuneiform was made by his order.',
   'Текст обвинял последнего вавилонского царя Набонида в запрете культа Мардука и угнетении подданных.',
   'The text accused the last Babylonian king, Nabonidus, of banning the cult of Marduk and oppressing his subjects.',
   'С 1971 года цилиндр часто трактуют как первую хартию прав человека, хотя это царская прокламация.',
   'Since 1971 the cylinder has often been read as a first charter of human rights, though it is a royal proclamation.')

ev('paper_china', 105, 'ancient', ['CN'], W + 'article/1120/paper-in-ancient-china/',
   'Изобретение бумаги в Китае',
   'Invention of paper in China',
   'Традиционно изобретение усовершенствованной бумаги приписывают Цай Луню, главе императорских мастерских в Лояне.',
   'Cai Lun, head of the imperial workshops at Luoyang, is traditionally credited with creating refined paper.',
   'Бумагу делали из размоченных и спрессованных растительных волокон, и она была дешевле и удобнее бамбука, дерева и шёлка.',
   'Paper was made from soaked, pressed plant fibres and was cheaper and handier than bamboo, wood or silk.',
   'Новый материал помог распространению литературы и грамотности.',
   'The new material helped spread literature and literacy.',
   approx=True)

ev('rome_476', 476, 'medieval', ['IT'], W + 'article/835/fall-of-the-western-roman-empire/',
   'Падение Западной Римской империи',
   'Fall of the Western Roman Empire',
   'Одоакр вошёл в Рим и низложил шестнадцатилетнего императора Ромула Августула.',
   'Odoacer entered Rome and deposed the sixteen-year-old emperor Romulus Augustulus.',
   'К середине V века значительная часть запада империи уже была потеряна.',
   'By the middle of the 5th century much of the western empire had already been lost.',
   'Историки в целом сходятся в дате 476 года, но спорят о причинах падения.',
   'Historians broadly agree on 476 as the year of the fall but dispute its causes.')

ev('khmer_empire', 802, 'medieval', ['KH'], W + 'Khmer_Empire/',
   'Основание Кхмерской империи',
   'Founding of the Khmer Empire',
   'Джаяварман II объединил мелкие королевства региона и положил начало Кхмерской империи.',
   'Jayavarman II united the small kingdoms of the region and began the Khmer Empire.',
   'Серия его военных походов подчинила большинство местных мелких государств.',
   'A series of his military campaigns subjugated most of the petty kingdoms.',
   'Империя просуществовала до 1431 года и в расцвете охватывала значительную часть современных Камбоджи и Таиланда.',
   'The empire lasted until 1431 and at its peak covered much of today’s Cambodia and Thailand.')

ev('manzikert', 1071, 'medieval', ['TR'], W + 'article/1189/battle-of-manzikert/',
   'Битва при Манцикерте',
   'Battle of Manzikert',
   'Армия сельджуков разгромила византийцев при Манцикерте и взяла в плен императора Романа IV Диогена.',
   'A Seljuk army routed the Byzantines at Manzikert and captured Emperor Romanos IV Diogenes.',
   'Империя оказалась в смуте: полководцы боролись за престол, и сельджукам никто не мог помешать.',
   'The empire fell into disarray as generals squabbled for the throne and nothing could stop the Seljuks.',
   'Хотя потери были невелики, удар по престижу империи и особе императора ощущался веками.',
   'Casualties were modest, but the blow to the empire’s prestige and the emperor’s person resounded for centuries.')

ev('great_zimbabwe', 1100, 'medieval', ['ZW'], 'https://whc.unesco.org/en/list/364',
   'Великий Зимбабве',
   'Great Zimbabwe',
   'Народ шона между XI и XV веками построил Великий Зимбабве, город площадью около 80 гектаров.',
   'The Shona people built Great Zimbabwe, a city of about 80 hectares, between the 11th and 15th centuries.',
   'Город был важным торговым центром.',
   'The city was an important trading centre.',
   'Современный Зимбабве принял за эмблему найденную там птицу из стеатита.',
   'Modern Zimbabwe adopted the steatite bird found there as its emblem.',
   approx=True)

ev('hattin', 1187, 'medieval', ['IL'], W + 'Battle_of_Hattin/',
   'Битва при Хаттине',
   'Battle of Hattin',
   'Войско Саладина, султана Египта и Сирии, полностью разгромило армию Иерусалимского королевства и его союзников.',
   'The army of Saladin, Sultan of Egypt and Syria, completely defeated the Kingdom of Jerusalem and its allies.',
   'Саладин правил Египтом и Сирией с 1174 года и вёл мусульманские силы против государств крестоносцев.',
   'Saladin ruled Egypt and Syria from 1174 and led Muslim forces against the Crusader states.',
   'Вскоре был взят Иерусалим, а поражение стало началом почти полного краха государств крестоносцев и Третьего крестового похода.',
   'Jerusalem soon fell, and the defeat nearly obliterated the Crusader states and sparked the Third Crusade.')

ev('baghdad_1258', 1258, 'medieval', ['IQ'], W + 'Ilkhanate/',
   'Монгольское взятие Багдада',
   'Mongol capture of Baghdad',
   'Монгольская армия под началом Хулагу взяла Багдад, и Аббасидский халифат пал.',
   'The Mongol army under Hulegu captured Baghdad, and the Abbasid Caliphate collapsed.',
   'Хулагу получил войско и приказ укрепить власть монголов в Западной Азии.',
   'Hulegu was given an army and ordered to consolidate Mongol control of western Asia.',
   'Хулагу стал основателем государства Ильханов.',
   'Hulegu went on to found the Ilkhanate.')

ev('mansa_musa', 1324, 'medieval', ['ML'], W + 'Mansa_Musa_I/',
   'Хадж Мансы Мусы',
   'Mansa Musa’s pilgrimage',
   'Правитель Мали Манса Муса совершил хадж в Мекку, пройдя с караваном через Сахару и Каир.',
   'Mansa Musa, ruler of Mali, made a pilgrimage to Mecca with a caravan across the Sahara and through Cairo.',
   'Мали владело золотом и медью и контролировало торговлю между севером и внутренней Африкой, поэтому сильно разбогатело.',
   'Mali controlled gold and copper lands and the trade between north and interior, and had grown very rich.',
   'Остановка в Каире прославила Мали, слухи о золоте дошли до Европы, а из хаджа Муса привёз архитекторов и учёных.',
   'The Cairo stopover spread Mali’s fame to Europe, and Musa brought back architects and scholars from the hajj.')

ev('zheng_he', 1405, 'medieval', ['CN'], W + 'article/1334/the-seven-voyages-of-zheng-he/',
   'Плавания Чжэн Хэ',
   'Voyages of Zheng He',
   'Адмирал Чжэн Хэ по приказу императора Юнлэ семь раз водил огромные флоты в плавания.',
   'Admiral Zheng He commanded huge fleets on seven voyages for the Yongle Emperor.',
   'Миссии должны были развивать торговлю и добиваться дани от далёких держав.',
   'The missions were meant to increase trade and secure tribute from distant powers.',
   'Флоты с товарами и дарами доходили от Ормуза в Персидском заливе до Могадишо в Восточной Африке.',
   'The fleets carried goods and gifts from Hormuz in the Persian Gulf to Mogadishu in East Africa.',
   end=1433)

ev('hangul', 1443, 'early_modern', ['KR'], 'https://www.unesco.org/en/memory-world/hunminjeongum-manuscript',
   'Корейский алфавит хангыль',
   'Hangul, the Korean alphabet',
   'Король Седжон Великий завершил создание корейского алфавита в 1443 году, а обнародовал его в 1446 году.',
   'King Sejong the Great completed the Korean alphabet in 1443 and promulgated it in 1446.',
   'Седжон, четвёртый король династии Чосон, разработал собственную письменность для корейского языка.',
   'Sejong, fourth king of the Joseon dynasty, developed a writing system for the Korean language.',
   'Рукопись «Хунмин чонъым» с комментариями внесена в реестр ЮНЕСКО «Память мира».',
   'The Hunminjeongeum manuscript with its commentaries is inscribed in UNESCO’s Memory of the World Register.')

ev('constantinople_1453', 1453, 'early_modern', ['TR'], W + 'article/1180/1453-the-fall-of-constantinople/',
   'Падение Константинополя',
   'Fall of Constantinople',
   'Османский султан Мехмед II взял Константинополь 29 мая 1453 года.',
   'The Ottoman sultan Mehmed II conquered Constantinople on 29 May 1453.',
   'Мощные пушки султана справились с укреплениями, которые выдерживали многие осады.',
   'The sultan’s mighty cannons overcame defences that had withstood many sieges.',
   'Город, основанный Константином I в 324 году как столица Восточной Римской империи, перешёл к османам.',
   'The city founded by Constantine I in 324 as capital of the Eastern Roman Empire passed to the Ottomans.')

ev('tordesillas', 1494, 'early_modern', ['ES'], W + 'Treaty_of_Tordesillas/',
   'Тордесильясский договор',
   'Treaty of Tordesillas',
   'Испания и Португалия 7 июня 1494 года поделили мир на две сферы влияния условной линией.',
   'On 7 June 1494 Spain and Portugal divided the world into two spheres of influence along an imaginary line.',
   'Монархи хотели закрепить за собой новые земли и оттеснить конкурентов.',
   'The monarchs wanted to secure the new lands for themselves and block rivals.',
   'Линия прошла в 370 лигах к западу от островов Зелёного Мыса, а местные народы и их границы не учитывались вовсе.',
   'The line ran 370 leagues west of Cape Verde, and local peoples and their borders were ignored entirely.')

ev('vasco_da_gama', 1498, 'early_modern', ['IN'], W + 'Vasco_da_Gama/',
   'Васко да Гама достигает Индии',
   'Vasco da Gama reaches India',
   'Флот Васко да Гамы 18 мая 1498 года подошёл к Каликуту на Малабарском берегу.',
   'Vasco da Gama’s fleet reached Calicut on the Malabar coast on 18 May 1498.',
   'Португальцы искали прямой морской путь вокруг мыса Доброй Надежды к выгодной восточной торговле пряностями.',
   'The Portuguese sought a direct sea route around the Cape of Good Hope to the lucrative eastern spice trade.',
   'Устоявшиеся торговые пути Индийского океана изменились навсегда, когда за ним последовали другие европейцы.',
   'Indian Ocean trade patterns changed forever as other Europeans followed.')

ev('tenochtitlan_1521', 1521, 'early_modern', ['MX'], W + 'Tenochtitlan/',
   'Падение Теночтитлана',
   'Fall of Tenochtitlan',
   'Эрнан Кортес с союзниками взял и разрушил Теночтитлан, столицу ацтеков, в 1521 году.',
   'Hernán Cortés and his allies took and destroyed Tenochtitlan, the Aztec capital, in 1521.',
   'Ацтеки держали империю силой, заложниками и данью, а тлашкальцы и другие народы жаждали её падения.',
   'The Aztecs held their empire by force, hostages and tribute, and the Tlaxcalans and others wanted it to fall.',
   'Разрушение столицы привело к окончательному краху Ацтекской империи.',
   'The destruction of the capital led to the final collapse of the Aztec Empire.')

ev('inca_cajamarca', 1532, 'early_modern', ['PE'], W + 'Francisco_Pizarro/',
   'Писарро и конец империи инков',
   'Pizarro and the fall of the Inca',
   'Небольшой отряд Франсиско Писарро 15 ноября 1532 года вступил в первый контакт с инками и потребовал встречи с их правителем в Кахамарке.',
   'Francisco Pizarro’s small band made first contact with the Inca on 15 November 1532 and asked to meet their king at Cajamarca.',
   'Инков ослабили гражданская война и занесённые европейцами болезни.',
   'The Inca were weakened by civil war and the arrival of European diseases.',
   'Писарро казнил правителя Атауальпу и занял столицу Куско.',
   'Pizarro executed the ruler Atahualpa and captured the capital Cusco.')

ev('westphalia', 1648, 'early_modern', ['DE'], W + 'Peace_of_Westphalia/',
   'Вестфальский мир',
   'Peace of Westphalia',
   'Договоры, подписанные 24 октября 1648 года, завершили Тридцатилетнюю войну.',
   'Treaties signed on 24 October 1648 ended the Thirty Years’ War.',
   'Они обеспечивали политическую самостоятельность множества малых государств Священной Римской империи и свободу вероисповедания.',
   'They secured political autonomy for the many small states of the Holy Roman Empire and religious freedoms.',
   'Возникло понятие вестфальского суверенитета: государство вправе само управлять собой независимо от размера.',
   'The concept of Westphalian sovereignty arose: states have the right to self-governance regardless of size.')

ev('plassey', 1757, 'early_modern', ['IN'], W + 'article/2107/battle-of-plassey/',
   'Битва при Плесси',
   'Battle of Plassey',
   'Армия Ост-Индской компании под началом Роберта Клайва 23 июня 1757 года разбила войска наваба Бенгалии.',
   'Robert Clive’s East India Company army defeated the Nawab of Bengal on 23 June 1757.',
   'К 1750-м годам компания хотела расширить торговую сеть и установить территориальный контроль.',
   'By the 1750s the Company wanted to expand its trade network and gain territorial control.',
   'Победа принесла компании богатство и открыла её территориальную экспансию, а Плесси часто называют началом британского правления в Индии.',
   'Victory brought new wealth and began the Company’s territorial expansion; Plassey is often cited as the start of British rule in India.')

ev('cook_australia', 1770, 'early_modern', ['AU'], 'https://www.sea.museum/learn/school-excursions/teacher-resources/hmb-endeavour/james-cook-gentlemen-and-crew/james-cook',
   'Эндевор у восточного берега Австралии',
   'Endeavour on the Australian east coast',
   'Корабль «Эндевор» Джеймса Кука в апреле 1770 года увидел восточный берег Австралии и поплыл вдоль него на север.',
   'James Cook’s ship Endeavour sighted the east coast of Australia in April 1770 and sailed north along it.',
   'Берег уже населяли коренные народы, жители которых следили за кораблём и подавали дымовые сигналы.',
   'The coast was already home to First Nations communities, who watched the ship and sent smoke signals ahead.',
   'Кук описывал и переименовывал места от залива Ботани до острова Поссешен, где 22 августа водрузил флаг.',
   'Cook recorded and renamed places from Botany Bay to Possession Island, where he planted a flag on 22 August.')

ev('smallpox_vaccine', 1796, 'modern', ['GB'], 'https://www.who.int/news-room/spotlight/history-of-vaccination/history-of-smallpox-vaccination',
   'Первая вакцина Дженнера',
   'Jenner’s first vaccination',
   'В мае 1796 года Эдвард Дженнер привил восьмилетнему Джеймсу Фиппсу коровью оспу.',
   'In May 1796 Edward Jenner inoculated eight-year-old James Phipps with cowpox.',
   'В деревнях верили, что коровья оспа защищает от натуральной.',
   'Rural communities believed cowpox protected against smallpox.',
   'Это стало первой в мире вакциной: принцип вариоляции сохранился, а вирус стал менее опасным.',
   'It became the world’s first vaccine, using the principle of variolation with a less dangerous virus.')

ev('boyaca', 1819, 'modern', ['CO'], 'https://colombia.co/en/colombia-country/history/history-of-colombia-independence',
   'Битва при Бояке',
   'Battle of Boyacá',
   'Армия Симона Боливара 7 августа 1819 года одержала победу в битве при Бояке.',
   'Simón Bolívar’s army won the Battle of Boyacá on 7 August 1819.',
   'Кампания освобождения началась в мае 1818 года в Венесуэле.',
   'The liberation campaign had begun in May 1818 in Venezuela.',
   'Победа завершила кампанию Боливара и привела к рождению Республики Колумбия.',
   'The victory ended Bolívar’s campaign and led to the birth of the Republic of Colombia.')

ev('waitangi', 1840, 'modern', ['NZ'], 'https://tepapa.govt.nz/discover-collections/read-watch-play/maori/treaty-waitangi/treaty-close/full-text-te-tiriti-o',
   'Договор Вайтанги',
   'Treaty of Waitangi',
   'Представитель британской Короны Уильям Хобсон и вожди маори 6 февраля 1840 года подписали в Вайтанги Те Тирити.',
   'The Crown’s representative William Hobson and Māori chiefs signed Te Tiriti o Waitangi at Waitangi on 6 February 1840.',
   'Корона хотела создать гражданское правление, чтобы избежать вреда от отсутствия законов для маори и британских подданных.',
   'The Crown wanted a settled civil government to avert the harm of having no laws for Māori and British subjects alike.',
   'Большинство вождей подписали текст на языке маори, и подписание продолжилось на севере и в Окленде.',
   'Most chiefs signed the Māori-language text, and signing continued in the north and at Auckland.')

ev('nanjing_1842', 1842, 'modern', ['CN'], 'https://history.state.gov/milestones/1830-1860/china-1',
   'Нанкинский договор',
   'Treaty of Nanjing',
   'Англо-китайский Нанкинский договор в 1842 году завершил Первую опиумную войну.',
   'The Anglo-Chinese Treaty of Nanjing ended the First Opium War in 1842.',
   'Британцы нашли в южном Китае крупный рынок контрабандного опиума, поскольку Китаю было мало что нужно с Запада.',
   'The British found a great market for smuggled opium in southern China, as China wanted few Western goods.',
   'За ним последовал Ванся (1844), первый формальный договор США с Китаем.',
   'It was followed by the Treaty of Wangxia (1844), the first formal US treaty with China.')

ev('perry_japan', 1853, 'modern', ['JP'], 'https://history.state.gov/milestones/1830-1860/opening-to-japan',
   'Миссия Перри в Японию',
   'Perry’s mission to Japan',
   'Коммодор Мэттью Перри 8 июля 1853 года привёл четыре американских корабля в Токийский залив.',
   'Commodore Matthew Perry led four American ships into Tokyo Bay on 8 July 1853.',
   'США хотели впервые за двести с лишним лет восстановить регулярную торговлю и связи с Японией.',
   'The US wanted to restore regular trade and contact with Japan for the first time in over 200 years.',
   'Канагавский договор 31 марта 1854 года открыл порты Симода и Хакодате для американских судов.',
   'The Treaty of Kanagawa of 31 March 1854 opened the ports of Shimoda and Hakodate to American ships.',
   end=1854)

ev('sepoy_1857', 1857, 'modern', ['IN'], W + 'Sepoy_Mutiny/',
   'Восстание сипаев',
   'Sepoy Mutiny',
   'Сипаи Ост-Индской компании в Мирате 10 мая 1857 года подняли оружие против британских офицеров.',
   'East India Company sepoys at Meerut raised arms against their British officers on 10 May 1857.',
   'Поводом стали 10-летние приговоры 85 сипаям, отказавшимся пользоваться патронами к винтовкам Энфилда, смазанными жиром.',
   'The trigger was 10-year sentences for 85 sepoys who refused greased Enfield rifle cartridges.',
   'Мятеж подавили, но британское государство упразднило компанию и взяло управление Индией на себя.',
   'The revolt was crushed, but the British state dissolved the Company and took over governing India.')

ev('origin_of_species', 1859, 'modern', ['GB'], 'https://darwin-online.org.uk/content/contentblock?basepage=1&itemID=F373&viewtype=side',
   'Происхождение видов Дарвина',
   'Darwin’s Origin of Species',
   'Чарльз Дарвин издал в Лондоне «Происхождение видов» 24 ноября 1859 года.',
   'Charles Darwin published On the Origin of Species in London on 24 November 1859.',
   'Дарвин утверждал, что виды меняются путём естественного отбора в борьбе за жизнь.',
   'Darwin argued that species change through natural selection in the struggle for life.',
   'Книга считается одной из самых влиятельных в истории.',
   'The book is considered one of the most influential in history.')

ev('serfdom_1861', 1861, 'modern', ['RU'], 'https://www.loc.gov/exhibits/world/rule.html',
   'Отмена крепостного права в России',
   'Abolition of serfdom in Russia',
   'Манифест 19 февраля 1861 года отменил крепостное право: около 23 миллионов крестьян получили личную свободу и надел.',
   'The Emancipation Manifesto of 19 February 1861 abolished serfdom, giving about 23 million serfs freedom and land.',
   'Реформу начал царь Александр II, правивший с 1855 года.',
   'The reform was initiated by Tsar Alexander II, who reigned from 1855.',
   'Надежды оправдались не полностью: многие дворяне дали наделы, годные лишь для пропитания, но реформа стала шагом к переменам.',
   'Hopes were only partly met, as many nobles gave subsistence-only plots, yet it was a step towards social change.')

ev('suez_canal', 1869, 'modern', ['EG'], W + 'article/2925/britain-and-the-suez-canal/',
   'Открытие Суэцкого канала',
   'Opening of the Suez Canal',
   'Суэцкий канал длиной около 160 километров открыли торжественно 17 ноября 1869 года.',
   'The Suez Canal, about 160 kilometres long, opened in a lavish ceremony on 17 November 1869.',
   'Канал строили с 1859 года под руководством Фердинанда де Лессепса силами египетских рабочих.',
   'The canal was built from 1859 under Ferdinand de Lesseps using Egyptian labour.',
   'Канал соединил Средиземное и Красное моря, а в 1882 году его захватила Британия и отпустила лишь через 75 лет.',
   'It linked the Mediterranean to the Red Sea; Britain seized it in 1882 and released it only 75 years later.')

ev('berlin_conference', 1884, 'modern', ['DE'], W + 'Berlin_Conference_1884-5/',
   'Берлинская конференция',
   'Berlin Conference',
   'Делегаты 14 государств с 15 ноября 1884 по 26 февраля 1885 года обсуждали в Берлине правила раздела Африки.',
   'Delegates of 14 states met in Berlin from 15 November 1884 to 26 February 1885 to set rules for claiming Africa.',
   'Канцлер Бисмарк собрал державы, чтобы они не воевали друг с другом из-за колоний.',
   'Chancellor Bismarck convened the powers so they would avoid war with each other over colonies.',
   'Африканских государств на конференции не было, а с 1886 года началось завоевание континента.',
   'No African states were represented, and from 1886 the conquest of the continent began in earnest.',
   end=1885)

ev('adwa', 1896, 'modern', ['ET'], W + 'Italo-Ethiopian_Wars/',
   'Битва при Адуа',
   'Battle of Adwa',
   'Эфиопские войска 1 марта 1896 года разгромили итальянскую армию при Адуа.',
   'Ethiopian forces heavily defeated the Italian army at Adwa on 1 March 1896.',
   'Италия давно стремилась колонизировать Эфиопию и начала вторжение.',
   'Italy had long sought to colonise Ethiopia and launched an invasion.',
   'Правительство Криспи пало, а Эфиопия на десятилетия сохранила полный суверенитет.',
   'Crispi’s cabinet fell, and Ethiopia kept full sovereignty for decades.')

ev('australia_federation', 1901, 'modern', ['AU'], 'https://peo.gov.au/understand-our-parliament/history-of-parliament/federation/the-federation-of-australia',
   'Федерация Австралии',
   'Federation of Australia',
   'Шесть британских колоний 1 января 1901 года объединились в Австралийский Союз.',
   'Six British colonies united on 1 January 1901 to form the Commonwealth of Australia.',
   'К 1880-м годам неэффективность разрозненной системы и желание общего правительства для торговли, обороны и иммиграции усилили поддержку федерации.',
   'By the 1880s the inefficiency of separate systems and a wish for a national government on trade, defence and immigration built support for federation.',
   'Новый Южный Уэльс, Виктория, Квинсленд, Южная Австралия, Западная Австралия и Тасмания стали штатами новой страны.',
   'New South Wales, Victoria, Queensland, South Australia, Western Australia and Tasmania became states of the new nation.')

ev('wright_flight', 1903, 'modern', ['US'], 'https://www.nps.gov/articles/wrightflyer.htm',
   'Первый полёт братьев Райт',
   'The Wright brothers’ first flight',
   'Уилбур и Орвилл Райт 17 декабря 1903 года совершили у Китти-Хок первый полёт аппарата тяжелее воздуха с двигателем.',
   'On 17 December 1903 Wilbur and Orville Wright made the first powered flight of a heavier-than-air aircraft at Kitty Hawk.',
   'Этому предшествовали годы экспериментов, включая постройку и испытания планеров.',
   'It followed years of experiments, including building and testing gliders.',
   'Первый полёт длился 12 секунд, а самый долгий в тот день — 59 секунд на 852 фута, и началась эпоха авиации.',
   'The first flight lasted 12 seconds and the longest that day 59 seconds over 852 feet, opening the age of aviation.')

ev('xinhai_1911', 1911, 'modern', ['CN'], 'https://history.state.gov/milestones/1899-1913/chinese-rev',
   'Синьхайская революция',
   'Xinhai Revolution',
   'В октябре 1911 года революционеры на юге Китая подняли восстание против династии Цин.',
   'In October 1911 revolutionaries in southern China rose against the Qing dynasty.',
   'Империя Цин сталкивалась с внешним давлением, а Революционный союз Сунь Ятсена требовал республики.',
   'The Qing Empire faced foreign pressure, and Sun Yat-sen’s Revolutionary Alliance demanded a republic.',
   'Была провозглашена Китайская Республика, и имперская система закончилась.',
   'The Republic of China was established and the imperial system ended.')

ev('penicillin', 1928, 'modern', ['GB'], 'https://www.nobelprize.org/prizes/medicine/1945/ceremony-speech/',
   'Открытие пенициллина',
   'Discovery of penicillin',
   'В 1928 году Александр Флеминг заметил, что вокруг плесени, попавшей в культуру стафилококков, бактерии погибли.',
   'In 1928 Alexander Fleming noticed that bacteria around a mould contaminating a staphylococcus culture had died.',
   'Флеминг и раньше изучал вещества, подавляющие рост бактерий.',
   'Fleming had earlier studied substances that prevent the growth of bacteria.',
   'В 1945 году Флеминг разделил Нобелевскую премию за открытие пенициллина и его лечебное действие.',
   'In 1945 Fleming shared the Nobel Prize for penicillin and its curative effect.')

ev('salt_march', 1930, 'modern', ['IN'], 'https://whc.unesco.org/en/tentativelists/7042/',
   'Соляной поход Ганди',
   'Gandhi’s Salt March',
   'Махатма Ганди 12 марта 1930 года начал Данди-марш от ашрама Сатьяграха.',
   'On 12 March 1930 Mahatma Gandhi began the Dandi March from Satyagraha Ashram.',
   'Поход был протестом против британского закона о соли.',
   'The march was a protest against the British Salt Law.',
   'Поход стал образцом массового гражданского неповиновения британским законам.',
   'The march became a model of mass civil disobedience to British law.')

ev('iran_1979', 1979, 'contemporary', ['IR'], W + 'Iranian_Revolution/',
   'Иранская революция',
   'Iranian Revolution',
   'Революция 1978–1979 годов в Иране свергла режим шаха Мохаммеда Резы Пехлеви.',
   'The 1978–1979 revolution in Iran overthrew the regime of Shah Mohammad Reza Pahlavi.',
   'Её питало глубокое недовольство отсутствием демократии и экономическим положением.',
   'It was fed by deep dissatisfaction with the lack of democracy and with economic conditions.',
   'Династия Пехлеви пала, и была создана Исламская Республика Иран.',
   'The Pahlavi dynasty ended and the Islamic Republic of Iran was established.')

ev('ghana_independence', 1957, 'contemporary', ['GH'], 'https://history.state.gov/countries/ghana',
   'Независимость Ганы',
   'Independence of Ghana',
   'Гана, прежде Золотой Берег, была провозглашена независимой от Британской империи 6 марта 1957 года.',
   'Ghana, formerly the Gold Coast, was proclaimed independent from the British Empire on 6 March 1957.',
   'Независимость завоевали под руководством Кваме Нкрумы.',
   'Independence was won under the leadership of Kwame Nkrumah.',
   'Независимость Ганы принято считать началом деколонизации Африки, а Нкрума обещал помогать другим антиколониальным движениям.',
   'Ghana’s independence is widely seen as the start of African decolonization, and Nkrumah pledged to help other anti-colonial movements.')

ev('gagarin', 1961, 'contemporary', ['RU'], 'https://news.un.org/en/story/2011/04/371742',
   'Полёт Гагарина',
   'Gagarin’s spaceflight',
   'Юрий Гагарин 12 апреля 1961 года на корабле «Восток-1» стал первым человеком в космосе.',
   'On 12 April 1961 Yuri Gagarin became the first human in space aboard Vostok 1.',
   'Полёт на корабле «Восток-1» открыл эпоху пилотируемой космонавтики.',
   'The Vostok 1 flight began the era of human spaceflight.',
   'Гагарин облетел Землю за 108 минут, а 12 апреля ООН объявила Международным днём полёта человека в космос.',
   'Gagarin orbited Earth in 108 minutes, and the UN declared 12 April the International Day of Human Space Flight.')

ev('chernobyl', 1986, 'contemporary', ['UA'], 'https://www.un.org/en/observances/chernobyl-remembrance-day/background',
   'Авария на Чернобыльской АЭС',
   'Chernobyl disaster',
   'При аварии на Чернобыльской АЭС 26 апреля 1986 года произошёл взрыв реактора.',
   'A reactor exploded at the Chernobyl nuclear power plant on 26 April 1986.',
   'Он случился во время испытания электрооборудования при плановой остановке системы.',
   'It happened during a test of electrical equipment in a routine shutdown of the system.',
   'Радиоактивное заражение распространилось на значительную часть Советского Союза, включая территории Белоруссии, Украины и России.',
   'Contamination spread over large parts of the Soviet Union, including Belarus, Ukraine and Russia.')

ev('maastricht', 1992, 'contemporary', ['NL'], 'https://european-union.europa.eu/principles-countries-history/history-eu/1990-99_en',
   'Маастрихтский договор',
   'Maastricht Treaty',
   'Договор о Европейском союзе подписали в Маастрихте 7 февраля 1992 года.',
   'The Treaty on European Union was signed in Maastricht on 7 February 1992.',
   'Единый рынок с четырьмя свободами движения людей, товаров, услуг и капитала должен был заработать в 1993 году.',
   'The single market with free movement of people, goods, services and money was due to be launched in 1993.',
   'Договор задал правила будущей единой валюты, внешней политики и безопасности и сотрудничества в юстиции.',
   'It set the rules for a future single currency, foreign and security policy, and cooperation in justice.')

ev('apartheid_end', 1994, 'contemporary', ['ZA'], 'https://sahistory.org.za/article/nelson-mandela-presidency-1994-1999',
   'Первые демократические выборы в ЮАР',
   'South Africa’s first democratic elections',
   'Южная Африка 27 апреля 1994 года провела первые демократические выборы, и АНК получил 62,65 процента голосов.',
   'South Africa held its first democratic elections on 27 April 1994, and the ANC won 62.65 per cent.',
   'Переговоры между чёрными и белыми южноафриканцами победили, а Мандела и де Клерк получили в 1993 году Нобелевскую премию мира.',
   'Negotiations between black and white South Africans prevailed, and Mandela and de Klerk won the 1993 Nobel Peace Prize.',
   'Нельсон Мандела 10 мая 1994 года стал первым чёрным президентом и возглавил правительство национального единства.',
   'On 10 May 1994 Nelson Mandela became the first black president and headed a Government of National Unity.')

E.sort(key=lambda e: e['year'])
out = []
for e in E:
    tr, te, wr, we, yr, ye, cr, ce = e['t']
    d = {'id': e['id'], 'year': e['year']}
    if e['approx']: d['approximate'] = True
    if e['end'] is not None: d['end_year'] = e['end']
    d.update({'era': e['era'], 'title_ru': tr, 'title_en': te, 'what_ru': wr, 'what_en': we,
              'why_ru': yr, 'why_en': ye, 'consequences_ru': cr, 'consequences_en': ce,
              'source_url': e['src'], 'country_ids': e['ids']})
    out.append(d)
here = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(here, 'delta.json'), 'w', encoding='utf-8') as f:
    json.dump({'events': out}, f, ensure_ascii=False, indent=2)
    f.write('\n')
print(len(out))
