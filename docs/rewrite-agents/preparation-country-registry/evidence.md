# Fetch and validation evidence

Generated on 2026-10-03 by `build_registry.py` using Python standard-library HTTP only. No image files are copied into the repository.

Primary inputs:

- UN M49 overview: English and Russian rows provide ISO2/ISO3, country names and regions.
- Official UN English/Russian member lists: 193 members, joined by an explicit seven-name normalization table rather than fuzzy matching.
- Official UN English/Russian non-member observer lists: Holy See and State of Palestine.
- UNdata legacy country profiles: actual profile Capital city row, linked original flag URL and profile hash.
- UNdata Terms & Conditions of Use: fetched and hashed in the image ledger.

Reproducible checks:

```powershell
python docs/rewrite-agents/preparation-country-registry/build_registry.py --self-check
python docs/rewrite-agents/preparation-country-registry/build_registry.py --offline-check
python docs/rewrite-agents/preparation-country-registry/build_registry.py
```

The self-check asserts that HTML `sup` footnotes are removed from the capital value while their keys remain separately captured. The offline check validates the frozen, editorially corrected records and their source-set parity. A fresh network run writes only into `raw-fetch/`, never over the reviewed files: it is new source evidence requiring a new review, not an automatic regeneration of accepted capital claims. See `exceptions.md` for Samoa, Syria, Afghanistan, machine-rendered city labels and artwork-rights limits.
