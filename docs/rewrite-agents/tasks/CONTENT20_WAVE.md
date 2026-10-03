# CONTENT20 / quiz_master-8k1.16

Workspace C:/ap/quiz_master. Base8c90873d6328c65cb2ca5cd0484c2a7c1e85d13e, live117 packs/3858questions. Protected dirty .beads/issues.jsonl, PROJECT_OVERVIEW_RU.md, preparation-flags-bank/batch80-checkpoint.md must not enter commits. Lead owns integration, Beads, git and deployment. User requests at least20 different new quizzes; target20 banks of20 distinct questions (400), not20 agents. Author profile qm_quiz_writer/Terra medium; independent qm_fact_checker/Terra high. No child agents, builds, browser launches, Docker/Postgres/Actions or publication by either worker.

Read qm-work-packet, qm-quiz-writing, local AGENTS and hub protocol. Ownership author ONLY docs/rewrite-agents/content20/**; reviewer ONLY assigned content20 review report, never writer files. You are not alone; preserve all other edits. Reserve actual existing path via own host session before work, interactive256MB/300s, shared read vs exclusive write correctly. Renew; release before review/waits. Queued grants no authority. Never restart broker or stop foreign processes. Checkpoint and wait capacity rather than allocating more agents. TTL is renewable: it is not a lifetime limit for400 questions.

Topics/slugs (all20questions). Use existing category roots to avoid expanding root layout:

1. paintings — История/Искусство/Картины
2. architecture — История/Искусство/Архитектура
3. sculpture — История/Искусство/Скульптура
4. space-missions — Природа/Космос/Исследования
5. solar-system — Природа/Космос/Солнечная система
6. chemistry — Природа/Наука/Химия
7. everyday-physics — Природа/Наука/Физика
8. biology — Природа/Наука/Биология
9. animal-world — Природа/Животные
10. landforms — География/Горы и воды
11. world-monuments — География/Памятники
12. inventions — История/Изобретения
13. ancient-world — История/Древний мир
14. middle-ages — История/Средние века
15. modern-events — История/Новое время
16. russian-book-plots — Литература/Герои и сюжеты/Русская
17. world-book-plots — Литература/Герои и сюжеты/Мировая
18. film-characters — Кино/Персонажи
19. egyptian-mythology — Мифология/Египет
20. roman-mythology — Мифология/Рим

Audience adult Russian quiz players. Interesting original questions, mostly medium, some accessible and harder; mix recall/comparison/application. Avoid repeating existing knowledge points: inspect relevant source quizzes by targeted search, not the entire repo. Existing source-backed cultures already cover author-book, film-actor/director, composers, Greek/Norse/folklore and selected history. Plot/character/event questions must genuinely teach another fact, not reword a known pair.

First save10-question pilot from paintings with blind candidate and separate key/source records, then STOP writes/release and notify lead for independent acceptance. After acceptedpilot complete20, then work in frozen batches2banks/40, checkpoint EACH completed20pack. Notify exactpaths/SHA. Continue remaining queue only after clear lead handoff; do not claim400 from partial receipts. Other topics may be replaced only with lead approval if unavoidable duplication or missing primary references.

Each pack prep-wave20-<slug>, question IDs wave20-<slug>-001..020, legacy schema {id,title,description,category,questions:[{id,type:"choice",text,options:[4strings],correct_answer:0..3,explanation}]}. No difficulty field unless valid source contract; estimated difficulty in private editorial record. Balance five positions each, noncyclic, maxrun2. Options parallel, plausible, only one best answer. Explanation20–45Russianwords explains fact and useful misconception, not merely answer repetition. Avoid subjective rankings/unsupported absolutes/current records. Exact version/year/tradition qualifiers when necessary. Public titles/descriptions must not say draft/pilot.

Private record perquestion: intended answer, source URL/access date, actual received evidence, estimated difficulty and concise rationale for all3distractors. Prefer original work and primary museums/archives/publishers/official science references; generated knowledge alone is not evidence, no invented citations. Source excerpts <=25words perwebsource copyright budget; paraphrase evidence primarily. Keep blind candidate free of answer/explanation/source clues. Writer creates simple deterministic renderer and real readonly --check if useful; reuse local patterns, no dependencies/frameworks. Use apply_patch for authored files; no shell write tricks. Reviewer solves blind first, then key and actual sources, checks every item and duplication, returns accept/revise/reject with precise fixes. Re-review only changed scope.

Lead alone imports accepted frozenpacks via quizctl, maintains normalized sourceSHA (CRLF/CR->LF), private answer mappings/public boundary, catalog counts, tests and deployment. Readiness is not publication. All400 require independent ACCEPT before claiming complete.
