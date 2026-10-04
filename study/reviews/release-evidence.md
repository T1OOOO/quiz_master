# Study release evidence — 2026-10-04

Validated scope: four accepted introductory modules, 80 source-backed local unranked questions and four real article illustrations. Separate question artwork and the future 58-chapter roadmap are not shipped as completed work.

Owner checks: Python builder parity PASS; seven reader regressions PASS both normally and under `-O`. Final Flutter full suite: **69 tests PASS**, including 14 study cases. Analyzer: **No issues found**. Independent source/content and code-quality/requirements reviews APPROVE, with frozen hashes in the review reports.

Actual desktop browser checks on the release build found an incorrect library image fallback and light headline on parchment; dedicated hero assets and explicit warm dark ink were corrected with failing-before/passing-after regressions. Final release build PASS (50 seconds). Isolated local browser session: cards open the article, practice starts with 20 questions, wrong answer displays a centered explanation/cited source, Enter on focused Continue advances. Desktop 1262×568 and phone 390×844 screenshots were inspected for readable text, illustrations and horizontal fit (library/article/question/feedback). Evidence PNGs are generated in ignored `study/site/`, not a production screenshot or complete accessibility audit.

No Android device acceptance, complete accessibility audit, local Docker/PostgreSQL or GitHub Actions claim is made. The existing server/API binary is unchanged and its SHA256 was independently checked against the running container: `47353a2844f12e3749da84cd13942d98dfb1fbe478d341f8370106ef0b026764`.
