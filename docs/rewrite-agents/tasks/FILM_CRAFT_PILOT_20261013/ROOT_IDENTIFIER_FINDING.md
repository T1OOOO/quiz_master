# Candidate identifier cue

The frozen v1 candidate uses IDs ending in `foley-sync`, `adr-lipsync`, `j-cut` and `stop-motion-frame`. These identify the intended concepts and can cue a reviewer reading the candidate JSON, despite the absence of an explicit answer field. They also should not carry answer clues into a public question DTO.

Root holds an unqualified cold-solve/publication gate until a separate, reviewed delta replaces them with opaque stable IDs and updates the matching private editorial references. Preserve frozen v1 and its review history. Factual/source review can continue on the unchanged texts; a reviewer already exposed to v1 cannot retrospectively claim a clean blind solve of the same questions. A fresh-context solve, if obtained, must be recorded honestly as an additional limited evidence step.

No canonical or production change has been made. This correction is controlled under `quiz_master-4gq` and does not require changing the actual question facts, option IDs or article source claims.
