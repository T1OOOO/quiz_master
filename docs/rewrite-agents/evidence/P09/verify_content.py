"""Reuse the accepted P08 verifier read-only, without rewriting its evidence."""
import json
import runpy

verifier = runpy.run_path("docs/rewrite-agents/evidence/P08/verify.py")
result = verifier["verify_pack"](verifier["PACK"])
print(json.dumps({key: result[key] for key in (
    "source_questions", "canonical_questions", "private_grading_entries",
    "nonzero_source_answers", "bundle_sha256", "artifact_file_sha256",
)}, sort_keys=True))
