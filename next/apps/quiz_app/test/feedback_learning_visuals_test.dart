import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/music_learning.dart';
import 'package:quiz_app/organ_atlas.dart';
import 'package:quiz_app/organ_atlas_models.dart';

void main() {
  testWidgets(
    'atlas uses direct structure cards instead of paged numbered callouts',
    (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: OrganAtlasPage()));
        await tester.pump();
        final future = tester.widget<FutureBuilder<OrganAtlas>>(
          find.byWidgetPredicate(
            (widget) => widget is FutureBuilder<OrganAtlas>,
          ),
        );
        await future.future!;
      });
      await tester.pump();

      expect(find.byKey(const Key('organ-callouts-next')), findsNothing);
      expect(find.byKey(const Key('organ-map-card-brain')), findsOneWidget);
    },
  );

  testWidgets(
    'notation cards show their real glyph preview in the reference list',
    (tester) async {
      await tester.runAsync(() async {
        await MusicCatalog.load();
        await tester.pumpWidget(const MaterialApp(home: MusicLearningPage()));
        await tester.pump();
      });
      await tester.pump();

      final note = find.byKey(const Key('music-entry-note-0'));
      expect(note, findsOneWidget);
      expect(
        find.descendant(of: note, matching: find.byType(MusicVisual)),
        findsOneWidget,
      );
    },
  );
}
