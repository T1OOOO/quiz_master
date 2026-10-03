# Independent capitals-world review — `review-countries-oct3`

Status: in progress — blind candidate pass complete; editorial key, legacy, registry evidence and generator have not yet been opened.

## Blind solve record

I read all 195 candidate prompts and selected the ordinary country–capital pair independently before accessing private editorial material. The ordinary pairs were high-confidence general-knowledge selections. The following source-sensitive prompts were explicitly selected and marked for later factual verification rather than inferred from option position:

| Candidate stable ID | Blind selection | Confidence / issue to verify |
|---|---|---|
| capw-c196802e48a8 | Porto-Novo | Benin constitutional function |
| capw-99654c5ca385 | Sucre | Bolivia constitutional function |
| capw-bd7de16c1e75 | Bern | Swiss federal-city wording |
| capw-2c7f4f0daa00 | Jakarta | dated UNdata/IKN transition qualifier |
| capw-2f9fffe9436e | Bairiki | South Tarawa profile wording |
| capw-90d24ab619e2 | Sri Jayewardenepura Kotte | Sri Lanka legislative function |
| capw-19110ba5826e | Kuala Lumpur | Malaysia/Putrajaya distinction |
| capw-e63b5ada2649 | Amsterdam | Netherlands constitutional function |
| capw-e0a1b4cf9b43 | Yaren | Nauru has no official capital |
| capw-d2c57322d420 | East Jerusalem | Palestinian declaration / recognition qualifier |
| capw-e7619898e7df | Ngerulmud | Palau city versus Melekeok State |
| capw-168034fcef88 | Mbabane | Eswatini administrative function |
| capw-70a5001ca0f3 | Pretoria | South Africa administrative function |

No candidate exposed an answer key, ISO code, source URL or explanation. Candidate hash will be recorded with the final re-review.

## Current factual and structural review

**Batch verdict: REVISE.** The country→target mapping is sound for all 195 records, but the 13 mandated special explanations do not preserve their source-supported function/caveat, and `build_bank.py` deterministically regenerates the same loss.

| Scope / IDs | Verdict | Evidence |
|---|---|---|
| Ordinary 182 country-capital records | ACCEPT | Registry comparison found 195 coverage mappings and zero target mismatches; every option city is a recorded registry capital, with four distinct choices. Candidate/key answer parity is 195/195. |
| BJ, BO, CH, ID, KI, LK, MY, NL, PS, PW, SZ, ZA | REVISE | Stems and targets are correct, but explanations flatten the required special function/caveat to “capital of country.” They must say, respectively, constitutional/federal-city/UNdata-before-transfer/South-Tarawa/legislative/administrative/declaration-not-recognition/state-of-Melekeok as applicable, using the registry role/note. |
| NR | ACCEPT | Stem and explanation correctly say that Nauru has no official capital and locate government in Yaren district. |
| Position and root shape | ACCEPT | 195 unique IDs/questions/key lines/coverage mappings; answer positions 49/49/49/48 and non-cyclic. Legacy records use supported `type:choice`, `text`, options, correct answer and explanation fields. |
| `build_bank.py` | REVISE | Its one generic explanation template is used for every special ISO except NR, so it loses mandated qualification facts on regeneration. It also does not assert candidate/key/coverage parity or exclude all special-row cities/target variants when choosing distractors. Do not run it as a preserving regeneration until fixed. |

The 13 required target mappings themselves match the accepted registry: BJ Porto-Novo, BO Sucre, CH Bern, ID Jakarta, KI Bairiki, LK Sri Jayewardenepura Kotte, MY Kuala Lumpur, NL Amsterdam, NR Yaren, PS East Jerusalem, PW Ngerulmud, SZ Mbabane and ZA Pretoria. No 195-item network refetch was needed or performed; this comparison used the accepted country-registry snapshot.

### Input fingerprints

- candidate: `d6733bd5c6610a089a9c341b756d960d6ba8268e1fd2fcf9b40bc89d00f7d253`
- editorial key: `70423c6eed2d6d88a6580ac771df812663dd091f1630c2f8b205af7b4a626e41`
- legacy: `d37e60677ac6b24669bb6cf6905cb824fe56bcdf0db2c3a19f5af4524b961725`
- coverage: `5f3015085fa029383841cffb1ab83ac1874cb4137e79d6d3535ffe39e2ff2235`
- generator: `828ca039207803b5edd6d7b0ca7bd8f7aab8c2bf444e285d95cb00cd0be24c0f`
- accepted registry `countries.json`: `78b1bb2d9fbfdb35033022dbdc94c34a89ad472a6cce835c5dd1ec2932f14b04`

No source, draft, generator or production file was modified. This review does not claim import, publication or acceptance.

## Final frozen correction re-review

**Verdict: ACCEPT for the 195-question draft review.** This supersedes the earlier special-explanation/generator REVISE finding; it is not an import or publication acceptance.

- All 13 special explanations now preserve the required natural, source-backed distinction: constitutional BJ/BO/NL; federal-city CH; UNdata-before-transition ID; South-Tarawa KI; legislative LK; Kuala Lumpur versus administrative Putrajaya; no-official-capital NR; declared-but-not-recognition PS; Melekeok State PW; and administrative SZ/ZA.
- Special-country source candidates are excluded from distractor selection. The final special distractors are ordinary other-country capitals, and no special target or a target-country variant is used as a wrong option.
- Recheck counts: 195 questions and unique IDs, 195 coverage mappings; correct positions 49/49/49/48. Correct-text/option parity across candidate, key and legacy remains aligned after the shuffle. The final index sequence is non-cyclic.
- Generator review: `SPECIAL_EXPLANATIONS` covers every special except intentionally separate NR; its outputs retain each qualification. It excludes `SPECIAL_ISOS` as distractor sources and asserts record/ID/options/position/parity invariants. It writes only its own capitals-world subtree when run; I did not regenerate it.

Final frozen input hashes:

- candidate: `9570d58bc247ce96879acce5125f8153c4b1f8f9ab8f6db94220d92600189592`
- editorial key: `524e87c4a38f9026df382a16d09171462c8c53a08ae2f00e5d8e4b159a23eacd`
- legacy: `3136f7867a399ee55b3f39cb9e35f7c20616fd55a4f637c1dcd7e255076548a5`
- coverage: `5f3015085fa029383841cffb1ab83ac1874cb4137e79d6d3535ffe39e2ff2235`
- generator: `6d2c8c7e1cfb670231918462ee834ea3ceeef1d5cfc0abe035ba3593a2653bbe`

## Final frozen Russian-display re-review — ACCEPT (2026-10-03)

This independently checks the last frozen regeneration, rather than carrying forward the earlier verdict.

- All 195 candidate, key and legacy records have identical ordered IDs, texts and options; key correct letter/text and the full explanation exactly match legacy. Coverage has 195 unique ISO2-to-ID rows.
- All answers semantically resolve to the target country's reviewed capital record; every distractor resolves to another country, and none comes from a special-case country. Every displayed option is the registry `name_ru` form: no Latin-script city fallback remains.
- Answer positions are A/B/C/D = 49/49/49/48. All 195 key source URLs and dates exactly match their registry capital records.
- The 15 special records are present and factually qualified: BJ/BO/NL constitutional capitals; MY/SZ/ZA administrative distinctions; LK legislative capital; NR no official capital/Yaren government district; ID UNdata/Jakarta transition wording; PS declared-capital non-recognition qualifier; PW/Melekeok; CH federal-city function; KI South Tarawa locality; IL declared-capital non-recognition qualifier; and VA's UNdata Holy See/two-observer-state distinction. NR now displays `Ярен`; no English `Yaren` remains in an option or explanation.
- Read-only reconstruction from `build_bank.py`, country registry and frozen outputs produced zero ID, correct-answer, option, special-distractor, source/date or published-parity mismatches. The generator's fail-closed display map accepts only reviewed Russian capital labels.

| Final input | SHA-256 |
|---|---|
| build_bank.py | `17162e822de6b4b4abf6a92df2103cd440c5611716f3394fcb4f88a9fd9e13fb` |
| candidate.md | `34a663b28359358b702d4c92f35a378d0efeb1a3e7e6ed9696cc0499a16315fe` |
| editorial-key.md | `a2fb66ab79a62eaed4514393229bed9b1ba18e88166c3a870ed12954e95c650a` |
| legacy.json | `7dcb15b820f18649a5d8fbc7adebac18fdff1dfda49fba70fe8d0e15fa891ccd` |
| coverage.md | `5f3015085fa029383841cffb1ab83ac1874cb4137e79d6d3535ffe39e2ff2235` |
