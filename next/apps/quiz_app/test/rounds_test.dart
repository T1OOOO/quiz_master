import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test('round counts and slices retain every selected question once', () {
    const cases = {
      0: <int>[],
      1: [1],
      19: [19],
      20: [20],
      21: [21],
      39: [39],
      40: [20, 20],
      41: [20, 21],
      61: [20, 20, 21],
    };
    for (final entry in cases.entries) {
      final questions = entry.key;
      final sizes = entry.value;
      expect(
        questionRoundCount(questions),
        sizes.length,
        reason: '$questions items',
      );

      var partitioned = 0;
      for (var round = 0; round < sizes.length; round++) {
        expect(
          questionCountInRound(questions, round),
          sizes[round],
          reason: '$questions items, round $round',
        );
        partitioned += questionCountInRound(questions, round);
      }
      expect(partitioned, questions, reason: '$questions items');
      expect(questionCountInRound(questions, sizes.length), 0);
      expect(questionCountInRound(questions, -1), 0);
    }
  });
}
