import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/animal_atlas.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle([this.animalJson = _animalsJson]);

  final String animalJson;

  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('No binary test asset for $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/quizipedia/atlas_media.json') return '[]';
    if (key != 'assets/quizipedia/animals.json') {
      throw FlutterError('unexpected asset $key');
    }
    return animalJson;
  }
}

const _animalsJson = '''{
      "schema_version":"qm-animals/v1",
      "animals":[
        {"id":"beagle","name_ru":"Бигль","wiki_title":"Beagle","group_ru":"Собаки","kind_ru":"Порода","fact_ru":"Факт бигля","source_url":"https://example.test/beagle"},
        {"id":"poodle","name_ru":"Пудель","wiki_title":"Poodle","group_ru":"Собаки","kind_ru":"Порода","fact_ru":"Факт пуделя","source_url":"https://example.test/poodle"},
        {"id":"maine_coon","name_ru":"Мейн-кун","wiki_title":"Maine Coon","group_ru":"Кошки","kind_ru":"Порода","fact_ru":"Факт мейн-куна","source_url":"https://example.test/maine"},
        {"id":"siamese","name_ru":"Сиамская кошка","wiki_title":"Siamese","group_ru":"Кошки","kind_ru":"Порода","fact_ru":"Факт сиамской кошки","source_url":"https://example.test/siamese"},
        {"id":"goldfish","name_ru":"Золотая рыбка","wiki_title":"Goldfish","group_ru":"Рыбы","kind_ru":"Вид","fact_ru":"Факт золотой рыбки","source_url":"https://example.test/goldfish"},
        {"id":"clownfish","name_ru":"Оцеллярис","wiki_title":"Clownfish","group_ru":"Рыбы","kind_ru":"Вид","fact_ru":"Факт оцелляриса","source_url":"https://example.test/clownfish"},
        {"id":"budgerigar","name_ru":"Волнистый попугай","wiki_title":"Budgerigar","group_ru":"Птицы","kind_ru":"Вид","fact_ru":"Факт волнистого попугая","source_url":"https://example.test/budgie"},
        {"id":"macaw","name_ru":"Сине-жёлтый ара","wiki_title":"Macaw","group_ru":"Птицы","kind_ru":"Вид","fact_ru":"Факт ара","source_url":"https://example.test/macaw"},
        {"id":"lion","name_ru":"Лев","wiki_title":"Lion","group_ru":"Дикие млекопитающие","kind_ru":"Вид","fact_ru":"Факт льва","source_url":"https://example.test/lion"},
        {"id":"tiger","name_ru":"Тигр","wiki_title":"Tiger","group_ru":"Дикие млекопитающие","kind_ru":"Вид","fact_ru":"Факт тигра","source_url":"https://example.test/tiger"}
      ]
    }''';

Widget _app() {
  final bundle = _Bundle();
  return DefaultAssetBundle(
    bundle: bundle,
    child: MaterialApp(home: AnimalsPage(bundle: bundle)),
  );
}

void main() {
  test('animal facts retain every source-backed record', () async {
    final facts = animalStudyFacts(await loadAnimals(_Bundle()));
    expect(facts, hasLength(10));
    expect(facts.every((fact) => fact.scope == 'animals'), isTrue);
    expect(
      facts.every((fact) => fact.sources.single.url.startsWith('https://')),
      isTrue,
    );
  });

  test(
    'catalogue rejects empty fields, duplicate IDs, and non-HTTPS sources',
    () async {
      final invalid = jsonDecode(_animalsJson) as Map<String, dynamic>;
      final animals = invalid['animals'] as List;

      (animals.first as Map<String, dynamic>)['name_ru'] = ' ';
      await expectLater(
        loadAnimals(_Bundle(jsonEncode(invalid))),
        throwsFormatException,
      );

      (animals.first as Map<String, dynamic>)['name_ru'] = 'Бигль';
      (animals[1] as Map<String, dynamic>)['id'] = 'beagle';
      await expectLater(
        loadAnimals(_Bundle(jsonEncode(invalid))),
        throwsFormatException,
      );

      (animals[1] as Map<String, dynamic>)['id'] = 'poodle';
      (animals.first as Map<String, dynamic>)['source_url'] =
          'http://example.test';
      await expectLater(
        loadAnimals(_Bundle(jsonEncode(invalid))),
        throwsFormatException,
      );
    },
  );

  testWidgets('group filter distinguishes breeds from species records', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Все (10)'), findsOneWidget);
    expect(find.text('Порода · Собаки'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('animal-group-Рыбы')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('animal-goldfish')), findsOneWidget);
    expect(find.byKey(const Key('animal-beagle')), findsNothing);
    expect(find.text('Вид · Рыбы'), findsNWidgets(2));
  });

  testWidgets('search opens a source-linked detail with image fallback', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('animal-search')), 'Бигль');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('animal-beagle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('animal-details')), findsOneWidget);
    expect(find.text('Факт бигля'), findsOneWidget);
    expect(find.text('Источник факта'), findsOneWidget);
  });
}
