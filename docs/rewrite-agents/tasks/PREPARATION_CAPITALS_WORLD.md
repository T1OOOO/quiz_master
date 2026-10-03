# Full capital bank — frozen registry transcription

Workspace C:/ap/quiz_master, base faf55b7, label content-capitals-world-oct3.
Own ONLY docs/rewrite-agents/preparation-capitals-world/**. Not alone: preserve
other edits. No git, production publication, children, builds or browser. Read
qm-work-packet, qm-mechanical and host coordination. One combined interactive
lease (agent_turns:1 plus exact read/write paths), renew and release at boundaries.

Input: reviewed preparation-country-registry/countries.json and its source
evidence. The source has 195 countries (193 members + two observers). Do not
change source files. Deliver 195 choice questions in ONE draft pack
prep-capitals-world, category География/Столицы; normal play already samples 20.
Keep published prep-capitals-1 unchanged. This is exact transcription, not a
licence to invent dates, historical anecdotes or new facts.

Ordinary rule: use the first recorded capital and stem `Какой город является
столицей государства «{name_ru}»?`. Country aliases NR use `Науру (Наоэро)`.
Special rules (do not flatten them):

| ISO | Stem qualification | Target |
| --- | --- | --- |
| BJ | конституционная столица Бенина | Porto-Novo |
| BO | конституционная столица Боливии | Sucre |
| NL | конституционная столица Нидерландов | Amsterdam |
| MY | столица Малайзии, в отличие от административного центра Путраджаи | Kuala Lumpur |
| SZ | административная столица Эсватини | Mbabane |
| ZA | административная столица ЮАР | Pretoria |
| LK | законодательная столица Шри-Ланки | Sri Jayewardenepura Kotte |
| NR | Науру не имеет официальной столицы. В каком округе находится правительство? | Yaren |
| ID | какой город указан как столица Индонезии в приведённом профиле UNdata, до поэтапного переноса столичных функций в Нусантару | Jakarta |
| PS | какой город Государство Палестина объявляет своей столицей (это не утверждение о международном признании её статуса) | East Jerusalem |
| PW | столица Палау, расположенная в штате Мелекеок | Ngerulmud |
| CH | какой город выполняет функцию федерального города — места федеральных властей Швейцарии | Bern |
| KI | какой населённый пункт Южной Таравы указан столицей Кирибати в профиле UNdata | Bairiki |

For special explanations include the actual registry role/note in natural short
Russian, not a copied English paragraph. PS preserves qualification; ID never
claims final transfer has occurred. CH distinguishes federal city from a legally
declared capital. KI does not call Bairiki a separate alternative to South Tarawa.
If source data cannot support a special mapping, STOP that record and report it.

Distractors: three distinct ordinary recorded capitals of OTHER countries,
prefer the same source region, otherwise nearest broader continent/remaining
pool. Exclude target country, all its recorded capital variants, special rows
above and any same city spelling. No speculative other cities. Balance correct
source positions 49/49/49/48 and SHUFFLE this multiset, not A B C D repeated.
Assign opaque stable IDs capw-<hash-derived opaque suffix>, no country code.

Ordinary explanation exact rule: identify correct city/country pair, then name
each distractor's actual country from the registry. Example construction:
`«{city}» — столица государства «{country}». Остальные варианты относятся к
другим странам: «{city1}» — «{country1}»; «{city2}» — «{country2}»;
«{city3}» — «{country3}». Запоминай именно пару страны и столицы.`
Prefer grammatical punctuation to filler; no minimum word count for this exact
source-backed format. Special explanations may extend this with the function
distinction, still only sourced facts. Estimated difficulty 4, not measured.

Files: candidate.md (ID/text/options, NO key/ISO hints), editorial-key.md
(ID/correct letter/text/ISO/source URL+date/distractor city-country pairs,
explanation), legacy.json, coverage.md ISO→ID and count, build_bank.py optional
stdlib mechanical generator with a runnable parity check. Use apply_patch for
scripts/files. Legacy root EXACT id/title/description/category/questions;
question EXACT id/type:"choice"/difficulty/text/options/correct_answer/explanation.
No canonical-only fields or unsupported properties. Validate against existing
quizzes/Preparation/prep_capitals_1.json and content/import.go, not a new schema.

Checks: 195 distinct ISO and question IDs, 4 unique options, targets/source
mapping correct, every wrong city belongs to its recorded other country,
candidate/key/legacy parity, non-cyclic 49/49/49/48 positions, no source/key in
candidate. Return READY and hashes, freeze and release. Independent blind solve
and factual review plus real quizctl import/validate remain mandatory; mechanical
checks are not ACCEPT. Do not stop after a pilot or publish the source bank.
