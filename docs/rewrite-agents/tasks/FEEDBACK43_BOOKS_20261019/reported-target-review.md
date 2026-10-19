# Independent Reported-Target Recheck — Ordinals `16`, `29`, `32`

**Decision:** **`ACCEPT REPORTED TARGETS`** for ordinals **`16`, `29`, `32`**.  
With concrete reported-target resolution applied and broader per-option reference expansion explicitly tracked under open **Bead `quiz_master-yp19`** (consistent with **Bead `3qx`** incremental batch policy), `16, 29, 32` move to **`SAFE_TO_RESOLVE`**.

* **Updated Batch Totals (43 reports):**
  * **`SAFE_TO_RESOLVE` (39 ordinals):** `1, 2, 3, 4, 5, 7, 9, 10, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 24, 25, 27, 28, 29, 31, 32, 33, 36, 40, 41, 42, 45, 48, 51, 56, 57, 63, 64, 65, 66`
  * **`KEEP_OPEN` (4 ordinals):** `6, 8, 11, 26`

---

## Target-by-Target Verification (`361×738` Chrome Viewport, Build `5df1d538`)

1. **Ordinal `16` (`prep-ballet` / `music-oct3-040`, rev `fb5f32c7...`) — `ACCEPT REPORTED TARGET`**
   * **Evidence:** [reported-option-articles.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/reported-option-articles.json), [evidence.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/evidence.md), [02-ballet-wrong-reveal.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/02-ballet-wrong-reveal.png), [03-ballet-article-top.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/03-ballet-article-top.png), [03-ballet-article-top.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/03-ballet-article-top.json).
   * **Verification:** Plain answer reveal already explains the answer, and `Узнать больше` opens `«Чудесный мандарин»: пантомима Бартока, а не балет Стравинского`, covering all 4 composers (`Бела Барток`, `Игорь Стравинский`, `Арам Хачатурян`, `Лео Делиб`), a listening guide (`Как слушать`), and 4 source buttons including the primary publisher's authorized audio clip (`Boosey & Hawkes: authorised Miraculous Mandarin audio sample`). Because the user phrased YouTube as desirable (`"желательно..."`), an authorized publisher audio sample link satisfies the concrete listening request. *(Minor UX note: on `361×738`, the 10-line plain explanation in [02-ballet-wrong-reveal.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/02-ballet-wrong-reveal.png) places `Узнать больше` below the initial scroll fold inside the reveal dialog before scrolling.)*

2. **Ordinal `29` (`prep-greek-mythology` / `greek-002`, rev `038a7a47...`) — `ACCEPT REPORTED TARGET`**
   * **Evidence:** [reported-option-articles.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/reported-option-articles.json), [43-greek-002-target-reveal.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_20261019/mobile-navigation/43-greek-002-target-reveal.png), [44-greek-002-reader.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_20261019/mobile-navigation/44-greek-002-reader.png).
   * **Verification:** The linked article (`Сунион: как различить Посейдона и три правдоподобных отвлекающих варианта`) provides detailed, sourced facts distinguishing the correct answer (`Посейдон` — sea, trident, Cape Sounion temple) and each of the 3 wrong Olympians (`Гефест`, `Арес`, `Дионис`) with 5 museum/archaeological references.

3. **Ordinal `32` (`dogs-biology-anatomy-part-2` / `q-dog-myth-29`, rev `c39f6189...`) — `ACCEPT REPORTED TARGET`**
   * **Evidence:** [reported-option-articles.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/reported-option-articles.json), [evidence.json](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/evidence.json), [09-dogs-exact-wrong-reveal.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/09-dogs-exact-wrong-reveal.png), [10-dogs-exact-article-top.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/10-dogs-exact-article-top.png), [11-dogs-exact-article-later.png](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/11-dogs-exact-article-later.png).
   * **Verification:** At canonical target position 9 (`Сколько голов было у Цербера, стража подземного мира в греческой мифологии?`), `Узнать больше` opens `Почему в викторине у Цербера три головы`, addressing `три` (Apollodorus 2.5.12), explicitly rejecting all 5 wrong option numbers (`одна`, `две`, `семь`, `девять`, `пять`), noting Hesiod's 50-headed *Theogony* caveat (`пятьдесят` absent from options), and linking both primary sources.

---

## Required Guardrail for Resolution

* Resolve **`16`, `29`, `32`** strictly as completion of the **concrete reported question features** (on top of existing plain explanations across the bank and 305 published mini-articles).
* Keep **Bead `quiz_master-yp19`** open for batch-by-batch per-option reference expansion across remaining questions (including the near-duplicate non-target Cerberus question observed at position 11 in [evidence.md](file:///E:/Projects/quiz_master/docs/rewrite-agents/tasks/FEEDBACK43_BOOKS_20261019/mobile-reference/evidence.md)).
