"""Validate independently reviewed mini articles and export the local reader catalog."""
import argparse
import copy
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
OUTPUT = ROOT / 'next/apps/quiz_app/assets/study/question-articles.json'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def article_hash(article):
    return hashlib.sha256(json.dumps(article, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def question_from_snapshot(snapshots, ref, label):
    quiz_id = ref.get('quiz_id')
    question_id = ref.get('question_id')
    revision = ref.get('revision_sha256')
    require(isinstance(quiz_id, str) and isinstance(question_id, str), f'{label}: malformed question reference')
    require(isinstance(revision, str) and len(revision) == 64 and all(c in '0123456789abcdef' for c in revision), f'{label}: malformed revision')
    bundle = snapshots.get(quiz_id)
    require(bundle is not None, f'{label}: missing public snapshot')
    require(bundle.get('quiz', {}).get('quiz_id') == quiz_id, f'{label}: snapshot quiz mismatch')
    matches = [
        question for question in bundle['quiz'].get('questions', [])
        if question.get('question_id') == question_id and question.get('revision', {}).get('sha256') == revision
    ]
    require(len(matches) == 1, f'{label}: question revision is stale or unknown')
    return matches[0]


def apply_binding_overlay(articles, overlay, snapshots):
    """Append reviewed derived-bank references without altering accepted drafts."""
    result = copy.deepcopy(articles)
    by_id = {article['id']: article for article in result}
    require(len(by_id) == len(result), 'overlay: duplicate article id')
    bindings = set()
    for article in result:
        for ref in article['question_refs']:
            binding = ('question', ref['quiz_id'], ref['question_id'], ref['revision_sha256'])
            require(binding not in bindings, f'{article["id"]}: duplicate question binding')
            bindings.add(binding)
    for index, binding in enumerate(overlay):
        prefix = f'overlay[{index}]'
        require(set(binding) == {'article_id', 'original_article_sha256', 'source_ref', 'new_ref'}, f'{prefix}: schema')
        article = by_id.get(binding['article_id'])
        require(article is not None, f'{prefix}: unknown article')
        require(binding['original_article_sha256'] == article_hash(article), f'{prefix}: stale article sha')
        source_ref = binding['source_ref']
        new_ref = binding['new_ref']
        require(source_ref in article['question_refs'], f'{prefix}: source_ref is not an accepted article binding')
        old_question = question_from_snapshot(snapshots, source_ref, f'{prefix}: source_ref')
        new_question = question_from_snapshot(snapshots, new_ref, f'{prefix}: new_ref')
        require(old_question['question_id'] == new_question['question_id'] == source_ref['question_id'] == new_ref['question_id'], f'{prefix}: question_id changed')
        require(old_question.get('stem') == new_question.get('stem'), f'{prefix}: stem changed')
        require(old_question.get('answer_kind') == new_question.get('answer_kind'), f'{prefix}: answer_kind changed')
        require(old_question.get('options') == new_question.get('options'), f'{prefix}: options changed')
        target = ('question', new_ref['quiz_id'], new_ref['question_id'], new_ref['revision_sha256'])
        require(target not in bindings, f'{prefix}: duplicate question binding')
        bindings.add(target)
        article['question_refs'].append(copy.deepcopy(new_ref))
    return result


def public_snapshot(quiz_id):
    snapshot = HERE / 'snapshots' / f'{quiz_id}.json'
    if snapshot.is_file():
        return read(snapshot)
    canonical = ROOT / 'next/content' / quiz_id / 'bundle.json'
    require(canonical.is_file(), f'overlay: canonical bundle or captured public revision required for {quiz_id}')
    return read(canonical)


def minimum20_overlay(articles):
    bindings_path = HERE / 'bindings' / 'minimum20.json'
    if not bindings_path.is_file():
        return articles
    data = read(bindings_path)
    require(data.get('schema_version') == 'qm-question-article-bindings/v1', f'{bindings_path}: schema')
    overlay = data.get('bindings')
    require(isinstance(overlay, list), f'{bindings_path}: bindings')
    required_quizzes = {ref['quiz_id'] for item in overlay for ref in (item.get('source_ref', {}), item.get('new_ref', {})) if isinstance(ref, dict) and isinstance(ref.get('quiz_id'), str)}
    snapshots = {quiz_id: public_snapshot(quiz_id) for quiz_id in required_quizzes}
    return apply_binding_overlay(articles, overlay, snapshots)


def export():
    atlas = read(ROOT / 'next/apps/quiz_app/assets/quizipedia/catalog.json')
    targets = {
        'landmark': {row['id'] for row in atlas['landmarks']},
        'anatomy': {row['id'] for row in atlas['anatomy']['targets']},
        'constellation': {row['id'] for row in atlas['constellations']},
        'country': {row['id'] for row in atlas['countries']},
    }
    reviews = {}
    for path in sorted((HERE / 'reviews').glob('*.json')):
        review = read(path)
        require(review.get('reviewer') and review.get('author') and review['reviewer'] != review['author'], f'{path}: independent identities required')
        for item in review['articles']:
            require(item['article_id'] not in reviews, f'{path}: duplicate review')
            reviews[item['article_id']] = item
    published, seen, bindings = [], set(), set()
    for path in sorted((HERE / 'drafts').glob('*.json')):
        batch = read(path)
        require(batch.get('schema_version') == 'qm-question-articles/v1', f'{path}: schema')
        for article in batch['articles']:
            aid = article['id']
            require(aid not in seen, f'{aid}: duplicate article')
            seen.add(aid)
            verdict = reviews.get(aid)
            if verdict is None or verdict.get('verdict') != 'accept':
                continue
            require(verdict.get('article_sha256') == article_hash(article), f'{aid}: reviewed text changed')
            require(article.get('status') in {'draft', 'accepted'}, f'{aid}: status')
            for field in ('title_ru', 'body_ru'):
                require(isinstance(article.get(field), str) and article[field].strip(), f'{aid}: {field}')
            require(len(article['body_ru'].split()) >= 100, f'{aid}: substantive article required')
            require(r'\n\n' not in article['body_ru'], f'{aid}: literal paragraph escape; use actual newlines')
            sources = article['source_links']
            require(2 <= len(sources) <= 5, f'{aid}: 2-5 checked sources required')
            urls = set()
            for source in sources:
                url = urlparse(source['url'])
                require(url.scheme == 'https' and url.netloc and not url.username and not url.password, f'{aid}: source URL')
                require(source['url'] not in urls, f'{aid}: duplicate source')
                urls.add(source['url'])
                require(source.get('title') and source.get('supports') and source.get('accessed'), f'{aid}: source evidence')
            refs = article['target_refs']
            questions = article['question_refs']
            require(refs or questions, f'{aid}: no question/target binding')
            for ref in refs:
                require(ref.get('kind') == 'quizipedia' and ref.get('domain') in targets and ref.get('target_id') in targets[ref['domain']], f'{aid}: unknown target')
                binding = ('target', ref['domain'], ref['target_id'])
                require(binding not in bindings, f'{aid}: duplicate target binding')
                bindings.add(binding)
            for ref in questions:
                qid, question_id, revision = ref['quiz_id'], ref['question_id'], ref['revision_sha256']
                require(len(revision) == 64 and all(c in '0123456789abcdef' for c in revision), f'{aid}: exact question revision required')
                if qid.startswith('study-'):
                    study = read(ROOT / 'next/apps/quiz_app/assets/study/catalog.json')
                    matches = [q for m in study['modules'] if f"study-{m['id']}" == qid for q in m['questions'] if q['id'] == question_id and study_revision(q) == revision]
                else:
                    bundle_path = HERE / 'snapshots' / f'{qid}.json'
                    if not bundle_path.is_file():
                        bundle_path = ROOT / 'next/content' / qid / 'bundle.json'
                    require(bundle_path.is_file(), f'{aid}: canonical bundle or captured public revision required before publishing question article')
                    bundle = read(bundle_path)
                    require(bundle['quiz']['quiz_id'] == qid, f'{aid}: snapshot quiz mismatch')
                    matches = [q for q in bundle['quiz']['questions'] if q['question_id'] == question_id and q['revision']['sha256'] == revision]
                require(len(matches) == 1, f'{aid}: stale/unknown question revision')
                binding = ('question', qid, question_id, revision)
                require(binding not in bindings, f'{aid}: duplicate question binding')
                bindings.add(binding)
            published.append(article)
    require(set(reviews) <= seen, 'Review references unknown article')
    published = minimum20_overlay(published)
    for article in published:
        article['status'] = 'accepted'
    return {'schema_version': 'qm-question-articles/v1', 'articles': sorted(published, key=lambda a: a['id'])}


def study_revision(question):
    # Same fixed field order as the unranked Study reader's revision binding.
    value = {key: question[key] for key in ('id', 'text', 'options', 'correct_answer', 'explanation', 'source_refs')}
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--write', action='store_true')
    mode.add_argument('--check', action='store_true')
    args = parser.parse_args()
    data = export()
    content = json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    if args.write:
        OUTPUT.write_text(content, encoding='utf-8')
    else:
        require(read(OUTPUT) == data, 'Stale mini article catalog')
    print(f"PASS: {len(data['articles'])} independently reviewed mini articles; checked bindings, review hashes and source metadata")


if __name__ == '__main__':
    main()
