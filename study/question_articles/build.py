"""Validate independently reviewed mini articles and export the local reader catalog."""
import argparse
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
                    bundle_path = ROOT / 'next/content' / qid / 'bundle.json'
                    if not bundle_path.is_file():
                        bundle_path = HERE / 'snapshots' / f'{qid}.json'
                    require(bundle_path.is_file(), f'{aid}: canonical bundle or captured public revision required before publishing question article')
                    bundle = read(bundle_path)
                    require(bundle['quiz']['quiz_id'] == qid, f'{aid}: snapshot quiz mismatch')
                    matches = [q for q in bundle['quiz']['questions'] if q['question_id'] == question_id and q['revision']['sha256'] == revision]
                require(len(matches) == 1, f'{aid}: stale/unknown question revision')
                binding = ('question', qid, question_id, revision)
                require(binding not in bindings, f'{aid}: duplicate question binding')
                bindings.add(binding)
            published.append({**article, 'status': 'accepted'})
    require(set(reviews) <= seen, 'Review references unknown article')
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
