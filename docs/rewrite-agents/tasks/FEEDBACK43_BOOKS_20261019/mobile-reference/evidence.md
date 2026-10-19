# FEEDBACK43_BOOKS mobile reference QA

Date: 2026-10-19
Target: `https://quiz.kotopedia.org` production, observed build `5df` context
Session: `feedback43_reference`
Viewport: 361 x 738 CSS px (browser viewport; no physical-device claim)

## Ballet target — PASS

- Route: `/#/quiz/prep-ballet`
- Exact stem observed at shuffled navigator position 5: `Кто написал музыку к сценической пантомиме «Чудесный мандарин»?`
- Visible options included `Арам Хачатурян`, `Бела Барток`, `Игорь Стравинский`, `Лео Делиб`.
- Wrong option `Арам Хачатурян` was selected. Reveal showed `Правильный ответ Бела Барток` and a relevant explanation.
- Reveal exposed `Узнать больше`; article opened successfully.
- Article heading: `«Чудесный мандарин»: пантомима Бартока, а не балет Стравинского`.
- Visible article text included the answer/genre explanation, the listening section, and source labels `Boosey & Hawkes: The Miraculous Mandarin` and `Boosey & Hawkes: authorised Miraculous Mandarin audio sample`. DOM inspection exposed no href for those Flutter-rendered source buttons, so no URL is asserted.
- Evidence: `01-ballet-target-before.png`, `02-ballet-wrong-reveal.png`, `03-ballet-article-top.png`, with matching JSON snapshots.

## Cerberus canonical target — PASS

- Route: `/#/quiz/dogs-biology-anatomy-part-2`
- Exact stem observed at shuffled navigator position 9: `Сколько голов было у Цербера, стража подземного мира в греческой мифологии?`
- Visible options were `Одна`, `Пять`, `Три`, `Две`, `Девять`, `Семь`.
- Wrong option `Одна` was selected. Reveal showed `Правильный ответ Три` and exposed `Узнать больше`.
- Article opened successfully. It listed all five incorrect option numbers and explained the Apollodorus three-headed version versus Hesiod's fifty-headed caveat; it also stated that “пятьдесят” is absent from the current options.
- Evidence: `08-dogs-exact-target-before.png`, `09-dogs-exact-wrong-reveal.png`, `10-dogs-exact-article-top.png`, `11-dogs-exact-article-later.png`, with matching JSON snapshots.

## Non-target Cerberus question retained as raw evidence

- The earlier stem at shuffled position 11, `Сколько голов было у Цербера — стража Аида, согласно наиболее распространенным греческим мифам?`, is a separate non-target question. Its reveal had no article control in this run; this is retained as raw evidence only and is excluded from canonical acceptance.
- Evidence: `05-dogs-target-before.png`, `06-dogs-wrong-reveal.png`, `07-dogs-revisit.json`.

## Scope and risks

Read-only browser QA only; no feedback submission, auth, production edits, commits, or publication actions. One preliminary exploratory pass used an ambiguous numeric child ref and marked a non-target item answered; that attempt was discarded by closing the browser and restarting the same isolated session before the recorded dogs run. The exact canonical target was then reached by full stem text at position 9; only that target was answered.
