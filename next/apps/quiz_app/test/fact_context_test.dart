import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';

void main() {
  test(
    'historical name dates ask a direct question instead of a field label',
    () {
      const fact = StudyFact(
        id: 'cadabra',
        scope: 'brands',
        entityId: 'amazon',
        nameRu: 'Амазон',
        nameEn: 'Amazon',
        fieldPath: 'former_names.0.from_year',
        fieldRu: 'Начало названия: Кадабра',
        fieldEn: 'Name start: Cadabra',
        valueRu: '1994',
        valueEn: '1994',
        sources: [],
      );
      expect(
        factQuestionPrompt(fact, russian: true),
        'С какого года «Амазон» использовал название «Кадабра»?',
      );
    },
  );
  test('checked facts retain sourced context and the identity of every alternative', () {
    final facts = [
      for (var i = 0; i < 6; i++)
        StudyFact(
          id: 'year-$i',
          scope: 'brands',
          entityId: 'brand-$i',
          nameRu: 'Бренд $i',
          nameEn: 'Brand $i',
          fieldPath: 'founded_year',
          fieldRu: 'Основание',
          fieldEn: 'Founded',
          valueRu: '${1900 + i}',
          valueEn: '${1900 + i}',
          sources: const [],
        ),
      for (var i = 0; i < 6; i++)
        StudyFact(
          id: 'note-$i',
          scope: 'brands',
          entityId: 'brand-$i',
          nameRu: 'Бренд $i',
          nameEn: 'Brand $i',
          fieldPath: 'date_note',
          fieldRu: 'Примечание о дате',
          fieldEn: 'Date note',
          valueRu: 'Примечание компании $i',
          valueEn: 'Company note $i',
          sources: const [],
        ),
    ];
    final question = buildFactQuestions(facts)
        .firstWhere((q) => q.fact.id == 'year-0');
    expect(question.contextFacts.single.id, 'note-0');
    expect(question.options, hasLength(6));
    for (final option in question.options) {
      expect(option.reference?.id, option.id);
    }
  });
}
