# BELIEFS_A0IZ source audit

Checked on 2026-10-19. This audit records pages actually opened and read before drafting. `belief_atlas.candidate.json` paraphrases them; it does not copy long source text. It is a candidate only and has not been imported, published, or accepted.

## Greek section

| Source ID | Opened page and evidence used | Candidate use |
|---|---|---|
| `hesiod_theogony` | Theoi’s opened translation of Hesiod’s *Theogony*. The cosmogony at 116–132 gives Chaos, Gaia, Uranus and the Titan generation; the later genealogy supplies the children of Cronus and Rhea, and 912 names Persephone as Zeus and Demeter’s daughter. The opened text also gives Hesiod’s sea-foam account of Aphrodite. | Primordial/Titan nodes, all parent edges through Cronus/Rhea, Zeus–Demeter–Persephone edges, and the source-qualified Aphrodite question. Every such edge says it is the Hesiodic version. |
| `homeric_hymns` | Theoi’s opened *Homeric Hymns* 5–33 translation. Hymn 5 distinguishes Athena, Artemis and Hestia; Hymn 7 contains Dionysus’s vine/ivy episode and names Semele and Zeus; Hymns 8–13 name Ares, Artemis, Hera, Demeter and Persephone; Hymn 18 calls Hermes messenger. | Athena, Artemis, Ares, Hera, Demeter, Hestia, Hermes and Dionysus facts; reciprocal Hera–Zeus and Apollo–Artemis links; exact-text questions. |
| `homeric_hymns_1_3` | Theoi’s separately opened *Homeric Hymns* 1–3 translation. Hymn 2 calls Persephone Demeter’s daughter, narrates her seizure by Hades, and later has Hades call himself her husband. | Hades–Persephone context, fact and reciprocal spouse links. The edge scopes retain the abduction context. |
| `met_greek_gods` | Opened Metropolitan Museum of Art essay, “Greek Gods and Religious Practices.” The core section identifies Zeus, Poseidon, Hades, Hera, Athena, Apollo, Artemis, Hermes, Aphrodite, Dionysus, Ares and Hephaestus, with the listed roles and several attributes (for example, Athena’s owl/olive and Hermes’s winged sandals/kerykeion). | Compact role/attribute support and museum-based questions. It is deliberately not the sole source for genealogy or every fact. |

Greek graph policy:

- The candidate has 21 figures across primordial, Titan, Olympian and underworld group labels.
- It makes no “canonical Twelve Olympians” claim or exhaustive list.
- Aphrodite’s card identifies the sea-foam narrative as Hesiod’s version and creates no parent edge.
- Hephaestus’s card creates neither a parent edge nor a spouse edge to Aphrodite; it does not convert differing ancient accounts into a single genealogy.
- Directed parent edges are paired with precise `Father`/`Mother` labels. Spouse and sibling relationships are reciprocal, and each contested/story-sensitive connection has source/version scope.

## Religion section

| Source ID | Opened page and evidence used | Candidate use |
|---|---|---|
| `pluralism_judaism` | Harvard Pluralism Project, “God, Torah, and Israel.” The opened article explains Judaism’s religious, cultural and historical dimensions and describes God, Torah and the people Israel as interdependent reference points. | Judaism overview, fact, and one text-specific question. |
| `pluralism_christianity` | Harvard Pluralism Project, “Introduction to Christianity.” The opened introduction describes traditions tracing teachings to Jesus and names Catholic, Orthodox and Protestant traditions as major contemporary branches. | Christianity overview, branch-qualified fact, and one question. It does not claim those branches exhaust Christian diversity. |
| `quran_2_177` | Quran.com’s opened rendering of Qur’an 2:177. The passage expressly mentions belief, charity, prayer, alms-tax, keeping pledges and steadfastness. | Islam’s deliberately narrow text-based fact and one question. It is not used as a total description of Muslim traditions. |
| `pluralism_hindu_veda` | Harvard Pluralism Project, “Veda: Scripture and Authority.” The opened article describes the four Vedas, oral transmission, and additional respected texts. | Hinduism overview, Veda fact and one question. It does not make one canon or practice stand for all Hindu traditions. |
| `pluralism_buddhist_dharma` | Harvard Pluralism Project, “The Dharma: The Teachings of the Buddha.” The opened article discusses Dharma, the Middle Way, Four Noble Truths and Eightfold Path; its navigation separately names Theravada, Mahayana and Vajrayana. | Buddhism overview, branch-aware note and one question. |
| `sikh_coalition_history` | Sikh Coalition, “History.” The opened page names Guru Nanak, ten Gurus, Guru Granth Sahib, Guru Khalsa Panth, gurdwara practice and the qualified context of the five articles of faith for initiated Sikhs. | Sikhism overview, scripture/community fact and question. The candidate does not universalize the initiated-Sikh practice. |
| `jainpedia_beliefs` | Jainpedia, “Jain Beliefs,” a scholarly/community resource. The opened page covers Jinas, Mahāvīra, karma, liberation, ahimsa, vows, lay/mendicant differences and the Three Jewels. | Jainism overview, ahimsa fact and question, with a lay/mendicant qualification. |
| `bahai_official` | The official worldwide Bahá’í community website. The opened page identifies the writings of Bahá’u’lláh, the Bahá’í Reference Library and the site’s account of Abraham, Krishna, Zoroaster, Moses, Buddha, Jesus and Muhammad as Manifestations of God. | Bahá’í overview and question. Five directed religion links are explicitly marked as this official Bahá’í self-description, never as a lineage tree or a claim made by the linked traditions. |
| `jinja_honcho_shinto` | Jinja Honcho, “What is Shinto?” The opened page says Shinto has no founder, dogma or doctrine; describes kami, jinja and matsuri; and distinguishes many kami and myths. | Shinto overview, fact and question. It reports Jinja Honcho’s presentation and does not assign a uniform identity to Japanese people. |

Religion graph policy:

- Nine traditions are represented: Judaism, Christianity, Islam, Hinduism, Buddhism, Sikhism, Jainism, the Bahá’í Faith and Shinto.
- There is no pan-religion hierarchy, exclusivity ranking, biological language, or claim that all traditions are members of one family tree.
- The only cross-tradition edges originate from the Bahá’í node and preserve the scope “Bahá’í teaching/self-description.”

## Question audit

- Greek: 11 questions, all four options are Greek-node IDs, with keys supported by the cited ancient text or Met essay.
- Religions: 9 questions, all four options are religion-node IDs, with keys tied to the source named in the stem/explanation.
- Each question has exactly four unique options, a correct ID present once, and a source ID. The two version-sensitive Greek questions name Hesiod or a specific Homeric Hymn in the stem.

## Remaining review points

1. A separate fact checker should independently open the listed sources and review Russian wording before any canonical import.
2. The Qur’an card intentionally limits itself to the opened verse. An integrator who wants broader Islamic practices or branches should add a separately opened, directly citable source rather than generalize this node.
3. The graph is intentionally incomplete: missing figures, traditions and intra-tradition links are coverage limits, not negative claims.
