# Flagpedia download verification

Access date: 2026-10-03. `build_flagpedia_ledger.py` fetched the provider's [API documentation](https://flagpedia.net/download/api), then fetched one width-320 PNG per ISO2 in the frozen registry. The resulting `flagpedia-download-ledger.json` has 195 entries and 195 successful byte/hash verifications; its SHA-256 is `c59e918515b5cec932225914ccecb3f293b1968bd28a28b8b0202dcdc685dac8`.

The ledger records the provider's documented project-download permission and its statement that a backlink is appreciated, without asserting a blanket public-domain conclusion. It is an alternative media source only: `countries.json.flag_uri` continues to record the original URL actually linked by each UNdata profile (or the explicit Samoa index fallback). The checked variants are explicit: Afghanistan is historical Republic (2004–2021), Syria is the 2025 UN three-star representation, and Nepal is non-rectangular double-pennon.
