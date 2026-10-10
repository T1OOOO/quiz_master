import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

BUILD_PATH = Path(__file__).with_name('build.py')
spec = importlib.util.spec_from_file_location('question_articles_build', BUILD_PATH)
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class BundleResolutionTests(unittest.TestCase):
    def export_fixture(self, root, *, snapshot_revision, canonical_revision):
        here = root / 'study' / 'question_articles'
        (here / 'drafts').mkdir(parents=True)
        (here / 'reviews').mkdir()
        (here / 'snapshots').mkdir()
        quiz_id, question_id = 'legacy-pack', 'q1'
        atlas = {'landmarks': [], 'anatomy': {'targets': []}, 'constellations': [], 'countries': []}
        (root / 'next' / 'apps' / 'quiz_app' / 'assets' / 'quizipedia').mkdir(parents=True)
        (root / 'next' / 'apps' / 'quiz_app' / 'assets' / 'quizipedia' / 'catalog.json').write_text(json.dumps(atlas))
        question = lambda revision: {'question_id': question_id, 'revision': {'sha256': revision}}
        for folder, revision in [('snapshots', snapshot_revision), ('canonical', canonical_revision)]:
            bundle = {'quiz': {'quiz_id': quiz_id, 'questions': [question(revision)]}}
            path = here / 'snapshots' / f'{quiz_id}.json' if folder == 'snapshots' else root / 'next' / 'content' / quiz_id / 'bundle.json'
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(bundle), encoding='utf-8')
        article = {
            'id': 'article-1', 'title_ru': 'Title', 'body_ru': ' '.join(['word'] * 100),
            'source_links': [{'url': 'https://example.org', 'title': 'Source', 'supports': 'Claim', 'accessed': '2026-10-11'}, {'url': 'https://example.net', 'title': 'Source 2', 'supports': 'Claim', 'accessed': '2026-10-11'}],
            'status': 'draft', 'target_refs': [], 'question_refs': [{'quiz_id': quiz_id, 'question_id': question_id, 'revision_sha256': snapshot_revision}],
        }
        (here / 'drafts' / 'draft.json').write_text(json.dumps({'schema_version': 'qm-question-articles/v1', 'articles': [article]}), encoding='utf-8')
        review = {'author': 'writer', 'reviewer': 'reviewer', 'articles': [{'article_id': 'article-1', 'article_sha256': build.article_hash(article), 'verdict': 'accept'}]}
        (here / 'reviews' / 'review.json').write_text(json.dumps(review), encoding='utf-8')
        return here

    def test_snapshot_wins_when_canonical_has_another_revision(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            here = self.export_fixture(root, snapshot_revision='a' * 64, canonical_revision='b' * 64)
            with patch.object(build, 'ROOT', root), patch.object(build, 'HERE', here):
                self.assertEqual(['article-1'], [a['id'] for a in build.export()['articles']])

    def test_canonical_fallback_when_snapshot_is_absent(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            here = self.export_fixture(root, snapshot_revision='a' * 64, canonical_revision='a' * 64)
            (here / 'snapshots' / 'legacy-pack.json').unlink()
            with patch.object(build, 'ROOT', root), patch.object(build, 'HERE', here):
                self.assertEqual(['article-1'], [a['id'] for a in build.export()['articles']])


if __name__ == '__main__':
    unittest.main()
