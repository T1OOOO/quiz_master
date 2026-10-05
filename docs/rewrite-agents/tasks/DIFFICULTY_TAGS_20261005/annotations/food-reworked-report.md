# Food annotation rework — editorial candidate

Source: 11 frozen Gastronomy packs, 299 distinct source questions. Read each complete stem, all options, keyed index, and explanation alongside the original annotation. Source inventory revision: `e802ed21db936bdb9809bab2d137903eb0aa425e`.
Original `food.json` remains an unaccepted draft (SHA-256 `d7fc50a5ce2f25117f33bfd6deff8d12683f6e0d9a018d8d315790d159227bbf`). No raw question or answer content was edited.
Taxonomy: `qm-tags-v1`, SHA-256 `fcaf4ce7c923bf6734f660c6873674e1f42bd6986d6fc3c04dd5d6095ed51e11`; all output IDs are members of the current 403-tag dictionary. All 11 current source pack byte hashes match the frozen inventory.
Reworked JSON SHA-256: `a6e07891e06cbb7f3d6f9d2b15d8cc3261b7640a20e03eb57d0aa17f91ecc7c9`.

## Coverage and editorial method

Identity coverage: 299/299, no duplicate or missing IDs. Scores: {2: 7, 3: 42, 4: 101, 5: 69, 6: 49, 7: 25, 8: 6}. Confidence: {'high': 132, 'low': 38, 'medium': 129}.
Each item has an individual integer estimate and a brief answer-specific reason using the rubric anchor. Flags concern answer validity or external factual verification and do not raise difficulty automatically. Context contains only the visible domain and topic; private country, cuisine and ingredient tags represent the actual fact or dish, not all alternatives. Some source questions belong to geography, science, nature, psychology, arts/characters or law; their domains/topics were corrected where available.

## Semantic corrections

Removed false ingredient matches including Nutella/duxelles/peanut «паста» → wheat pasta; butter in pesto or vinaigrette; milk in «молоко тигра»; rice in rice-shaped orzo; apple in the pomegranate etymology; almond in the Witchetty Grub taste comparison. Reassigned Malbec and other wine facts to beverages, cappuccino after noon and table customs to food etiquette, floating apples to science/physics, and the two bookstore-city questions to geography/world geography. Added Australia for the Witchetty Grub question and corrected non-food questions' domains. The malformed mirepoix options and repeated Tourné misconception remain flagged; raw content is immutable.

## Controlled-vocabulary gaps

There are 66 true topic gaps. The IDs below are exact **proposals**, absent from the current 403-tag dictionary; root decides whether to amend it. No nearest incorrect topic was used to satisfy the schema. Each listed record retains an accurate domain and `taxonomy-topic-gap` flag.

### `topic:food-products` — 18 questions

`q_gastronomy_общие_факты_1_10_food_20`, `q_gastronomy_общие_факты_1_51_food_181`, `q_gastronomy_общие_факты_2_27_food_668`, `q_gastronomy_общие_факты_2_28_food_669`, `q_gastronomy_сладости_и_десерты_23_food_p5_22`, `q_gastronomy_сладости_и_десерты_28_food_p5_81`, `q_gastronomy_специи_и_ингредиенты_0_food_5`, `q_gastronomy_сыры_и_молочные_продукты_24_food_667`, `q_gastronomy_сыры_и_молочные_продукты_6_food_120`, `q_gastronomy_сыры_и_молочные_продукты_9_food_193`, `q_gastronomy_техника_приготовления_33_food_p5_4`, `q_gastronomy_традиции_и_этикет_0_food_3`, `q_gastronomy_традиции_и_этикет_11_food_100`, `q_gastronomy_традиции_и_этикет_19_food_172`, `q_gastronomy_традиции_и_этикет_1_food_4`, `q_gastronomy_традиции_и_этикет_20_food_185`, `q_gastronomy_традиции_и_этикет_47_food_665`, `q_gastronomy_фрукты_и_овощи_29_food_189`.

### `topic:edible-fungi` — 5 questions

`q_gastronomy_напитки_и_алкоголь_0_food_13`, `q_gastronomy_общие_факты_1_36_food_108`, `q_gastronomy_общие_факты_1_7_food_17`, `q_gastronomy_общие_факты_2_14_food_p5_66`, `q_gastronomy_техника_приготовления_50_food_690`.

### `topic:restaurant-industry` — 4 questions

`q_gastronomy_напитки_и_алкоголь_18_food_148`, `q_gastronomy_традиции_и_этикет_45_food_644`, `q_gastronomy_традиции_и_этикет_8_food_95`, `q_gastronomy_традиции_и_этикет_9_food_96`.

### `topic:food-senses` — 1 questions

`q_gastronomy_напитки_и_алкоголь_19_food_165`.

### `topic:culinary-profession` — 6 questions

`q_gastronomy_напитки_и_алкоголь_33_food_440`, `q_gastronomy_напитки_и_алкоголь_41_food_p5_42`, `q_gastronomy_напитки_и_алкоголь_42_food_p5_43`, `q_gastronomy_напитки_и_алкоголь_5_food_61`, `q_gastronomy_общие_факты_2_5_food_p5_44`, `q_gastronomy_техника_приготовления_9_food_105`.

### `topic:space-food` — 3 questions

`q_gastronomy_общие_факты_1_12_food_26`, `q_gastronomy_общие_факты_2_20_food_617`, `q_gastronomy_фрукты_и_овощи_3_food_29`.

### `topic:food-history` — 9 questions

`q_gastronomy_общие_факты_1_20_food_44`, `q_gastronomy_общие_факты_1_21_food_50`, `q_gastronomy_общие_факты_1_24_food_54`, `q_gastronomy_сладости_и_десерты_1_food_46`, `q_gastronomy_техника_приготовления_1_food_40`, `q_gastronomy_традиции_и_этикет_3_food_45`, `q_gastronomy_традиции_и_этикет_41_food_p5_86`, `q_gastronomy_фрукты_и_овощи_27_food_167`, `q_gastronomy_фрукты_и_овощи_9_food_52`.

### `topic:grain-pasta` — 3 questions

`q_gastronomy_общие_факты_1_23_food_53`, `q_gastronomy_общие_факты_1_2_food_8`, `q_gastronomy_общие_факты_1_92_food_p5_8`.

### `topic:food-law` — 7 questions

`q_gastronomy_общие_факты_1_33_food_91`, `q_gastronomy_общие_факты_1_61_food_217`, `q_gastronomy_сладости_и_десерты_7_food_138`, `q_gastronomy_традиции_и_этикет_15_food_141`, `q_gastronomy_традиции_и_этикет_22_food_196`, `q_gastronomy_традиции_и_этикет_38_food_p5_64`, `q_gastronomy_традиции_и_этикет_7_food_89`.

### `topic:brand-logos` — 1 questions

`q_gastronomy_общие_факты_1_84_food_300`.

### `topic:law-regulations` — 7 questions

`q_gastronomy_общие_факты_2_18_food_612`, `q_gastronomy_общие_факты_2_19_food_614`, `q_gastronomy_общие_факты_2_3_food_p5_40`, `q_gastronomy_общие_факты_2_4_food_p5_41`, `q_gastronomy_традиции_и_этикет_37_food_p5_39`, `q_gastronomy_традиции_и_этикет_43_food_611`, `q_gastronomy_традиции_и_этикет_44_food_613`.

### `topic:food-safety` — 2 questions

`q_gastronomy_мясо_и_рыба_2_food_111`, `q_gastronomy_сыры_и_молочные_продукты_4_food_94`.

## Remaining review

Flag counts: {'answer-format-ambiguous': 10, 'cultural-generalization-needs-source': 21, 'factual-error-suspected': 9, 'food-safety-oversimplified': 1, 'law-claim-needs-source': 15, 'medical-claim-needs-source': 6, 'needs-independent-fact-check': 54, 'ranking-time-sensitive': 12, 'superlative-needs-source': 23, 'taxonomy-topic-gap': 66}.
The flags preserve disputed superlatives, legal claims, broad cultural assertions, possible medical oversimplifications and malformed or contradictory answers. This annotation candidate does not fact-check or certify the source claims, statistically calibrate difficulty, or authorise publication. Root must validate and independently review it before application.
