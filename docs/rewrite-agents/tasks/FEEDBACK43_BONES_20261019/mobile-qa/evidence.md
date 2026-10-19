# Local mobile QA — bones and study glossary

**Build checked:** local preview `http://127.0.0.1:8791`; before testing,
`main.dart.js` contained `quiz-2026.10.19-bones-36e0b68c`.  This is local
browser-emulation evidence, not a publication result. Physical-phone testing
was unavailable.

## Passed at 361 × 738

* The organ atlas semantic list includes the new individual bones. Search found
  `Левая пястная кость I`, `Правая пястная кость V`, and `Копчик`
  (`02-left-metacarpal-search-361.png`,
  `03-right-metacarpal-coccyx-search-361.png`).
* Combining `Верхняя конечность` with kind `Кость` left individual upper-limb
  bones, including metacarpals, in the result list
  (`04-bone-upper-limb-filters-361.png`).
* Opening `Левая пястная кость II` exposes the Russian source caption
  `Источник: Издатель «ОпенСтакс», 8.2: кости свободной верхней конечности`
  (`05-metacarpal-detail-source-361.png`).
* The selected single bone's `Тренировка` falls back to fact practice, offering
  its fact/function/type/location/body-region/system cards. Selecting its fact
  opened exactly four answer choices (`06-bone-practice-four-options-361.png`).
  A deliberately wrong choice revealed the source and disabled answers
  (`07-bone-practice-wrong-reveal-361.png`); retrying the error with the correct
  choice ended at `Верных ответов: 1 из 1`
  (`08-bone-practice-retry-score-361.png`).
* Both map and evolution article tables of contents expose `Слова простыми
  словами` and `Самопроверка · 20 вопросов` (`09-maps-study-toc-361.png`,
  `11-evolution-study-toc-361.png`). The map glossary is readable in-place
  (`10-maps-glossary-361.png`), as is the evolution content at the tested width
  (`12-evolution-glossary-361.png`).

## Checked at 320 × 568

* The anatomy entry is reachable after a normal vertical swipe
  (`14-anatomy-entry-320.png`), and a Coccyx search is readable with the
  selected result and map area (`15-coccyx-320.png`).
* Screenshot inspection found no visible horizontal clipping or automatic zoom;
  the browser reported `visualViewport.scale: 1`. The DOM body width (341 px)
  includes Flutter semantics host width, so it was not used as an overflow
  verdict. The visible header uses expected ellipsis for the long atlas title.
* Evolution content was also captured at 320 × 568
  (`13-evolution-glossary-320.png`).

No ordinary quiz was started and no server answer was submitted. Navigator
counts were not inferred from the mounted horizontal DOM.

## Published production retest

**Surface:** `https://quiz.kotopedia.org` at 361 × 738, hard-reloaded in the
owned browser session after publication. The fetched `main.dart.js` contains
`quiz-2026.10.19-bones-36e0b68c`. The live atlas loaded the individual bone
asset into the application: searching `Правая пястная кость V` returned the
single result (`18-public-bone-search-361.png`) and its detail exposes the same
Russian OpenStax source caption (`19-public-bone-source-361.png`).

The selected public bone's fact-practice fallback was deliberately answered
wrong, revealed its source, retried, and completed at `Верных ответов: 1 из 1`
(`20-public-bone-retry-score-361.png`). The live evolution article also exposes
both `Слова простыми словами` and `Самопроверка · 20 вопросов`
(`21-public-evolution-toc-361.png`). No ordinary-quiz or server answer was
sent. Physical-device coverage remains unavailable; this is Chrome emulation.
