# Semantic pools для minimum-20 — редакционный draft

Статус: только mapping для независимой редакционной и технической проверки. Он
не меняет source JSON, canonical bundle, catalog, статьи, маршруты, сборку или
сервер. Пользователь разрешил тематически честные объединения; этот документ
фиксирует их границы до реализации.

Основания: `minimum20-catalog-audit.json` сообщает 48 пакетов меньше 20
вопросов. Прочитаны текущий Flutter catalog и все 144 source JSON. Для каждого
предложенного пула `semantic-pools-draft.json` хранит exact source path,
public quiz ID, source quiz ID, число вопросов, итог, проверку дубликатов ID и
совпадающих stem. Во всех 22 предложенных пулах эти две проверки дали ноль
коллизий. Указанные там totals: 65, 53, 54, 20, 20, 32, 76, 42, 39, 55, 60, 85,
34, 76, 72, 32, 32, 31, 29, 29, 21 и 63; каждый не меньше 20.

Предлагаемая форма реализации — один статически derived canonical bank на
каждый `target_quiz_id`, как региональные банки географии. В него копируются
вопросы без изменений: ID, revision, stem, options, правильный ответ и grading.
Это не требует отдельной runtime-системы provenance. Для каждого исходного
public quiz ID из `legacy_alias_quiz_ids` нужна явная alias/reachability map к
целевому банку, поэтому старые URL продолжают открывать тот же учебный материал
через новый банк. Если cloned source URI участвует в article binding, при
канонической регенерации следует создать точную новую привязку к сохранённому
question ID/revision; её нельзя угадывать или заменять широким runtime lookup.

Ключевые редакционные решения:

- `home-alone-2-part-1`–`3` становятся `home-alone-2` (65): части одного фильма.
- Legacy `lotr` вместе с «Братством Кольца», «Двумя крепостями» и
  «Возвращением короля» становится `lotr-trilogy` (253): старые вопросы про
  Ородруин, девять членов Братства и Тенегрива не принадлежат одному «Братству».
  В JSON отмечены четыре близкие по смыслу пары для редакционной дедупликации;
  особенно вероятен повтор ответа о коне Гэндальфа.
- Pixar + DreamWorks дают 20 ровно, а «Игра престолов» + другие телесериалы —
  также 20; оба названия прямо отражают состав.
- Пулы кошек и собак объединены только по анатомии, породам, истории/культуре
  или циклу фактов. Поведение кошек и собачные эксперименты намеренно не
  присоединены к ним.
- Общая категория «научная фантастика» не признана достаточной причиной
  склеить «Звёздные войны» и «Терминатора».

Шесть честно не объединённых пакетов: Гарри Поттер (10), Звёздные войны (10),
Терминатор (10), гастрономический off-topic (2), поведение кошек (17), собаки
в науке (15). Для каждого причина и source path записаны в JSON. Им нужно
отдельное редакционное дополнение, а не случайное объединение.

`theme-game-worlds` и `planet-paradoxes-20261010` исключены из mapping: для
каждого уже есть собственный черновик десяти новых вопросов и требуется его
независимая проверка. Это объясняет все 48 short packs: 40 входят в предложенные
пулы, 6 помечены как честно несливаемые, 2 уже имеют отдельные drafts.

Аудит дополнительно различает 252 непустые известные difficulty bands ниже 20
и 261 с учётом девяти `unknown`: это не противоречие и не повод менять
`QuestionRound`, который уже делит остаток 41 на 20+21.

После исправления LOTR все остальные 21 mapping-пулы заново прошли механическую
проверку exact source path, source quiz ID, question count, уникальности question ID
и stem. Это не заменяет независимую семантическую проверку их заголовков и причин.


## Lead amendments accepted independently

Exact accepted plan SHA a9fc8a92e7902b23d9b269e5eaa4cdaf2edfc95c37dc413aadb0543b09ec5f29 supersedes the earlier22/253 advisory counts above:23 pools, Middle-earth251 with2 explicit old duplicate questions excluded from new play, additional StarWars/Terminator20 bank, and old off-topic food route redirects to Americas capitals35. This yields105 visible playable banks after the five independent standalone supplements. Known old-source factual/near-duplicate quality is not globally recertified by this editorial merge acceptance.
