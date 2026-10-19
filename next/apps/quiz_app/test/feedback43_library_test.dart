import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('library pack card stays compact and launches directly', (
    tester,
  ) async {
    await _pumpLibrary(tester, '/library?q=compact');

    final card = find.ancestor(
      of: find.byKey(const Key('pack-compact')),
      matching: find.byType(Card),
    );
    expect(tester.getRect(card).height, lessThanOrEqualTo(96));
    expect(find.text('20 questions'), findsOneWidget);
    expect(find.text('Unused description'), findsNothing);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('pack-compact'))).onTap,
      isNotNull,
    );
  });

  testWidgets('category library uses its current category cover as background', (
    tester,
  ) async {
    await _pumpLibrary(
      tester,
      '/library?folder=%D0%93%D0%B5%D0%BE%D0%B3%D1%80%D0%B0%D1%84%D0%B8%D1%8F',
    );

    final background = find.byKey(const Key('source-background'));
    final image = tester.widget<Image>(background);
    expect(_assetName(image), 'assets/categories/geography.jpg');
  });
}

Future<void> _pumpLibrary(WidgetTester tester, String location) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryCatalogProvider.overrideWith(
          (ref) async => const [
            CatalogPack(
              'compact',
              'Compact pack',
              'Unused description',
              'География/Столицы',
              20,
            ),
          ],
        ),
      ],
      child: QuizApp(
        initialLocation: location,
        defaultLocale: const Locale('en'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String? _assetName(Image image) {
  final provider = image.image;
  if (provider is AssetImage) return provider.assetName;
  if (provider is ResizeImage && provider.imageProvider is AssetImage) {
    return (provider.imageProvider as AssetImage).assetName;
  }
  return null;
}
