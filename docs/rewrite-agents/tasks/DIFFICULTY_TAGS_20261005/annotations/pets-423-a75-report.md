# PETS first75 — fresh semantic rework

Status: DONE_WITH_CONCERNS; ready for independent review, not accepted or published.

Author: Codex gpt-6-sol; actual host session session-722dd1313cb04509a831961ec1838af6. Beads parent quiz_master-qr4.3. Only pets-423-a75.json and this report changed. No children, Git/index/source/code/taxonomy/accepted/manifests/deployment changes.

Scope: exact ordered PETS_423_A_IDS.json selection[:75], excluding its second75. Baseline e802ed21db936bdb9809bab2d137903eb0aa425e. Taxonomy qm-tags-v1 / 09e8e90542c121bda2e4978daaf74639ed32f3e828838d3a3f2d4e8896a4276e.

Candidate SHA256: `74e51f915921f60461136678a3d6806da7c032c5a6cdad17528fa89e131acbef`.

## Reading and decisions

Full raw text, every alternative, numeric correct_answer and full explanation were read before writing decisions in three non-truncated batches: 1–25 (tool chunk 78261c), 26–50 (7049f5), 51–75 (78392a). Pack titles/descriptions were read to check announced context (d2eb49). CONTRACT, RUBRIC, and rejection PETS_423_A150_REWORK were read. No rejected a150 decisions or helper were loaded.

Every rating, tag list, confidence, flag and rationale was authored as literal per-ID data. The inline Python only resolved assigned identities, sorted/serialized literal tag lists and validated exact batch/order. No keyword/filename classifier, old-score copy, default5, interpolated rationale or rating formula was used. No persistent helper file was created.

Audience: Russian adult general quiz participant; Easy1–3, Medium4–6, Hard7–8, Nightmare9–10. Estimates are editorial, not measured. Repetition is flagged but each score estimates this existing item alone, not familiarity from earlier questions. Exact-record/biographical facts, historical generalizations, medical explanations and folklore variants have private concerns; these flags do not certify facts or force difficulty10. No score10 was needed.

Context tags were chosen per item from safe dictionary concepts plus visible stem or announced cat/Egypt/mythology context. Country/place tags remain private. No tags for merely listed distractors. Spatial tags occur only for places/origins; quantitative tags only for requested numbers. Choupette has no country tag because this item supplies no geographic fact.

## Checks

Cwd: C:/ap/quiz_master. `python -X utf8 metadata/quiz_metadata.py check docs/rewrite-agents/tasks/DIFFICULTY_TAGS_20261005/annotations/pets-423-a75.json --partial` returned exit0: Validated 75/4078 annotations; source integrity preserved. After the narrow unsupported Choupette-country removal, the same validator functions were rerun: validate_taxonomy, load_annotations and check_annotations(partial=True), PASS for 75/4078.

Additional exact assertions PASS: 75 identities in manifest order; 75 unique individual rationales; six selected raw pack byte SHA256 hashes equal frozen INVENTORY; all4078 source semantic hashes equal INVENTORY. Sorted unique known IDs, domain/topic coverage, integer1–10, exact taxonomy_ref, approved safe context subset and private-facet exclusion are enforced by the actual validator.

No independent content/fact review or empirical calibration is claimed. Root must review all low/flagged entries and a stratified sample before acceptance.

Score counts: {"1": 5, "2": 4, "3": 8, "4": 13, "5": 10, "6": 13, "7": 9, "8": 11, "9": 2}. Bands: {"nightmare": 2, "hard": 20, "medium": 36, "easy": 17}. Confidence: {"medium": 42, "low": 15, "high": 18}. Flagged 64/75; low 15/75.

## Resource evidence

Initial full bundle lease-7b35ef53ced0422986131f0a0df696fb generation1 GRANTED; full source reads completed under grant. Composing one75-row shell write took too long; process creation rejected Windows os error206 before launch, no file changed. Lease expiry was detected, work stopped, owner reconciliation recorded concrete quiescence and generation2 RELEASED. Fresh full bundle lease-6baa90505ea5440ba002db55ec7e8597 generation1 GRANTED; renewed before each bounded25-row serialization and final verification/report. Only exact existing output leaves were exclusively locked; sources/contract/taxonomy/validator were shared-read locked. Foreign leases were untouched.

## Source byte hashes

- `quizzes/Nature/Cats/cats_breeds_man_made.json`: `4ad6a80bf33b7128bd952142a7a326e47dd2a60183a869575bad6d56737a9e84` (equals INVENTORY).
- `quizzes/Nature/Cats/cats_breeds_natural_and_ancient_part_1.json`: `3deb462aadbdf9f50d142ba7f43fce98d223865706fa76e77c4bb3c17953005e` (equals INVENTORY).
- `quizzes/Nature/Cats/cats_breeds_natural_and_ancient_part_2.json`: `d9f4ce6271f3d7c15661336489e85e29498f813d24b89c5b074d4a62850039c4` (equals INVENTORY).
- `quizzes/Nature/Cats/cats_history_ancient_egypt.json`: `210daef7a394fb7f7fb4e89cb10dd996d99769ff6b20b20d63e6b3db383ce6ae` (equals INVENTORY).
- `quizzes/Nature/Cats/cats_history_famous_and_culture.json`: `a45e227d6ea64933a56b0feb649c38a957ef2c1fc3b7c719cef94f5fdc7b8432` (equals INVENTORY).
- `quizzes/Nature/Cats/cats_history_mythology.json`: `342779b0b56b5fa7e6c08d0a3a53d8c012513102b1d1828cb02fbac0bf03ad6a` (equals INVENTORY).

## Low-confidence identities

- `q_nature_cats_behavior_cat_310`
- `q_nature_cats_breeds_cat_186`
- `q_nature_cats_breeds_cat_187`
- `q_nature_cats_breeds_cat_036`
- `q_nature_cats_breeds_cat_103`
- `q_nature_cats_breeds_cat_124`
- `q_nature_cats_breeds_cat_162`
- `q_nature_cats_breeds_cat_299`
- `q_cat_new_egypt_4`
- `q_nature_cats_history_culture_cat_091`
- `q_nature_cats_history_culture_cat_375`
- `q_cat_new_fam_2`
- `q_cat_new_fam_4`
- `q_cat_new_fam_7`
- `q_nature_cats_history_culture_cat_142`

## All flagged identities

- `q_nature_cats_breeds_cat_387`: historical_claim_unverified: дата и происхождение линии требуют источника
- `q_nature_cats_breeds_cat_306`: historical_claim_unverified: год создания и авторство породы
- `q_nature_cats_behavior_cat_310`: ambiguous_nickname: тени и липучки обе описывают близость к хозяину; nickname_claim_unverified: распространённость Velcro cats именно для серенгети
- `q_nature_cats_anatomy_cat_307`: lexical_hint: точки и Pointed; explanation_concern: температурный механизм окраса описан сомнительно, требует проверки
- `q_nature_cats_breeds_cat_125`: weak_distractors: свадебный подарок почти прямо указывает на удачу; cultural_claim_unverified: обычай дарения коратов
- `q_nature_cats_breeds_cat_186`: record_claim_unverified: 32 пальца без имени животного, даты и источника
- `q_nature_cats_breeds_cat_187`: ambiguous_key: короткие лапы подходят манчкину и наполеону, прозвище минскина требует источника
- `q_nature_cats_breeds_cat_080`: time_sensitive_record: нынешний обладатель без даты; record_claim_unverified: имя и статус рекорда
- `q_nature_cats_breeds_cat_106`: near_duplicate: тот же факт о саванне, что в cat_088
- `q_nature_cats_breeds_cat_185`: lexical_hint: Toyger напоминает tiger
- `q_nature_cats_breeds_cat_277`: near_duplicate: повтор происхождения саванны
- `q_nature_cats_breeds_cat_280`: record_claim_unverified: самый высокий и статус живущего рекордсмена
- `q_nature_cats_breeds_cat_395`: answer_in_stem: Фенрир назван в вопросе; time_sensitive_record: самый высокий живой кот без даты
- `q_nature_cats_breeds_cat_036`: size_claim_unverified: вес зависит от пола и особи, абсолютное самая маленькая требует оговорки
- `q_nature_cats_breeds_cat_082`: record_claim_unverified: точный вес и официальный рекорд; option_specificity_hint: только 21,3 кг дано также в фунтах
- `q_nature_cats_breeds_cat_083`: near_duplicate: тот же образ ликоя, что в cat_015
- `q_nature_cats_breeds_cat_103`: record_claim_unverified: богатейший кот и диапазон наследства без даты и источника
- `q_nature_cats_breeds_cat_105`: historical_claim_unverified: дата и универсальность происхождения всех вислоухих
- `q_nature_cats_breeds_cat_110`: explanation_concern: перевод названия как оборотень требует уточнения
- `q_nature_cats_breeds_cat_124`: ambiguous_description: улыбка также ассоциируется с русской голубой, нужен источник прозвища
- `q_nature_cats_breeds_cat_130`: weak_distractors: три уха, лай и невозможность прыгать заведомо неправдоподобны; wording_concern: уникальная и одна из немногих не тождественны
- `q_nature_cats_breeds_cat_162`: record_claim_concern: статус самого тяжёлого у Патчес требует проверки; option_specificity_hint: только ключ дан в фунтах
- `q_nature_cats_breeds_cat_196`: record_claim_unverified: максимум помёта и число выживших без даты или источника
- `q_nature_cats_breeds_cat_200`: near_duplicate: узнавание ликоя повторяет cat_015 и cat_083
- `q_nature_cats_breeds_cat_240`: near_duplicate: кличка Сюзи повторяет cat_105; historical_claim_unverified: дата и всеобщая родословная
- `q_nature_cats_breeds_cat_259`: record_claim_unverified: самый тяжёлый официально зарегистрированный
- `q_nature_cats_breeds_cat_284`: record_claim_unverified: старейшая в истории и официальный статус
- `q_nature_cats_breeds_cat_299`: ambiguous_description: вечная улыбка не отделяет однозначно от русской голубой; near_duplicate: описание шартреза в cat_124
- `q_nature_cats_breeds_cat_309`: record_claim_unverified: 24 трюка в минуту и статус Гиннесса
- `q_nature_cats_breeds_cat_343`: lexical_hint: Сококе полностью входит в название леса
- `q_nature_cats_breeds_cat_371`: record_claim_unverified: самый тяжёлый в истории и причина смерти; near_duplicate: кличка Химми повторяет cat_259
- `q_nature_cats_breeds_cat_039`: breed_generalization: любовь к воде и водостойкость не гарантированы у каждой особи
- `q_nature_cats_breeds_cat_079`: dated_record_unverified: статус живущего рекордсмена на 2025 год
- `q_nature_cats_breeds_cat_084`: breed_generalization: любовь к плаванию и невпитывающий мех требуют оговорок; near_duplicate: тот же признак в cat_039
- `q_nature_cats_breeds_cat_260`: record_claim_unverified: максимальная длина и способ измерения; option_specificity_hint: только 123 см переведено в дюймы
- `q_nature_cats_breeds_cat_282`: breed_generalization: любовь к воде не обязательна у всех ванов; near_duplicate: плавающая кошка уже спрашивается в cat_039
- `q_nature_cats_breeds_cat_342`: record_and_certification_unverified: мировая длина и терапевтический статус
- `q_nature_cats_breeds_cat_379`: breed_generalization: плавание и водостойкость требуют оговорок; near_duplicate: повтор вопроса о турецком ване
- `q_nature_cats_history_culture_cat_256`: historical_generalization: все члены семьи и охват обычая требуют источника
- `q_nature_cats_history_culture_cat_093`: explanation_concern: местоимение её допускает чтение про богиню вместо кошки, казнь требует исторического источника
- `q_nature_cats_history_culture_cat_298`: historical_generalization: смертная казнь за всякое убийство требует контекста
- `q_nature_cats_history_culture_cat_317`: historical_generalization: казнь даже за случайное убийство требует источника; explanation_concern: Бастет названа богом вместо богини
- `q_nature_cats_history_culture_cat_365`: historical_generalization: без периода и источника обряда
- `q_nature_cats_history_culture_cat_030`: historical_generalization: обычай траура требует источника; near_duplicate: сбривание бровей в cat_365
- `q_nature_cats_history_culture_cat_111`: archaeological_claim_unverified: старейшее, домашняя кошка, дата и вывод об одомашнивании
- `q_cat_new_egypt_1`: historical_generalization: непреднамеренное убийство и неизменная казнь требуют источника; near_duplicate: наказание уже спрашивается в cat_317
- `q_cat_new_egypt_2`: historical_generalization: египетский обряд без времени и источника; near_duplicate: вопрос о сбривании бровей
- `q_cat_new_egypt_4`: etymology_claim_concern: происхождение названий кошек во многих языках не подтверждено объяснением; ambiguous_sound_hint: Мяу тоже звукоподражание
- `q_cat_new_egypt_5`: historical_claim_unverified: главный храм и ежегодные фестивали
- `q_cat_new_egypt_6`: myth_variant_unverified: ежедневный эпизод Великого Кота требует источника
- `q_cat_new_egypt_7`: historical_claim_unverified: 1888 год и сотни тысяч кошек; pack_context_hint: объявленная тема кошек облегчает выбор
- `q_nature_cats_history_culture_cat_289`: biographical_claim_unverified: период должности не указан; explanation_concern: музейный персонаж не объясняет политическую роль
- `q_nature_cats_history_culture_cat_091`: time_sensitive_population_ratio: 2024–2025 и почти 36:1 требуют датированного источника
- `q_nature_cats_history_culture_cat_273`: near_duplicate: любимая еда Гарфилда уже в cat_155
- `q_nature_cats_history_culture_cat_375`: ambiguous_options: ключ оба пересекается с отдельно предложенными Линкольном и Клинтоном; historical_claim_unverified: четыре кошки Линкольна и другие президенты
- `q_cat_new_fam_1`: legend_not_fact: легендарное выживание следует сохранить как легенду; option_hint: Непотопляемый Сэм описывает нужное свойство
- `q_cat_new_fam_2`: ambiguous_biography: Дорис Лессинг тоже связана с кошками, десятки требуют источника
- `q_cat_new_fam_4`: ambiguous_favourite: любимый без периода, у Черчилля были разные коты; biographical_claim_unverified: Нельсон и место за столом
- `q_cat_new_fam_5`: pack_context_hint: кошачий квиз делает кошку заметной альтернативой
- `q_cat_new_fam_6`: medical_explanation_unverified: причина хмурого выражения требует источника; weak_distractors: русские общие клички против известного необычного имени
- `q_cat_new_fam_7`: inheritance_claim_unverified: стала наследницей не подтверждено объяснением
- `q_nature_cats_history_culture_cat_096`: folklore_variant_unverified: описание и трактовка Кат Ши требуют источника традиции
- `q_nature_cats_history_culture_cat_141`: folklore_variant_unverified: исцеление голосом и сочетание способностей
- `q_nature_cats_history_culture_cat_142`: folklore_conflation_concern: кража душ и самайнское подношение могут относиться к разным мотивам

## Individual decisions (75)

### 1. q_nature_cats_breeds_cat_387

Pack: `cats_breeds_man_made`; level 9 (nightmare); confidence medium.

Кличка родоначальницы селкирк-рексов — редкая деталь истории одной породы; Белла, Сюзи, Флосси и Маша не исключаются по описанию, узнавания самой породы недостаточно.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: historical_claim_unverified: дата и происхождение линии требуют источника.

### 2. q_nature_cats_breeds_cat_306

Pack: `cats_breeds_man_made`; level 7 (hard); confidence medium.

Нужно отличить малоизвестную Cheetoh от бенгальской, саванны и серенгети: все три правдоподобно напоминают диких пятнистых кошек; дата 2001 помогает лишь знакомым с селекцией.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: historical_claim_unverified: год создания и авторство породы.

### 3. q_nature_cats_behavior_cat_310

Pack: `cats_breeds_natural_and_ancient_part_1`; level 4 (medium); confidence low.

Слово «липучки» непосредственно соответствует привычке быть рядом, поэтому редкое название можно угадать; «кошки-тени» и «кошки-собаки» сохраняют конкурирующий смысл и делают ключ неоднозначным.

Editorial tags: `domain:nature, skill:association, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Flags: ambiguous_nickname: тени и липучки обе описывают близость к хозяину; nickname_claim_unverified: распространённость Velcro cats именно для серенгети.

### 4. q_nature_cats_anatomy_cat_307

Pack: `cats_breeds_natural_and_ancient_part_1`; level 3 (easy); confidence medium.

Узнаваемый сиамский окрас нужно связать с названием; английское Pointed и «точки» дают подсказку, а тэбби, калико, черепаховый и смокинг относятся к другим рисункам шерсти.

Editorial tags: `domain:nature, skill:terminology, topic:animal-anatomy, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:cat`.
Flags: lexical_hint: точки и Pointed; explanation_concern: температурный механизм окраса описан сомнительно, требует проверки.

### 5. q_nature_cats_breeds_cat_085

Pack: `cats_breeds_natural_and_ancient_part_1`; level 5 (medium); confidence high.

Связь многопалых кошек с Хемингуэем встречается в культурной эрудиции, но не является повседневным знанием; Диккенс, Твен, Кинг и Толстой — реальные писатели без подсказки в стеме.

Editorial tags: `domain:literature, domain:nature, skill:association, topic:animal-anatomy, topic:cat, topic:writers`.
Context tags: `domain:literature, domain:nature, topic:animal-anatomy, topic:cat, topic:writers`.
Flags: none.

### 6. q_nature_cats_breeds_cat_125

Pack: `cats_breeds_natural_and_ancient_part_1`; level 2 (easy); confidence medium.

Даже без знания коратов подарок молодожёнам естественно связывается с удачей и процветанием; гнев, долгий сон и скорость плохо подходят, терпение лишь слабо конкурирует.

Editorial tags: `country:th, domain:mythology, domain:nature, skill:association, topic:animal-breeds, topic:animal-culture, topic:cat, topic:customs`.
Context tags: `domain:mythology, domain:nature, topic:animal-breeds, topic:animal-culture, topic:cat, topic:customs`.
Flags: weak_distractors: свадебный подарок почти прямо указывает на удачу; cultural_claim_unverified: обычай дарения коратов.

### 7. q_nature_cats_breeds_cat_186

Pack: `cats_breeds_natural_and_ancient_part_1`; level 8 (hard); confidence low.

Точное число пальцев у рекордсмена нельзя вывести из обычной анатомии; 20, 25, 32 и 40 обозначают разные возможные отклонения, а 18 лишь знакомую норму, поэтому нужен редкий рекордный факт.

Editorial tags: `domain:nature, skill:quantitative, topic:animal-anatomy, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: 32 пальца без имени животного, даты и источника.

### 8. q_nature_cats_breeds_cat_187

Pack: `cats_breeds_natural_and_ancient_part_1`; level 6 (medium); confidence low.

Сравнение с корги выделяет коротконогих кошек, но не отделяет минскина от манчкина и наполеона; балинезийская и шартрез легче отсеиваются, остаётся знание узкого прозвища.

Editorial tags: `domain:nature, skill:association, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Flags: ambiguous_key: короткие лапы подходят манчкину и наполеону, прозвище минскина требует источника.

### 9. q_nature_cats_breeds_cat_080

Pack: `cats_breeds_natural_and_ancient_part_1`; level 8 (hard); confidence medium.

Фенрир — кличка конкретного рекордсмена, не название породы или школьный факт; Зевс, Тигр, Великан и Спот звучат как возможные клички, надёжной подсказки для общего игрока нет.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: time_sensitive_record: нынешний обладатель без даты; record_claim_unverified: имя и статус рекорда.

### 10. q_nature_cats_breeds_cat_088

Pack: `cats_breeds_natural_and_ancient_part_1`; level 5 (medium); confidence high.

Происхождение саванны от сервала известно любителям кошек, но требует отдельного знания о гибридах; гепард, оцелот, рысь и манул дают правдоподобные дикие альтернативы.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: none.

### 11. q_nature_cats_breeds_cat_106

Pack: `cats_breeds_natural_and_ancient_part_1`; level 5 (medium); confidence high.

Уточнение «африканский» помогает отсечь манула и рысь, но оставляет гепарда и сервала; для выбора всё ещё нужно любительское знание конкретной гибридной породы.

Editorial tags: `domain:nature, place:africa, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: near_duplicate: тот же факт о саванне, что в cat_088.

### 12. q_nature_cats_breeds_cat_185

Pack: `cats_breeds_natural_and_ancient_part_1`; level 3 (easy); confidence high.

Латинское Toyger позволяет связать название с тигром даже без знания селекции; бенгальская и саванна правдоподобны как дикие на вид кошки, но название ключа даёт сильную подсказку.

Editorial tags: `domain:nature, skill:association, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: lexical_hint: Toyger напоминает tiger.

### 13. q_nature_cats_breeds_cat_277

Pack: `cats_breeds_natural_and_ancient_part_1`; level 5 (medium); confidence high.

Здесь нужно назвать саванну по родительскому сервалу; бенгальская и чаузи тоже известны как гибридные породы, а Toyger и оцелот легче исключаются, поэтому факт остаётся умеренно специальным.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: near_duplicate: повтор происхождения саванны.

### 14. q_nature_cats_breeds_cat_280

Pack: `cats_breeds_natural_and_ancient_part_1`; level 8 (hard); confidence medium.

Рост и порода не раскрывают кличку: Стьюи, Баривель и Арктур тоже выглядят как имена рекордных котов; узнать Фенрира можно лишь по конкретной записи о высоте.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: самый высокий и статус живущего рекордсмена.

### 15. q_nature_cats_breeds_cat_395

Pack: `cats_breeds_natural_and_ancient_part_1`; level 1 (easy); confidence high.

В скобках вопроса уже написано «саванна Фенрир», и тот же Фенрир есть среди вариантов; достаточно сопоставить текст, сведения о рекорде и остальные клички не нужны.

Editorial tags: `domain:nature, skill:recognition, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: answer_in_stem: Фенрир назван в вопросе; time_sensitive_record: самый высокий живой кот без даты.

### 16. q_nature_cats_breeds_cat_015

Pack: `cats_breeds_natural_and_ancient_part_1`; level 6 (medium); confidence high.

Ликой — менее известная порода, которую нужно связать с образом оборотня; сфинкс правдоподобно конкурирует из-за необычной внешности, а манчкин, рэгдолл и мейн-кун не дают прямой подсказки.

Editorial tags: `domain:nature, skill:association, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: none.

### 17. q_nature_cats_breeds_cat_036

Pack: `cats_breeds_natural_and_ancient_part_1`; level 6 (medium); confidence low.

Миниатюрность Сингапуры позволяет исключить 5 и 4 кг, а 500 г похоже на котёнка; между 1,8 и 3 кг остаётся знание типичного веса взрослых животных, а не расчёт.

Editorial tags: `domain:nature, skill:quantitative, topic:animal-anatomy, topic:animal-breeds, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-breeds, topic:animal-records, topic:cat`.
Flags: size_claim_unverified: вес зависит от пола и особи, абсолютное самая маленькая требует оговорки.

### 18. q_nature_cats_breeds_cat_082

Pack: `cats_breeds_natural_and_ancient_part_1`; level 7 (hard); confidence medium.

Нужно помнить точный вес Химми, и 15,5, 21,3 и 25 кг не различаются общими знаниями; перевод только одного ответа в фунты выделяет его и немного снижает трудность редкого рекорда.

Editorial tags: `country:au, domain:nature, skill:quantitative, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: точный вес и официальный рекорд; option_specificity_hint: только 21,3 кг дано также в фунтах.

### 19. q_nature_cats_breeds_cat_083

Pack: `cats_breeds_natural_and_ancient_part_1`; level 6 (medium); confidence high.

Узнавание ликоя как кошки-оборотня требует знакомства с редкой породой; сфинкс из-за лысости остаётся разумным отвлекающим вариантом, рэгдолл, мейн-кун и саванна менее близки к описанию.

Editorial tags: `domain:nature, skill:association, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: near_duplicate: тот же образ ликоя, что в cat_015.

### 20. q_nature_cats_breeds_cat_103

Pack: `cats_breeds_natural_and_ancient_part_1`; level 7 (hard); confidence low.

Сумма наследства не выводит кличку Блэки; Томассо, Сокс, Стаббс и Ларри выглядят как известные коты и могут сбивать, нужен отдельный факт из рекордной хроники.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: богатейший кот и диапазон наследства без даты и источника.

### 21. q_nature_cats_breeds_cat_105

Pack: `cats_breeds_natural_and_ancient_part_1`; level 8 (hard); confidence medium.

Белый цвет, ферма и 1961 год не помогают выбрать между Сюзи, Беллой, Флосси, Луной и Молли; это узкая кличка основательницы линии, заметно труднее узнавания шотландской породы.

Editorial tags: `country:gb, domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: historical_claim_unverified: дата и универсальность происхождения всех вислоухих.

### 22. q_nature_cats_breeds_cat_110

Pack: `cats_breeds_natural_and_ancient_part_1`; level 4 (medium); confidence medium.

Ликой уже назван, нужно лишь связать частичную лысость и окрас с прозвищем оборотня; эльф, вампир и демон тоже образные варианты, но это легче, чем вспоминать название породы с нуля.

Editorial tags: `domain:nature, skill:association, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: explanation_concern: перевод названия как оборотень требует уточнения.

### 23. q_nature_cats_breeds_cat_124

Pack: `cats_breeds_natural_and_ancient_part_2`; level 6 (medium); confidence low.

Постоянная «улыбка» — специальное описание шартреза, не общая школьная характеристика; русская голубая правдоподобно конкурирует, а сиамская, персидская и мейн-кун отсеиваются лишь при знании пород.

Editorial tags: `domain:nature, skill:association, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Flags: ambiguous_description: улыбка также ассоциируется с русской голубой, нужен источник прозвища.

### 24. q_nature_cats_breeds_cat_130

Pack: `cats_breeds_natural_and_ancient_part_2`; level 1 (easy); confidence high.

Ответ о природных пятнах — единственный обычный биологический признак; отсутствие усов, три уха, лай и запрет прыжков настолько неправдоподобны, что знание египетской мау почти не требуется.

Editorial tags: `domain:nature, skill:recognition, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Flags: weak_distractors: три уха, лай и невозможность прыгать заведомо неправдоподобны; wording_concern: уникальная и одна из немногих не тождественны.

### 25. q_nature_cats_breeds_cat_162

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence low.

Вес конкретного Патчес — редкая новостная подробность, 15, 18,1 и 21,3 кг вполне конкурируют; перевод ключа в 40 фунтов выделяет его, но не делает сам факт общим знанием.

Editorial tags: `domain:nature, skill:quantitative, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_concern: статус самого тяжёлого у Патчес требует проверки; option_specificity_hint: только ключ дан в фунтах.

### 26. q_nature_cats_breeds_cat_196

Pack: `cats_breeds_natural_and_ancient_part_2`; level 7 (hard); confidence medium.

Рекорд помёта в 19 котят заметно превышает обычный опыт владельца; 10 и 12 выглядят как большие помёты, 30 как экстремальный рекорд, поэтому одного представления о кошках недостаточно.

Editorial tags: `domain:nature, skill:quantitative, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: максимум помёта и число выживших без даты или источника.

### 27. q_nature_cats_breeds_cat_200

Pack: `cats_breeds_natural_and_ancient_part_2`; level 6 (medium); confidence high.

Нужно перевести прозвище werewolf cat в официальное название редкой породы; сфинкс и петерболд — правдоподобные необычные бесшёрстные кошки, без знакомства с ликоем ключ не очевиден.

Editorial tags: `domain:nature, skill:terminology, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: near_duplicate: узнавание ликоя повторяет cat_015 и cat_083.

### 28. q_nature_cats_breeds_cat_240

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence medium.

Имя Сюзи относится к истории одной селекционной линии; английская запись Susie не даёт смысловой подсказки, остальные четыре женские клички столь же возможны для белой кошки.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: near_duplicate: кличка Сюзи повторяет cat_105; historical_claim_unverified: дата и всеобщая родословная.

### 29. q_nature_cats_breeds_cat_259

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence medium.

Число 21,3 кг нужно связать именно с Химми; Патчес — убедительный другой тяжёлый кот, Стаббс, Стьюи и Барни тоже не исключаются по звучанию, это редкая персональная рекордная запись.

Editorial tags: `country:au, domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: самый тяжёлый официально зарегистрированный.

### 30. q_nature_cats_breeds_cat_284

Pack: `cats_breeds_natural_and_ancient_part_2`; level 6 (medium); confidence medium.

Кримм Пафф встречается в подборках кошачьих рекордов, но Флосси — особенно убедительная альтернатива из темы долголетия; остальные клички не дают опоры, требуется знакомство с этой хроникой.

Editorial tags: `country:us, domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: старейшая в истории и официальный статус.

### 31. q_nature_cats_breeds_cat_299

Pack: `cats_breeds_natural_and_ancient_part_2`; level 6 (medium); confidence low.

Выбор шартреза по «вечной улыбке» опирается на породное описание; русская голубая делает альтернативу содержательно близкой, отсутствие изображения не позволяет сравнить мордочки напрямую.

Editorial tags: `domain:nature, skill:association, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-anatomy, topic:animal-breeds, topic:cat`.
Flags: ambiguous_description: вечная улыбка не отделяет однозначно от русской голубой; near_duplicate: описание шартреза в cat_124.

### 32. q_nature_cats_breeds_cat_303

Pack: `cats_breeds_natural_and_ancient_part_2`; level 7 (hard); confidence medium.

Тойбоб малоизвестен широкой аудитории, а название Toybob не указывает на Россию; США, Япония, Франция и Таиланд — возможные центры происхождения пород, нужен специальный факт о месте выведения.

Editorial tags: `country:ru, domain:nature, skill:spatial, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: none.

### 33. q_nature_cats_breeds_cat_309

Pack: `cats_breeds_natural_and_ancient_part_2`; level 9 (nightmare); confidence medium.

Количество трюков не раскрывает имя Дидги; Тара, Фейт, Сюзи и Мерлин выглядят как реальные клички, это малозаметная запись о конкретной дрессированной кошке даже для подготовленного любителя.

Editorial tags: `country:au, domain:nature, skill:direct-recall, topic:animal-behavior, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: 24 трюка в минуту и статус Гиннесса.

### 34. q_nature_cats_breeds_cat_343

Pack: `cats_breeds_natural_and_ancient_part_2`; level 1 (easy); confidence high.

Название Арабуко-Сококе содержит Сококе, которое дословно повторено в ответе; серенгети, саванна, абиссинская и мау не требуют сравнения происхождения, достаточно прочитать формулировку.

Editorial tags: `country:ke, domain:nature, skill:recognition, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-breeds, topic:cat`.
Flags: lexical_hint: Сококе полностью входит в название леса.

### 35. q_nature_cats_breeds_cat_371

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence medium.

Чтобы выбрать Химми по весу 21,3 кг, нужна конкретная рекордная кличка; Патчес особенно правдоподобен в вопросе об ожирении, общая узнаваемость котов не исключает и прочие имена.

Editorial tags: `country:au, domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: самый тяжёлый в истории и причина смерти; near_duplicate: кличка Химми повторяет cat_259.

### 36. q_nature_cats_breeds_cat_039

Pack: `cats_breeds_natural_and_ancient_part_2`; level 4 (medium); confidence medium.

Турецкий ван как «плавающая кошка» — известная любительская особенность породы; привычные сиамская, персидская, русская голубая и вислоухая не несут такой устойчивой ассоциации, но школьного знания недостаточно.

Editorial tags: `domain:nature, skill:association, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Flags: breed_generalization: любовь к воде и водостойкость не гарантированы у каждой особи.

### 37. q_nature_cats_breeds_cat_079

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence medium.

Нужно различить Баривеля и Стьюи по рекорду именно живущего кота; Арктур, Саймон и Геркулес тоже возможные известные клички, дата не даёт вывода без знания конкретной записи.

Editorial tags: `country:it, domain:nature, skill:direct-recall, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: dated_record_unverified: статус живущего рекордсмена на 2025 год.

### 38. q_nature_cats_breeds_cat_084

Pack: `cats_breeds_natural_and_ancient_part_2`; level 4 (medium); confidence medium.

Любительская ассоциация турецкого вана с плаванием позволяет решить за один шаг; остальные четыре распространённые породы не дают равносильной подсказки, однако факт не является почти универсальным.

Editorial tags: `domain:nature, skill:association, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Flags: breed_generalization: любовь к плаванию и невпитывающий мех требуют оговорок; near_duplicate: тот же признак в cat_039.

### 39. q_nature_cats_breeds_cat_260

Pack: `cats_breeds_natural_and_ancient_part_2`; level 7 (hard); confidence medium.

Имя Стьюи уже дано, требуется точная длина; 100 и 150 см правдоподобно конкурируют, 80 и 200 легче отсечь, а дополнительная запись 48,5 дюйма выделяет ключ и снижает чистую трудность рекорда.

Editorial tags: `domain:nature, skill:quantitative, topic:animal-records, topic:cat`.
Context tags: `domain:nature, topic:animal-records, topic:cat`.
Flags: record_claim_unverified: максимальная длина и способ измерения; option_specificity_hint: только 123 см переведено в дюймы.

### 40. q_nature_cats_breeds_cat_282

Pack: `cats_breeds_natural_and_ancient_part_2`; level 4 (medium); confidence medium.

Прозвище «плавающая кошка» нужно связать с турецким ваном, что известно по популярным описаниям пород; сиамская, персидская, голубая и вислоухая не объясняют прозвище, но требуется любительская эрудиция.

Editorial tags: `domain:nature, skill:association, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Flags: breed_generalization: любовь к воде не обязательна у всех ванов; near_duplicate: плавающая кошка уже спрашивается в cat_039.

### 41. q_nature_cats_breeds_cat_342

Pack: `cats_breeds_natural_and_ancient_part_2`; level 8 (hard); confidence medium.

Здесь связаны две биографические детали Стьюи — длина и терапевтическая работа; Баривель, Арктур, Сигнус и Фенрир звучат как конкурирующие рекордсмены, обычного знания мейн-кунов недостаточно.

Editorial tags: `domain:nature, skill:direct-recall, topic:animal-records, topic:cat, topic:service-animals`.
Context tags: `domain:nature, topic:animal-records, topic:cat, topic:service-animals`.
Flags: record_and_certification_unverified: мировая длина и терапевтический статус.

### 42. q_nature_cats_breeds_cat_379

Pack: `cats_breeds_natural_and_ancient_part_2`; level 4 (medium); confidence medium.

Плавание и шерсть напоминают распространённое описание турецкого вана; английское Turkish Van не даёт новой смысловой подсказки, среди других обычных пород выбрать поможет знакомство с популярной породной особенностью.

Editorial tags: `domain:nature, skill:association, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Context tags: `domain:nature, topic:animal-behavior, topic:animal-breeds, topic:cat`.
Flags: breed_generalization: плавание и водостойкость требуют оговорок; near_duplicate: повтор вопроса о турецком ване.

### 43. q_nature_cats_history_culture_cat_256

Pack: `cats_history_ancient_egypt`; level 5 (medium); confidence medium.

Сбривание бровей уже сообщено, нужно вспомнить охват обряда; «все члены семьи» естественно для общего траура, но отец, дети или слуги тоже мыслимы в иерархическом обществе, нужна культурная подробность.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:customs`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:customs`.
Flags: historical_generalization: все члены семьи и охват обычая требуют источника.

### 44. q_nature_cats_history_culture_cat_093

Pack: `cats_history_ancient_egypt`; level 3 (easy); confidence medium.

Бастет с кошачьей головой — узнаваемая египетская богиня; Сехмет является содержательно близким отвлечением, а Нефертити и Клеопатра — исторические женщины, поэтому требуется обычная культурная эрудиция.

Editorial tags: `country:eg, domain:mythology, era:ancient, skill:association, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Context tags: `domain:mythology, era:ancient, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Flags: explanation_concern: местоимение её допускает чтение про богиню вместо кошки, казнь требует исторического источника.

### 45. q_nature_cats_history_culture_cat_198

Pack: `cats_history_ancient_egypt`; level 3 (easy); confidence high.

Кошачья голова и покровительство кошкам дают две знакомые опоры для Бастет; Сехмет и Хатор — правдоподобные богини, Изида менее близка к образу, Нефертити легче исключить как историческую фигуру.

Editorial tags: `country:eg, domain:mythology, era:ancient, skill:association, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Context tags: `domain:mythology, era:ancient, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Flags: none.

### 46. q_nature_cats_history_culture_cat_298

Pack: `cats_history_ancient_egypt`; level 2 (easy); confidence medium.

Священные кошки — очень знакомая ассоциация с Древним Египтом; Китай, Индия, Япония и Россия не дают столь сильной общеизвестной связи, точное правовое утверждение для выбора страны не нужно.

Editorial tags: `country:eg, domain:history, era:ancient, skill:association, topic:animal-culture, topic:cat, topic:law-regulations`.
Context tags: `domain:history, topic:animal-culture, topic:cat`.
Flags: historical_generalization: смертная казнь за всякое убийство требует контекста.

### 47. q_nature_cats_history_culture_cat_317

Pack: `cats_history_ancient_egypt`; level 3 (easy); confidence medium.

Суровая защита священных кошек часто встречается в популярной истории Египта; штраф, изгнание и тюрьма правдоподобны как наказания, но знакомый рассказ помогает выбрать казнь одним шагом.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:law-regulations`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:law-regulations`.
Flags: historical_generalization: казнь даже за случайное убийство требует источника; explanation_concern: Бастет названа богом вместо богини.

### 48. q_nature_cats_history_culture_cat_365

Pack: `cats_history_ancient_egypt`; level 5 (medium); confidence medium.

Брови — менее известная египетская похоронная деталь, которую нельзя вывести из священного статуса кошки; плач 40 дней выглядит как обряд, уход из дома и перекраска волос слабее, но не раскрывают ответ.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:customs`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:customs`.
Flags: historical_generalization: без периода и источника обряда.

### 49. q_nature_cats_history_culture_cat_030

Pack: `cats_history_ancient_egypt`; level 5 (medium); confidence medium.

Сбривание бороды и бровей — близкие телесные жесты траура, поэтому знание лишь общего египетского обычая недостаточно; перекраска, уход и 100 дней плача менее убедительны, остаётся конкретная культурная деталь.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:customs`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:customs`.
Flags: historical_generalization: обычай траура требует источника; near_duplicate: сбривание бровей в cat_365.

### 50. q_nature_cats_history_culture_cat_111

Pack: `cats_history_ancient_egypt`; level 6 (medium); confidence medium.

Привычная связь кошек с Египтом делает Гизу сильным отвлечением, Месопотамия тоже правдоподобна для раннего одомашнивания; Кипр нужно знать по специальной археологической находке, а не вывести из возраста.

Editorial tags: `country:cy, domain:history, domain:nature, era:ancient, skill:spatial, topic:animal-domestication, topic:cat`.
Context tags: `domain:history, domain:nature, era:ancient, topic:animal-domestication, topic:cat`.
Flags: archaeological_claim_unverified: старейшее, домашняя кошка, дата и вывод об одомашнивании.

### 51. q_cat_new_egypt_1

Pack: `cats_history_ancient_egypt`; level 3 (easy); confidence medium.

Это знакомый популярный рассказ о священных кошках Египта; штраф, тюрьма и изгнание могли бы подходить случайному убийству, но припоминание легенды о суровом наказании ведёт к казни без нескольких шагов.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:law-regulations`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:law-regulations`.
Flags: historical_generalization: непреднамеренное убийство и неизменная казнь требуют источника; near_duplicate: наказание уже спрашивается в cat_317.

### 52. q_cat_new_egypt_2

Pack: `cats_history_ancient_egypt`; level 5 (medium); confidence medium.

Все четыре ответа — части волос, поэтому почти нет исключения по нелепости; брови нужно отличить от головы, бороды и усов по менее заметному факту о погребальном обычае.

Editorial tags: `country:eg, domain:history, era:ancient, skill:direct-recall, topic:animal-culture, topic:cat, topic:customs`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:customs`.
Flags: historical_generalization: египетский обряд без времени и источника; near_duplicate: вопрос о сбривании бровей.

### 53. q_cat_new_egypt_3

Pack: `cats_history_ancient_egypt`; level 3 (easy); confidence high.

Кошачья голова является знакомым атрибутом Бастет; Исида, Сехмет и Хатхор — реальные имена пантеона и требуют различения, но для взрослого общего игрока это распространённая египетская ассоциация.

Editorial tags: `country:eg, domain:mythology, era:ancient, skill:association, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Context tags: `domain:mythology, era:ancient, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Flags: none.

### 54. q_cat_new_egypt_4

Pack: `cats_history_ancient_egypt`; level 4 (medium); confidence low.

Подсказка «звукоподражание» отсеивает кот и Баст, но оставляет мяу и миу; именно древнеегипетскую форму нужно припомнить, а тезис о её влиянии на множество языков отдельно сомнителен.

Editorial tags: `country:eg, domain:language, era:ancient, skill:terminology, topic:cat, topic:word-origin`.
Context tags: `domain:language, era:ancient, topic:cat, topic:word-origin`.
Flags: etymology_claim_concern: происхождение названий кошек во многих языках не подтверждено объяснением; ambiguous_sound_hint: Мяу тоже звукоподражание.

### 55. q_cat_new_egypt_5

Pack: `cats_history_ancient_egypt`; level 6 (medium); confidence medium.

Фивы, Мемфис и Гиза — знакомые египетские города, а Бубастис — менее известный центр культа; созвучие Бастет помогает, но надёжный ответ требует специального знания расположения святилища.

Editorial tags: `country:eg, domain:history, era:ancient, skill:spatial, topic:animal-culture, topic:cat, topic:religion`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:religion`.
Flags: historical_claim_unverified: главный храм и ежегодные фестивали.

### 56. q_cat_new_egypt_6

Pack: `cats_history_ancient_egypt`; level 5 (medium); confidence medium.

Апоп как змей хаоса — стандартная подробность египетской мифологии для любителя; Сет сильнее остальных отвлекает ролью противника, Тот и Кнум менее подходят, кошачий образ Ра не нужен для многошагового вывода.

Editorial tags: `country:eg, domain:mythology, era:ancient, skill:association, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Context tags: `domain:mythology, era:ancient, topic:animal-culture, topic:cat, topic:mythic-tradition`.
Flags: myth_variant_unverified: ежедневный эпизод Великого Кота требует источника.

### 57. q_cat_new_egypt_7

Pack: `cats_history_ancient_egypt`; level 4 (medium); confidence medium.

В кошачьем египетском квизе массовые мумии естественно подходят некрополю; золотые статуи остаются возможной находкой, древний корм и чертежи слабее, поэтому неизвестный Бени-Хасан не делает вопрос специалистским.

Editorial tags: `country:eg, domain:history, era:ancient, skill:recognition, topic:animal-culture, topic:cat, topic:historical-events`.
Context tags: `domain:history, era:ancient, topic:animal-culture, topic:cat, topic:historical-events`.
Flags: historical_claim_unverified: 1888 год и сотни тысяч кошек; pack_context_hint: объявленная тема кошек облегчает выбор.

### 58. q_nature_cats_history_culture_cat_155

Pack: `cats_history_famous_and_culture`; level 2 (easy); confidence high.

Лазанья — один из самых узнаваемых признаков Гарфилда; рыба, сметана, пицца и мыши правдоподобны для котов вообще, но конкретный широко известный герой делает выбор простым.

Editorial tags: `domain:screen, medium:animation, skill:association, topic:animal-culture, topic:cat, topic:characters`.
Context tags: `domain:screen, medium:animation, topic:animal-culture, topic:cat, topic:characters`.
Flags: none.

### 59. q_nature_cats_history_culture_cat_156

Pack: `cats_history_famous_and_culture`; level 6 (medium); confidence high.

Песня Memory широко известна отдельно от сюжета, но исполнительницу Гризабеллу надо связать с именем роли; Макэвити, Рам-Там-Таггер, Бастофер Джонс и Скимблшенкс — убедительные персонажи того же мюзикла.

Editorial tags: `domain:arts, skill:association, topic:animal-culture, topic:cat, topic:characters, topic:musical-theatre`.
Context tags: `domain:arts, topic:animal-culture, topic:cat, topic:characters, topic:musical-theatre`.
Flags: none.

### 60. q_nature_cats_history_culture_cat_289

Pack: `cats_history_famous_and_culture`; level 4 (medium); confidence medium.

Ларри часто появляется в международных новостях как кот Даунинг-стрит, поэтому факт доступен общему читателю; Стаббс, Сокс и Саймон — правдоподобные знаменитые коты, Василий легче исключить.

Editorial tags: `country:gb, domain:society, skill:direct-recall, topic:animal-culture, topic:cat`.
Context tags: `domain:society, topic:animal-culture, topic:cat`.
Flags: biographical_claim_unverified: период должности не указан; explanation_concern: музейный персонаж не объясняет политическую роль.

### 61. q_nature_cats_history_culture_cat_017

Pack: `cats_history_famous_and_culture`; level 6 (medium); confidence medium.

Нужно отличить Аосиму от Тасиросимы, тоже известного кошачьего острова; префектура Эхимэ помогает только знающим японскую географию, Окинава, Хоккайдо и Сикоку менее точны, но узнаваемы.

Editorial tags: `country:jp, domain:geography, skill:spatial, topic:animal-culture, topic:cat, topic:world-geography`.
Context tags: `domain:geography, topic:animal-culture, topic:cat, topic:world-geography`.
Flags: none.

### 62. q_nature_cats_history_culture_cat_091

Pack: `cats_history_famous_and_culture`; level 8 (hard); confidence low.

Образ кошачьего острова позволяет исключить 1:1, но не выбрать уверенно между 5:1, 36:1 и 100:1; нужно редкое конкретное соотношение на указанную дату, которое нельзя вычислить из стема.

Editorial tags: `country:jp, domain:geography, domain:nature, skill:quantitative, topic:animal-records, topic:cat, topic:world-geography`.
Context tags: `domain:geography, domain:nature, topic:animal-records, topic:cat, topic:world-geography`.
Flags: time_sensitive_population_ratio: 2024–2025 и почти 36:1 требуют датированного источника.

### 63. q_nature_cats_history_culture_cat_273

Pack: `cats_history_famous_and_culture`; level 2 (easy); confidence high.

Связь лазаньи с Гарфилдом — заметный массовый образ; Том, Леопольд, Матроскин и Феликс тоже знакомые коты, но это не их устойчивый пищевой признак, достаточно простого узнавания.

Editorial tags: `domain:screen, medium:animation, skill:association, topic:animal-culture, topic:cat, topic:characters`.
Context tags: `domain:screen, medium:animation, topic:animal-culture, topic:cat, topic:characters`.
Flags: near_duplicate: любимая еда Гарфилда уже в cat_155.

### 64. q_nature_cats_history_culture_cat_375

Pack: `cats_history_famous_and_culture`; level 5 (medium); confidence low.

Сокс делает Клинтона узнаваемым владельцем кота, а для ответа «оба» нужно дополнительно знать Линкольна; Вашингтон и Рейган выглядят возможными владельцами, пересечение отдельного Клинтона с ключом осложняет однозначность.

Editorial tags: `country:us, domain:history, skill:association, topic:animal-culture, topic:cat`.
Context tags: `domain:history, topic:animal-culture, topic:cat`.
Flags: ambiguous_options: ключ оба пересекается с отдельно предложенными Линкольном и Клинтоном; historical_claim_unverified: четыре кошки Линкольна и другие президенты.

### 65. q_cat_new_fam_1

Pack: `cats_history_famous_and_culture`; level 4 (medium); confidence medium.

Можно узнать популярную легенду о Сэме, но даже без неё прозвище «Непотопляемый» в ключе прямо соответствует пережитым крушениям; Феликс, Барни и Саймон такой опоры не имеют.

Editorial tags: `domain:history, skill:association, topic:animal-culture, topic:cat, topic:historical-events`.
Context tags: `domain:history, topic:animal-culture, topic:cat, topic:historical-events`.
Flags: legend_not_fact: легендарное выживание следует сохранить как легенду; option_hint: Непотопляемый Сэм описывает нужное свойство.

### 66. q_cat_new_fam_2

Pack: `cats_history_famous_and_culture`; level 7 (hard); confidence low.

Колетт надо узнать по частной биографической привычке, а не произведению; Дорис Лессинг особенно правдоподобна из-за её кошачьей тематики, Кристи и Вулф также нельзя отсечь по формулировке.

Editorial tags: `country:fr, domain:literature, skill:association, topic:animal-culture, topic:cat, topic:writers`.
Context tags: `domain:literature, topic:animal-culture, topic:cat, topic:writers`.
Flags: ambiguous_biography: Дорис Лессинг тоже связана с кошками, десятки требуют источника.

### 67. q_cat_new_fam_3

Pack: `cats_history_famous_and_culture`; level 1 (easy); confidence high.

Шрек и Бандерас дают две сильные массовые подсказки к Коту в сапогах; Гарфилд и Том принадлежат другим узнаваемым историям, Шалтай не кот, поэтому выбор почти непосредственный.

Editorial tags: `domain:screen, franchise:dreamworks, medium:animation, skill:recognition, topic:animal-culture, topic:cat, topic:characters`.
Context tags: `domain:screen, franchise:dreamworks, medium:animation, topic:animal-culture, topic:cat, topic:characters`.
Flags: none.

### 68. q_cat_new_fam_4

Pack: `cats_history_famous_and_culture`; level 7 (hard); confidence low.

Кличка Нельсон — узкая подробность домашней жизни Черчилля; Цезарь, Британец и Шерлок звучат как подходящие британскому политику имена, формулировка не позволяет вывести любимца и не задаёт период.

Editorial tags: `country:gb, domain:history, skill:direct-recall, topic:animal-culture, topic:cat`.
Context tags: `domain:history, topic:animal-culture, topic:cat`.
Flags: ambiguous_favourite: любимый без периода, у Черчилля были разные коты; biographical_claim_unverified: Нельсон и место за столом.

### 69. q_cat_new_fam_5

Pack: `cats_history_famous_and_culture`; level 4 (medium); confidence medium.

Требуется частный музыкальный факт о Delilah, но в объявленном квизе о кошках «любимая кошка» сильно выделяется среди матери, жены и гитары; это облегчает вопрос по сравнению с называнием конкретного питомца.

Editorial tags: `domain:arts, skill:association, topic:animal-culture, topic:cat, topic:composition`.
Context tags: `domain:arts, topic:animal-culture, topic:cat, topic:composition`.
Flags: pack_context_hint: кошачий квиз делает кошку заметной альтернативой.

### 70. q_cat_new_fam_6

Pack: `cats_history_famous_and_culture`; level 4 (medium); confidence medium.

Grumpy Cat широко узнаваема как мем, настоящее имя Тардар Соус известно меньше; Снежок, Вредина и Пушок выглядят общими русскими кличками, необычная форма ключа позволяет легче вспомнить медийное имя.

Editorial tags: `domain:society, skill:direct-recall, topic:animal-culture, topic:cat`.
Context tags: `domain:society, topic:animal-culture, topic:cat`.
Flags: medical_explanation_unverified: причина хмурого выражения требует источника; weak_distractors: русские общие клички против известного необычного имени.

### 71. q_cat_new_fam_7

Pack: `cats_history_famous_and_culture`; level 4 (medium); confidence low.

Шупетт встречается в светских новостях о Лагерфельде; Версаче, Шанель и Диор — знакомые модные имена и возможные клички, но ключ можно узнать по заметному медийному питомцу без специальных знаний моды.

Editorial tags: `domain:arts, skill:association, topic:animal-culture, topic:cat`.
Context tags: `domain:arts, topic:animal-culture, topic:cat`.
Flags: inheritance_claim_unverified: стала наследницей не подтверждено объяснением.

### 72. q_cat_new_fam_8

Pack: `cats_history_famous_and_culture`; level 1 (easy); confidence high.

Исчезающий кот с остающейся улыбкой — почти универсальный образ Чеширского кота; Мартовский связан с другим животным, Кот в шляпе и Феликс — другие герои, дополнительная подсказка Кэрролла делает выбор прямым.

Editorial tags: `domain:literature, skill:recognition, topic:animal-culture, topic:cat, topic:characters, topic:literary-works`.
Context tags: `domain:literature, topic:animal-culture, topic:cat, topic:characters, topic:literary-works`.
Flags: none.

### 73. q_nature_cats_history_culture_cat_096

Pack: `cats_history_mythology`; level 6 (medium); confidence medium.

Нужно знать внешний вид малоизвестного шотландского Кат Ши; чёрный кот с белым пятном, крылатый и огненный кот одинаково мыслимы как фольклорные образы, значение имени не раскрывает нужную деталь.

Editorial tags: `country:gb, domain:mythology, skill:direct-recall, topic:animal-culture, topic:cat, topic:folklore`.
Context tags: `domain:mythology, topic:animal-culture, topic:cat, topic:folklore`.
Flags: folklore_variant_unverified: описание и трактовка Кат Ши требуют источника традиции.

### 74. q_nature_cats_history_culture_cat_141

Pack: `cats_history_mythology`; level 3 (easy); confidence medium.

Кот Баюн знаком по русской сказочной культуре, само имя ассоциируется с убаюкиванием; разрушение стен, окаменение и дождь менее близки голосу сказителя, поэтому можно выбрать сон даже без подробного знания исцеления.

Editorial tags: `domain:mythology, skill:association, topic:animal-culture, topic:cat, topic:folklore`.
Context tags: `domain:mythology, topic:animal-culture, topic:cat, topic:folklore`.
Flags: folklore_variant_unverified: исцеление голосом и сочетание способностей.

### 75. q_nature_cats_history_culture_cat_142

Pack: `cats_history_mythology`; level 7 (hard); confidence low.

Поступок Кат Ши на Самайн — узкая деталь шотландского фольклора; подарок детям и тыква выглядят поздними праздничными отвлечениями, но кражу душ не вывести из имени, а связь с подношением требует отдельной проверки.

Editorial tags: `country:gb, domain:mythology, skill:direct-recall, topic:animal-culture, topic:cat, topic:folklore`.
Context tags: `domain:mythology, topic:animal-culture, topic:cat, topic:folklore`.
Flags: folklore_conflation_concern: кража душ и самайнское подношение могут относиться к разным мотивам.


## Root bounded review correction

Independent full75 metadata review required18 repeated-fact flags and2 Easy cue ratings. Root reread all20 changed source records and applied only those fields. Current candidate SHA256 `330496d99533701cc4ac297c025ec64c683bd22298d7e3a5bc21f017c4c34e17`; exact before/after rows in review/PETS_A75_DELTA.json. Original metrics/hashes above describe the pre-delta candidate; final reviewer recheck pending. Source facts/options/keys unchanged.
