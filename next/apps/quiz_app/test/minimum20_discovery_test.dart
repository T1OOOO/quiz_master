import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test('ordinary quiz rounds require twenty and keep larger remainders', () {
    expect(questionRoundCount(19), 0);
    expect(questionRoundCount(20), 1);
    expect(questionRoundCount(41), 2);
    expect(questionCountInRound(41, 1), 21);
  });

  testWidgets('difficulty shows only packs with twenty matching questions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryCatalogProvider.overrideWith(
            (ref) async => const [
              CatalogPack(
                'short-band',
                'Short band',
                'Description',
                'Разное',
                40,
                {DifficultyBand.medium: 19},
              ),
              CatalogPack(
                'full-band',
                'Full band',
                'Description',
                'Разное',
                40,
                {DifficultyBand.medium: 20},
              ),
            ],
          ),
        ],
        child: const QuizApp(initialLocation: '/library?difficulty=medium'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-short-band')), findsNothing);
    expect(find.byKey(const Key('pack-full-band')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
