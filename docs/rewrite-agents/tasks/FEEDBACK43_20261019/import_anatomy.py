"""Deterministically append the exact independently accepted anatomy draft."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DRAFT = ROOT / 'study/drafts/feedback43-anatomy-20261019.json'
OUTPUT = ROOT / 'next/apps/quiz_app/assets/quizipedia/organ_atlas.json'
EXPECTED = '93443d961be758d81b005078e57bb3053c7e6ccc41ab01ee0c2f4e9fce5af1a9'
ENGLISH = [
 ('Which group contains the 22 adult skull bones?', 'The skull has 8 cranial and 14 facial bones, making 22.'),
 ('Where are the malleus, incus and stapes?', 'These are the three auditory ossicles of each middle ear, six in both ears.'),
 ('Which group has an adult count of 26 bones?', 'The 24 separate vertebrae, sacrum and coccyx make 26 adult bones.'),
 ('Which group includes 12 pairs of ribs and the sternum?', 'The 24 ribs and sternum make 25 bones; thoracic vertebrae are counted separately.'),
 ('Which group consists of two clavicles and two scapulae?', 'The two clavicles and two scapulae form the four-bone pectoral girdle.'),
 ('Which group includes the eight carpal bones of each hand?', 'Each hand has eight carpals; both free upper limbs have sixteen.'),
 ('Which group contains two hip bones but not the sacrum?', 'The hip bones belong to the appendicular skeleton; the sacrum is axial.'),
 ('Which group includes seven tarsal bones of each foot?', 'Each foot has seven tarsals, making fourteen in both free lower limbs.'),
 ('Which outer grey-matter layer includes the four major cerebral lobes?', 'The cerebral cortex includes the frontal, parietal, temporal and occipital lobes.'),
 ('Which cortical region is hidden deep within the lateral sulcus?', 'The insula is a deep region of cerebral cortex within the lateral sulcus.'),
 ('Which structure relays most sensory information to cortex, except olfaction?', 'The thalamus is a major sensory relay; olfaction is the exception.'),
 ('Which deep nuclei within the cerebral hemispheres participate in planning movement?', 'The basal nuclei are deep within the cerebral hemispheres, distinct from the outer cortex and cerebellum.'),
 ('Which major white-matter pathway connects the right and left cerebral hemispheres?', 'The corpus callosum connects the hemispheres; the longitudinal fissure separates them.'),
 ('Which part forms the brain stem together with the pons and medulla?', 'The midbrain, pons and medulla form the brain stem.'),
 ('Which brain-stem part lies between the midbrain and medulla?', 'The pons lies between the midbrain and medulla.'),
 ('Which lowest brain-stem part continues into the spinal cord?', 'The medulla lies at the lower end of the brain stem and continues into the spinal cord.'),
 ('Which major brain region compares motor commands with sensory feedback?', 'The cerebellum receives brain-stem connections and helps coordinate movement.'),
]

def main():
    raw = DRAFT.read_bytes()
    if hashlib.sha256(raw).hexdigest() != EXPECTED:
        raise SystemExit('accepted anatomy draft hash differs')
    acceptance = json.loads((Path(__file__).parent / 'anatomy-acceptance.json').read_text())
    if acceptance.get('draft_sha256') != EXPECTED or acceptance.get('verdict') != 'ACCEPT':
        raise SystemExit('exact independent factual acceptance is required')
    draft = json.loads(raw)
    atlas = json.loads(OUTPUT.read_text(encoding='utf-8'))
    added = draft['skeleton_groups'] + draft['brain_regions']
    if len(atlas['organs']) != 52 or len(added) != 17 or len(draft['questions']) != len(ENGLISH):
        raise SystemExit('baseline structure count or draft scope differs')
    if sum(row.get('bone_count', 0) for row in added) != 206:
        raise SystemExit('adult skeleton count differs')
    old_ids = {row['id'] for row in atlas['organs']}
    source_ids = {row['id'] for row in atlas['sources']}
    if old_ids.intersection(row['id'] for row in added):
        raise SystemExit('new structure collides with existing structure')
    for row in draft['sources']:
        if row['id'] in source_ids:
            previous = next(item for item in atlas['sources'] if item['id'] == row['id'])
            if previous['url'] != row['url']:
                raise SystemExit('source identity has a different URL')
            continue
        atlas['sources'].append(dict(id=row['id'], title=row['title_ru'], url=row['url'], checked_on=row['accessed']))
    atlas['organs'].extend(added)
    for question, (stem, explanation) in zip(draft['questions'], ENGLISH):
        atlas['questions'].append(dict(question, stem_en=stem, explanation_en=explanation))
    atlas['coverage_note_ru'] = '69 учебных структур: крупные органы и железы, 8 групп скелета взрослого человека (206 костей) и 9 отделов мозга. Это обзор; мелкие железы, ядра и микроструктуры перечислены не исчерпывающе. Для парных групп число костей дано суммарно с обеих сторон.'
    atlas['coverage_note_en'] = '69 learning structures: major organs and glands, 8 adult skeletal groups (206 bones), and 9 brain regions. This overview is not an exhaustive list of small glands, nuclei or microscopic structures. Counts for paired groups include both sides.'
    OUTPUT.write_text(json.dumps(atlas, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Imported 17 accepted structures; 69 structures total; 206 adult bones in 8 groups')

if __name__ == '__main__':
    main()
