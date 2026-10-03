# Full country registry — quiz_master-8k1.2

Base824eefd; cwd C:/ap/quiz_master. Label content-countries-oct3.
You are not alone: preserve all other edits. No children/git/build/browser/deploy.
Read qm-work-packet, qm-contracts-content and agent-hub-coordination skills.
Only writable subtree: docs/rewrite-agents/preparation-country-registry/.
Use own interactive host leases with exact write scope and shared read: pointers.

Produce a complete SOURCE-BACKED registry for193 UN member states + Holy See
and State of Palestine. Russian names from official UN Russian member/observer
lists; ISO2/ISO3 and names reconcile against official UN M49. No territories,
Kosovo/Taiwan or invented membership in this core; record expansions separately.

Existing primary dataset discovered by lead:
https://data.un.org/legacy/en/iso/XX.html country profiles from UN Statistics
Division include Capital city, relevant footnotes and actual linked flag images.
Use actual fetched profile rows, not a recalled/plausible capital or guessed flag
URL. Both original flag URL and verification date are required. A bounded
stdlib HTTP fetch is fine without browser; record failures rather than guess.
Download no provider runtimes/packages, no heavy jobs. Do not print195 fullpages.

Deliver countries.json with scope/as_of/countries. Each row: iso2, iso3,
name_ru/name_en, un_status(member/observer), region, profile_uri, flag_uri,
capitals(array of name_ru/name_en/role/note/source_uri). Preserve distinctions:
constitutional/seat_of_government/legislative/administrative/judicial/de_facto.
Nauru has no official capital; qualify Yaren. SriLanka/Netherlands/Bolivia/SA
footnotes must not collapse. Include source URLs/accessdates and exceptions.md
for failures, disputed/variant flags/capitals. Special current-flag checks:
Syria change2025, Afghanistan UN-representation vs de-facto flag; do not silently
label obsolete/controversial variants as universal current national flags.
Keep source edition/representation clear; country identification can be keyed
to a documented official UN representation, not an unqualified political claim.

195 unique countries, deterministic ISO2 order; exact193member/2observer counts,
no duplicate country/code, every capital/flag source recorded. Estimated content
difficulty later, not registry. Produce evidence.md with actual fetch coverage,
source/date/hash, unresolved exceptions and how extracted fields were verified.
No quizzes/canonical/API/UI edits and no publication. Return READY/freeze/release;
lead schedules independent coverage/fact audit before generating flag quizzes.
