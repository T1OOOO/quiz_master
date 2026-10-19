# Local mobile acceptance evidence — anatomy and study

**When:** 2026-10-19  
**Surface:** local static preview `http://127.0.0.1:8791` in the owned
`feedback43_nav` browser session.  The page was loaded from build `badd3338`;
the release owner confirmed that the application `lib/assets` tree is identical
to final candidate `8954b166` / `d74cf16d35cfa1cd7a9894b03ad4884bd5d12a50`.
This is local content screening only, not evidence of publication.

## Passed local checks

* At **361 × 738**, the organ atlas exposes the newly added `Гиппокамп` and
  `Лобная доля` through its search field (`03-hippocampus-search.png`,
  `09-frontal-search.png`).
* The Hippocampus detail drawer gives Russian position/function text and two
  Russian-labelled source controls: OpenStax anatomy/central nervous system and
  FIPAT anatomical terminology (`08-hippocampus-detail.png`).  Semantics also
  exposes both full source captions; the compact drawer body remains readable at
  **320 × 568** (`13-hippocampus-detail-320.png`).
* Latin substring search is usable: `cor` includes `Сердце`, and `encephalon`
  includes `Головной мозг` and `Средний мозг`
  (`10-latin-cor-search.png`, `11-latin-encephalon-search.png`).
* At **320 × 568**, `Гиппокамп` search returns the expected Hippocampus and
  amygdala choices; zoom controls remain exposed (`12-hippocampus-320.png`).
* A new Hippocampus fact-practice card was answered deliberately wrong, then
  retried with the verified correct response.  The completed retry reported
  `Верных ответов: 1 из 1` (`05-hippocampus-wrong.png`,
  `06-hippocampus-retry.png`, `07-hippocampus-score.png`).
* The `Природа: связи, которые работают незаметно` guide shows one explicit
  `Самопроверка · 20 вопросов` action at **320 × 568**.  Its visible article
  list is the seven guide articles, with no animal-quiz destination presented
  (`15-nature-study-20-self-check.png`).

## Production same-origin QA

**Surface:** `https://quiz.kotopedia.org`, hard-reloaded in the same owned
session after the release owner's `books-8954b166` ready signal.

The catalog card for `Литература: послевоенная и современная — авторы` advertises
`Вопросов: 42`; the local compiled catalog likewise declares 22 easy and 20
medium questions.  Both production launches pass when the horizontal navigator
is scrolled to its end:

* With `Средне` selected, the final visible positions are `12`–`20`, including
  `20` (`21-books-medium-20-nav-end-production.png`).
* With no difficulty filter, the final visible positions are `34`–`42`,
  including `42` (`20-books-ordinary-42-nav-end-production.png`).

The initial DOM/semantics snapshot exposed only positions `1`–`11`; that is the
visible portion of the horizontal `ListView`, not the snapshot length.  The
subsequent end-scroll supersedes that preliminary observation.  No answer was
selected or submitted.

## Screenshots

`01`–`15` in this directory are the captured browser states referenced above.
