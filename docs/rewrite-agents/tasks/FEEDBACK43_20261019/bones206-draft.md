# Bones 206 draft — Feedback 43

Status: **DRAFT ONLY — an independent fact check by a different provider is required before import.**

The draft [feedback43-bones206-20261019.json](../../../../study/drafts/feedback43-bones206-20261019.json) contains a finite inventory of 206 adult bones under the standard educational convention. It is a data proposal only: it makes no canonical edit, UI or enum change, marker/projection claim, import, commit, publication, or release claim.

There are 206 individual selectable Russian/English bone records. Every one has `kind: bone`, `diagram_group: skeleton`, a parent group, region, adult convention, and a source-profile reference. The source profile deterministically supplies the ordinary atlas fields `position_ru/en`, `function_ru/en`, `facts`, and `source_ids`.

The revision uses 24 anatomy-family profiles rather than eight broad group descriptions. It separates auditory ossicles from the hyoid; individual vertebrae from the fused sacrum and coccyx; ribs from the sternum; clavicles from scapulae; each upper-limb family; and each lower-limb family. Thus the coccyx is simply placed below the sacrum as a fused adult bone, ribs are located in the bony thoracic cage with posterior vertebral attachment, and the patella is described at the knee with the distal femur rather than as a weight-bearing bone. The profiles use shared source-backed membership and count facts only where they explicitly describe the family/group.

The profile binding now has explicit structural guards: 16 carpal records, 10 metacarpal records, 14 tarsal records, 10 metatarsal records, and 56 phalanges split into 28 hand and 28 foot records. The validator also requires every one of the 24 profiles to be referenced, so a future substring classifier cannot silently leave a defined family unused.

The count matrix is exact: 22 skull bones; 6 auditory ossicles plus 1 hyoid; 26 vertebral bones (`C1–C7`, `T1–T12`, `L1–L5`, sacrum, coccyx); 24 ribs plus sternum; 4 pectoral-girdle bones; 60 free upper-limb bones; 2 hip bones; and 60 free lower-limb bones. That is 80 axial plus 126 appendicular = 206. Laterality, digit I–V, and proximal/middle/distal phalanx are present in the record IDs and Russian labels. The thumb and great toe each have two phalanges.

The draft deliberately omits `bone_count` and `diagram_anchor` from every individual bone. It also omits per-bone Latin names: a later editor may supply a verified TA2 base term, but this draft does not manufacture left/right Latin names. The existing eight group cards remain the count receipt; the new entries are the literal individual-bone inventory requested by the user.

The source envelope records the nine existing primary source IDs: OpenStax sections 7.1–7.4 and 8.1–8.4, plus the TA2 Viewer, with the cached primary-source paths. The group profiles contain the stable position, function, and composition facts that the importer must copy into each child entity.

The required next gate is an independent different-provider review of all labels/IDs, source profiles, count matrix, materialization rule, and no-anchor policy. Passing that review does not by itself authorize import or publication.
