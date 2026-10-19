# План: скелет и мозг для анатомического атласа

## Граница следующего пакета

Существующий `organ_atlas.json` содержит **52** крупных органа, железы и группы желёз и **24** тренировочных вопроса. В нём уже есть обобщённые пункты «Головной мозг» и «Кости», а также отдельные гипоталамус, гипофиз и эпифиз. Поле `coverage_note_ru` честно исключает исчерпывающий перечень микроскопических желёз и окончательный подсчёт всех органов. Поэтому следующий пакет не должен объявлять «все органы человека» завершёнными.

Задача пакета уже и проверяема: добавить обзор **206 костей взрослого человека** как группы с числом костей, основными названиями по-русски и латинскими терминами, а также основные отделы головного мозга. Это не означает 206 одинаковых кликабельных точек на силуэте: карточка группы раскрывает состав и запускает тренировочные вопросы; отдельные маркеры требуются только для заметных учебных ориентиров.

## Модель полного скелета взрослого человека

OpenStax определяет взрослый скелет как 206 костей: 80 в осевом и 126 в добавочном скелете. Суммы ниже намеренно учитывают сросшиеся крестец и копчик как отдельные кости взрослого скелета. Латинские названия — кандидаты для независимой сверки с разделом `Systema skeletale` международной *Terminologia Anatomica* (FIPAT TA2) перед импортом; русские подписи являются переводами для интерфейса.

| Раздел и карточка | Состав, число | Основные русские / латинские названия | Основание |
| --- | ---: | --- | --- |
| Осевой скелет — череп | 22 = 8 мозгового отдела + 14 лицевого | череп — *cranium*; лобная кость — *os frontale*; теменная — *os parietale*; височная — *os temporale*; затылочная — *os occipitale*; верхняя челюсть — *maxilla*; нижняя челюсть — *mandibula*; скуловая — *os zygomaticum* | [OpenStax 7.1](https://openstax.org/books/anatomy-and-physiology-2e/pages/7-1-divisions-of-the-skeletal-system), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Осевой скелет — слуховые косточки и подъязычная кость | 7 = 6 слуховых косточек + 1 подъязычная | слуховые косточки — *ossicula auditus*: молоточек — *malleus*, наковальня — *incus*, стремечко — *stapes*; подъязычная кость — *os hyoideum* | [OpenStax 7.1](https://openstax.org/books/anatomy-and-physiology-2e/pages/7-1-divisions-of-the-skeletal-system), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Осевой скелет — позвоночный столб | 26 = 7 шейных + 12 грудных + 5 поясничных позвонков + крестец + копчик | позвоночный столб — *columna vertebralis*; шейные — *vertebrae cervicales* (C1–C7); грудные — *vertebrae thoracicae* (T1–T12); поясничные — *vertebrae lumbales* (L1–L5); крестец — *os sacrum*; копчик — *os coccygis* | [OpenStax 7.3](https://openstax.org/books/anatomy-and-physiology-2e/pages/7-3-the-vertebral-column), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Осевой скелет — рёбра и грудина | 25 = 24 ребра + грудина; грудные позвонки учтены в позвоночном столбе | рёбра — *costae* (12 пар); грудина — *sternum* | [OpenStax 7.4](https://openstax.org/books/anatomy-and-physiology-2e/pages/7-4-the-thoracic-cage), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Добавочный скелет — плечевой пояс | 4 = 2 ключицы + 2 лопатки | плечевой пояс — *cingulum pectorale*; ключица — *clavicula*; лопатка — *scapula* | [OpenStax 8.1](https://openstax.org/books/anatomy-and-physiology-2e/pages/8-1-the-pectoral-girdle), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Добавочный скелет — верхние конечности | 60 = 2 плечевые + 2 лучевые + 2 локтевые + 16 костей запястья + 10 пястных + 28 фаланг | плечевая кость — *humerus*; лучевая — *radius*; локтевая — *ulna*; кости запястья — *ossa carpi*; пястные — *ossa metacarpi*; фаланги кисти — *phalanges manus* | [OpenStax 8.2](https://openstax.org/books/anatomy-and-physiology-2e/pages/8-2-bones-of-the-upper-limb), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Добавочный скелет — тазовый пояс | 2 = 2 тазовые кости | тазовый пояс — *cingulum pelvicum*; тазовая кость — *os coxae* | [OpenStax 8.3](https://openstax.org/books/anatomy-and-physiology-2e/pages/8-3-the-pelvic-girdle-and-pelvis), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| Добавочный скелет — нижние конечности | 60 = 2 бедренные + 2 надколенника + 2 большеберцовые + 2 малоберцовые + 14 костей предплюсны + 10 плюсневых + 28 фаланг | бедренная кость — *femur*; надколенник — *patella*; большеберцовая — *tibia*; малоберцовая — *fibula*; кости предплюсны — *ossa tarsi*; плюсневые — *ossa metatarsi*; фаланги стопы — *phalanges pedis* | [OpenStax 8.4](https://openstax.org/books/anatomy-and-physiology-2e/pages/8-4-bones-of-the-lower-limb), [FIPAT TA2](https://fipat.library.dal.ca/TA2/) |
| **Итого** | **80 осевых + 126 добавочных = 206** | Счёт показывается в заголовках групп и проверяется автоматически по подгруппам. | [OpenStax 7.1](https://openstax.org/books/anatomy-and-physiology-2e/pages/7-1-divisions-of-the-skeletal-system) |

## Мозг: учебные отделы, а не ложная «полная карта»

Для первого расширения выбрать четыре главные области взрослого мозга, которые прямо выделяет OpenStax: большой мозг, промежуточный мозг, ствол и мозжечок. Каждая карточка получает русское имя, латинский термин, расположение, основную функцию на вводном уровне и несколько безопасных связей для тренировки. Терминология сверяется с *Terminologia Neuroanatomica* FIPAT; этот справочник предназначен именно для подробной терминологии макро- и микроструктур мозга и спинного мозга.

| Карточка | Русское / латинское имя | Обязательные дочерние ориентиры | Источник |
| --- | --- | --- | --- |
| Большой мозг | большой мозг — *cerebrum* | полушария — *hemispheria cerebri*; кора — *cortex cerebri*; лобная, теменная, височная, затылочная доли — *lobus frontalis, parietalis, temporalis, occipitalis*; островок — *insula*; мозолистое тело — *corpus callosum*; базальные ядра — *nuclei basales* | [OpenStax 13.2](https://openstax.org/books/anatomy-and-physiology-2e/pages/13-2-the-central-nervous-system), [FIPAT TNA](https://fipat.library.dal.ca/wp-content/uploads/2017/02/FIPAT-TNA-Ch2.pdf) |
| Промежуточный мозг | промежуточный мозг — *diencephalon* | таламус — *thalamus*; гипоталамус — *hypothalamus*; эпиталамус — *epithalamus*; эпифиз — *glandula pinealis*; субталамус — *subthalamus* | [OpenStax 13.2](https://openstax.org/books/anatomy-and-physiology-2e/pages/13-2-the-central-nervous-system), [FIPAT TNA](https://fipat.library.dal.ca/wp-content/uploads/2017/02/FIPAT-TNA-Ch2.pdf) |
| Ствол мозга | ствол мозга — *truncus encephali* | средний мозг — *mesencephalon*; мост — *pons*; продолговатый мозг — *medulla oblongata* | [OpenStax 13.2](https://openstax.org/books/anatomy-and-physiology-2e/pages/13-2-the-central-nervous-system), [FIPAT TNA](https://fipat.library.dal.ca/wp-content/uploads/2017/02/FIPAT-TNA-Ch2.pdf) |
| Мозжечок | мозжечок — *cerebellum* | полушария мозжечка — *hemispheria cerebelli*; червь — *vermis*; ножки мозжечка — *pedunculi cerebellares* | [OpenStax 13.2](https://openstax.org/books/anatomy-and-physiology-2e/pages/13-2-the-central-nervous-system), [FIPAT TNA](https://fipat.library.dal.ca/wp-content/uploads/2017/02/FIPAT-TNA-Ch2.pdf) |

## Порядок поставки и ограничения

1. Сначала добавить данные групп, латинские имена и вычисляемый контроль `80 + 126 = 206`; не дублировать карточки для парных костей без учебной причины.
2. Затем добавить карточки четырёх областей мозга и перечисленные ориентиры; вопросы строить на расположении, составе и различении терминов, без медицинской диагностики.
3. Перед публикацией независимый фактчекер сверяет русские переводы и латинские термины с FIPAT, а тесты проверяют все суммы и уникальность идентификаторов.
4. Отдельным будущим пакетом остаются подробная карта черепных отверстий, малые кости запястья/предплюсны поштучно, ядра, проводящие пути, сосуды, оболочки, микроструктуры и границы видимости на иллюстрации. Пока они не добавлены и не проверены, интерфейс не должен обещать «все части мозга» или «все органы».

## Замороженное состояние черновика и оставшиеся вопросы проверки

Черновик `study/drafts/feedback43-anatomy-20261019.json` после редакторских исправлений использует отдельную группу «Рёбра и грудина»: её 25 костей не включают грудные позвонки. В нём также перечислены все 8 костей мозгового отдела и все 14 костей лицевого отдела черепа, а связи мозжечка описаны тремя парами ножек, без сведения к одному мосту.

До импорта независимый фактчекер должен подтвердить каждый латинский термин по FIPAT и решить, какие из групп и ориентиров могут иметь визуальные метки. FIPAT указан как нормативный источник-кандидат, но независимая терминологическая сверка в этом черновике ещё не зафиксирована. Существующие 52 органа, 24 вопроса и оговорка об отсутствии полного перечня всех органов остаются без изменений.
