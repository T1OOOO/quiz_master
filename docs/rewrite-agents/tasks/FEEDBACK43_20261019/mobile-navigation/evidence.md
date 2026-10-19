# Feedback 43 mobile navigation QA evidence

Date: 2026-10-19
Source supplied for this check: `0c409557`
Route: `http://127.0.0.1:8791/#/quiz/gastronomy-traditions-and-etiquette`
Browser session: `feedback43_nav`
Viewport: 361 x 738 CSS pixels

## Result

The quiz cannot open in this compiled build, so question-navigation behavior
cannot be exercised in a real attempt.  The visible Russian error is
`Не удалось загрузить викторины` ("Could not load quizzes").

`01-start.png` and `02-retry.png` were visually inspected at the requested
phone viewport. They show the same error state and the Retry control.

## Reproduction and network evidence

1. Open the supplied route in a fresh `feedback43_nav` browser session.
2. Wait three seconds. The route renders the error state.
3. Press `Повторить` once. The state remains the same.

The first load made one guest bootstrap POST and one quiz-specific catalog
GET. The guest bootstrap's browser preflight failed:

| Request | Observed result |
| --- | --- |
| `POST https://quiz.kotopedia.org/v1/guests` | initiated |
| `GET https://quiz.kotopedia.org/v1/catalog?quiz_id=gastronomy-traditions-and-etiquette` | initiated |
| `OPTIONS https://quiz.kotopedia.org/v1/guests` | HTTP 405 |

One Retry repeated the POST, the quiz-specific catalog GET, and the failing
OPTIONS request. The local Flutter bootstrap and catalog/food assets loaded
successfully. This is a runtime API/CORS blocker, rather than a phone layout
failure.

## Unexecuted acceptance cases

No attempt was created after the failed guest bootstrap, so the following
real-browser checks remain blocked: arbitrary question jump, pending/manual
uncertain state, answered/unanswered marks, read-only revisits, back-viewing
an answer, two-second auto-advance and pause, and last-question review/finish.

## Same-origin production follow-up

The published same-origin build was checked at
`https://quiz.kotopedia.org/#/quiz/gastronomy-traditions-and-etiquette` in the
same 361 x 738 session. The preview CORS result above is local-preview-only:
production guest bootstrap returned 201, the quiz-specific catalog returned
200, and attempt creation returned 201.

Visually inspected screenshots:

- `04-arbitrary-question.png`: jumping from question 1 to question 4 changes
  the prompt and selected navigator chip.
- `05-uncertain-return.png`: the manual `Не уверен` mark survives navigation
  away from question 4; its navigator chip carries the bookmark mark.
- `06-answer-feedback.png`: an incorrect answer reveals the authoritative
  outcome and explanation.
- `07-readonly-revisit.png`: revisiting that answered question shows the
  chosen answer, correct answer and explanation in disabled/read-only form.
- `13-pause-rapid.png`: a correct answer was paused rapidly, then remained on
  the same question and modal for more than three seconds. The action changes
  to `Продолжить автоматически`.
- `14-resumed-autoadvance.png`: resuming then advances to the next question
  after the two-second interval and closes the modal.
- `17-greek-002-reveal.png`: a non-target, shuffled Greek question about the
  Lernaean Hydra was revealed. It is retained only as navigation evidence;
  navigator position does not equal canonical question ID.
- `42-greek-position20.png` shows the actual canonical `greek-002` prompt
  about Poseidon and Sounion after navigation through the shuffled list.
  `43-greek-002-target-reveal.png` shows its wrong-answer reveal with the
  `Узнать больше` control. `44-greek-002-reader.png` shows the linked reader
  opening with its Sounion/Poseidon article heading and first section.

`09-paused-autoadvance.png` is retained as diagnostic evidence only. It was
taken after a late pause click during the timer's closing transition, so it
does not reproduce as a pause failure; the controlled rapid-pause run above
is the result.

The initial navigation check did not complete all 33 production questions,
and this single-choice flow offers no unsubmitted answer state to exercise.
No credentials, answer keys, or private identifiers are recorded.

## Completion-path follow-up

A separately controlled same-origin browser run answered all 33 questions.
Before finishing, it navigated back to question 1 and showed the answered
review state (`47-finish-current.png`). The visible `Завершить викторину`
control then completed the attempt. `48-production-finished-result.png` shows
the resulting `Счёт: 5`; the independent count of correct feedback dialogs was
also 5. Machine-readable, non-sensitive evidence is in
`production-finish.json`.
