"""Import the independently accepted six-region anatomy delta, with prefix checks."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
DRAFT_SHA = '12bd87bd1c91e4823bbf6eff9e9cf78aafbaf6e8160dc39afaa5e711c4a8ca05'
BASE_SHA = '6955438fc9b2e98b3407a9c7eafe696cbfe56141d4101f84d66053f9947351f1'
TRANSLATIONS = [
    ('Which lobe lies anterior to the central sulcus and is associated primarily with motor functions?',
     'The frontal lobe lies anterior to the central sulcus and is associated with motor functions.'),
    ('Which lobe lies posterior to the central sulcus and is associated with somatic sensation?',
     'The parietal lobe is associated with somatic sensation; the primary somatosensory cortex is in the postcentral gyrus.'),
    ('Which lobe contains the primary visual cortex?',
     'The primary visual cortex is in the occipital lobe.'),
    ('Which lobe is associated with primary auditory sensation rather than primary visual perception?',
     'OpenStax associates primary auditory sensation with the superior temporal lobe; primary visual perception is associated with the occipital lobe.'),
    ('Which of these structures lies in the medial temporal lobe and participates in long-term memory formation?',
     'OpenStax describes the hippocampus and amygdala as medial-lobe structures involved with memory and emotional responses.'),
    ('Which structure corresponds to the Latin term corpus amygdaloideum?',
     'In TA2, corpus amygdaloideum is the primary term for the amygdaloid body; amygdala is a synonym.'),
]


def main():
    draft_bytes = (ROOT / 'study/drafts/feedback43-anatomy-completion-20261019.json').read_bytes()
    assert hashlib.sha256(draft_bytes).hexdigest() == DRAFT_SHA
    receipt = json.loads((Path(__file__).parent / 'anatomy-completion-acceptance.json').read_text())
    assert receipt['decision'] == 'ACCEPT EXACTDRAFT' and receipt['draft_sha256'] == DRAFT_SHA
    assert receipt['reviewer_provider'] == 'google'
    path = ROOT / 'next/apps/quiz_app/assets/quizipedia/organ_atlas.json'
    original = path.read_bytes()
    assert hashlib.sha256(original.replace(b'\r\n', b'\n')).hexdigest() == BASE_SHA
    old = json.loads(original)
    result = copy.deepcopy(old)
    draft = json.loads(draft_bytes)
    entities = {e['id']: e for e in result['organs']}
    for update in draft['latin_name_updates']:
        entity = entities[update['entity_id']]
        assert entity['name_ru'] == update['name_ru'] and 'name_la' not in entity
        entity['name_la'] = update['proposed_name_la']
        entity['source_ids'] += [s for s in update['source_ids'] if s not in entity['source_ids']]
    for entity in draft['brain_regions']:
        assert entity['id'] not in entities and 'diagram_anchor' not in entity
        result['organs'].append(entity)
    for source in draft['sources']:
        assert source['id'] not in {s['id'] for s in old['sources']}
        result['sources'].append({'id': source['id'], 'title': source['title_ru'],
                                  'url': source['url'], 'checked_on': source['accessed']})
    for question, translation in zip(draft['questions'], TRANSLATIONS, strict=True):
        question = dict(question, stem_en=translation[0], explanation_en=translation[1])
        if question['topic'] == 'latin_name':
            question['topic'] = 'fact'
        result['questions'].append(question)
    result['coverage_note_ru'] = old['coverage_note_ru'].replace('69 учебных структур', '75 учебных структур').replace('9 отделов мозга', '15 отделов мозга')
    result['coverage_note_en'] = old['coverage_note_en'].replace('69 learning structures', '75 learning structures').replace('9 brain regions', '15 brain regions')
    assert len(result['organs']) == 75 and len(result['questions']) == 47
    assert result['questions'][:41] == old['questions']
    restored = copy.deepcopy(result['organs'][:69])
    for update in draft['latin_name_updates']:
        entity = next(e for e in restored if e['id'] == update['entity_id'])
        del entity['name_la']
        entity['source_ids'] = next(e['source_ids'] for e in old['organs'] if e['id'] == entity['id'])
    assert restored == old['organs']
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(json.dumps({'organs': 75, 'questions': 47, 'latin_updates': 14,
                      'old_questions_preserved': 41, 'draft_sha256': DRAFT_SHA}))


if __name__ == '__main__':
    main()
