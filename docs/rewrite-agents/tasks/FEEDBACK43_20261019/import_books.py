"""Append an independently accepted draft; preserve all 30 published questions."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / 'quizzes/Preparation/prep_books_modern.json'
DRAFT = ROOT / 'study/drafts/feedback43-books-medium-20261019.json'
BASE_SHA = 'e6a7d15cdd9e450cc853860845e6ed1ca445093607a0abae71b768d61b51c52d'


def candidate(source, draft):
    assert source['id'] == draft['target_pack'] == 'preparation-books-modern'
    old = source['questions']
    assert len(old) == 30 and len(draft['questions']) == 12
    existing = {q['id'] for q in old}
    additions = []
    for question in draft['questions']:
        assert question['id'] not in existing
        existing.add(question['id'])
        assert question['difficulty'] == 4 and question['type'] == 'choice'
        assert len(question['options']) == 4 and 0 <= question['correct_answer'] < 4
        assert len(set(question['options'])) == 4
        item = {k: question[k] for k in (
            'id', 'type', 'text', 'options', 'correct_answer', 'difficulty', 'explanation')}
        # The source envelope retains the reviewed option-by-option rationale.
        # The legacy reader has one explanation field, so include those facts there.
        wrong = [f'{option}: {reason}' for index, (option, reason) in enumerate(
            zip(question['options'], question['distractor_rationale'], strict=True))
            if index != question['correct_answer']]
        item['explanation'] += ' Другие варианты: ' + '; '.join(wrong)
        additions.append(item)
    assert {r['question_id'] for r in draft['source_records']} == {q['id'] for q in additions}
    result = dict(source, questions=old + additions,
                  description='42 вопроса о послевоенной и современной литературе: авторы, герои, сюжеты и премии. 22 лёгких и 20 средних вопросов с объяснениями.')
    assert result['questions'][:30] == old
    assert sum(q['difficulty'] <= 3 for q in result['questions']) == 22
    assert sum(q['difficulty'] == 4 for q in result['questions']) == 20
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--acceptance', type=Path)
    args = parser.parse_args()
    source_bytes = SOURCE.read_bytes()
    assert hashlib.sha256(source_bytes.replace(b'\r\n', b'\n')).hexdigest() == BASE_SHA
    draft_bytes = DRAFT.read_bytes()
    result = candidate(json.loads(source_bytes), json.loads(draft_bytes))
    digest = hashlib.sha256(draft_bytes).hexdigest()
    if args.apply:
        assert args.acceptance, 'A different-provider acceptance receipt is required'
        receipt = json.loads(args.acceptance.read_text(encoding='utf-8'))
        assert receipt['decision'] == 'ACCEPT EXACTDRAFT'
        assert receipt['draft_sha256'] == digest
        assert receipt['reviewer_provider'] != 'openai'
        SOURCE.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n',
                          encoding='utf-8', newline='\n')
    print(json.dumps({'applied': args.apply, 'draft_sha256': digest,
                      'questions': len(result['questions']), 'easy': 22, 'medium': 20}))


if __name__ == '__main__':
    main()
