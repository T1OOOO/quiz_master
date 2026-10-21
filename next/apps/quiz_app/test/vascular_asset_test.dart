import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/fact_practice_models.dart';
import 'package:quiz_app/vascular_atlas.dart';

class _RecordingBundle extends CachingAssetBundle {
  final requested = <String>[];
  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('vessel facts load only their asset and retain six choices after single-region filtering', () async {
    final bundle = _RecordingBundle();
    final facts = await loadStudyFacts('vascular', bundle: bundle);
    expect(bundle.requested, [vascularAtlasAsset]);
    final atlas = VascularAtlas.fromJson(
      jsonDecode(await rootBundle.loadString(vascularAtlasAsset)),
    );
    expect(atlas.records, hasLength(15));
    expect(facts, hasLength(45));
    expect(
      facts.map((fact) => fact.id).toSet(),
      vascularStudyFacts(
        atlas.records,
        atlas.sources,
      ).map((fact) => fact.id).toSet(),
    );
    final neckIds = atlas.records
        .where((record) => record.region == 'neck')
        .map((record) => record.id)
        .toSet();
    expect(neckIds, hasLength(1));
    final questions = buildFactQuestions(facts)
        .where((question) => neckIds.contains(question.fact.entityId));
    expect(questions, hasLength(3));
    for (final question in buildFactQuestions(facts)) {
      expect(
        question.options.map((option) => option.textRu).toSet(),
        hasLength(6),
        reason: question.fact.id,
      );
      expect(
        question.options.where((option) => option.id == question.correctId),
        hasLength(1),
      );
      expect(question.fact.sources, isNotEmpty);
    }
  });
}
