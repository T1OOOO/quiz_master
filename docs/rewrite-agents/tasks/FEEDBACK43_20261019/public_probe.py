"""Read-only verification of exact published assets and regional catalogs."""
import argparse
import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path


def fetch(path):
    with urllib.request.urlopen('https://quiz.kotopedia.org/' + path, timeout=30) as response:
        assert response.status == 200, path
        return response.read()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    web = args.package / 'web'
    expected = json.loads((web / 'version.json').read_text(encoding='utf-8'))
    assert json.loads(fetch('version.json')) == expected
    js_hash = hashlib.sha256(fetch('main.dart.js')).hexdigest()
    assert js_hash == expected['main_dart_js_sha256']
    for path in ['health/ready', 'health/live']:
        fetch(path)
    assets = ['assets/assets/catalog.json', 'assets/assets/study/question-articles.json',
              'assets/assets/quizipedia/organ_atlas.json']
    for path in assets:
        assert fetch(path) == (web / path).read_bytes(), path
    flags = sorted((web / 'flags').glob('*.png'))
    assert len(flags) == 195

    def verify_flag(path):
        data = fetch('flags/' + path.name)
        assert data.startswith(b'\x89PNG\r\n\x1a\n')
        assert hashlib.sha256(data).hexdigest() + '.png' == path.name

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(verify_flag, flags))
    regional = []
    for path in sorted((args.package / 'extra-quizzes').glob('*.json')):
        private = json.loads(path.read_text(encoding='utf-8-sig'))
        catalog = json.loads(fetch('v1/catalog?quiz_id=' + private['id']))
        public = catalog['quiz']
        assert public['quiz_id'] == private['id']
        assert len(public['questions']) == len(private['questions'])
        assert {q['question_id'] for q in public['questions']} == {q['id'] for q in private['questions']}
        assert 'private_grading' not in catalog
        regional.append({'quiz_id': private['id'], 'questions': len(public['questions'])})
    result = {'build_id': expected['buildId'], 'source_commit': expected['source_commit'],
              'main_dart_js_sha256': js_hash, 'health': 'ready/live HTTP200',
              'exact_static_assets': assets, 'flag_images_verified': len(flags),
              'regional_catalogs': regional}
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'build_id': result['build_id'], 'flags': len(flags), 'regional_catalogs': len(regional)}))


if __name__ == '__main__':
    main()
