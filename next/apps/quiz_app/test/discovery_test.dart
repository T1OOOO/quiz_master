import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  test('category cover resolver uses topic art and a stable fallback', () {
    expect(
      categoryCoverAsset('География/Столицы'),
      'assets/categories/geography-capitals.png',
    );
    expect(
      categoryCoverAsset('Мифология/Греция/Боги'),
      'assets/categories/mythology-greece.png',
    );
    expect(
      categoryCoverAsset('География/СтолицыЛайф'),
      'assets/categories/geography.jpg',
    );
    expect(categoryCoverAsset('Неизвестное'), 'assets/categories/nature.jpg');
  });

  for (final height in [568.0, 768.0]) {
    testWidgets(
      'twelve category cards fit a desktop screen of height $height',
      (tester) async {
        tester.view.physicalSize = Size(1262, height);
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
            lessThanOrEqualTo(height),
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
      },
    );
  }

  testWidgets('full catalog can be browsed without creating a guest', (
    tester,
  ) async {
    await _pumpDiscovery(tester, '/library');
    expect(find.byKey(const Key('catalog-search')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image && _assetName(widget) == 'assets/library-bg-v1.png',
      ),
      findsOneWidget,
    );
    expect(find.text('136 quizzes · 4084 questions'), findsOneWidget);
    expect(find.text('Display name'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SourceFolderCard),
        matching: find.byType(Image),
      ),
      findsNWidgets(15),
    );

    await tester.enterText(
      find.byKey(const Key('catalog-search')),
      'Смешанный',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('pack-pub-connections-20261014')),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('catalog-search')), 'Столицы');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-prep-capitals-1')), findsOneWidget);
    final capitalsCover = tester.widget<Image>(
      find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('pack-prep-capitals-1')),
          matching: find.byType(Card),
        ),
        matching: find.byType(Image),
      ),
    );
    expect(
      _assetName(capitalsCover),
      'assets/categories/geography-capitals.png',
    );

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

  testWidgets('narrow text-scaled catalog keeps its quiz card actionable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 738);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpDiscovery(
      tester,
      '/library?q=%D0%A1%D1%82%D0%BE%D0%BB%D0%B8%D1%86%D1%8B',
    );
    final card = find.byKey(const Key('pack-prep-capitals-1'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: card, matching: find.byType(Card)),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
    final round = find.descendant(
      of: find.ancestor(of: card, matching: find.byType(Card)),
      matching: find.byType(ActionChip),
    );
    expect(tester.widget<ActionChip>(round).onPressed, isNotNull);
    expect(tester.widget<ListTile>(card).onTap, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long LOTR title remains available on a narrow text-scaled card',
    (tester) async {
      tester.view.physicalSize = const Size(361, 738);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pumpDiscovery(
        tester,
        '/library?q=%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5',
      );
      expect(
        find.byKey(const Key('pack-lotr-return-king-bts-100')),
        findsOneWidget,
      );
      expect(
        find.text('Властелин Колец: Возвращение Короля и Создание'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

String? _assetName(Image image) {
  final provider = image.image;
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage && provider.imageProvider is AssetImage) {
    return (provider.imageProvider as AssetImage).assetName;
  }
  return null;
}

Future<void> _pumpDiscovery(WidgetTester tester, String location) async {
  // Wait for real asset IO outside fake-async, not for an arbitrary delay.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        child: QuizApp(initialLocation: location, defaultLocale: Locale('en')),
      ),
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
