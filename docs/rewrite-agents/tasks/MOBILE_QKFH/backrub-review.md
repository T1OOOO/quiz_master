# Independent BackRub historical-fact review — MOBILE_QKFH

**Scope:** read-only review of the Google `former_names` record and the
proposed separate fact-bank treatment. No production asset or generator was
changed.

**Source checked:** [Google, “Our story”](https://about.google/company-info/our-story/),
accessed 2026-10-19. Its account says that Page and Brin built a link-based
search engine named Backrub, that Backrub was soon renamed Google, and that
Google Inc. was officially born only after the August 1998 investment.

**Verdict:** **ACCEPT, with the qualification below.** BackRub may be used in a
new, source-bound historical fact bank as the name of a pre-company search
project. It must not be presented as a former legal or corporate name of Google
or Google Inc.

## Exact permitted Russian wording

- Category/field: `Исследовательский проект до Гугл`
- Name/value: `BackRub`
- Source note: `Пейдж и Брин создали поисковую систему BackRub; вскоре её
  переименовали в Гугл.`
- Fair question: `Как называлась поисковая система Пейджа и Брина, вскоре
  переименованная в Гугл?` Correct answer: `BackRub`.

The category distinguishes the project from the later company. Keep `BackRub`
as the source's proper project name; it is not a claim that `BackRub` was a
legal company name.

## Required limitations

1. Leave the existing `brands.json` entry's `quiz_enabled: false` unchanged.
   The historical item must be a separately authored, qualified fact-bank
   record; do not enable it through the former-name generator.
2. Do not use a stem such as “former name of Google,” “former name of Google
   Inc.,” or “what was Google called before 1998.” Those wordings conflate the
   student-built search engine with the incorporated company.
3. Do not create questions from `from_year: 1996` or `to_year: 1997` on the
   strength of this source. Google’s official account provides “the following
   year” and “soon after,” not those exact BackRub start/end dates. It does
   support the separate statement that Google Inc. was officially born in
   August 1998.
4. Do not change the existing former-name data, old generator, or brand JSON in
   order to add this fact.

## Context from review blocker 4.2

`code-review-1.md` correctly identifies that the existing brand-fact extractor
must honor `former_names[].quiz_enabled`; this review does not relax that
requirement. The qualified standalone fact is appropriate precisely because it
avoids exposing the disabled former-name record as a company-renaming question.

**Fresh evidence:** `brands.json` currently retains Google’s BackRub record
with `quiz_enabled: false`. The production source URL and the review source
both lead to Google’s official company-history page. No tests, builds, UI
checks, or release actions were run.