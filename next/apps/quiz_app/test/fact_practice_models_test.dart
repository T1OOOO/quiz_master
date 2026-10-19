import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads every frozen scope and preserves the known coverage gaps',
    () async {
      final facts = await loadStudyFacts('all');
      const scopes = {
        'countries',
        'sky',
        'endocrine',
        'landmarks',
        'music',
        'organs',
        'greek',
        'religions',
        'food',
        'brands',
        'history',
        'works',
        'people',
      };
      expect(facts.map((fact) => fact.scope).toSet(), containsAll(scopes));
      expect(
        facts
            .where((fact) => fact.scope == 'music')
            .map((fact) => fact.entityId)
            .toSet(),
        hasLength(95),
      );
      expect(
        facts
            .where((fact) => fact.scope == 'organs')
            .map((fact) => fact.entityId)
            .toSet(),
        hasLength(281),
      );
      expect(
        facts.where(
          (fact) => fact.scope == 'food' && fact.fieldPath.startsWith('steps.'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.scope == 'food' && fact.fieldPath.startsWith('ingredients.'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) => fact.scope == 'food' && fact.fieldPath.startsWith('facts.'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.scope == 'countries' &&
              fact.fieldPath.startsWith('languages.'),
        ),
        isNotEmpty,
      );
      for (final prefix in [
        'official_languages.',
        'neighbors.',
        'religion_shares.',
        'links.',
        'culture.',
        'waters.',
        'president.',
      ]) {
        expect(
          facts.where(
            (fact) =>
                fact.scope == 'countries' && fact.fieldPath.startsWith(prefix),
          ),
          isNotEmpty,
        );
      }
      expect(
        facts.where(
          (fact) => fact.scope == 'sky' && fact.fieldPath.contains('stars.'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.scope == 'religions' && fact.fieldPath.startsWith('facts.'),
        ),
        isNotEmpty,
      );
      expect(
        facts.every(
          (fact) =>
              fact.sources.isNotEmpty &&
              fact.valueRu.trim().isNotEmpty &&
              fact.valueEn.trim().isNotEmpty,
        ),
        isTrue,
      );
    },
  );

  test(
    'keeps item qualifiers, true country neighbours, and reviewed guards',
    () async {
      final facts = await loadStudyFacts('all');
      expect(
        facts.where((fact) => fact.fieldPath.startsWith('neighbors.')),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.startsWith('links.') &&
              fact.fieldRu.contains('Соседняя'),
        ),
        isEmpty,
      );
      expect(
        facts.any(
          (fact) =>
              fact.fieldPath.startsWith('religion_shares.') &&
              fact.fieldRu.contains(':'),
        ),
        isTrue,
      );
      expect(
        facts.any(
          (fact) =>
              fact.fieldPath.contains('stars.') &&
              fact.fieldPath.endsWith('.magnitude') &&
              fact.fieldRu.contains('звезды'),
        ),
        isTrue,
      );
      expect(
        facts.any(
          (fact) =>
              fact.fieldPath.contains('ingredients.') &&
              fact.fieldPath.endsWith('.amount') &&
              fact.fieldRu.contains('ингредиента'),
        ),
        isTrue,
      );
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.contains('variants.') &&
              fact.fieldPath.endsWith('.region') &&
              fact.fieldRu.contains(':'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.contains('former_names.') &&
              fact.fieldPath.endsWith('.note') &&
              fact.fieldRu.contains(':'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.contains('logo_history.') &&
              fact.fieldPath.endsWith('.text') &&
              fact.fieldRu.contains(':'),
        ),
        isNotEmpty,
      );
      final relations = facts
          .where((fact) => fact.fieldPath.endsWith('.relation'))
          .toList();
      expect(relations, isNotEmpty);
      expect(relations.every((fact) => fact.fieldRu.contains(':')), isTrue);
      expect(relations.every((fact) => fact.fieldEn.contains(':')), isTrue);
      expect(
        relations.map((fact) => fact.entityId).toSet().length,
        relations.length,
      );
      final factsById = {for (final fact in facts) fact.id: fact};
      for (final question in buildFactQuestions(
        facts,
        seed: 31,
      ).where((question) => question.fact.fieldPath.endsWith('.relation'))) {
        expect(
          question.options.every(
            (option) => factsById[option.id]!.fieldPath.endsWith('.relation'),
          ),
          isTrue,
        );
      }
      expect(facts.where((fact) => fact.fieldPath == 'religion_year'), isEmpty);
      expect(
        facts.where((fact) => fact.fieldPath == 'president.checked'),
        isEmpty,
      );
      expect(
        facts.where(
          (fact) => fact.sources.any(
            (source) =>
                source.titleRu.contains('factbook-') ||
                source.titleRu.contains('president-') ||
                source.titleRu.contains('curated-'),
          ),
        ),
        isEmpty,
      );
      final backRub = facts.singleWhere((fact) => fact.valueEn == 'BackRub');
      expect(backRub.fieldPath, 'historical_project');
      expect(backRub.fieldRu, 'Исследовательский проект до Гугл');
      expect(backRub.fieldEn, 'Research project before Google');
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.contains('former_names') &&
              fact.valueEn == 'BackRub',
        ),
        isEmpty,
      );
      expect(facts.where((fact) => fact.fieldPath == 'owner.name'), isNotEmpty);
      expect(
        facts.where(
          (fact) =>
              fact.fieldPath.contains('cast.') && fact.fieldRu.contains(':'),
        ),
        isNotEmpty,
      );
      expect(
        facts.where((fact) => fact.fieldPath.startsWith('credit_work_ids.')),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) => fact.scope == 'people' && fact.fieldPath == 'born',
        ),
        isNotEmpty,
      );
      expect(
        facts.where(
          (fact) => fact.fieldPath == 'date' && fact.valueEn.startsWith('-'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'builds deterministic checkable questions with exactly one valid answer',
    () async {
      final questions = buildFactQuestions(
        await loadStudyFacts('all'),
        seed: 17,
      );
      expect(questions, isNotEmpty);
      expect(questions, hasLength((await loadStudyFacts('all')).length));
      for (final question in questions) {
        expect(question.options, hasLength(greaterThanOrEqualTo(2)));
        expect(
          question.options.map((option) => option.id).toSet(),
          hasLength(question.options.length),
        );
        expect(
          question.options.where((option) => option.id == question.correctId),
          hasLength(1),
        );
        expect(
          question.options.where(
            (option) => option.textRu == question.fact.valueRu,
          ),
          hasLength(1),
        );
        expect(
          question.options.where(
            (option) => option.textEn == question.fact.valueEn,
          ),
          hasLength(1),
        );
        expect(
          question.fact.sources.every((source) {
            final uri = Uri.tryParse(source.url);
            return uri?.scheme == 'https' &&
                uri?.host.isNotEmpty == true &&
                source.titleRu.trim().isNotEmpty;
          }),
          isTrue,
        );
      }
      expect(
        buildFactQuestions(
          await loadStudyFacts('music'),
          seed: 17,
        ).map((item) => item.fact.id),
        orderedEquals(
          buildFactQuestions(
            await loadStudyFacts('music'),
            seed: 17,
          ).map((item) => item.fact.id),
        ),
      );
    },
  );

  test('excludes every other value belonging to the target entity', () {
    const target = StudyFact(
      id: 'a',
      scope: 'food',
      entityId: 'pizza',
      nameRu: 'Пицца',
      nameEn: 'Pizza',
      fieldPath: 'ingredients.0.name',
      fieldRu: 'Ингредиент',
      fieldEn: 'Ingredient',
      valueRu: 'томаты',
      valueEn: 'tomatoes',
      sources: [
        FactSource(
          titleRu: 'Источник',
          titleEn: 'Source',
          url: 'https://example.test/a',
        ),
      ],
    );
    const anotherTargetValue = StudyFact(
      id: 'b',
      scope: 'food',
      entityId: 'pizza',
      nameRu: 'Пицца',
      nameEn: 'Pizza',
      fieldPath: 'ingredients.1.name',
      fieldRu: 'Ингредиент',
      fieldEn: 'Ingredient',
      valueRu: 'базилик',
      valueEn: 'basil',
      sources: [
        FactSource(
          titleRu: 'Источник',
          titleEn: 'Source',
          url: 'https://example.test/a',
        ),
      ],
    );
    const peer = StudyFact(
      id: 'c',
      scope: 'food',
      entityId: 'soup',
      nameRu: 'Суп',
      nameEn: 'Soup',
      fieldPath: 'ingredients.0.name',
      fieldRu: 'Ингредиент',
      fieldEn: 'Ingredient',
      valueRu: 'морковь',
      valueEn: 'carrot',
      sources: [
        FactSource(
          titleRu: 'Источник',
          titleEn: 'Source',
          url: 'https://example.test/b',
        ),
      ],
    );
    final question = buildFactQuestions([target, anotherTargetValue, peer])
        .singleWhere((item) => item.fact.id == 'a');
    expect(question.options.map((item) => item.id), isNot(contains('b')));
  });
}
