import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('twelve category cards fit a short desktop screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1262, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const roots = [
      'Гастрономия',
      'География',
      'История',
      'Кино',
      'Литература',
      'Мифология',
      'Музыка',
      'Новый Год',
      'Природа',
      'Психология',
      'Филии',
      'Филология',
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryCatalogProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < roots.length; i++)
                CatalogPack(
                  'category-$i',
                  'Quiz $i',
                  'Description',
                  '${roots[i]}/Test',
                  20,
                ),
            ],
          ),
        ],
        child: QuizApp(initialLocation: '/library'),
      ),
    );
    await tester.pumpAndSettle();
    for (final root in roots) {
      expect(
        tester.getBottomRight(find.byKey(Key('folder-$root'))).dy,
        lessThanOrEqualTo(568),
        reason: '$root is below the viewport',
      );
    }
    const covers = {
      'Литература': 'philology',
      'Музыка': 'music',
      'История': 'history',
      'Мифология': 'mythology',
    };
    for (final entry in covers.entries) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(Key('folder-${entry.key}')),
          matching: find.byType(Image),
        ),
      );
      expect(
        (image.image as ResizeImage).imageProvider,
        isA<AssetImage>().having(
          (asset) => asset.assetName,
          'assetName',
          'assets/categories/${entry.value}.jpg',
        ),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('full catalog can be browsed without creating a guest', (
    tester,
  ) async {
    await _pumpDiscovery(tester, '/library');
    expect(find.byKey(const Key('catalog-search')), findsOneWidget);
    expect(find.text('115 quizzes · 3798 questions'), findsOneWidget);
    expect(find.text('Display name'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SourceFolderCard),
        matching: find.byType(Image),
      ),
      findsNWidgets(12),
    );

    await tester.enterText(find.byKey(const Key('catalog-search')), 'Столицы');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-prep-capitals-1')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('catalog-search')), 'сыр');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pack-gastronomy-cheeses-and-dairy')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('folder-Кино')), findsNothing);
    final card = tester.widget<ListTile>(
      find.byKey(const Key('pack-gastronomy-cheeses-and-dairy')),
    );
    expect(
      card.onTap,
      isNotNull,
    ); // Every migrated source pack must have a real start action.

    await tester.enterText(
      find.byKey(const Key('catalog-search')),
      'no-such-quiz',
    );
    await tester.pumpAndSettle();
    expect(find.text('No quizzes match your search.'), findsOneWidget);
  });

  testWidgets('geography has its own category cover', (tester) async {
    await _pumpDiscovery(tester, '/library');
    final cover = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('folder-География')),
        matching: find.byType(Image),
      ),
    );
    expect(
      (cover.image as ResizeImage).imageProvider,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        'assets/categories/geography.jpg',
      ),
    );
  });

  testWidgets('folder deep link and breadcrumbs restore catalog navigation', (
    tester,
  ) async {
    await _pumpDiscovery(tester, '/library?folder=%D0%9A%D0%B8%D0%BD%D0%BE');
    expect(find.byKey(const Key('catalog-search')), findsOneWidget);
    expect(find.byKey(const Key('catalog-root')), findsOneWidget);
    await tester.tap(find.byKey(const Key('catalog-root')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('folder-Кино')), findsOneWidget);
  });
}

Future<void> _pumpDiscovery(WidgetTester tester, String location) async {
  // Wait for real asset IO outside fake-async, not for an arbitrary delay.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(child: QuizApp(initialLocation: location)),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DiscoveryPage)),
    );
    await container
        .read(discoveryCatalogProvider.future)
        .timeout(const Duration(seconds: 5));
  });
  await tester.pumpAndSettle();
}
