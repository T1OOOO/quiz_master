"""Focused checks for rendering untrusted article text in the local reader."""
import unittest
from unittest.mock import patch

import build


class ReaderRenderingChecks(unittest.TestCase):
    def test_flutter_export_rejects_unreviewed_modules(self):
        modules = build.load_modules()
        modules[0]['metadata']['status'] = 'draft'
        with self.assertRaisesRegex(ValueError, 'accepted'):
            build.outputs(modules, include_flutter=True)

    def test_flutter_export_preserves_questions_and_source_links(self):
        modules = build.load_modules()
        for module in modules:
            module['metadata']['status'] = 'accepted'
        import json
        generated = build.outputs(modules, include_flutter=True)
        path = build.ROOT.parent / 'next/apps/quiz_app/assets/study/catalog.json'
        self.assertIn(path, list(generated))
        payload = json.loads(generated[path])
        self.assertEqual(len(payload['modules']), 4)
        for module in payload['modules']:
            self.assertEqual(len(module['questions']), 20)
            self.assertIn('resource:assets/study/', module['article_markdown'])
            self.assertTrue(module['sources'])
            self.assertNotIn('status', module)
            self.assertNotIn('html', module)
            self.assertTrue(all(q['source_refs'] for q in module['questions']))

    def test_invalid_module_id_is_rejected_even_when_python_is_optimized(self):
        original = build.read_json
        def invalid_metadata(path):
            value = original(path)
            if path.name == 'module.json':
                value['id'] = 'invalid-id'
            return value
        with patch.object(build, 'read_json', invalid_metadata):
            with self.assertRaisesRegex(ValueError, 'module id'):
                build.load_modules()

    def test_payload_marker_must_exist_exactly_once(self):
        for template in ('const modules = [];', '/*__STUDY_PAYLOAD__*/[]' * 2):
            with self.subTest(template=template):
                with patch.object(build.Path, 'read_text', return_value=template):
                    with self.assertRaisesRegex(ValueError, 'payload marker'):
                        build.outputs([])

    def test_raw_html_and_unsafe_links_cannot_execute(self):
        output = build.markdown(
            '# Sample\n\n<script>alert(1)</script>\n\n'
            '[bad](javascript:alert)\n\n[good](https://example.org/)'
        )
        self.assertNotIn('<script>', output)
        self.assertNotIn('href="javascript:', output)
        self.assertIn('&lt;script&gt;', output)
        self.assertIn('href="https://example.org/"', output)

    def test_article_images_and_tables_keep_valid_reader_paths(self):
        output = build.markdown(
            '![Landscape](../../assets/nature-hero.png)\n\n'
            '| A | B |\n|---|---|\n| X | Y |'
        )
        self.assertIn('src="../assets/nature-hero.png"', output)
        self.assertIn('<table>', output)
        self.assertIn('<td>X</td>', output)
        self.assertEqual(output.count('<table>'), output.count('</table>'))

    def test_embedded_payload_cannot_close_script_element(self):
        module = {
            'metadata': {'id': 'example', 'title': '</script><script>bad()</script>',
                         'description': 'example', 'category': 'example'},
            'html': '<p>example</p>', 'questions': [],
        }
        output = build.outputs([module])[build.ROOT / 'site' / 'index.html']
        self.assertIn('\\u003c/script>', output)
        self.assertEqual(output.count('</script>'), 1)


if __name__ == '__main__':
    unittest.main()
