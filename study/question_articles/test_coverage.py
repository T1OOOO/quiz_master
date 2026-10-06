"""Coverage must not certify an article for an obsolete question revision."""
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import coverage


class RevisionCoverageTest(unittest.TestCase):
    def fixture(self, root, article_revision, current_revision):
        def write(path, value):
            target = root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(value), encoding='utf-8')

        write('next/apps/quiz_app/assets/catalog.json', [{'quiz_id': 'quiz-one', 'questions_count': 1}])
        importer = root / 'next/server/internal/content/import.go'
        importer.parent.mkdir(parents=True)
        importer.write_text('var legacyQuizIDs = map[string]string{}', encoding='utf-8')
        write('quizzes/one.json', {'id': 'quiz-one', 'questions': [{'id': 'q-one', 'text': 'Question'}]})
        write('next/content/quiz-one/bundle.json', {'quiz': {'quiz_id': 'quiz-one', 'questions': [{'question_id': 'q-one', 'revision': {'sha256': current_revision}}]}})
        write('next/apps/quiz_app/assets/study/catalog.json', {'modules': []})
        write('next/apps/quiz_app/assets/quizipedia/catalog.json', {'map_target_ids': [], 'countries': [], 'anatomy': {'targets': []}, 'landmarks': [], 'constellations': []})
        article = {'id': 'article-one', 'question_refs': [{'quiz_id': 'quiz-one', 'question_id': 'q-one', 'revision_sha256': article_revision}], 'target_refs': []}
        write('articles/drafts/one.json', {'articles': [article]})
        write('next/apps/quiz_app/assets/study/question-articles.json', {'articles': [article]})
        with patch.object(coverage, 'ROOT', root), patch.object(coverage, 'HERE', root / 'articles'), contextlib.redirect_stdout(io.StringIO()):
            coverage.main()
        return json.loads((root / 'articles/coverage.json').read_text(encoding='utf-8'))

    def test_changed_revision_requires_new_article(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.fixture(Path(directory), 'a' * 64, 'b' * 64)
        self.assertEqual(result['counts']['accepted'], 0)
        self.assertEqual(result['entries'][0]['status'], 'missing')
        self.assertIsNone(result['entries'][0]['article_id'])

    def test_exact_revision_is_covered(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.fixture(Path(directory), 'a' * 64, 'a' * 64)
        self.assertEqual(result['counts']['accepted'], 1)
        self.assertEqual(result['entries'][0]['article_id'], 'article-one')


if __name__ == '__main__':
    unittest.main()
