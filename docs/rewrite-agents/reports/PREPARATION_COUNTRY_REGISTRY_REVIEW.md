# Independent country-registry audit — `review-countries-oct3`

**Base inspected:** `faf55b7`  
**Scope:** `docs/rewrite-agents/preparation-country-registry/` only; independent draft/evidence review, not publication or quiz acceptance.  
**Verdict:** **REVISE** — the set and its internal evidence structure are sound, but several identity/label and media-ledger statements require correction before a registry can be relied on.

## Scoped verdicts

| Scope | Verdict | Evidence / required outcome |
| --- | --- | --- |
| UN identity set | **ACCEPT** | Structural set is correct: 195 unique ISO-2 and ISO-3 values, ISO-2 sorted, 193 `member` and 2 `observer`. The current official M49 table explicitly records NR/NRU/520 as **Naoero** in English and **Наоэро** in Russian; those registry fields are correct and must not be normalized to the common alias Nauru. |
| Capital rows and special functions | **REVISE** | All 195 registry ISO-2 records have a profile-evidence record and the current literal profile-capital values match (apart from the documented Samoa profile failure). Correct the concrete rows below; preserve the stated special-capital qualifications and the Palestine disclaimer. |
| Russian display labels | **REVISE** | I read all **203** capital-label occurrences (195 country rows) against their Latin values. The machine-rendered-label warning is real: at least the five factual/editing corrections below are mandatory. Do not describe the remaining unchecked-by-editor machine output as source-authoritative. |
| Profile and source evidence | **ACCEPT WITH LIMIT** | `profile-row-evidence.json` contains 195 ISO-matched records. The draft records the one known UNdata failure correctly: `https://data.un.org/legacy/en/iso/WS.html` and its linked original flag return 404. The independently accessible Samoa Tourism Authority fallback explicitly calls Apia the capital. This demonstrates a valid fallback for WS, but is not proof that every historical UNdata page is currently available. |
| Flag download integrity | **ACCEPT WITH LIMIT** | Flagpedia ledger has 195 ISO-matched rows; all 195 have `fetched` status and a lowercase 64-hex SHA-256, with 285,680 total bytes. These are provider-download integrity facts, not proof of UN-current flags or of artwork-reuse rights. |
| Media attribution / current variants | **REVISE** | Flagpedia’s retrieved API page says “we appreciate backlink to https://flagpedia.net”; it does **not** say a backlink is mandatory. Replace every ledger statement that says required attribution/backlink with neutral source attribution and the provider’s actual, appreciated wording. Do not make a blanket public-domain or artwork-reuse claim. |

## Required record corrections

1. **PW — capital:** replace `Melekeok / Мелекеок` as the capital city with **`Ngerulmud / Нгерулмуд`**, and add “in Melekeok State, Babeldaob” as context if desired. Palau’s official PIF site calls Ngerulmud the capital; the Palau Judiciary separately describes the capital moving to Ngerulmud in Melekeok State. The current UNdata profile value `Melekeok` therefore cannot be treated as the final city-level answer.
2. **MV — Russian label:** `Male / Мужской` must be **`Мале`**. The present Russian word is an adjective generated from “male,” not the city.
3. **KM — Russian label:** `Moroni / Мороний` must be **`Морони`**.
4. **MM — Russian label:** use a fixed editorial Russian form for `Nay Pyi Taw`, e.g. **`Нейпьидо`**, rather than machine-rendered `Нэй Пьи Тау`.
5. **LK — Russian label:** normalize `Sri Jayewardenepura Kotte` to **`Шри-Джаяварденепура-Котте`**. Preserve the role `legislative`; do not collapse it into the separate Colombo capital claim.
6. **MY — Russian label:** normalize `Putrajaya` to **`Путраджая`** (not `Путраджайя`) and preserve the `administrative` role; Kuala Lumpur remains the capital in the UNdata profile.
7. **MD — Russian label (editorial normalization):** use **`Кишинёв`** rather than `Кишинев` if the project’s Russian style permits `ё`; document the style choice consistently rather than presenting machine output as a source transcription.
8. **PS — qualified capital claim:** retain the exact UNdata evidence caveat for East Jerusalem (designation/data supplied by the State of Palestine and the UN position on Jerusalem is governed by the cited resolutions). The registry’s bare `capital` role and generic note do not by themselves preserve that qualification.
9. **ID — time-sensitive capital:** Jakarta presently matches the legacy UNdata profile, but add a current-status note and a dated source. The Nusantara Authority says transfer of national-capital status requires implementing regulation; the relocation is staged. Do not silently present Jakarta/Nusantara as an uncomplicated permanent one-line fact.

## Special-capital audit

The literal evidence rows and intended functional distinctions are internally aligned and should be retained after the corrections above:

- **MY:** Kuala Lumpur `capital`; Putrajaya `administrative`.
- **SZ:** Mbabane `administrative`; Lobamba `legislative`.
- **BJ:** Porto-Novo `constitutional`; Cotonou `economic` — use these exact source-supported terms, not an unsupported “sole government seat” claim.
- **ID:** Jakarta remains the current row; transition to Nusantara needs the dated qualifier above.
- **NR:** Yaren `de_facto`, not an official capital. Keep the M49 country label `Naoero / Наоэро`; a common-name alias such as Nauru belongs in separately sourced display metadata, not in the M49 field.
- **ZA:** Pretoria `administrative`, Cape Town `legislative`, Bloemfontein `judicial`. Avoid extrapolating this shorthand into a claim about every court.
- **BO:** Sucre `constitutional`; La Paz `seat_of_government`.
- **NL:** Amsterdam `constitutional`; The Hague `seat_of_government`.
- **LK:** Colombo `capital`; Sri Jayewardenepura Kotte `legislative`.

The relevant legacy profiles are the official UNdata country pages, including [Benin](https://data.un.org/legacy/en/iso/BJ.html), [Bolivia](https://data.un.org/legacy/en/iso/BO.html), [Malaysia](https://data.un.org/legacy/en/iso/MY.html), [Netherlands](https://data.un.org/legacy/en/iso/NL.html), [Sri Lanka](https://data.un.org/legacy/en/iso/LK.html), and [South Africa](https://data.un.org/legacy/en/iso/ZA.html). Their footnotes support the stated distinctions; they should not be flattened during normalization.

## Primary-source spot checks and actual media inspection

- UN’s [M49 standard](https://unstats.un.org/unsd/methodology/m49/) plus the UN’s [Member States](https://www.un.org/en/about-us/member-states) and [non-member states](https://www.un.org/en/about-us/non-member-states) pages are the correct authority for the 193/2 scope. Fresh primary-page verification finds the current M49 rows `Naoero | 520 | NR | NRU` (English) and `Наоэро | 520 | NR | NRU` (Russian), so the draft NR display fields already reconcile to M49.
- The [Samoa Tourism Authority](https://www.samoa.travel/discover/the-islands-of-samoa/upolu-island/apia/) calls Apia Samoa’s capital. It is an accessible official fallback for the documented WS UNdata 404; do not falsely mark the original profile/flag as successfully fetched.
- The official [Palau PIF page](https://55piflm.gov.pw/about) says Ngerulmud is Palau’s capital; the [Palau Judiciary history](https://palaucourts.gov.pw/history-1.cshtml) locates Ngerulmud in Melekeok State. This resolves the PW profile-versus-city discrepancy.
- The [Nusantara Authority](https://ikn.go.id/en/hubungi-kami) says a regulation is required for transfer of national-capital status from DKI Jakarta to IKN. That supports a dated Jakarta/transition qualifier, not an unsupported finality claim.
- I retrieved `https://flagpedia.net/download/api` directly. Its operative wording is “we appreciate backlink to https://flagpedia.net”; the current `required` wording in `flagpedia-evidence.md` and both ledgers is inaccurate.
- I independently viewed the delivered hashed PNGs: **SY** (`1c80b649…851ecf`, 743 bytes) is green/white/black with **three red stars**, matching the UN’s [24 April 2025 briefing](https://www.un.org/sg/en/content/highlight/2025-04-24.html) and [25 April ceremony](https://webtv.un.org/en/asset/k1w/k1wk7g2zfp). **AF** (`25845722…3dbb`, 9,978 bytes) is the black/red/green vertical tricolour with the former republic emblem. Label it specifically as a historical/republic variant (2004–2021), not as a universal current Afghanistan representation. **NP** (`9a566325…0c7d`, 3,611 bytes) visually retains the non-rectangular double-pennon form.

## Fresh deterministic checks

Read-only PowerShell/standard-library inspection of the frozen draft produced:

| Check | Result |
| --- | --- |
| Registry rows / unique ISO-2 / unique ISO-3 | 195 / 195 / 195 |
| ISO-2 ascending order | pass |
| `un_status` membership counts | 193 `member`, 2 `observer` |
| Profile-evidence rows / ISO-set delta | 195 / 0 |
| Literal profile-capital mismatches before editorial corrections | 0 (WS is represented as the documented fetch failure) |
| Flagpedia rows / `fetched` rows / invalid SHA-256 fields | 195 / 195 / 0 |
| Flagpedia ISO-set delta; image-ledger ISO-set delta | 0; 0 |
| Original UNdata fetch failures | WS profile and linked original flag: HTTP 404; distinct from the 195 Flagpedia provider PNG downloads |
| Russian capital labels read | 203 occurrences across 195 countries |

## Input fingerprints

| File | SHA-256 |
| --- | --- |
| `countries.json` | `cf098dc0ad504df1e769f35237e472543575574a4de7180eb8297d8ca4c0013e` |
| `profile-row-evidence.json` | `02147bc17b09935ce7431850053f186fb108f7b3386bd8b64da210d2aa409ccc` |
| `capital-label-sources.json` | `38f459d5807d457793743d99bebbe901953fc45aac70c87c55810a5bcb7013d7` |
| `flagpedia-download-ledger.json` | `c59e918515b5cec932225914ccecb3f293b1968bd28a28b8b0202dcdc685dac8` |
| `image-source-license-ledger.json` | `ea5bbffa0512fed68d9f31b09e1c2d10d52978efe7abdca83cf09107b4d5dbaf` |

## Remaining risks

- This is a review finding only; it does not publish, copy, or approve any flag artwork.
- The corrected Russian forms need a project-approved editorial/transliteration authority before mechanical application; the listed machine errors themselves are not defensible as final labels.
- The UNdata source is a legacy snapshot. It validates its recorded rows and special-function footnotes, but cannot establish current political representation for every flag; Syria and Afghanistan demonstrate why explicit variant/date metadata is necessary.

## Recheck after registry correction — 2026-10-03

This section supersedes the earlier REVISE findings **only for the corrected records named below**. It is not publication approval.

| Corrected scope | Verdict | Independent recheck |
| --- | --- | --- |
| M49 identity | **ACCEPT** | `NR` retains the current M49 raw identity `Naoero / Наоэро`; `Nauru / Науру` is kept only in `display_aliases`. |
| Capital records and Russian labels | **ACCEPT** | `PW` now uses `Ngerulmud / Нгерулмуд` with its Melekeok State qualifier; `MV` is `Мале`, `KM` `Морони`, `MM` `Нейпьидо`, `LK` `Шри-Джаяварденепура-Котте`, and `MY` `Путраджая`. PS preserves the UNdata Jerusalem caveat and ID now records a staged, regulation-dependent IKN transition. |
| Flagpedia attribution | **ACCEPT** | Ledger records project-download permission and says a backlink is appreciated, not required; it makes no blanket public-domain/artwork-rights claim. |
| Afghanistan de-facto identification | **ACCEPT WITH RELEASE LIMIT** | `afghanistan-de-facto-media.json` points to the specific white 330×165 PNG. I verified the local file has PNG magic, 8,699 bytes, SHA-256 `b9cad74265690900d0eae7743a3f836e7fa8200604a46a125505de3dcc1a6d9a`, and visibly contains the black shahada on white. Its text correctly calls this a de-facto-authorities representation, not universal diplomatic recognition, and keeps the 2004–2021 republic variant separate. The Commons file page supports the narrow ancient-script PD/fallback-license statement, but also carries jurisdictional symbol-use warnings (including Russia). No general media-publication or legal-clearance conclusion follows. |

Offline invariant recheck: 195 registry rows, 195 unique ISO-2/ISO-3 values, ascending ISO-2 order, 193 members plus 2 observers; 195 profile-evidence rows and 195 Flagpedia rows remain ISO-matched. Corrected input hashes: `countries.json` `78b1bb2d9fbfdb35033022dbdc94c34a89ad472a6cce835c5dd1ec2932f14b04`; `capital-label-sources.json` `c7074bfbb1a5a4708bab1c92961498aa3a708d28a9764e7d3f1094a230dfbfd6`; `flagpedia-download-ledger.json` `4da94232ecb762a414fafa7f2dbf7e29ded2051aff333aeb485291416d967690`; `afghanistan-de-facto-media.json` `41883a0ab5e23aae0f536a07a5098505455aa3652cbcca95148833c098edb00e`.

## Scoped generator-preservation re-review — 2026-10-03

**Verdict: ACCEPT for the three reviewed generator/evidence files only.** This does not supersede the broader registry’s remaining publication and representation limits.

| Scope | Verdict | Evidence |
| --- | --- | --- |
| `build_registry.py` | **ACCEPT** | A normal network run now writes newly fetched `countries.json`, media ledger, label cache and profile evidence only under `raw-fetch/`; it no longer overwrites the frozen editorial records at the registry root. The explicit `Nauru` → M49 `Naoero` join and offline NR assertion preserve the reviewed M49 identity. |
| `build_flagpedia_ledger.py` | **ACCEPT** | A provider re-fetch writes only `raw-fetch/flagpedia-download-ledger.json`. The generator wording now correctly says a backlink is appreciated, not required; AF/SY remain qualified as representation variants rather than universal-current flags. |
| `offline_check()` / evidence | **ACCEPT** | Offline checks verify 195 unique sorted ISO-2 and ISO-3 values, 193/2 membership, reviewed label overrides including PW Ngerulmud and NR Naoero, and 195-row ISO-set parity for profile and Flagpedia ledgers. `evidence.md` accurately distinguishes this frozen-file check from a network re-generation. |

Fresh read-only execution from `C:\ap\quiz_master`:

```text
python docs/rewrite-agents/preparation-country-registry/build_registry.py --self-check  # exit 0
python docs/rewrite-agents/preparation-country-registry/build_registry.py --offline-check
OK: frozen 195-country registry, membership, editorial labels and source parity
```

I did **not** run a full network re-fetch. Any resulting `raw-fetch/` material is deliberately new source evidence, not an automatically accepted replacement for the frozen registry.
