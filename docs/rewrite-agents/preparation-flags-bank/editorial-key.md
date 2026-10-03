# Редакционный ключ — пилот `prep-flags-world`

Общий визуальный источник: Flagpedia download API (`https://flagpedia.net/download/api`), доступ 2026-10-03; реестр фактических URL и SHA-256: `../preparation-country-registry/flagpedia-download-ledger.json`. Идентичность страны и русские названия: `../preparation-country-registry/countries.json`, источники UN M49 и списки членов/наблюдателей ООН, доступ 2026-10-03. Все изображения сверены с фактическими локальными PNG.

| ID | ответ | изображение SHA-256 / URL | видимые признаки и дистракторы |
|---|---|---|---|
| flag-9a42e01 | A. Япония | d70de87…ff8e6 · `/jp.png` | Белое поле и единственный красный круг; Турция ошибочна: у неё красный фон, полумесяц и звезда. |
| flag-2f7c8b3 | C. Швеция | 475c1e62…56887 · `/se.png` | Синее поле, жёлтый смещённый крест; Финляндия похожа крестом, но поле у неё белое. |
| flag-c51d4e8 | B. Норвегия | 22a09e44…22aca · `/no.png` | Красное поле, синий крест в белой окантовке; Дания без синей внутренней полосы. |
| flag-61b0a29 | D. Финляндия | e109f87f…021dc · `/fi.png` | Белое поле и тёмно-синий крест; Исландия имеет синее поле и красную внутреннюю полосу. |
| flag-e83a6f0 | C. Дания | c2d1f782…bd17e · `/dk.png` | Красное поле, один белый крест; Норвегия добавляет синюю полосу внутри креста. |
| flag-04d9b72 | A. Исландия | 49e20da9…c697 · `/is.png` | Синее поле, белый крест с красной серединой; Норвегия имеет красный фон. |
| flag-7de30c4 | D. Швейцария | 5af6c932…d0693 · `/ch.png` | Квадратное красное поле и белый прямой крест; Канада прямоугольна и несёт лист. |
| flag-b1e5f96 | B. Франция | d1bdc5f0…22f5 · `/fr.png` | Вертикальные синяя-белая-красная полосы; Италия начинается зелёной. |
| flag-36c91a5 | B. Италия | d50c6434…17227 · `/it.png` | Вертикальные зелёная-белая-красная полосы; Франция начинается синей. |
| flag-a70d2c6 | D. Германия | 7fc1961f…b988 · `/de.png` | Горизонтальные чёрная-красная-жёлтая полосы; Эстония имеет синюю и белую. |
| flag-d48e7a1 | A. Польша | c5703c9d…8ee77 · `/pl.png` | Белая полоса сверху, красная снизу; Австрия имеет три полосы. |
| flag-8c63d40 | C. Эстония | 2253b34c…6bbe · `/ee.png` | Горизонтальные синяя-чёрная-белая полосы; Литва жёлто-зелёно-красная. |
| flag-15fa8c2 | D. Латвия | 0cc124f4…317b0 · `/lv.png` | Тёмно-красные полосы с узкой белой серединой; Польша имеет широкую белую верхнюю полосу. |
| flag-f2a64b9 | B. Литва | 1146487a…e415 · `/lt.png` | Горизонтальные жёлтая-зелёная-красная полосы; Латвия не содержит зелёного или жёлтого. |
| flag-93e1d57 | C. Украина | b7f4d286…e274b · `/ua.png` | Синяя верхняя и жёлтая нижняя полосы; Швеция использует эти цвета в кресте. |
| flag-4bd07e3 | A. Греция | 76e34805…4b46 · `/gr.png` | Сине-белые полосы и белый крест у древка; Израиль имеет звезду и две полосы. |
| flag-6a29f0d | C. Турция | e50ad4fe…f3a3a · `/tr.png` | Красный фон, белые полумесяц и звезда; у Туниса знаки находятся в белом круге. |
| flag-c84e15b | A. Израиль | 7eceedb3…6cbf9 · `/il.png` | Две синие полосы и синяя шестиконечная звезда; у Греции звезды нет. |
| flag-0e76c4a | D. Канада | 85490776…3b95a · `/ca.png` | Красные боковые полосы, белый центр и кленовый лист; Япония показывает круг без боковых полос. |
| flag-5d18ba4 | B. Бразилия | 76f921bc…f9750 · `/br.png` | Зелёное поле, жёлтый ромб, синий круг с белой лентой и звёздами; Габон состоит лишь из полос. |

Полные URL каждого изображения имеют форму `https://flagpedia.net/data/flags/w320/<iso2-в-нижнем-регистре>.png`; полная хеш-строка, дата, байты, разрешение провайдера и вариантная заметка находятся в указанном фактическом ledger. У всех 20 выбранных строк `variant_note` пуст.

## Приватная привязка ISO2 → медиа

Дата источника и проверки для каждой строки: 2026-10-03; первичный фактический ledger: `../preparation-country-registry/flagpedia-download-ledger.json`.

| ISO2 | SHA-256 PNG | URL источника |
|---|---|---|
| JP | d70de87c9b178bf7a4ce09478eb8375df20bafa16d50e34b837f471f2daff8e6 | https://flagpedia.net/data/flags/w320/jp.png |
| SE | 475c1e628d62b218b10b7581fec823056789c1d9daf6c01d6e54796fc9256887 | https://flagpedia.net/data/flags/w320/se.png |
| NO | 22a09e44d8121d2ab152b714d1ecef35da50d5c878f9e3f501699e691cb22aca | https://flagpedia.net/data/flags/w320/no.png |
| FI | e109f87f56b559b3d4497be214e902a702b4a656852029fa89820d9c249021dc | https://flagpedia.net/data/flags/w320/fi.png |
| DK | c2d1f782feb85e9f3a91d02e2518284e523e8d66fe711161ae0eae32051bd17e | https://flagpedia.net/data/flags/w320/dk.png |
| IS | 49e20da9b264d9719bfb766876fe4322837ecc35bb2e737742055a380d9dc697 | https://flagpedia.net/data/flags/w320/is.png |
| CH | 5af6c932b78ce18b0253f516f8f3c74a0e333287e6848e7afc055104065d0693 | https://flagpedia.net/data/flags/w320/ch.png |
| FR | d1bdc5f08a3d7290376cfc0dcd33c9604e1b5e5cbea3143cdc02da85fddf22f5 | https://flagpedia.net/data/flags/w320/fr.png |
| IT | d50c6434f7f34424dd524d3535cea21725ed72ea66c706d964f0643e91c17227 | https://flagpedia.net/data/flags/w320/it.png |
| DE | 7fc1961f8730109eebd4569961349dbd39081e3b256007bceda3e5074198b988 | https://flagpedia.net/data/flags/w320/de.png |
| PL | c5703c9d89f1d04249636445d6a5b7304f53138c226219f4f4e43dae6d88ee77 | https://flagpedia.net/data/flags/w320/pl.png |
| EE | 2253b34cdf1ae595320f2a1c7347a3cf3ad5ff4fdcff7fcdd6febc9e845a6bbe | https://flagpedia.net/data/flags/w320/ee.png |
| LV | 0cc124f49c3d28fb02ae46cece1cb2643d51dc406f7f37c5f4911447d87317b0 | https://flagpedia.net/data/flags/w320/lv.png |
| LT | 1146487ae5c3467f355d9f6199ab155a6dba17dc228dfd4fb2e84128616ee415 | https://flagpedia.net/data/flags/w320/lt.png |
| UA | b7f4d28611b207b8e713540c104a7f127c1936eb03c1b9cb38de70938ace274b | https://flagpedia.net/data/flags/w320/ua.png |
| GR | 76e348051d4252b06feebb816ba386169600a77fbeff1724645efcd2fa364b46 | https://flagpedia.net/data/flags/w320/gr.png |
| TR | e50ad4feb4f7d0f03348415bec20ccf61049d3d08968ae175d1c7cb5d98f3a3a | https://flagpedia.net/data/flags/w320/tr.png |
| IL | 7eceedb3e274ed48f38686c24ed5b95e5c42f9b5f99800324a2b9be962c6cbf9 | https://flagpedia.net/data/flags/w320/il.png |
| CA | 85490776a6998e472e5928719f44ab6e352f5ead15508b6995c931b17053b95a | https://flagpedia.net/data/flags/w320/ca.png |
| BR | 76f921bcec127a82ac23e7d46eabbe4780c32cbd5447574f984b7e2115ef9750 | https://flagpedia.net/data/flags/w320/br.png |
