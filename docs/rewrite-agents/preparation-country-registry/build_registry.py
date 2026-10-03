"""Fetch the UN-backed preparation-country registry with only the stdlib.

Run from the repository root: python docs/rewrite-agents/preparation-country-registry/build_registry.py
"""
from __future__ import annotations

import hashlib
import html
import json
import re
from datetime import date
from pathlib import Path
from urllib.parse import urlencode, urljoin
from urllib.request import Request, urlopen

ROOT = Path(__file__).parent
# Raw refetches must never overwrite independently reviewed editorial records.
OUT = ROOT / "raw-fetch"
M49 = "https://unstats.un.org/unsd/methodology/m49/overview/"
MEMBERS_EN = "https://www.un.org/en/about-us/member-states"
MEMBERS_RU = "https://www.un.org/ru/about-us/member-states"
OBSERVERS_EN = "https://www.un.org/en/about-us/non-member-states"
OBSERVERS_RU = "https://www.un.org/ru/about-us/non-member-states"
PROFILE = "https://data.un.org/legacy/en/iso/{iso2}.html"
TERMS = "https://data.un.org/Host.aspx?Content=UNdataUse"
TRANSLATE = "https://translate.googleapis.com/translate_a/single?"
ACCESS_DATE = date.today().isoformat()

# The seven display-name differences between the current UN English member page
# and UN M49 are explicit, audited joins rather than fuzzy country matching.
MEMBER_M49_NAME = {
    "Bahamas (The)": "Bahamas",
    "China (the People's Republic of)": "China",
    "Côte D'Ivoire": "Côte d’Ivoire",
    "Gambia (Republic of The)": "Gambia",
    "Guinea Bissau": "Guinea-Bissau",
    "Lao People’s Democratic Republic": "Lao People's Democratic Republic",
    "Nauru": "Naoero",
    "Venezuela, Bolivarian Republic of": "Venezuela (Bolivarian Republic of)",
}

# These distinctions are in the UNdata profile footnotes.  They are records,
# not a replacement of the profile's displayed capital city.
CAPITAL_VARIANTS = {
    "BJ": [("Porto-Novo", "constitutional", "UNdata capital-city footnote."),
           ("Cotonou", "economic", "UNdata capital-city footnote identifies the economic capital.")],
    "BO": [("Sucre", "constitutional", "UNdata lists Sucre; La Paz is the seat of government."),
           ("La Paz", "seat_of_government", "UNdata capital-city footnote identifies La Paz as seat of government.")],
    "LK": [("Colombo", "capital", "UNdata capital-city footnote."),
           ("Sri Jayewardenepura Kotte", "legislative", "UNdata capital-city footnote identifies the legislative capital.")],
    "MY": [("Kuala Lumpur", "capital", "UNdata capital-city footnote."),
           ("Putrajaya", "administrative", "UNdata capital-city footnote identifies the administrative capital.")],
    "NL": [("Amsterdam", "constitutional", "UNdata capital-city footnote."),
           ("The Hague", "seat_of_government", "UNdata capital-city footnote identifies the seat of government.")],
    "NR": [("Yaren", "de_facto", "Nauru has no official capital; UNdata lists Yaren as capital city.")],
    "SZ": [("Mbabane", "administrative", "UNdata capital-city footnote."),
           ("Lobamba", "legislative", "UNdata capital-city footnote identifies the legislative capital.")],
    "ZA": [("Pretoria", "administrative", "UNdata capital-city footnote."),
           ("Cape Town", "legislative", "UNdata capital-city footnote."),
           ("Bloemfontein", "judicial", "UNdata capital-city footnote.")],
    "WS": [("Apia", "capital", "UNdata profile URL returned 404; official Samoa Tourism Authority identifies Apia as the capital city.")],
}
SAMOA_CAPITAL_SOURCE = "https://specialist.samoa.travel/home/page/1082"


def fetch(url: str) -> bytes:
    request = Request(url, headers={"User-Agent": "quiz-master-registry/1.0 (+UN source verification)"})
    with urlopen(request, timeout=30) as response:
        return response.read()


def clean(value: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", value)).replace("\xa0", " ").strip()


def table_rows(page: str, table_id: str) -> list[list[str]]:
    start = page.index(f'id = "{table_id}"')
    section = page[start:page.index("</table>", start)]
    rows = []
    for row in re.findall(r"<tr[^>]*>(.*?)</tr>", section, re.S | re.I):
        cells = [clean(cell) for cell in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S | re.I)]
        if cells:
            rows.append(cells)
    return rows


def m49_records(page: str, table_id: str) -> dict[str, list[str]]:
    return {row[10]: row for row in table_rows(page, table_id)[1:] if len(row) >= 12 and row[10]}


def h2_names(page: str) -> list[str]:
    return [clean(value).rstrip("*").strip() for value in re.findall(r"<h2[^>]*>(.*?)</h2>", page, re.S | re.I)]


def field(profile: str, label: str) -> tuple[str, list[str]]:
    match = re.search(
        rf"<td[^>]*>\s*{re.escape(label)}&nbsp;</td>\s*<td[^>]*>.*?</td>\s*<td[^>]*>(.*?)</td>",
        profile,
        re.S | re.I,
    )
    if not match:
        raise ValueError(f"missing {label}")
    raw = match.group(1)
    return clean(re.sub(r"<sup>.*?</sup>", "", raw, flags=re.S | re.I)), re.findall(r"<sup>([^<]*)</sup>", raw)


def profile_data(iso2: str) -> dict[str, object]:
    uri = PROFILE.format(iso2=iso2)
    try:
        page = fetch(uri).decode("utf-8")
    except Exception as exc:
        raise ValueError(f"{iso2} profile fetch failed: {exc}") from exc
    capital, footnote_keys = field(page, "Capital city")
    capital_footnotes = {}
    for key in footnote_keys:
        match = re.search(rf"<tr><td[^>]*><b>{re.escape(key)}</b></td>.*?<td[^>]*>(.*?)</td></tr>", page, re.S | re.I)
        if match:
            capital_footnotes[key] = clean(match.group(1))
    region, _ = field(page, "Region")
    flag = re.search(r"<img\s+id='myImg'\s+src='([^']+)'", page, re.I)
    if not flag:
        raise ValueError("missing linked flag image")
    return {
        "profile_uri": uri,
        "profile_sha256": hashlib.sha256(page.encode("utf-8")).hexdigest(),
        "capital_en": capital,
        "capital_footnotes": footnote_keys,
        "capital_footnote_text": capital_footnotes,
        "region": region,
        "flag_uri": urljoin(uri, flag.group(1)),
    }


def index_flag_uri(index_page: str, iso2: str) -> str | None:
    item = re.search(rf"<li><a href='iso/{iso2.lower()}\.html'>(.*?)</li>", index_page, re.S | re.I)
    match = re.search(r"<img src='([^']*flags/[^']+)'", item.group(1), re.S | re.I) if item else None
    return urljoin("https://data.un.org/legacy/en/index.html", match.group(1)) if match else None


def parser_self_check() -> None:
    snippet = "<td>Capital city&nbsp;</td><td>&nbsp;</td><td align='right'>Sucre<sup>d</sup></td>"
    assert field(snippet, "Capital city") == ("Sucre", ["d"])


def russian_labels(names_en: set[str]) -> dict[str, str]:
    """Render labels in four bounded requests; UNdata remains the fact source."""
    labels: dict[str, str] = {}
    names = sorted(names_en)
    for start in range(0, len(names), 50):
        chunk = names[start:start + 50]
        query = urlencode({"client": "gtx", "sl": "en", "tl": "ru", "dt": "t", "q": "\n".join(chunk)})
        data = json.loads(fetch(TRANSLATE + query).decode("utf-8"))
        translated = "".join(part[0] for part in data[0]).split("\n")
        if len(translated) != len(chunk):
            raise ValueError("capital Russian-label batch length mismatch")
        labels.update(zip(chunk, translated))
    return labels


def main() -> None:
    parser_self_check()
    OUT.mkdir(exist_ok=True)
    raw = {
        "m49": fetch(M49), "members_en": fetch(MEMBERS_EN), "members_ru": fetch(MEMBERS_RU),
        "observers_en": fetch(OBSERVERS_EN), "observers_ru": fetch(OBSERVERS_RU), "terms": fetch(TERMS),
    }
    m49_en = m49_records(raw["m49"].decode("utf-8"), "downloadTableEN")
    m49_ru = m49_records(raw["m49"].decode("utf-8"), "downloadTableRU")
    en_members = set(h2_names(raw["members_en"].decode("utf-8"))) - {"Search the United Nations"}
    ru_members = set(h2_names(raw["members_ru"].decode("utf-8")))
    if len(en_members) != 193 or len(ru_members) != 193:
        raise ValueError(f"UN member-list count mismatch: EN={len(en_members)} RU={len(ru_members)}")
    member_m49 = {MEMBER_M49_NAME.get(name, name) for name in en_members}
    by_en_name = {row[8]: code for code, row in m49_en.items()}
    if set(by_en_name) & {"Kosovo", "Taiwan"}:
        raise ValueError("unexpected M49 record invariant")
    member_codes = {by_en_name[name] for name in member_m49}
    if len(member_codes) != 193:
        raise ValueError("member M49 join is not one-to-one")
    observer_codes = {"PS", "VA"}
    if not observer_codes <= set(m49_en):
        raise ValueError("M49 observer codes missing")

    index_page = fetch("https://data.un.org/legacy/en/index.html").decode("utf-8")
    profiles: dict[str, dict[str, object]] = {}
    failures: list[dict[str, str]] = []
    variants_by_iso2: dict[str, list[tuple[str, str, str]]] = {}
    for iso2 in sorted(member_codes | observer_codes):
        try:
            profile = profile_data(iso2)
        except ValueError as exc:
            fallback_flag = index_flag_uri(index_page, iso2)
            failures.append({"iso2": iso2, "profile_uri": PROFILE.format(iso2=iso2), "error": str(exc), "flag_uri_from_index": fallback_flag or ""})
            profile = {
                "profile_uri": PROFILE.format(iso2=iso2), "profile_sha256": "", "capital_en": "",
                "capital_footnotes": [], "capital_footnote_text": {}, "region": m49_en[iso2][5], "flag_uri": fallback_flag,
            }
        profiles[iso2] = profile
        variants_by_iso2[iso2] = CAPITAL_VARIANTS.get(iso2, [] if not profile["capital_en"] else [(profile["capital_en"], "capital", "UNdata Capital city field.")])
    label_cache = russian_labels({name_en for variants in variants_by_iso2.values() for name_en, _, _ in variants})
    countries = []
    for iso2 in sorted(member_codes | observer_codes):
        row_en, row_ru = m49_en[iso2], m49_ru[iso2]
        profile = profiles[iso2]
        variants = variants_by_iso2[iso2]
        capitals = [{
            "name_en": name_en,
            "name_ru": label_cache[name_en],
            "role": role,
            "note": note,
            "source_uri": SAMOA_CAPITAL_SOURCE if iso2 == "WS" else profile["profile_uri"],
        } for name_en, role, note in variants]
        countries.append({
            "iso2": iso2,
            "iso3": row_en[11],
            "name_ru": row_ru[8],
            "name_en": row_en[8],
            "un_status": "member" if iso2 in member_codes else "observer",
            "region": profile["region"],
            "profile_uri": profile["profile_uri"],
            "flag_uri": profile["flag_uri"],
            "capitals": capitals,
        })
    if len(countries) != 195 or sum(x["un_status"] == "member" for x in countries) != 193:
        raise ValueError("country/status cardinality invariant failed")

    registry = {
        "scope": "193 UN Member States plus the two UN non-member observer States; no territories, Kosovo or Taiwan.",
        "as_of": ACCESS_DATE,
        "sources": {
            "m49": {"uri": M49, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(raw["m49"]).hexdigest()},
            "members_en": {"uri": MEMBERS_EN, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(raw["members_en"]).hexdigest()},
            "members_ru": {"uri": MEMBERS_RU, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(raw["members_ru"]).hexdigest()},
            "observers_en": {"uri": OBSERVERS_EN, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(raw["observers_en"]).hexdigest()},
            "observers_ru": {"uri": OBSERVERS_RU, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(raw["observers_ru"]).hexdigest()},
            "samoa_capital": {"uri": SAMOA_CAPITAL_SOURCE, "accessed": ACCESS_DATE, "sha256": hashlib.sha256(fetch(SAMOA_CAPITAL_SOURCE)).hexdigest()},
        },
        "fetch_failures": failures,
        "countries": countries,
    }
    flags = []
    for iso2 in sorted(profiles):
        flag_uri = profiles[iso2]["flag_uri"]
        try:
            flag_bytes = fetch(flag_uri) if flag_uri else b""
            byte_verification = {"status": "fetched", "bytes": len(flag_bytes), "sha256": hashlib.sha256(flag_bytes).hexdigest()}
        except Exception as exc:
            byte_verification = {"status": "failed", "error": str(exc)}
            failures.append({"iso2": iso2, "profile_uri": profiles[iso2]["profile_uri"], "error": f"flag fetch: {exc}", "flag_uri_from_index": flag_uri or ""})
        flags.append({
            "iso2": iso2, "source_uri": flag_uri, "profile_uri": profiles[iso2]["profile_uri"],
            "profile_sha256": profiles[iso2]["profile_sha256"], "verified_on": ACCESS_DATE,
            "byte_verification": byte_verification,
            "attribution": "UNdata country profile linked image",
            "data_metadata_reuse": "UNdataUse permits copying/distributing UNdata data and metadata with citation.",
            "artwork_reuse_status": "not established by UNdataUse alone; do not copy/publish flag artwork until separately reviewed",
        })
    ledger = {
        "scope": "Source and reuse-status ledger for linked flag media; no image is copied into this repository.",
        "accessed": ACCESS_DATE,
        "terms": {"uri": TERMS, "sha256": hashlib.sha256(raw["terms"]).hexdigest(), "status": "fetched; review required before any publication"},
        "flags": flags,
    }
    (OUT / "countries.json").write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "image-source-license-ledger.json").write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "capital-label-sources.json").write_text(json.dumps({
        "source": "Machine-rendered Russian labels; capital identity is from each UNdata profile and needs editorial review before publication.",
        "endpoint": TRANSLATE, "accessed": ACCESS_DATE, "labels": label_cache,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (OUT / "profile-row-evidence.json").write_text(json.dumps({
        "source": "Actual fetched UNdata Capital city table rows and only their referenced footnotes.",
        "accessed": ACCESS_DATE,
        "profiles": [{"iso2": iso2, "profile_uri": profiles[iso2]["profile_uri"], "profile_sha256": profiles[iso2]["profile_sha256"],
                      "capital_en": profiles[iso2]["capital_en"], "footnote_keys": profiles[iso2]["capital_footnotes"],
                      "footnote_text": profiles[iso2]["capital_footnote_text"]} for iso2 in sorted(profiles)],
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def offline_check() -> None:
    countries = json.loads((ROOT / "countries.json").read_text(encoding="utf-8"))["countries"]
    codes = [c["iso2"] for c in countries]
    assert len(countries) == len(set(codes)) == 195
    assert len({c["iso3"] for c in countries}) == 195
    assert codes == sorted(codes)
    assert sum(c["un_status"] == "member" for c in countries) == 193
    assert sum(c["un_status"] == "observer" for c in countries) == 2
    by_code = {c["iso2"]: c for c in countries}
    labels = json.loads((ROOT / "capital-label-sources.json").read_text(encoding="utf-8"))
    for code, expected in labels["editorial_overrides"].items():
        assert any(capital["name_ru"] == expected for capital in by_code[code]["capitals"])
    assert by_code["PW"]["capitals"][0]["name_en"] == "Ngerulmud"
    assert by_code["NR"]["name_en"] == "Naoero"
    assert by_code["NR"]["capitals"][0]["role"] == "de_facto"
    for filename, key in [("profile-row-evidence.json", "profiles"),
                          ("flagpedia-download-ledger.json", "flags")]:
        records = json.loads((ROOT / filename).read_text(encoding="utf-8"))[key]
        assert len(records) == 195 and {r["iso2"] for r in records} == set(codes)
    print("OK: frozen 195-country registry, membership, editorial labels and source parity")


if __name__ == "__main__":
    import sys
    if "--self-check" in sys.argv:
        parser_self_check()
    elif "--offline-check" in sys.argv:
        offline_check()
    else:
        main()
