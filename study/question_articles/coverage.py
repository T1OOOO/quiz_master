"""Editorial backlog for every current question/visual target, never an article generator."""
import json
import re
from pathlib import Path
from build import ROOT, HERE, read, study_revision


def stable_id(value):
    value = re.sub('[^a-z0-9-]+', '-', value.lower()).strip('-')
    return 'id-' + value if value and (len(value) < 3 or not 'a' <= value[0] <= 'z') else value


def main():
    catalog = {q['quiz_id']: q for q in read(ROOT / 'next/apps/quiz_app/assets/catalog.json')}
    # Reuse the importer's explicit exceptional identities, including Cyrillic food topics.
    importer = (ROOT / 'next/server/internal/content/import.go').read_text(encoding='utf-8')
    exceptions = dict(re.findall(r'"([^"]+)":\s*"([^"]+)",', importer.split('var legacyQuizIDs =')[1].split('}')[0]))
    revisions = {}
    for path in sorted((ROOT / 'next/content').glob('*/bundle.json')) + sorted((HERE / 'snapshots').glob('*.json')):
        quiz = read(path)['quiz']
        for question in quiz['questions']:
            revisions[(quiz['quiz_id'], question['question_id'])] = question['revision']['sha256']
    drafted, accepted = {}, {}
    for folder, destination in [(HERE / 'drafts', drafted)]:
        for path in sorted(folder.glob('*.json')):
            for article in read(path)['articles']:
                for ref in article['question_refs']:
                    destination[('question', ref['quiz_id'], ref['question_id'], ref['revision_sha256'])] = article['id']
                for ref in article['target_refs']:
                    destination[('target', ref['domain'], ref['target_id'])] = article['id']
    for article in read(ROOT / 'next/apps/quiz_app/assets/study/question-articles.json')['articles']:
        for ref in article['question_refs']:
            accepted[('question', ref['quiz_id'], ref['question_id'], ref['revision_sha256'])] = article['id']
        for ref in article['target_refs']:
            accepted[('target', ref['domain'], ref['target_id'])] = article['id']
    entries = []
    seen_packs = set()
    for path in sorted((ROOT / 'quizzes').rglob('*.json')):
        raw = read(path)
        qid = exceptions.get(raw['id'], stable_id(raw['id']))
        assert qid in catalog and qid not in seen_packs, f'Unknown/duplicate pack {qid}'
        seen_packs.add(qid)
        assert len(raw['questions']) == catalog[qid]['questions_count'], f'Count mismatch {qid}'
        for q in raw['questions']:
            question_id = stable_id(q['id'])
            entries.append({'kind': 'question', 'quiz_id': qid, 'question_id': question_id,
                'revision_sha256': revisions.get((qid, question_id)), 'source_path': str(path.relative_to(ROOT)).replace('\\', '/'), 'stem': q['text']})
    assert seen_packs == set(catalog), 'Missing packs'
    study = read(ROOT / 'next/apps/quiz_app/assets/study/catalog.json')
    for module in study['modules']:
        for q in module['questions']:
            entries.append({'kind': 'question', 'quiz_id': f"study-{module['id']}", 'question_id': q['id'],
                'revision_sha256': study_revision(q), 'source_path': 'next/apps/quiz_app/assets/study/catalog.json', 'stem': q['text']})
    atlas = read(ROOT / 'next/apps/quiz_app/assets/quizipedia/catalog.json')
    train = set(atlas['map_target_ids'])
    for domain, targets in [('country', atlas['countries']), ('anatomy', atlas['anatomy']['targets']), ('landmark', atlas['landmarks']), ('constellation', atlas['constellations'])]:
        for target in targets:
            entries.append({'kind': 'target', 'domain': domain, 'target_id': target['id'], 'title': target['name_ru'], 'training': domain != 'country' or target['id'] in train})
    keys = set()
    for entry in entries:
        key = ('question', entry['quiz_id'], entry['question_id'], entry['revision_sha256']) if entry['kind'] == 'question' else ('target', entry['domain'], entry['target_id'])
        assert key not in keys, f'Duplicate reference {key}'
        keys.add(key)
        entry['article_id'] = accepted.get(key) or drafted.get(key)
        entry['status'] = 'accepted' if key in accepted else 'draft' if key in drafted else 'missing'
    counts = {status: sum(e['status'] == status for e in entries) for status in ('missing', 'draft', 'accepted')}
    result = {'schema_version': 'qm-article-coverage/v1', 'note': 'Exact unrecorded ranked revisions are null; capture actual public DTO before authoring/publishing. Accepted means reviewed local catalog, not production deployment.', 'counts': counts, 'entries': entries}
    (HERE / 'coverage.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'packs': len(catalog), 'quiz_questions': sum(q['questions_count'] for q in catalog.values()), 'study_questions': sum(len(m['questions']) for m in study['modules']), 'visual_targets': len(entries) - sum(q['questions_count'] for q in catalog.values()) - sum(len(m['questions']) for m in study['modules']), 'counts': counts}))


if __name__ == '__main__':
    main()
