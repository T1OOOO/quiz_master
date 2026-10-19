# Public release70 mobile QA

- **Target:** `https://quiz.kotopedia.org`
- **Evidence of deployed build:** `/version.json` returned `quiz-2026.10.19-minimum20-7f8344d6`, commit `7f8344d638e2079d3b47b74972754a3425419791`, `packs: 105`, `questions: 4520`, `quizipedia_sections: 13`.
- **Device basis:** Chrome emulation only, 390×844 and 360×800 CSS pixels, session `feedback43_nav`; no physical-device claim.

## Observed public behaviour

- `public-library-390.png`: Russian catalog shows **105 quizzes · 4520 questions** with readable category cards, difficulty chips and bottom navigation at 390px.
- `public-search-cheese-390.png` and `public-search-cheese-360.png`: `сыр` finds the merged playable pack **«Продукты животного происхождения: сыры, мясо и рыба»** (32 questions). Its card remains legible and actionable at both widths.
- `public-alias-lotr-390.png`: legacy `/quiz/lotr` opens a playable canonical derived-pool UI (**«Средиземье: книги и фильмы»**) instead of an invalid-response screen.
- `public-alias-selected.png`: one intentionally wrong ordinary-practice answer returned authoritative feedback: **«Неверно»**, correct option **«Гвайхир»**, explanation, and a Continue control. This confirms the public answer/check/feedback path for the alias route.
- `public-new20-games-390.png`: imported 20-question **«Игровые миры»** bank opened successfully and showed a four-option question UI without overflow.

No clipped controls, horizontal overflow, or runtime error was observed on the captured public screens. The sampled LOTR feedback did not offer an article-link action, so no article reader was opened. This bounded run did not bulk-answer quizzes or assess all 13 Quizipedia sections individually.
