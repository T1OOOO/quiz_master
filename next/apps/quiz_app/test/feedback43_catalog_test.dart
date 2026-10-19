import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'shipped catalog preserves difficulty choices and regional topics',
    () async {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/catalog.json'),
      ) as List;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final packs = await container.read(discoveryCatalogProvider.future);
      expect(packs, hasLength(144));
      expect(packs.fold<int>(0, (sum, p) => sum + p.questions), 4486);
      for (final row in raw.cast<Map<String, dynamic>>()) {
        final counts = row['difficulty_counts'] as Map<String, dynamic>;
        expect(counts.keys.toSet(), {
          'easy',
          'medium',
          'hard',
          'nightmare',
          'unknown',
        });
        expect(
          counts.values.cast<int>().reduce((a, b) => a + b),
          row['questions_count'],
        );
      }
      for (final band in DifficultyBand.values) {
        expect(
          packs.where((p) => (p.count(band) ?? 0) > 0),
          isNotEmpty,
          reason: 'Actual catalog must remain browseable for ${band.wireName}',
        );
      }
      final regional = packs.where(
        (p) => RegExp(
          r'^prep-(capitals|flags)-(europe|africa|americas|asia-oceania)$',
        ).hasMatch(p.id),
      );
      expect(regional, hasLength(8));
      expect(regional.every((p) => p.questions >= 20), isTrue);
    },
  );
}
