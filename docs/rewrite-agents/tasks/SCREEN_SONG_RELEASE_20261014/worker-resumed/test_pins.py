import json
import tempfile
import unittest
from pathlib import Path
import prepare_screen_song_release as p

SCRATCH=Path('C:/ap/quiz_master/.run/screen_song_controller_resumed_20261014')


def inert_complete_pins(**overrides):
    files = {
        p.RAW_PATH: 'a'*64,
        **{f'next/content/{p.SCREEN_SONG_ID}/{name}.json': 'b'*64 for name in ('draft','bundle','manifest')},
        f'study/question_articles/drafts/{p.SCREEN_SONG_ID}.json': 'c'*64,
        f'study/question_articles/reviews/{p.SCREEN_SONG_ID}-review.json': 'd'*64,
        'next/apps/quiz_app/assets/catalog.json': 'e'*64,
        'next/apps/quiz_app/assets/study/question-articles.json': 'f'*64,
    }
    pins = {
        'schema_version': 'qm-screen-song-release-pins/v1',
        'frozen_commit': '1'*40,
        'build_id': 'quiz-2026.10.14-screen-song-1111111',
        'frozen_files': files,
        'article_refs': {f'screen-song-pilot-{number:03d}': str(number)*64 for number in range(1,5)},
        'normalized_source_sha256': '2'*64,
        'production_js_sha256': '3'*64,
        'qa_js_sha256': '4'*64,
        'production_web': 'C:/inert/production-web',
        'qa_web': 'C:/inert/qa-web',
        'build_evidence': 'C:/inert/build-evidence.json',
        'build_evidence_sha256': '5'*64,
        'source_review': {'path': 'C:/inert/source-review.json', 'sha256': '6'*64},
        'export_review': {'path': 'C:/inert/export-review.json', 'sha256': '7'*64},
    }
    pins.update(overrides)
    return pins

class MissingPinsTests(unittest.TestCase):
    def test_missing_file_is_rejected(self):
        with self.assertRaisesRegex((RuntimeError,FileNotFoundError),'pins|No such file'):
            p.load_required_pins(SCRATCH/'missing-release-pins.json')

    def test_missing_full_pins_are_rejected(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            path=Path(directory)/'pins.json';path.write_text('{}')
            with self.assertRaisesRegex(RuntimeError,'pins'):
                p.load_required_pins(path)

    def test_actor_source_cannot_be_used_as_screen_song_target(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            path=Path(directory)/'pins.json'
            path.write_text(json.dumps(inert_complete_pins(
                frozen_commit=p.BASELINE_SOURCE_COMMIT,
                build_id='quiz-2026.10.14-screen-song-83748f5',
            )))
            with self.assertRaisesRegex(RuntimeError,'fresh final Screen Song source'):
                p.load_required_pins(path)

    def test_complete_shape_with_non_hash_values_is_rejected(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            path=Path(directory)/'pins.json'
            path.write_text(json.dumps(inert_complete_pins(normalized_source_sha256='not-a-hash')))
            with self.assertRaisesRegex(RuntimeError,'full SHA256'):
                p.load_required_pins(path)

    def test_fresh_reviewed_source_reaches_real_review_gate(self):
        with tempfile.TemporaryDirectory(dir=SCRATCH) as directory:
            path=Path(directory)/'pins.json'
            path.write_text(json.dumps(inert_complete_pins(
                frozen_commit='6866608bd7c20ceff2b454970b315eaee86329a9',
                build_id='quiz-2026.10.14-screen-song-6866608',
            )))
            # This is not an acceptance fixture: its review path is deliberately
            # absent. Reaching this FileNotFoundError proves the identity guard
            # permits the fresh source and that real review evidence remains
            # mandatory before package preparation.
            with self.assertRaises(FileNotFoundError):
                p.load_required_pins(path)

if __name__=='__main__':unittest.main()
