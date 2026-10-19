import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice.dart';
import 'package:quiz_app/fact_practice_models.dart';
import 'package:quiz_app/organ_atlas_models.dart';
import 'package:quiz_app/organ_atlas.dart';

class _BoneBundle extends CachingAssetBundle {
  _BoneBundle(this.atlas);
  final String atlas;
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      key == organAtlasAsset ? atlas : '{}';
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 206 individual adult bones reconcile to the eight counted groups',
    () async {
      final raw =
          jsonDecode(await rootBundle.loadString(organAtlasAsset)) as Map;
      final rows = (raw['organs'] as List).cast<Map>();
      final bones = rows.where((row) => row['kind'] == 'bone').toList();
      expect(bones, hasLength(206));
      expect(bones.map((row) => row['id']).toSet(), hasLength(206));
      expect(bones.map((row) => row['name_ru']).toSet(), hasLength(206));
      final groups = rows.where((row) => row['kind'] == 'bone_group');
      expect(groups, hasLength(8));
      for (final group in groups) {
        expect(
          bones.where((row) => row['parent_group_id'] == group['id']).length,
          group['bone_count'],
          reason: '${group['id']} must account for each adult bone once',
        );
      }
      for (final bone in bones) {
        expect(bone.containsKey('bone_count'), isFalse);
        expect(bone.containsKey('diagram_anchor'), isFalse);
        expect(bone['source_ids'], isNotEmpty);
      }
      expect(
        bones.where((row) => (row['id'] as String).contains('-metacarpal-')),
        hasLength(10),
      );
      expect(
        bones.where((row) => (row['id'] as String).contains('-metatarsal-')),
        hasLength(10),
      );
      for (final row in bones.where(
        (row) => (row['id'] as String).contains('-metacarpal-'),
      )) {
        expect(row['position_ru'], 'В ладони кисти, дистальнее запястья.');
      }
    },
  );

  test(
    'individual bones accept limb and spine regions without diagram anchors',
    () async {
      final raw =
          jsonDecode(await rootBundle.loadString(organAtlasAsset)) as Map;
      final template = Map<String, dynamic>.from(
        (raw['organs'] as List).first as Map,
      );
      for (final region in ['upper_limb', 'lower_limb', 'spine']) {
        final bone = OrganStructure.fromJson({
          ...template,
          'id': 'individual-$region',
          'kind': 'bone',
          'region': region,
          'diagram_group': 'skeleton',
        });
        expect(bone.kind, 'bone');
        expect(bone.region, region);
      }
    },
  );

  testWidgets(
    'one selected bone keeps fair distractors from the complete fact bank',
    (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final facts = [
        for (var i = 0; i < 4; i++)
          StudyFact(
            id: 'bone-fact-$i',
            scope: 'organs',
            entityId: 'bone-$i',
            nameRu: 'Кость $i',
            nameEn: 'Bone $i',
            fieldPath: 'description',
            fieldRu: 'Описание',
            fieldEn: 'Description',
            valueRu: 'Описание кости $i',
            valueEn: 'Bone description $i',
            sources: const [],
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: FactPracticePage(
            scope: 'organs',
            facts: facts,
            entityIds: const {'bone-0'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Доступно вопросов: 1'), findsOneWidget);
      expect(find.byKey(const Key('fact-open-bone-fact-0')), findsOneWidget);
      for (var i = 1; i < 4; i++) {
        expect(find.byKey(Key('fact-open-bone-fact-$i')), findsNothing);
      }
      final target = find.byKey(const Key('fact-open-bone-fact-0'));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsNWidgets(4));
      expect(find.text('Описание кости 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bone training opens checked facts when no curated question targets it',
    (tester) async {
      tester.view.physicalSize = const Size(320, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Map<String, dynamic> raw;
      await tester.runAsync(() async {
        raw = jsonDecode(
          await rootBundle.loadString(organAtlasAsset),
        ) as Map<String, dynamic>;
      });
      raw['organs'] = (raw['organs'] as List)
          .take(4)
          .map(
            (row) => {
              ...Map<String, dynamic>.from(row as Map),
              'kind': 'bone',
              'region': 'upper_limb',
              'diagram_group': 'skeleton',
            },
          )
          .toList();
      raw['questions'] = [];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: OrganAtlasPage(bundle: _BoneBundle(jsonEncode(raw))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тренировка'));
      await tester.pumpAndSettle();
      expect(
        find.text('Факты из карточек · вопросы с проверкой ответа'),
        findsOneWidget,
      );
      expect(find.text('Доступно вопросов: 0'), findsNothing);
      expect(
        find.text('Нет подходящих вопросов для этих фильтров.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
