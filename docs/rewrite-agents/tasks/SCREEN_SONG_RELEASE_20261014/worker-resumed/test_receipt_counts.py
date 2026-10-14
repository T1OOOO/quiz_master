"""Pure receipt-count contract: target facts and preserved-baseline facts differ."""
import unittest

import prepare_screen_song_release as producer


class ReceiptCountsTests(unittest.TestCase):
    def test_target_receipt_counts_do_not_restate_actor51_baseline(self):
        self.assertEqual(
            producer.TARGET_RECEIPT_COUNTS,
            {"packs": 135, "questions": 4064, "reader_articles": 264},
        )
        self.assertEqual(
            producer.PRESERVED_BASELINE_COUNTS,
            {"preserved_catalog_rows": 134, "preserved_questions": 4060, "preserved_article_objects": 260},
        )
        self.assertNotEqual(producer.TARGET_RECEIPT_COUNTS["packs"], producer.PRESERVED_BASELINE_COUNTS["preserved_catalog_rows"])
        self.assertNotEqual(producer.TARGET_RECEIPT_COUNTS["questions"], producer.PRESERVED_BASELINE_COUNTS["preserved_questions"])
        self.assertNotEqual(producer.TARGET_RECEIPT_COUNTS["reader_articles"], producer.PRESERVED_BASELINE_COUNTS["preserved_article_objects"])


if __name__ == "__main__":
    unittest.main()
