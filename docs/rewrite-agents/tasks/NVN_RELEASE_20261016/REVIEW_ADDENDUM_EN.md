# Provenance field correction for the pending review

Root found and corrected a metadata-label error before publication. The
historical `runtime/fixture-source.json` field `server.py.sha256` was computed
from normalized UTF-8 source text before Windows CRLF translation. It is not
the raw file checksum. The source-generation helper now hashes the written
file; it was not rerun and no fixture or capture bytes were overwritten.

`fixture-provenance-correction.json` supplies the actual raw byte checksum.
Crucially, the frozen 103-entry runtime manifest already contains that correct
raw checksum for both the ignored actual server and the committed runtime
copy. Root independently checked their equality and that the actual fixture
is exactly the prior pinned fixture with only the two path substitutions.
The historical normalized checksum also matches its now-disclosed meaning.

Read this addendum in the pending task571 input/runtime review and task524
controller review. The validator correctly binds actual file bytes through
the immutable runtime manifest; it does not use the mislabeled nested field.
Preserve the historical record and use the correction when evaluating
provenance. No existing release-input hash, source guard, built artifact,
runtime screenshot or claimed behavior changed. Independent review is still
pending, and no archive/candidate/publication is authorized by this correction.
