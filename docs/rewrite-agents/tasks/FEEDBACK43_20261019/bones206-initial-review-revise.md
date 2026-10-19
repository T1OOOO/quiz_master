### Verdict: **REVISE** (`SHA256: d54f3359774975b8ad504e158a6647c9ef53a9297a85097a44ee80acdcec0c9f`)

---

### Blocking Factual Defect (20 Records Misassigned to Wrong `source_profile_id`)

Although the [`metacarpals`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L289-L309) and [`metatarsals`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L436-L456) profiles are accurately defined in `source_profiles`, **zero bone records reference them**. Instead, all 10 metacarpals and all 10 metatarsals reference the wrist (`"carpals"`) and ankle/hindfoot (`"tarsals"`) profiles, causing materialized records to state the wrong anatomical location, function, and bone-count facts:

1. **10 Metacarpal Records (`source_profile_id: "carpals"` → must be `"metacarpals"`):**
   - [`bone-left-metacarpal-1` .. `bone-left-metacarpal-5`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L2076-L2144) and [`bone-right-metacarpal-1` .. `bone-right-metacarpal-5`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L2342-L2410) (also in [bones206-review-projection.txt](file:///E:/Projects/quiz_master/.run/feedback43_20261019/bones206-review-projection.txt#L549-L572)).
   - **Impact:** Currently assigns metacarpals I–V the carpal position (`"В основании кисти, в области запястья."` / `"At the base of the hand in the wrist region."`) and the 8-carpal-bone fact instead of the palm (`"В ладонной части кисти, между костями запястья и фалангами пальцев кисти."`) and 5-metacarpal fact.

2. **10 Metatarsal Records (`source_profile_id: "tarsals"` → must be `"metatarsals"`):**
   - [`bone-left-metatarsal-1` .. `bone-left-metatarsal-5`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L2944-L3012) and [`bone-right-metatarsal-1` .. `bone-right-metatarsal-5`](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L3210-L3278) (also in [bones206-review-projection.txt](file:///E:/Projects/quiz_master/.run/feedback43_20261019/bones206-review-projection.txt#L611-L634)).
   - **Impact:** Currently assigns metatarsals I–V the tarsal position (`"В задней части стопы, дистальнее голеностопного сустава."` / `"In the posterior foot, distal to the ankle."`) and the 7-tarsal-bone fact instead of the anterior foot (`"В передней части стопы, между костями предплюсны и фалангами пальцев стопы."`) and 5-metatarsal fact.

---

### Verified & Passing in Current Draft

- **Adult 206 Matrix & Non-Overlapping Group Totals:**
  - `skeleton-skull` (22) + `skeleton-auditory-hyoid` (7) + `skeleton-vertebral-column` (26) + `skeleton-thoracic-cage` (25) = **80 axial**.
  - `skeleton-pectoral-girdle` (4) + `skeleton-upper-limbs` (60) + `skeleton-pelvic-girdle` (2) + `skeleton-lower-limbs` (60) = **126 appendicular**.
  - Total = **206 unique bone records**, all with `kind: "bone"`, `diagram_group: "skeleton"`, no `bone_count`, no fake coordinates, and no unverified Latin labels.
- **All 24 `source_profiles` ([feedback43-bones206-20261019.json](file:///E:/Projects/quiz_master/study/drafts/feedback43-bones206-20261019.json#L18-L477)):**
  - Verified against cached OpenStax 7.1–8.4 sources ([openstax-skeleton.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-skeleton.json), [openstax-skull.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-skull.json), [openstax-vertebral.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-vertebral.json), [openstax-thoracic.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-thoracic.json), [openstax-pectoral.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-pectoral.json), [openstax-upper.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-upper.json), [openstax-pelvic.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-pelvic.json), [openstax-lower.json](file:///E:/Projects/quiz_master/.run/feedback43_20261019/sources/openstax-lower.json)).
  - `coccyx` makes no spinal-cord-protection claim; `ribs` makes no false anterior-attachment claim for floating ribs; `patella` makes no direct weight-bearing claim; `tibia` vs. `fibula` accurately distinguish weight-bearing medial tibia from lateral fibula; `radius` and `ulna` qualify lateral/medial placement with `"в анатомическом положении"` (`"in anatomical position"`).
- **Russian & English Nomenclature, Laterality, and Numbering:**
  - **Skull (22):** 8 cranial (`лобная`, paired `теменная`, paired `височная`, `затылочная`, `клиновидная`, `решётчатая`) and 14 facial (paired `верхняя челюсть`, `скуловая`, `носовая`, `слёзная`, `нёбная`, `нижняя носовая раковина`; unpaired `сошник`, `нижняя челюсть`).
  - **Auditory ossicles & hyoid (7):** paired `молоточек`, `наковальня`, `стремя` + unpaired `подъязычная кость`.
  - **Vertebral column (26):** `C1–C7` (with `C1 (атлант)` and `C2 (осевой)`), `T1–T12`, `L1–L5`, single adult fused `крестец`, single adult fused `копчик`.
  - **Carpals (16) & Tarsals (14):** Carpal `trapezium` (`кость-трапеция`) vs. `trapezoid` (`трапециевидная кость`) properly distinguished; tarsal navicular disambiguated in Russian as `ладьевидная кость стопы`; all 3 cuneiforms (`медиальная`, `промежуточная`, `латеральная клиновидная кость`) accurate.
  - **Phalanges (56):** Thumb (`I палец кисти`) and hallux (`I палец стопы`) have 2 phalanges each (`проксимальная`, `дистальная`); digits II–V of hand and foot have 3 phalanges each (`проксимальная`, `средняя`, `дистальная`).

*(Import note for root: when materializing into the app, ensure [`organKinds`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas_models.dart#L3-L19) and [`organRegions`](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas_models.dart#L21-L28) in [organ_atlas_models.dart](file:///E:/Projects/quiz_master/next/apps/quiz_app/lib/organ_atlas_models.dart) are updated to include `kind: "bone"` and `region: "spine" | "upper_limb" | "lower_limb"`).*
