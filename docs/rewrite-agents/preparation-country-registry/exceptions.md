# Registry exceptions and representation limits

Access date: 2026-10-03. This is a preparation registry, not a publication or a political-recognition statement.

## Samoa (`WS`)

The requested UNdata profile URL `https://data.un.org/legacy/en/iso/WS.html` returned HTTP 404 during the recorded fetch. The UNdata country index still linked the original flag asset `https://data.un.org/legacy/common/flags/wsm_flag.png`; its URL and bytes are retained in the media ledger. `Apia` is sourced instead from the [Samoa Tourism Authority](https://specialist.samoa.travel/home/page/1082), which identifies it as Samoa's capital city. The failure remains in `countries.json.fetch_failures`; it is not silently treated as a successful profile fetch.

## Syria (`SY`)

`flag_uri` is the image actually linked by the fetched UNdata profile and is only a source-edition snapshot. It must not be labelled as an unqualified current national flag. The UN Secretary-General's [24 April 2025 highlight](https://www.un.org/sg/en/content/highlight/2025-04-24.html) says the new three-star Syrian flag would be raised at United Nations Headquarters the next day; the [25 April 2025 UN Web TV ceremony](https://webtv.un.org/en/asset/k1w/k1wk7g2zfp) is the primary event record. Any current-flag media decision needs a fresh representation review.

## Afghanistan (`AF`)

`flag_uri` is likewise the image actually linked by the UNdata country profile as fetched. The registry does not call it a universally current national flag and does not resolve UN representation versus de-facto flag claims. A release using this image requires a representation and rights review separate from country identity.

## Capital labels and rights

Country Russian names come from the Russian UN M49 table after membership is joined against the official UN member/observer lists. Russian city labels are machine-rendered convenience text recorded in `capital-label-sources.json`; the capital identity and English spellings are from UNdata profile rows (or the explicit Samoa fallback above). They require editorial review before publication.

UNdata terms evidence covers UNdata data/metadata with citation; it does not, by itself, establish rights in every linked flag artwork. `image-source-license-ledger.json` therefore records byte verification and separates data/metadata reuse from artwork reuse. `flagpedia-download-ledger.json` is a separate, verified 195-PNG provider-permission alternative: its API documentation permits project downloads and says a backlink is appreciated, not required. It leaves original UNdata URLs unchanged. Its Afghanistan PNG is the historical Republic variant (2004–2021); its Syria PNG is the 2025 three-star UN representation; Nepal retains its double-pennon form.

## Reviewed capital/identity corrections

M49 currently records `NR` as `Naoero / Наоэро`; these raw fields are preserved, with `Nauru / Науру` recorded only as common aliases. Palau's raw legacy UNdata capital evidence remains `Melekeok`, but the effective capital row is `Ngerulmud / Нгерулмуд` from the official [Palau PIF page](https://55piflm.gov.pw/about), with Melekeok State context from the [Palau Judiciary](https://palaucourts.gov.pw/history-1.cshtml). The Palestine row now reproduces its actual UNdata Jerusalem caveat. Jakarta remains the legacy profile row; the IKN contact page returned HTTP 403 during the 2026-10-03 check, so the record states only a staged, regulation-dependent transition.
