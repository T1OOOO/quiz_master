import copy
import importlib.util
import unittest
from pathlib import Path


BUILD_PATH = Path(__file__).with_name('build.py')
spec = importlib.util.spec_from_file_location('question_articles_build', BUILD_PATH)
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class Minimum20BindingTests(unittest.TestCase):
    def setUp(self):
        self.old_ref = {
            'quiz_id': 'legacy-pack',
            'question_id': 'q1',
            'revision_sha256': 'a' * 64,
        }
        self.new_ref = {
            'quiz_id': 'derived-pack',
            'question_id': 'q1',
            'revision_sha256': 'b' * 64,
        }
        self.article = {
            'id': 'article-1',
            'title_ru': 'Title',
            'body_ru': ' '.join(['word'] * 100),
            'source_links': [],
            'status': 'accepted',
            'target_refs': [],
            'question_refs': [self.old_ref],
        }
        self.overlay = [{
            'article_id': self.article['id'],
            'original_article_sha256': build.article_hash(self.article),
            'source_ref': self.old_ref,
            'new_ref': self.new_ref,
        }]
        self.snapshots = {
            'legacy-pack': self.quiz('legacy-pack', self.old_ref['revision_sha256']),
            'derived-pack': self.quiz('derived-pack', self.new_ref['revision_sha256']),
        }

    @staticmethod
    def quiz(quiz_id, revision, *, stem='What is the answer?', options=None):
        return {
            'quiz': {
                'quiz_id': quiz_id,
                'questions': [{
                    'question_id': 'q1',
                    'revision': {'sha256': revision},
                    'stem': stem,
                    'answer_kind': 'single_choice',
                    'options': options or [
                        {'option_id': 'a', 'text': 'A'},
                        {'option_id': 'b', 'text': 'B'},
                    ],
                }],
            },
        }

    def apply(self, *, overlay=None, snapshots=None, articles=None):
        return build.apply_binding_overlay(
            copy.deepcopy(articles or [self.article]),
            copy.deepcopy(overlay or self.overlay),
            copy.deepcopy(snapshots or self.snapshots),
        )

    def test_valid_overlay_appends_target_ref_without_mutating_accepted_article(self):
        result = self.apply()
        self.assertEqual([self.old_ref], self.article['question_refs'])
        self.assertEqual([self.old_ref, self.new_ref], result[0]['question_refs'])

    def test_wrong_target_revision_is_rejected(self):
        overlay = copy.deepcopy(self.overlay)
        overlay[0]['new_ref']['revision_sha256'] = 'c' * 64
        with self.assertRaisesRegex(ValueError, 'new_ref.*revision'):
            self.apply(overlay=overlay)

    def test_changed_target_stem_is_rejected(self):
        snapshots = copy.deepcopy(self.snapshots)
        snapshots['derived-pack'] = self.quiz('derived-pack', 'b' * 64, stem='A changed stem')
        with self.assertRaisesRegex(ValueError, 'stem'):
            self.apply(snapshots=snapshots)

    def test_changed_target_options_are_rejected(self):
        snapshots = copy.deepcopy(self.snapshots)
        snapshots['derived-pack'] = self.quiz(
            'derived-pack', 'b' * 64,
            options=[{'option_id': 'a', 'text': 'Changed'}, {'option_id': 'b', 'text': 'B'}],
        )
        with self.assertRaisesRegex(ValueError, 'options'):
            self.apply(snapshots=snapshots)

    def test_stale_accepted_article_hash_is_rejected(self):
        overlay = copy.deepcopy(self.overlay)
        overlay[0]['original_article_sha256'] = 'f' * 64
        with self.assertRaisesRegex(ValueError, 'article sha'):
            self.apply(overlay=overlay)

    def test_duplicate_target_binding_is_rejected(self):
        second = copy.deepcopy(self.article)
        second['id'] = 'article-2'
        second['question_refs'] = [self.new_ref]
        duplicate = copy.deepcopy(self.overlay[0])
        duplicate['article_id'] = second['id']
        duplicate['original_article_sha256'] = build.article_hash(second)
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            self.apply(articles=[self.article, second], overlay=[self.overlay[0], duplicate])


if __name__ == '__main__':
    unittest.main()
